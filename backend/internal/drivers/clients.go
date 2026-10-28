package drivers

import (
	"net/http"
	"strings"
	"time"
	"unicode/utf8"

	"github.com/google/uuid"

	"github.com/kyq/backend/internal/auth"
	"github.com/kyq/backend/internal/httpx"
	"github.com/kyq/backend/internal/store"
)

// MaxNote is the length limit of a client note (010, FR-008).
const MaxNote = 500

// UpcomingReservation is a reservation of the client shown in his card.
type UpcomingReservation struct {
	ID          uuid.UUID `json:"id"`
	ScheduledAt time.Time `json:"scheduled_at"`
	Status      string    `json:"status"`
}

// ClientCard is GET /v1/driver/clients/{passengerId} (contracts: ClientCard): only for the
// driver; the note never reaches the passenger (SC-005).
type ClientCard struct {
	PassengerID   uuid.UUID             `json:"passenger_id"`
	DisplayName   string                `json:"display_name"`
	AffiliatedAt  time.Time             `json:"affiliated_at"`
	Source        string                `json:"source"`
	TripsTogether int                   `json:"trips_together"`
	LastTripAt    *time.Time            `json:"last_trip_at"`
	Note          *string               `json:"note"`
	Upcoming      []UpcomingReservation `json:"upcoming_reservations"`
}

func passengerID(w http.ResponseWriter, r *http.Request) (uuid.UUID, bool) {
	id, err := uuid.Parse(r.PathValue("passengerId"))
	if err != nil {
		httpx.WriteError(w, http.StatusNotFound, "client_not_found", "ese pasajero no está en tu cartera")
		return uuid.Nil, false
	}
	return id, true
}

func (h *Handlers) clientCard(w http.ResponseWriter, r *http.Request) {
	pid, ok := passengerID(w, r)
	if !ok {
		return
	}
	p, _ := auth.FromContext(r.Context())
	ctx := r.Context()
	row, err := h.Store.GetClientSummary(ctx, store.GetClientSummaryParams{DriverID: p.UserID, PassengerID: pid})
	if store.IsNotFound(err) {
		httpx.WriteError(w, http.StatusNotFound, "client_not_found", "ese pasajero no está en tu cartera")
		return
	}
	if err != nil {
		httpx.InternalError(w, r, err)
		return
	}
	card := ClientCard{
		PassengerID: pid, DisplayName: row.DisplayName, AffiliatedAt: row.AffiliatedAt, Source: row.Source,
		TripsTogether: int(row.TripsTogether), Upcoming: []UpcomingReservation{},
	}
	if row.LastTripUnix > 0 {
		last := time.Unix(row.LastTripUnix, 0).UTC()
		card.LastTripAt = &last
	}
	note, err := h.Store.GetClientNote(ctx, store.GetClientNoteParams{DriverID: p.UserID, PassengerID: pid})
	switch {
	case err == nil:
		card.Note = &note.Body
	case !store.IsNotFound(err):
		httpx.InternalError(w, r, err)
		return
	}
	upcoming, err := h.Store.ListUpcomingReservationsForPair(ctx, store.ListUpcomingReservationsForPairParams{
		PassengerID: pid, DriverID: p.UserID, Now: h.now(),
	})
	if err != nil {
		httpx.InternalError(w, r, err)
		return
	}
	for _, u := range upcoming {
		card.Upcoming = append(card.Upcoming, UpcomingReservation{ID: u.ID, ScheduledAt: u.ScheduledAt, Status: string(u.Status)})
	}
	httpx.WriteJSON(w, http.StatusOK, card)
}

// putNote saves or, with an empty body, deletes the note about a client (FR-008).
func (h *Handlers) putNote(w http.ResponseWriter, r *http.Request) {
	pid, ok := passengerID(w, r)
	if !ok {
		return
	}
	var body struct {
		Body string `json:"body"`
	}
	if !httpx.DecodeJSON(w, r, &body) {
		return
	}
	text := strings.TrimSpace(body.Body)
	if utf8.RuneCountInString(text) > MaxNote {
		httpx.WriteError(w, http.StatusBadRequest, "invalid_note", "la nota admite hasta 500 caracteres")
		return
	}
	p, _ := auth.FromContext(r.Context())
	ctx := r.Context()
	affiliated, err := h.Store.IsAffiliated(ctx, store.IsAffiliatedParams{PassengerID: pid, DriverID: p.UserID})
	if err != nil {
		httpx.InternalError(w, r, err)
		return
	}
	if !affiliated {
		httpx.WriteError(w, http.StatusNotFound, "client_not_found", "ese pasajero no está en tu cartera")
		return
	}
	if text == "" {
		err = h.Store.DeleteClientNote(ctx, store.DeleteClientNoteParams{DriverID: p.UserID, PassengerID: pid})
	} else {
		err = h.Store.UpsertClientNote(ctx, store.UpsertClientNoteParams{DriverID: p.UserID, PassengerID: pid, Body: text, UpdatedAt: h.now()})
	}
	if err != nil {
		httpx.InternalError(w, r, err)
		return
	}
	h.clientCard(w, r)
}
