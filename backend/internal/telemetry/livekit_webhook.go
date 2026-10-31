package telemetry

import (
	"context"
	"crypto/sha256"
	"crypto/subtle"
	"encoding/base64"
	"encoding/json"
	"errors"
	"io"
	"log/slog"
	"net/http"
	"strconv"
	"strings"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"

	"github.com/kyq/backend/internal/httpx"
	"github.com/kyq/backend/internal/store"
)

// LiveKitWebhook turns LiveKit's participant_left events into voice seconds of the trip's
// driver. LiveKit signs each call with a JWT (HS256, API secret) whose sha256 claim is the
// base64 SHA-256 of the body.
type LiveKitWebhook struct {
	APIKey    string
	APISecret string
	Store     *store.Store
	Usage     Usage
	// Radio receives the events of radio-* rooms (011): turn audio, track recordings and voice
	// seconds. nil ignores them.
	Radio RadioRooms
}

// RadioRooms is what the webhook tells Radio Kyq (implemented by radio.Service).
type RadioRooms interface {
	TrackPublished(ctx context.Context, room, identity string)
	TrackUnpublished(ctx context.Context, room, identity string)
	ParticipantLeft(ctx context.Context, room, identity string, seconds int64)
	EgressStarted(ctx context.Context, room, egressID string)
	EgressEnded(ctx context.Context, room, egressID, key string, durationMs, size int64, failed bool)
}

func (h *LiveKitWebhook) Register(mux *http.ServeMux) {
	mux.HandleFunc("POST /v1/livekit/webhook", h.serve)
}

type flexInt int64

// UnmarshalJSON accepts protojson's int64-as-string as well as plain numbers.
func (f *flexInt) UnmarshalJSON(b []byte) error {
	n, err := strconv.ParseInt(strings.Trim(string(b), `"`), 10, 64)
	*f = flexInt(n)
	return err
}

type webhookEvent struct {
	Event       string                `json:"event"`
	CreatedAt   flexInt               `json:"createdAt"`
	Room        struct{ Name string } `json:"room"`
	Participant struct {
		Identity string  `json:"identity"`
		JoinedAt flexInt `json:"joinedAt"`
	} `json:"participant"`
	Track struct {
		Source string `json:"source"`
	} `json:"track"`
	EgressInfo struct {
		EgressID    string `json:"egressId"`
		RoomName    string `json:"roomName"`
		Status      string `json:"status"`
		Error       string `json:"error"`
		FileResults []struct {
			Filename string  `json:"filename"`
			Duration flexInt `json:"duration"` // nanosegundos
			Size     flexInt `json:"size"`
		} `json:"fileResults"`
	} `json:"egressInfo"`
}

var errBadSignature = errors.New("invalid livekit webhook signature")

func (h *LiveKitWebhook) verify(r *http.Request, body []byte) error {
	raw := strings.TrimPrefix(r.Header.Get("Authorization"), "Bearer ")
	claims := jwt.MapClaims{}
	_, err := jwt.ParseWithClaims(raw, claims, func(*jwt.Token) (any, error) { return []byte(h.APISecret), nil },
		jwt.WithValidMethods([]string{"HS256"}), jwt.WithIssuer(h.APIKey))
	if err != nil {
		return errBadSignature
	}
	want, _ := claims["sha256"].(string)
	sum := sha256.Sum256(body)
	if subtle.ConstantTimeCompare([]byte(want), []byte(base64.StdEncoding.EncodeToString(sum[:]))) != 1 {
		return errBadSignature
	}
	return nil
}

func (h *LiveKitWebhook) serve(w http.ResponseWriter, r *http.Request) {
	body, err := io.ReadAll(http.MaxBytesReader(w, r.Body, httpx.MaxBodyBytes))
	if err != nil {
		httpx.WriteError(w, http.StatusBadRequest, "invalid_body", "cuerpo inválido")
		return
	}
	if err := h.verify(r, body); err != nil {
		httpx.WriteError(w, http.StatusUnauthorized, "invalid_signature", "firma inválida")
		return
	}
	var ev webhookEvent
	if err := json.Unmarshal(body, &ev); err != nil {
		httpx.WriteError(w, http.StatusBadRequest, "invalid_body", "cuerpo inválido")
		return
	}
	if h.radioEvent(r, ev) {
		w.WriteHeader(http.StatusOK)
		return
	}
	if ev.Event == "participant_left" {
		h.countVoice(r, ev)
	}
	w.WriteHeader(http.StatusOK)
}

