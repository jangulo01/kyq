package safety

import (
	"context"
	"errors"
	"strings"
	"time"
	"unicode/utf8"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"

	"github.com/kyq/backend/internal/ptt"
	"github.com/kyq/backend/internal/realtime"
	"github.com/kyq/backend/internal/storage"
	"github.com/kyq/backend/internal/store"
	"github.com/kyq/backend/internal/trips"
)

// Consola de emergencias (US2): solo administradores con permiso de operador; cada acceso y
// acción queda en sos_audit (FR-012).

var (
	ErrNotOperator    = errors.New("not an emergency operator")
	ErrClaimed        = errors.New("alert claimed by another operator")
	ErrNotClaimant    = errors.New("alert not claimed by caller")
	ErrInvalidOutcome = errors.New("invalid outcome")
	ErrInvalidNote    = errors.New("invalid note")
	ErrInvalidFilter  = errors.New("invalid filter")
)

// Outcomes are the valid sos_outcome values (FR-010).
var Outcomes = []store.SosOutcome{
	store.SosOutcomeFalseAlarm, store.SosOutcomeResolved, store.SosOutcomeEscalatedAuthorities, store.SosOutcomeNoResponse,
}

// LocationView is one fix of an alert.
type LocationView struct {
	Lat       float64   `json:"lat"`
	Lng       float64   `json:"lng"`
	AccuracyM *float64  `json:"accuracy_m"`
	At        time.Time `json:"at"`
}

func locationView(at time.Time, lat, lng float64, acc pgtype.Float4) LocationView {
	v := LocationView{Lat: lat, Lng: lng, At: at}
	if acc.Valid {
		a := float64(acc.Float32)
		v.AccuracyM = &a
	}
	return v
}

// AlertSummary is a row of the console queue or history (contracts: SosAlertSummary).
type AlertSummary struct {
	ID               uuid.UUID     `json:"id"`
	TripID           uuid.UUID     `json:"trip_id"`
	RaisedRole       string        `json:"raised_role"`
	RaisedByName     string        `json:"raised_by_name"`
	Status           string        `json:"status"`
	CancelWithoutPIN bool          `json:"cancel_without_pin"`
	ClaimedBy        *uuid.UUID    `json:"claimed_by"`
	ClaimedByName    *string       `json:"claimed_by_name"`
	Outcome          *string       `json:"outcome"`
	Escalated        bool          `json:"escalated"`
	HasRecording     bool          `json:"has_recording"`
	CreatedAt        time.Time     `json:"created_at"`
	ClaimedAt        *time.Time    `json:"claimed_at"`
	ClosedAt         *time.Time    `json:"closed_at"`
	LastLocation     *LocationView `json:"last_location"`
}

func timePtr(t pgtype.Timestamptz) *time.Time {
	if !t.Valid {
		return nil
	}
	v := t.Time
	return &v
}

func summary(a store.SosAlert, raisedByName string, claimedByName pgtype.Text) AlertSummary {
	s := AlertSummary{
		ID: a.ID, TripID: a.TripID, RaisedRole: string(a.RaisedRole), RaisedByName: raisedByName, Status: string(a.Status),
		CancelWithoutPIN: a.CancelWithoutPin, Escalated: a.EscalatedAt.Valid, HasRecording: a.RecordingKey.Valid,
		CreatedAt: a.CreatedAt, ClaimedAt: timePtr(a.ClaimedAt), ClosedAt: timePtr(a.ClosedAt),
	}
	if a.ClaimedBy.Valid {
		id := a.ClaimedBy.UUID
		s.ClaimedBy = &id
	}
	if claimedByName.Valid {
		n := claimedByName.String
		s.ClaimedByName = &n
	}
	if a.Outcome.Valid {
		o := string(a.Outcome.SosOutcome)
		s.Outcome = &o
	}
	return s
}

func (s *Service) requireOperator(ctx context.Context, operatorID uuid.UUID) error {
	ok, err := s.Store.IsEmergencyOperator(ctx, operatorID)
	if err != nil {
		return err
	}
	if !ok {
		return ErrNotOperator
	}
	return nil
}

