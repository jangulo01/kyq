// Package safety is the safety toolkit of 003 (RN-KYQ-015): the SOS button of a trip (alert,
// location at 1 Hz, live voice room with the operators and its recording), the emergency
// console of the operators, the live trip link and the emergency contacts and PIN.
//
// The other party of the trip never learns about an alert (FR-006): SOS events only go to
// ops:sos and sos:{alertId} (operators) and to user:{raisedBy}.
package safety

import (
	"context"
	"errors"
	"log/slog"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"

	"github.com/kyq/backend/internal/notify"
	"github.com/kyq/backend/internal/ptt"
	"github.com/kyq/backend/internal/realtime"
	"github.com/kyq/backend/internal/storage"
	"github.com/kyq/backend/internal/store"
	"github.com/kyq/backend/internal/telemetry"
	"github.com/kyq/backend/internal/trips"
)

const (
	// EscalateAfter is how long an alert may wait unclaimed before the on-duty operators get an
	// SMS (FR-011).
	EscalateAfter = 60 * time.Second
	// MaxPINAttempts wrong PINs block cancelling until an operator closes the alert (research R6).
	MaxPINAttempts = 5
	// MaxBatch caps the points of one POST /v1/sos/{id}/locations.
	MaxBatch = 5
	// RecordingURLTTL bounds the signed URL of a recording (research R4).
	RecordingURLTTL = 5 * time.Minute
	// ShareGrace keeps a shared link answering 15 min after the trip ends (FR-014).
	ShareGrace = trips.PTTCloseDelay
)

var (
	ErrNotFound         = errors.New("not found")
	ErrUnavailable      = errors.New("sos only during a trip")
	ErrClosed           = errors.New("alert closed")
	ErrInvalidLocation  = errors.New("invalid location")
	ErrNoPIN            = errors.New("no safety pin")
	ErrInvalidPIN       = errors.New("invalid pin")
	ErrPINLocked        = errors.New("pin locked")
	ErrVoiceUnavailable = errors.New("voice server unavailable")
)

// Voice manages the LiveKit room and the recording of each alert (ptt.LiveKit implements it).
type Voice interface {
	CreateSOSRoom(ctx context.Context, name string) error
	// DeleteRoom succeeds when the room no longer exists.
	DeleteRoom(ctx context.Context, name string) error
	// SetCanPublish succeeds when the participant is not in the room.
	SetCanPublish(ctx context.Context, room, identity string, canPublish bool) error
	StartAudioEgress(ctx context.Context, room, filepath string) (string, error)
	StopEgress(ctx context.Context, egressID string) error
}

// Service implements the safety use cases.
type Service struct {
	Store     *store.Store
	LiveKit   ptt.LiveKit // firma los tokens de las salas SOS
	Voice     Voice
	VoiceURL  string // URL WebSocket de LiveKit para las apps y la consola
	Publisher realtime.Publisher
	SMS       notify.SMSSender
	// Recordings reads the kyq-sos bucket to sign recording URLs; nil: no playback.
	Recordings storage.Objects
	// Record starts a LiveKit Egress per alert (FR-018); off where egress does not run.
	Record bool
	// PublicBaseURL is where contacts open shared links, e.g. https://kyq.example.
	PublicBaseURL string
	Usage         telemetry.Usage
	Now           func() time.Time
	Logger        *slog.Logger
	// Go runs background work (SMS to contacts) after answering; nil: a goroutine. Tests run
	// it inline.
	Go func(func())
}

func (s *Service) now() time.Time {
	if s.Now != nil {
		return s.Now()
	}
	return time.Now()
}

func (s *Service) logger() *slog.Logger {
	if s.Logger != nil {
		return s.Logger
	}
	return slog.Default()
}

func (s *Service) background(ctx context.Context, fn func(ctx context.Context)) {
	ctx = context.WithoutCancel(ctx)
	if s.Go != nil {
		s.Go(func() { fn(ctx) })
		return
	}
	go func() {
		ctx, cancel := context.WithTimeout(ctx, time.Minute)
		defer cancel()
		fn(ctx)
	}()
}

func ts(t time.Time) pgtype.Timestamptz { return pgtype.Timestamptz{Time: t, Valid: true} }

