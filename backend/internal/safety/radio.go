package safety

import (
	"context"
	"errors"
	"fmt"

	"github.com/google/uuid"

	"github.com/kyq/backend/internal/realtime"
	"github.com/kyq/backend/internal/store"
	"github.com/kyq/backend/internal/telemetry"
)

// RaiseFromRadio is the Emergency button of Radio Kyq (011, FR-030, research R7): with a trip in
// progress it opens that trip's SOS (003); without one, an alert without trip (`raised_from =
// radio`) with the same room, recording, console and contacts. It returns the alert and its trip.
func (s *Service) RaiseFromRadio(ctx context.Context, userID, conversationID uuid.UUID, lat, lng *float64) (uuid.UUID, *uuid.UUID, error) {
	var at *Point
	if lat != nil && lng != nil {
		at = &Point{Lat: *lat, Lng: *lng}
		if !at.valid() {
			return uuid.Nil, nil, ErrInvalidLocation
		}
	}
	user, err := s.Store.GetUserByID(ctx, userID)
	if err != nil {
		return uuid.Nil, nil, err
	}
	// Con viaje en curso, el SOS es el del viaje.
	var trip store.Trip
	switch user.Role {
	case store.UserRoleDriver:
		trip, err = s.Store.GetActiveTripForDriver(ctx, userID)
	case store.UserRolePassenger:
		trip, err = s.Store.GetActiveTripForPassenger(ctx, userID)
	default:
		return uuid.Nil, nil, ErrNotFound
	}
	if err == nil {
		res, _, err := s.Raise(ctx, userID, trip.ID, at)
		switch {
		case err == nil:
			id := trip.ID
			return res.Alert.ID, &id, nil
		case !errors.Is(err, ErrUnavailable):
			return uuid.Nil, nil, err
		}
		// Viaje aún sin aceptar: cuenta como sin viaje.
	} else if !store.IsNotFound(err) {
		return uuid.Nil, nil, err
	}
	return s.raiseWithoutTrip(ctx, user, conversationID, at)
}

func (s *Service) raiseWithoutTrip(ctx context.Context, user store.User, conversationID uuid.UUID, at *Point) (uuid.UUID, *uuid.UUID, error) {
	now := s.now()
	id, err := uuid.NewV7()
	if err != nil {
		return uuid.Nil, nil, err
	}
	conv := uuid.NullUUID{UUID: conversationID, Valid: conversationID != uuid.Nil}
	role := store.SosRolePassenger
	if user.Role == store.UserRoleDriver {
		role = store.SosRoleDriver
	}
	var alert store.SosAlert
	created := false
	err = s.Store.WithTx(ctx, func(q *store.Queries) error {
		var err error
		alert, err = q.GetOpenRadioSOSAlertFor(ctx, user.ID)
		if err == nil {
			return nil // ya tiene una abierta: la misma sigue valiendo
		}
		if !store.IsNotFound(err) {
			return err
		}
		alert, err = q.InsertRadioSOSAlert(ctx, store.InsertRadioSOSAlertParams{
			ID: id, RaisedBy: user.ID, RaisedRole: role, RoomName: "sos-" + id.String(), CreatedAt: now,
			RadioConversationID: conv,
		})
		if store.IsNotFound(err) {
			alert, err = q.GetOpenRadioSOSAlertFor(ctx, user.ID)
			return err
		}
		if err != nil {
			return err
		}
		created = true
		if at == nil {
			return nil // sin GPS: el operador verá la ubicación cuando llegue
		}
		return q.InsertSOSLocation(ctx, store.InsertSOSLocationParams{
			AlertID: alert.ID, At: at.at(now), Lat: at.Lat, Lng: at.Lng, AccuracyM: accuracy(at.AccuracyM),
		})
	})
	if err != nil {
		return uuid.Nil, nil, err
	}
	if created {
		s.openVoice(ctx, alert)
		s.publish(ctx, realtime.OpsSOSChannel, "sos.created", now, map[string]any{
			"alert_id": alert.ID, "trip_id": nil, "raised_from": "radio", "raised_role": alert.RaisedRole,
			"raised_by_name": user.DisplayName, "created_at": alert.CreatedAt, "location": at,
		})
		if user.Role == store.UserRoleDriver {
			telemetry.Add(s.Usage, user.ID, telemetry.Events, 1)
		}
		s.background(ctx, func(ctx context.Context) { s.notifyContactsNoTrip(ctx, user, at) })
	}
	return alert.ID, nil, nil
}

// notifyContactsNoTrip texts the emergency contacts with the last location; without a trip
// there is no live link (003 FR-013 lo da solo con viaje).
func (s *Service) notifyContactsNoTrip(ctx context.Context, user store.User, at *Point) {
	if s.SMS == nil {
		return
	}
	contacts, err := s.Store.ListEmergencyContacts(ctx, user.ID)
	if err != nil {
		s.logger().ErrorContext(ctx, "list emergency contacts", "err", err)
		return
	}
	body := "Kyq: " + user.DisplayName + " activó el botón de emergencia. Si no responde, llama al 123."
	if at != nil {
		body = fmt.Sprintf("Kyq: %s activó el botón de emergencia. Su ubicación: https://maps.google.com/?q=%.5f,%.5f . "+
			"Si no responde, llama al 123.", user.DisplayName, at.Lat, at.Lng)
	}
	for _, c := range contacts {
		if err := s.SMS.SendSMS(ctx, c.PhoneE164, body); err != nil {
			s.logger().WarnContext(ctx, "send radio sos sms to contact", "position", c.Position, "err", err)
		}
	}
}