// audit records an operator's access or action; a failure fails the request (FR-012).
func (s *Service) audit(ctx context.Context, operatorID uuid.UUID, alertID *uuid.UUID, action string) error {
	var id uuid.NullUUID
	if alertID != nil {
		id = nullID(*alertID)
	}
	return s.Store.InsertSOSAudit(ctx, store.InsertSOSAuditParams{OperatorID: operatorID, AlertID: id, Action: action, CreatedAt: s.now()})
}

// operate checks the permission and audits the action before running it.
func (s *Service) operate(ctx context.Context, operatorID uuid.UUID, alertID *uuid.UUID, action string) error {
	if err := s.requireOperator(ctx, operatorID); err != nil {
		return err
	}
	return s.audit(ctx, operatorID, alertID, action)
}

// HistoryFilter selects closed alerts (FR-007).
type HistoryFilter struct {
	From, To time.Time
	Outcome  string
}

// ListOpen returns the open and claimed alerts, oldest first (the console shows waiting time).
func (s *Service) ListOpen(ctx context.Context, operatorID uuid.UUID) ([]AlertSummary, error) {
	if err := s.operate(ctx, operatorID, nil, "list_open"); err != nil {
		return nil, err
	}
	rows, err := s.Store.ListOpenSOSAlerts(ctx)
	if err != nil {
		return nil, err
	}
	out := make([]AlertSummary, 0, len(rows))
	ids := make([]uuid.UUID, 0, len(rows))
	for _, r := range rows {
		out = append(out, summary(store.SosAlert{
			ID: r.ID, TripID: r.TripID, RaisedBy: r.RaisedBy, RaisedRole: r.RaisedRole, Status: r.Status,
			CancelWithoutPin: r.CancelWithoutPin, ClaimedBy: r.ClaimedBy, Outcome: r.Outcome, RecordingKey: r.RecordingKey,
			EscalatedAt: r.EscalatedAt, CreatedAt: r.CreatedAt, ClaimedAt: r.ClaimedAt, ClosedAt: r.ClosedAt,
		}, r.RaisedByName, r.ClaimedByName))
		ids = append(ids, r.ID)
	}
	return out, s.withLastLocations(ctx, out, ids)
}

// ListHistory returns closed and cancelled alerts filtered by date and outcome (FR-007).
func (s *Service) ListHistory(ctx context.Context, operatorID uuid.UUID, f HistoryFilter) ([]AlertSummary, error) {
	var outcome store.NullSosOutcome
	if f.Outcome != "" {
		if !validOutcome(f.Outcome) {
			return nil, ErrInvalidFilter
		}
		outcome = store.NullSosOutcome{SosOutcome: store.SosOutcome(f.Outcome), Valid: true}
	}
	if !f.To.After(f.From) {
		return nil, ErrInvalidFilter
	}
	if err := s.operate(ctx, operatorID, nil, "list_history"); err != nil {
		return nil, err
	}
	rows, err := s.Store.ListClosedSOSAlerts(ctx, store.ListClosedSOSAlertsParams{Since: f.From, Until: f.To, Outcome: outcome})
	if err != nil {
		return nil, err
	}
	out := make([]AlertSummary, 0, len(rows))
	for _, r := range rows {
		out = append(out, summary(store.SosAlert{
			ID: r.ID, TripID: r.TripID, RaisedBy: r.RaisedBy, RaisedRole: r.RaisedRole, Status: r.Status,
			CancelWithoutPin: r.CancelWithoutPin, ClaimedBy: r.ClaimedBy, Outcome: r.Outcome, RecordingKey: r.RecordingKey,
			EscalatedAt: r.EscalatedAt, CreatedAt: r.CreatedAt, ClaimedAt: r.ClaimedAt, ClosedAt: r.ClosedAt,
		}, r.RaisedByName, r.ClaimedByName))
	}
	return out, nil
}

func (s *Service) withLastLocations(ctx context.Context, out []AlertSummary, ids []uuid.UUID) error {
	if len(ids) == 0 {
		return nil
	}
	last, err := s.Store.GetLastSOSLocations(ctx, ids)
	if err != nil {
		return err
	}
	byID := map[uuid.UUID]LocationView{}
	for _, l := range last {
		byID[l.AlertID] = locationView(l.At, l.Lat, l.Lng, l.AccuracyM)
	}
	for i := range out {
		if v, ok := byID[out[i].ID]; ok {
			out[i].LastLocation = &v
		}
	}
	return nil
}