func nullID(id uuid.UUID) uuid.NullUUID { return uuid.NullUUID{UUID: id, Valid: true} }

func (s *Service) publish(ctx context.Context, channel, typ string, now time.Time, data any) {
	if s.Publisher == nil {
		return
	}
	if err := s.Publisher.Publish(ctx, channel, realtime.Event{Type: typ, OccurredAt: now, Data: data}); err != nil {
		s.logger().WarnContext(ctx, "publish "+typ, "channel", strings.SplitN(channel, ":", 2)[0], "err", err)
	}
}

// Point is one location fix sent by the app.
type Point struct {
	Lat        float64   `json:"lat"`
	Lng        float64   `json:"lng"`
	AccuracyM  *float64  `json:"accuracy_m,omitempty"`
	RecordedAt time.Time `json:"recorded_at"`
}

func (p Point) valid() bool {
	return p.Lat >= -90 && p.Lat <= 90 && p.Lng >= -180 && p.Lng <= 180 && (p.AccuracyM == nil || *p.AccuracyM >= 0)
}

// at clamps the recorded time: a future or missing time counts as now.
func (p Point) at(now time.Time) time.Time {
	if p.RecordedAt.IsZero() || p.RecordedAt.After(now) {
		return now
	}
	return p.RecordedAt.UTC().Truncate(time.Millisecond)
}

func accuracy(a *float64) pgtype.Float4 {
	if a == nil {
		return pgtype.Float4{}
	}
	return pgtype.Float4{Float32: float32(*a), Valid: true}
}

// AlertSelf is what the person who raised an alert sees (contracts: SosAlertSelf).
type AlertSelf struct {
	ID                uuid.UUID `json:"id"`
	TripID            uuid.UUID `json:"trip_id"`
	Status            string    `json:"status"`
	OperatorConnected bool      `json:"operator_connected"`
	Escalated         bool      `json:"escalated"`
	CreatedAt         time.Time `json:"created_at"`
}

func toSelf(a store.SosAlert) AlertSelf {
	return AlertSelf{
		ID: a.ID, TripID: a.TripID, Status: string(a.Status), OperatorConnected: a.Status == store.SosStatusClaimed,
		Escalated: a.EscalatedAt.Valid, CreatedAt: a.CreatedAt,
	}
}

func closed(a store.SosAlert) bool {
	return a.Status == store.SosStatusClosed || a.Status == store.SosStatusCancelledByUser
}

// VoiceCredentials join the alert's LiveKit room.
type VoiceCredentials struct {
	URL        string `json:"url"`
	Token      string `json:"token"`
	Room       string `json:"room"`
	CanPublish bool   `json:"can_publish"`
}

// RaiseResult is the body of POST /v1/trips/{tripId}/sos.
type RaiseResult struct {
	Alert AlertSelf `json:"alert"`
	// Voice is null when LiveKit did not answer: the app asks GET /v1/sos/{id}/token again.
	Voice *VoiceCredentials `json:"voice"`
	// NeedsPIN asks the app to set the safety PIN after the alert (US4-3).
	NeedsPIN bool `json:"needs_pin"`
}

// sosWindow reports whether trip allows an SOS: from ACCEPTED until 15 min after COMPLETED, the
// same window as the PTT channel (FR-001).
func sosWindow(status store.TripStatus, completedAt pgtype.Timestamptz, now time.Time) bool {
	switch status {
	case store.TripStatusACCEPTED, store.TripStatusARRIVED, store.TripStatusINPROGRESS:
		return true
	case store.TripStatusCOMPLETED:
		return completedAt.Valid && now.Before(completedAt.Time.Add(trips.PTTCloseDelay))
	}
	return false
}

// role returns the caller's role in the trip, or ErrNotFound when the caller is not a party
// (the trip's existence is not revealed).
func role(t store.GetTripForSOSRow, userID uuid.UUID) (store.SosRole, error) {
	switch userID {
	case t.PassengerID:
		return store.SosRolePassenger, nil
	case t.DriverID:
		return store.SosRoleDriver, nil
	}
	return "", ErrNotFound
}