// radioEvent forwards the events of radio-* rooms to Radio Kyq and reports whether it did.
func (h *LiveKitWebhook) radioEvent(r *http.Request, ev webhookEvent) bool {
	room := ev.Room.Name
	if ev.EgressInfo.RoomName != "" {
		room = ev.EgressInfo.RoomName
	}
	if !strings.HasPrefix(room, "radio-") {
		return false
	}
	if h.Radio == nil {
		return true
	}
	ctx := r.Context()
	switch ev.Event {
	case "track_published":
		if ev.Track.Source == "" || ev.Track.Source == "MICROPHONE" {
			h.Radio.TrackPublished(ctx, room, ev.Participant.Identity)
		}
	case "track_unpublished":
		h.Radio.TrackUnpublished(ctx, room, ev.Participant.Identity)
	case "participant_left":
		seconds := int64(0)
		if ev.Participant.JoinedAt > 0 {
			seconds = int64(ev.CreatedAt - ev.Participant.JoinedAt)
		}
		h.Radio.ParticipantLeft(ctx, room, ev.Participant.Identity, seconds)
	case "egress_started":
		h.Radio.EgressStarted(ctx, room, ev.EgressInfo.EgressID)
	case "egress_ended":
		info := ev.EgressInfo
		failed := info.Status == "EGRESS_FAILED" || info.Status == "EGRESS_ABORTED" || info.Error != ""
		var key string
		var durationMs, size int64
		if len(info.FileResults) > 0 {
			f := info.FileResults[0]
			key, durationMs, size = f.Filename, int64(f.Duration)/1_000_000, int64(f.Size)
		}
		h.Radio.EgressEnded(ctx, room, info.EgressID, key, durationMs, size, failed)
	}
	return true
}

func (h *LiveKitWebhook) countVoice(r *http.Request, ev webhookEvent) {
	seconds := int64(ev.CreatedAt - ev.Participant.JoinedAt)
	if seconds <= 0 || ev.Participant.JoinedAt == 0 {
		return
	}
	driverID, err := h.roomDriver(r, ev.Room.Name)
	if err != nil {
		slog.WarnContext(r.Context(), "voice usage without trip", "room", ev.Room.Name, "err", err)
		return
	}
	Add(h.Usage, driverID, VoiceSeconds, seconds)
}

// roomDriver devuelve el conductor que paga la sala: la del viaje (`trip-{id}`), la de una
// pre-consulta (`pre-{id}`, specs/005-ptt-extras) o la de una alerta SOS (`sos-...`,
// specs/003-sos-emergency-console), cuya voz cuenta en el conductor del viaje asociado.
func (h *LiveKitWebhook) roomDriver(r *http.Request, room string) (uuid.UUID, error) {
	if rest, ok := strings.CutPrefix(room, "pre-"); ok {
		id, err := uuid.Parse(rest)
		if err != nil {
			return uuid.Nil, err
		}
		return h.Store.GetPreconsultDriver(r.Context(), id)
	}
	var tripID uuid.UUID
	var err error
	if strings.HasPrefix(room, "sos-") {
		alert, err := h.Store.GetSOSAlertRoom(r.Context(), room)
		if err != nil {
			return uuid.Nil, err
		}
		// 011: una alerta desde Radio sin viaje cuenta en quien la levantó (research R7).
		if !alert.TripID.Valid {
			return alert.RaisedBy, nil
		}
		tripID = alert.TripID.UUID
	} else {
		tripID, err = uuid.Parse(strings.TrimPrefix(room, "trip-"))
	}
	if err != nil {
		return uuid.Nil, err
	}
	parties, err := h.Store.GetTripParties(r.Context(), tripID)
	if err != nil {
		return uuid.Nil, err
	}
	return parties.DriverID, nil
}