// PersonView is a party of the trip as the operator sees it.
type PersonView struct {
	UserID uuid.UUID `json:"user_id"`
	Name   string    `json:"name"`
}

// DriverView adds the vehicle (FR-009).
type DriverView struct {
	PersonView
	VehiclePlate       string  `json:"vehicle_plate"`
	VehicleDescription string  `json:"vehicle_description"`
	VehicleBrand       *string `json:"vehicle_brand"`
	VehicleModel       *string `json:"vehicle_model"`
	VehicleColor       *string `json:"vehicle_color"`
}

// ContactView is an emergency contact.
type ContactView struct {
	Name      string `json:"name"`
	PhoneE164 string `json:"phone_e164"`
}

// NoteView is an operator note.
type NoteView struct {
	ID           uuid.UUID `json:"id"`
	OperatorID   uuid.UUID `json:"operator_id"`
	OperatorName string    `json:"operator_name"`
	Body         string    `json:"body"`
	CreatedAt    time.Time `json:"created_at"`
}

// AlertDetail is GET /v1/ops/sos/{id} (contracts: SosAlertDetail).
type AlertDetail struct {
	AlertSummary
	// RaisedByPhone and EmergencyContacts let the operator call the person or the family.
	RaisedByPhone     string        `json:"raised_by_phone_e164"`
	EmergencyContacts []ContactView `json:"emergency_contacts"`
	Trip              struct {
		Status  string      `json:"status"`
		Pickup  trips.Point `json:"pickup"`
		Dropoff trips.Point `json:"dropoff"`
	} `json:"trip"`
	Passenger PersonView     `json:"passenger"`
	Driver    DriverView     `json:"driver"`
	Track     []LocationView `json:"track"`
	Notes     []NoteView     `json:"notes"`
	// RelatedAlertIDs are the other alerts of the same trip (passenger and driver).
	RelatedAlertIDs []uuid.UUID `json:"related_alert_ids"`
	// RecordingURL is signed for RecordingURLTTL once the recording exists (FR-018).
	RecordingURL *string `json:"recording_url"`
	// History of the person: alerts raised and how many were false alarms.
	RaisedByAlerts      int `json:"raised_by_alerts"`
	RaisedByFalseAlarms int `json:"raised_by_false_alarms"`
}

func textPtr(t pgtype.Text) *string {
	if !t.Valid {
		return nil
	}
	v := t.String
	return &v
}