// Raise creates the caller's alert on tripID, or returns the open one (created=false). The
// alert is stored and announced even if LiveKit fails: the location and the console matter more
// than the voice, which the app retries with Token.
func (s *Service) Raise(ctx context.Context, userID, tripID uuid.UUID, at *Point) (RaiseResult, bool, error) {
	now := s.now()
	if at != nil && !at.valid() {
		return RaiseResult{}, false, ErrInvalidLocation
	}
	trip, err := s.Store.GetTripForSOS(ctx, tripID)
	if store.IsNotFound(err) {
		return RaiseResult{}, false, ErrNotFound
	}
	if err != nil {
		return RaiseResult{}, false, err
	}
	raisedRole, err := role(trip, userID)
	if err != nil {
		return RaiseResult{}, false, err
	}
	id, err := uuid.NewV7()
	if err != nil {
		return RaiseResult{}, false, err
	}
	var alert store.SosAlert
	created := false
	err = s.Store.WithTx(ctx, func(q *store.Queries) error {
		var err error
		alert, err = q.GetOpenSOSAlertFor(ctx, store.GetOpenSOSAlertForParams{TripID: tripID, RaisedBy: userID})
		if err == nil {
			return nil // reintento de la app: la alerta abierta sigue valiendo fuera de la ventana
		}
		if !store.IsNotFound(err) {
			return err
		}
		if !sosWindow(trip.Status, trip.CompletedAt, now) {
			return ErrUnavailable
		}
		alert, err = q.InsertSOSAlert(ctx, store.InsertSOSAlertParams{
			ID: id, TripID: tripID, RaisedBy: userID, RaisedRole: raisedRole, RoomName: "sos-" + id.String(), CreatedAt: now,
		})
		if store.IsNotFound(err) {
			// Otra petición simultánea la creó.
			alert, err = q.GetOpenSOSAlertFor(ctx, store.GetOpenSOSAlertForParams{TripID: tripID, RaisedBy: userID})
			return err
		}
		if err != nil {
			return err
		}
		created = true
		if at == nil {
			return nil
		}
		return q.InsertSOSLocation(ctx, store.InsertSOSLocationParams{
			AlertID: alert.ID, At: at.at(now), Lat: at.Lat, Lng: at.Lng, AccuracyM: accuracy(at.AccuracyM),
		})
	})
	if err != nil {
		return RaiseResult{}, false, err
	}

	if created {
		s.openVoice(ctx, alert)
		name, err := s.Store.GetUserDisplayName(ctx, userID)
		if err != nil {
			return RaiseResult{}, false, err
		}
		s.publish(ctx, realtime.OpsSOSChannel, "sos.created", now, map[string]any{
			"alert_id": alert.ID, "trip_id": alert.TripID, "raised_role": alert.RaisedRole, "raised_by_name": name,
			"created_at": alert.CreatedAt, "location": at,
		})
		telemetry.Add(s.Usage, trip.DriverID, telemetry.Events, 1)
		s.background(ctx, func(ctx context.Context) { s.notifyContacts(ctx, userID, tripID, name) })
	}

	out := RaiseResult{Alert: toSelf(alert)}
	if creds, err := s.userCredentials(ctx, alert, userID); err == nil {
		out.Voice = &creds
	} else {
		s.logger().ErrorContext(ctx, "sos voice credentials", "alert_id", alert.ID, "err", err)
	}
	if _, err := s.Store.GetSafetyPin(ctx, userID); store.IsNotFound(err) {
		out.NeedsPIN = true
	} else if err != nil {
		return RaiseResult{}, false, err
	}
	return out, created, nil
}

// openVoice creates the room and starts the recording; failures are retried later (Token
// creates the room, the sweeper starts missing recordings).
func (s *Service) openVoice(ctx context.Context, alert store.SosAlert) {
	if err := s.Voice.CreateSOSRoom(ctx, alert.RoomName); err != nil {
		s.logger().ErrorContext(ctx, "create sos room", "alert_id", alert.ID, "err", err)
		return
	}
	s.startRecording(ctx, alert.ID, alert.RoomName)
}

// RecordingKey is the object of an alert's audio in the kyq-sos bucket: no personal data.
func RecordingKey(alertID uuid.UUID) string { return "sos/" + alertID.String() + ".ogg" }