// Detail returns everything the operator needs about an alert (FR-009).
func (s *Service) Detail(ctx context.Context, operatorID, alertID uuid.UUID) (AlertDetail, error) {
	if err := s.requireOperator(ctx, operatorID); err != nil {
		return AlertDetail{}, err
	}
	r, err := s.Store.GetSOSDetail(ctx, alertID)
	if store.IsNotFound(err) {
		return AlertDetail{}, ErrNotFound
	}
	if err != nil {
		return AlertDetail{}, err
	}
	if err := s.audit(ctx, operatorID, &alertID, "view"); err != nil {
		return AlertDetail{}, err
	}
	d := AlertDetail{
		AlertSummary: summary(store.SosAlert{
			ID: r.ID, TripID: r.TripID, RaisedBy: r.RaisedBy, RaisedRole: r.RaisedRole, Status: r.Status,
			CancelWithoutPin: r.CancelWithoutPin, ClaimedBy: r.ClaimedBy, Outcome: r.Outcome, RecordingKey: r.RecordingKey,
			EscalatedAt: r.EscalatedAt, CreatedAt: r.CreatedAt, ClaimedAt: r.ClaimedAt, ClosedAt: r.ClosedAt,
		}, r.RaisedByName, r.ClaimedByName),
		RaisedByPhone:     r.RaisedByPhone,
		EmergencyContacts: []ContactView{},
		Passenger:         PersonView{UserID: r.PassengerID, Name: r.PassengerName},
		Driver: DriverView{
			PersonView: PersonView{UserID: r.DriverID, Name: r.DriverName}, VehiclePlate: r.VehiclePlate,
			VehicleDescription: r.VehicleDescription, VehicleBrand: textPtr(r.VehicleBrand),
			VehicleModel: textPtr(r.VehicleModel), VehicleColor: textPtr(r.VehicleColor),
		},
		Track: []LocationView{}, Notes: []NoteView{}, RelatedAlertIDs: []uuid.UUID{},
	}
	d.Trip.Status = string(r.TripStatus)
	d.Trip.Pickup = trips.Point{Lat: r.PickupLat, Lng: r.PickupLng}
	d.Trip.Dropoff = trips.Point{Lat: r.DropoffLat, Lng: r.DropoffLng}

	contacts, err := s.Store.ListEmergencyContacts(ctx, r.RaisedBy)
	if err != nil {
		return AlertDetail{}, err
	}
	for _, c := range contacts {
		d.EmergencyContacts = append(d.EmergencyContacts, ContactView{Name: c.Name, PhoneE164: c.PhoneE164})
	}
	track, err := s.Store.ListSOSLocations(ctx, alertID)
	if err != nil {
		return AlertDetail{}, err
	}
	for _, l := range track {
		d.Track = append(d.Track, locationView(l.At, l.Lat, l.Lng, l.AccuracyM))
	}
	if n := len(d.Track); n > 0 {
		last := d.Track[n-1]
		d.LastLocation = &last
	}
	notes, err := s.Store.ListSOSNotes(ctx, alertID)
	if err != nil {
		return AlertDetail{}, err
	}
	for _, n := range notes {
		d.Notes = append(d.Notes, NoteView{ID: n.ID, OperatorID: n.OperatorID, OperatorName: n.OperatorName, Body: n.Body, CreatedAt: n.CreatedAt})
	}
	related, err := s.Store.ListSOSAlertIDsForTrip(ctx, r.TripID)
	if err != nil {
		return AlertDetail{}, err
	}
	for _, id := range related {
		if id != alertID {
			d.RelatedAlertIDs = append(d.RelatedAlertIDs, id)
		}
	}
	history, err := s.Store.CountSOSAlertsByUser(ctx, r.RaisedBy)
	if err != nil {
		return AlertDetail{}, err
	}
	d.RaisedByAlerts, d.RaisedByFalseAlarms = int(history.Total), int(history.FalseAlarms)
	if r.RecordingKey.Valid && s.Recordings != nil {
		if url, err := s.recordingURL(ctx, r.RecordingKey.String); err == nil {
			d.RecordingURL = url
		} else {
			s.logger().WarnContext(ctx, "sign sos recording", "alert_id", alertID, "err", err)
		}
	}
	return d, nil
}

// recordingURL signs the recording once egress has uploaded it (at the end of the alert).
func (s *Service) recordingURL(ctx context.Context, key string) (*string, error) {
	if _, err := s.Recordings.Stat(ctx, key); errors.Is(err, storage.ErrNotFound) {
		return nil, nil
	} else if err != nil {
		return nil, err
	}
	url, err := s.Recordings.PresignGet(ctx, key, RecordingURLTTL)
	if err != nil {
		return nil, err
	}
	return &url, nil
}

func (s *Service) operatorName(ctx context.Context, operatorID uuid.UUID) string {
	name, err := s.Store.GetUserDisplayName(ctx, operatorID)
	if err != nil {
		return ""
	}
	return name
}

// Claim takes the alert and lets the operator talk in its room (FR-008). Claiming an alert the
// caller already holds grants the voice again (after joining the room or a LiveKit failure).
//
// Publishing follows voice_holder_id fail-closed, like the PTT floor: the column is set before
// granting and cleared only after LiveKit confirms the revoke, so whoever may talk is always
// recorded and nobody else can take the alert meanwhile.
func (s *Service) Claim(ctx context.Context, operatorID, alertID uuid.UUID) (AlertSummary, error) {
	now := s.now()
	if err := s.operate(ctx, operatorID, &alertID, "claim"); err != nil {
		return AlertSummary{}, err
	}
	alert, err := s.Store.ClaimSOSAlert(ctx, store.ClaimSOSAlertParams{OperatorID: nullID(operatorID), Now: ts(now), ID: alertID})
	if store.IsNotFound(err) {
		current, err := s.Store.GetSOSAlert(ctx, alertID)
		switch {
		case store.IsNotFound(err):
			return AlertSummary{}, ErrNotFound
		case err != nil:
			return AlertSummary{}, err
		case closed(current):
			return AlertSummary{}, ErrClosed
		}
		return AlertSummary{}, ErrClaimed
	}
	if err != nil {
		return AlertSummary{}, err
	}
	name := s.operatorName(ctx, operatorID)
	firstClaim := alert.ClaimedAt.Valid && alert.ClaimedAt.Time.Equal(now)
	if firstClaim {
		s.publish(ctx, realtime.OpsSOSChannel, "sos.claimed", now, map[string]any{
			"alert_id": alertID, "operator_id": operatorID, "operator_name": name,
		})
	}
	raisedByName, _ := s.Store.GetUserDisplayName(ctx, alert.RaisedBy)
	out := summary(alert, raisedByName, pgtype.Text{String: name, Valid: true})

	if err := s.Voice.SetCanPublish(ctx, alert.RoomName, operatorID.String(), true); err != nil {
		s.logger().ErrorContext(ctx, "grant sos publish", "alert_id", alertID, "err", err)
		// LiveKit pudo aplicar el permiso: solo se olvida si la retirada se confirma.
		if s.Voice.SetCanPublish(ctx, alert.RoomName, operatorID.String(), false) == nil {
			if err := s.Store.ClearSOSVoiceHolder(ctx, store.ClearSOSVoiceHolderParams{ID: alertID, VoiceHolderID: nullID(operatorID)}); err != nil {
				return AlertSummary{}, err
			}
		}
		return out, ErrVoiceUnavailable
	}
	return out, nil
}

// Release takes the voice away and frees the alert for another operator. If LiveKit does not
// confirm the revoke the alert stays claimed.
func (s *Service) Release(ctx context.Context, operatorID, alertID uuid.UUID) error {
	if err := s.operate(ctx, operatorID, &alertID, "release"); err != nil {
		return err
	}
	alert, err := s.Store.GetSOSAlert(ctx, alertID)
	if store.IsNotFound(err) {
		return ErrNotFound
	}
	if err != nil {
		return err
	}
	if alert.Status != store.SosStatusClaimed || alert.ClaimedBy != nullID(operatorID) {
		return ErrNotClaimant
	}
	if err := s.Voice.SetCanPublish(ctx, alert.RoomName, operatorID.String(), false); err != nil {
		s.logger().ErrorContext(ctx, "revoke sos publish", "alert_id", alertID, "err", err)
		return ErrVoiceUnavailable
	}
	n, err := s.Store.ReleaseSOSAlert(ctx, store.ReleaseSOSAlertParams{ID: alertID, ClaimedBy: nullID(operatorID)})
	if err != nil {
		return err
	}
	if n == 0 {
		return ErrNotClaimant
	}
	s.publish(ctx, realtime.OpsSOSChannel, "sos.released", s.now(), map[string]any{"alert_id": alertID})
	return nil
}

// AddNote appends a timestamped note (FR-010). Notes are allowed after closing too.
func (s *Service) AddNote(ctx context.Context, operatorID, alertID uuid.UUID, body string) (NoteView, error) {
	body = strings.TrimSpace(body)
	if n := utf8.RuneCountInString(body); n < 1 || n > 2000 {
		return NoteView{}, ErrInvalidNote
	}
	if err := s.operate(ctx, operatorID, &alertID, "note"); err != nil {
		return NoteView{}, err
	}
	if _, err := s.Store.GetSOSAlert(ctx, alertID); store.IsNotFound(err) {
		return NoteView{}, ErrNotFound
	} else if err != nil {
		return NoteView{}, err
	}
	id, err := uuid.NewV7()
	if err != nil {
		return NoteView{}, err
	}
	n, err := s.Store.InsertSOSNote(ctx, store.InsertSOSNoteParams{ID: id, AlertID: alertID, OperatorID: operatorID, Body: body, CreatedAt: s.now()})
	if err != nil {
		return NoteView{}, err
	}
	return NoteView{ID: n.ID, OperatorID: operatorID, OperatorName: s.operatorName(ctx, operatorID), Body: n.Body, CreatedAt: n.CreatedAt}, nil
}