func (s *Service) startRecording(ctx context.Context, alertID uuid.UUID, room string) {
	if !s.Record {
		return
	}
	key := RecordingKey(alertID)
	egressID, err := s.Voice.StartAudioEgress(ctx, room, key)
	if err != nil {
		s.logger().ErrorContext(ctx, "start sos recording", "alert_id", alertID, "err", err)
		return
	}
	if err := s.Store.SetSOSEgress(ctx, store.SetSOSEgressParams{
		ID: alertID, EgressID: pgtype.Text{String: egressID, Valid: true}, RecordingKey: pgtype.Text{String: key, Valid: true},
	}); err != nil {
		s.logger().ErrorContext(ctx, "save sos egress", "alert_id", alertID, "err", err)
	}
}

func (s *Service) userCredentials(ctx context.Context, alert store.SosAlert, userID uuid.UUID) (VoiceCredentials, error) {
	if err := s.Voice.CreateSOSRoom(ctx, alert.RoomName); err != nil {
		s.logger().ErrorContext(ctx, "create sos room", "alert_id", alert.ID, "err", err)
		return VoiceCredentials{}, ErrVoiceUnavailable
	}
	name, err := s.Store.GetUserDisplayName(ctx, userID)
	if err != nil {
		return VoiceCredentials{}, err
	}
	token, err := s.LiveKit.SOSToken(userID.String(), name, alert.RoomName, s.now(), ptt.TokenTTL)
	if err != nil {
		return VoiceCredentials{}, err
	}
	return VoiceCredentials{URL: s.VoiceURL, Token: token, Room: alert.RoomName, CanPublish: true}, nil
}

// own returns the alert when userID raised it.
func (s *Service) own(ctx context.Context, userID, alertID uuid.UUID) (store.SosAlert, error) {
	alert, err := s.Store.GetSOSAlert(ctx, alertID)
	if store.IsNotFound(err) || (err == nil && alert.RaisedBy != userID) {
		return store.SosAlert{}, ErrNotFound
	}
	return alert, err
}

// Token issues the person's room credentials again (reconnection).
func (s *Service) Token(ctx context.Context, userID, alertID uuid.UUID) (VoiceCredentials, error) {
	alert, err := s.own(ctx, userID, alertID)
	if err != nil {
		return VoiceCredentials{}, err
	}
	if closed(alert) {
		return VoiceCredentials{}, ErrClosed
	}
	return s.userCredentials(ctx, alert, userID)
}

// Active returns the caller's open alert, to resume it when the app reopens.
func (s *Service) Active(ctx context.Context, userID uuid.UUID) (*AlertSelf, error) {
	alert, err := s.Store.GetActiveSOSAlertForUser(ctx, userID)
	if store.IsNotFound(err) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	v := toSelf(alert)
	return &v, nil
}

// Locations stores a batch of fixes and forwards the newest to the operators (FR-003). A closed
// alert answers ErrClosed so the app stops sending.
func (s *Service) Locations(ctx context.Context, userID, alertID uuid.UUID, points []Point) (AlertSelf, error) {
	now := s.now()
	if len(points) == 0 || len(points) > MaxBatch {
		return AlertSelf{}, ErrInvalidLocation
	}
	for _, p := range points {
		if !p.valid() {
			return AlertSelf{}, ErrInvalidLocation
		}
	}
	alert, err := s.own(ctx, userID, alertID)
	if err != nil {
		return AlertSelf{}, err
	}
	if closed(alert) {
		return AlertSelf{}, ErrClosed
	}
	latest, latestAt := points[0], points[0].at(now)
	err = s.Store.WithTx(ctx, func(q *store.Queries) error {
		for _, p := range points {
			at := p.at(now)
			if at.After(latestAt) {
				latest, latestAt = p, at
			}
			if err := q.InsertSOSLocation(ctx, store.InsertSOSLocationParams{
				AlertID: alertID, At: at, Lat: p.Lat, Lng: p.Lng, AccuracyM: accuracy(p.AccuracyM),
			}); err != nil {
				return err
			}
		}
		return nil
	})
	if err != nil {
		return AlertSelf{}, err
	}
	s.publish(ctx, "sos:"+alertID.String(), "sos.location", now, map[string]any{
		"alert_id": alertID, "lat": latest.Lat, "lng": latest.Lng, "accuracy_m": latest.AccuracyM, "at": latestAt,
	})
	if parties, err := s.Store.GetTripParties(ctx, alert.TripID); err == nil {
		telemetry.Add(s.Usage, parties.DriverID, telemetry.Events, 1)
	}
	return toSelf(alert), nil
}