func validOutcome(o string) bool {
	for _, v := range Outcomes {
		if string(v) == o {
			return true
		}
	}
	return false
}

// Close ends the case with a mandatory outcome (FR-010): the app stops sending its location
// (Locations answers ErrClosed and sos.closed reaches the person), the room is deleted and the
// recording stops. Only the operator who claimed the alert closes it.
func (s *Service) Close(ctx context.Context, operatorID, alertID uuid.UUID, outcome string) error {
	now := s.now()
	if !validOutcome(outcome) {
		return ErrInvalidOutcome
	}
	if err := s.operate(ctx, operatorID, &alertID, "close:"+outcome); err != nil {
		return err
	}
	var alert store.SosAlert
	err := s.Store.WithTx(ctx, func(q *store.Queries) error {
		var err error
		alert, err = q.GetSOSAlertForUpdate(ctx, alertID)
		if store.IsNotFound(err) {
			return ErrNotFound
		}
		if err != nil {
			return err
		}
		if closed(alert) {
			return ErrClosed
		}
		n, err := q.CloseSOSAlert(ctx, store.CloseSOSAlertParams{
			Outcome: store.NullSosOutcome{SosOutcome: store.SosOutcome(outcome), Valid: true}, Now: ts(now),
			ID: alertID, OperatorID: nullID(operatorID),
		})
		if err != nil {
			return err
		}
		if n == 0 {
			return ErrNotClaimant
		}
		// El bloqueo por intentos de PIN dura hasta que el operador cierra (research R6).
		return q.SetSafetyPinAttempts(ctx, store.SetSafetyPinAttemptsParams{UserID: alert.RaisedBy, FailedAttempts: 0})
	})
	if err != nil {
		return err
	}
	s.closeVoice(ctx, alert)
	data := map[string]any{"alert_id": alertID, "status": store.SosStatusClosed, "outcome": outcome}
	s.publish(ctx, realtime.OpsSOSChannel, "sos.closed", now, data)
	s.publish(ctx, "user:"+alert.RaisedBy.String(), "sos.closed", now, map[string]any{"alert_id": alertID})
	return nil
}

// OperatorToken lets an operator join the alert's room to listen (FR-008); talking needs Claim.
func (s *Service) OperatorToken(ctx context.Context, operatorID, alertID uuid.UUID) (VoiceCredentials, error) {
	if err := s.operate(ctx, operatorID, &alertID, "listen"); err != nil {
		return VoiceCredentials{}, err
	}
	alert, err := s.Store.GetSOSAlert(ctx, alertID)
	if store.IsNotFound(err) {
		return VoiceCredentials{}, ErrNotFound
	}
	if err != nil {
		return VoiceCredentials{}, err
	}
	if closed(alert) {
		return VoiceCredentials{}, ErrClosed
	}
	if err := s.Voice.CreateSOSRoom(ctx, alert.RoomName); err != nil {
		s.logger().ErrorContext(ctx, "create sos room", "alert_id", alertID, "err", err)
		return VoiceCredentials{}, ErrVoiceUnavailable
	}
	token, err := s.LiveKit.OperatorToken(operatorID.String(), s.operatorName(ctx, operatorID), alert.RoomName, s.now(), ptt.TokenTTL)
	if err != nil {
		return VoiceCredentials{}, err
	}
	return VoiceCredentials{URL: s.VoiceURL, Token: token, Room: alert.RoomName}, nil
}

// Duty returns whether the operator receives escalation SMS.
func (s *Service) Duty(ctx context.Context, operatorID uuid.UUID) (bool, error) {
	if err := s.requireOperator(ctx, operatorID); err != nil {
		return false, err
	}
	return s.Store.GetOperatorDuty(ctx, operatorID)
}

// SetDuty turns the operator's on-call status on or off (FR-011).
func (s *Service) SetDuty(ctx context.Context, operatorID uuid.UUID, onDuty bool) error {
	action := "duty_off"
	if onDuty {
		action = "duty_on"
	}
	if err := s.operate(ctx, operatorID, nil, action); err != nil {
		return err
	}
	_, err := s.Store.SetOperatorDuty(ctx, store.SetOperatorDutyParams{UserID: operatorID, OnDuty: onDuty})
	return err
}