// Cancel closes the caller's alert only with the right PIN (FR-005). Without it the alert stays
// open and is flagged for the operator as a possible coercion; after MaxPINAttempts wrong PINs
// cancelling is blocked until an operator closes the alert.
func (s *Service) Cancel(ctx context.Context, userID, alertID uuid.UUID, pin string) error {
	now := s.now()
	var alert store.SosAlert
	var result error
	attempts := 0
	err := s.Store.WithTx(ctx, func(q *store.Queries) error {
		var err error
		alert, err = q.GetSOSAlertForUpdate(ctx, alertID)
		if store.IsNotFound(err) || (err == nil && alert.RaisedBy != userID) {
			return ErrNotFound
		}
		if err != nil {
			return err
		}
		if closed(alert) {
			return ErrClosed
		}
		row, err := q.GetSafetyPinForUpdate(ctx, userID)
		switch {
		case store.IsNotFound(err):
			result = ErrNoPIN
		case err != nil:
			return err
		case row.FailedAttempts >= MaxPINAttempts:
			result, attempts = ErrPINLocked, int(row.FailedAttempts)
		case !checkPIN(row.PinHash, pin):
			attempts = int(row.FailedAttempts) + 1
			result = ErrInvalidPIN
			if attempts >= MaxPINAttempts {
				result = ErrPINLocked
			}
			if err := q.SetSafetyPinAttempts(ctx, store.SetSafetyPinAttemptsParams{UserID: userID, FailedAttempts: int16(attempts)}); err != nil {
				return err
			}
		}
		if result != nil {
			// Se guarda la marca aunque la respuesta sea un error: el operador debe verla.
			return q.MarkSOSCancelWithoutPIN(ctx, alertID)
		}
		if err := q.SetSafetyPinAttempts(ctx, store.SetSafetyPinAttemptsParams{UserID: userID, FailedAttempts: 0}); err != nil {
			return err
		}
		_, err = q.CancelSOSAlert(ctx, store.CancelSOSAlertParams{Now: ts(now), ID: alertID})
		return err
	})
	if err != nil {
		return err
	}
	if result != nil {
		s.publish(ctx, realtime.OpsSOSChannel, "sos.cancel_attempt", now, map[string]any{
			"alert_id": alertID, "cancel_without_pin": true, "failed_attempts": attempts, "locked": errors.Is(result, ErrPINLocked),
		})
		return result
	}
	s.closeVoice(ctx, alert)
	s.publish(ctx, realtime.OpsSOSChannel, "sos.closed", now, map[string]any{
		"alert_id": alertID, "status": store.SosStatusCancelledByUser,
	})
	return nil
}

// closeVoice stops the recording and deletes the room of a closed alert. On failure the alert
// stays pending and the sweeper retries (the room keeps nobody talking: the alert is closed and
// no new token is issued).
func (s *Service) closeVoice(ctx context.Context, alert store.SosAlert) {
	if err := s.stopVoice(ctx, alert.ID, alert.RoomName, alert.EgressID); err != nil {
		s.logger().WarnContext(ctx, "close sos voice", "alert_id", alert.ID, "err", err)
	}
}

func (s *Service) stopVoice(ctx context.Context, alertID uuid.UUID, room string, egressID pgtype.Text) error {
	if egressID.Valid {
		if err := s.Voice.StopEgress(ctx, egressID.String); err != nil {
			return err
		}
	}
	if err := s.Voice.DeleteRoom(ctx, room); err != nil {
		return err
	}
	return s.Store.MarkSOSVoiceClosed(ctx, store.MarkSOSVoiceClosedParams{ID: alertID, VoiceClosedAt: ts(s.now())})
}

// notifyContacts sends each emergency contact an SMS with the live trip link (FR-017).
func (s *Service) notifyContacts(ctx context.Context, userID, tripID uuid.UUID, name string) {
	if s.SMS == nil {
		return
	}
	contacts, err := s.Store.ListEmergencyContacts(ctx, userID)
	if err != nil {
		s.logger().ErrorContext(ctx, "list emergency contacts", "err", err)
		return
	}
	if len(contacts) == 0 {
		return
	}
	link, err := s.shareLink(ctx, s.Store.Queries, userID, tripID)
	if err != nil {
		s.logger().ErrorContext(ctx, "share link for contacts", "err", err)
		return
	}
	body := "Kyq: " + name + " activó el botón de emergencia durante un viaje. Síguelo en vivo: " + link.URL +
		" . Si no responde, llama al 123."
	for _, c := range contacts {
		if err := s.SMS.SendSMS(ctx, c.PhoneE164, body); err != nil {
			s.logger().WarnContext(ctx, "send sos sms to contact", "position", c.Position, "err", err)
		}
	}
}

// Escalate texts the on-duty operators about alerts unclaimed for EscalateAfter, once per alert
// (FR-011). It returns how many alerts were escalated.
func (s *Service) Escalate(ctx context.Context) (int, error) {
	now := s.now()
	rows, err := s.Store.EscalateSOSAlerts(ctx, store.EscalateSOSAlertsParams{Now: ts(now), Before: now.Add(-EscalateAfter)})
	if err != nil || len(rows) == 0 {
		return 0, err
	}
	phones, err := s.Store.ListOnDutyOperatorPhones(ctx)
	if err != nil {
		return len(rows), err
	}
	for _, r := range rows {
		s.publish(ctx, realtime.OpsSOSChannel, "sos.escalated", now, map[string]any{"alert_id": r.ID})
		if s.SMS == nil {
			continue
		}
		who := "un pasajero"
		if r.RaisedRole == store.SosRoleDriver {
			who = "un conductor"
		}
		body := "Kyq: alerta SOS de " + who + " sin atender desde hace 1 minuto. Abre la consola de emergencias."
		for _, phone := range phones {
			if err := s.SMS.SendSMS(ctx, phone, body); err != nil {
				s.logger().WarnContext(ctx, "send sos escalation sms", "alert_id", r.ID, "err", err)
			}
		}
	}
	if len(phones) == 0 {
		s.logger().WarnContext(ctx, "alerta SOS sin atender y ningún operador de guardia", "count", len(rows))
	}
	return len(rows), nil
}

// CloseVoicePending retries closing the rooms and recordings of closed alerts.
func (s *Service) CloseVoicePending(ctx context.Context) (int, error) {
	rows, err := s.Store.ListSOSVoicePending(ctx)
	if err != nil {
		return 0, err
	}
	count := 0
	for _, r := range rows {
		if err := s.stopVoice(ctx, r.ID, r.RoomName, r.EgressID); err != nil {
			s.logger().WarnContext(ctx, "close sos voice", "alert_id", r.ID, "err", err)
			continue
		}
		count++
	}
	return count, nil
}

// StartMissingRecordings retries the recording of open alerts whose egress did not start.
func (s *Service) StartMissingRecordings(ctx context.Context) error {
	if !s.Record {
		return nil
	}
	rows, err := s.Store.ListSOSAlertsWithoutEgress(ctx)
	if err != nil {
		return err
	}
	for _, r := range rows {
		if err := s.Voice.CreateSOSRoom(ctx, r.RoomName); err != nil {
			s.logger().WarnContext(ctx, "create sos room", "alert_id", r.ID, "err", err)
			continue
		}
		s.startRecording(ctx, r.ID, r.RoomName)
	}
	return nil
}

// RunSweeper escalates unclaimed alerts, closes pending rooms and retries recordings every
// interval until ctx ends (research R7: every 10 s).
func (s *Service) RunSweeper(ctx context.Context, interval time.Duration) {
	ticker := time.NewTicker(interval)
	defer ticker.Stop()
	for {
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
			if n, err := s.Escalate(ctx); err != nil {
				s.logger().ErrorContext(ctx, "escalate sos alerts", "err", err)
			} else if n > 0 {
				s.logger().WarnContext(ctx, "sos alerts escalated", "count", n)
			}
			if _, err := s.CloseVoicePending(ctx); err != nil {
				s.logger().ErrorContext(ctx, "close sos voice", "err", err)
			}
			if err := s.StartMissingRecordings(ctx); err != nil {
				s.logger().ErrorContext(ctx, "start sos recordings", "err", err)
			}
		}
	}
}
