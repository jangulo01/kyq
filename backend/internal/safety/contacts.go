package safety

import (
	"context"
	"errors"
	"regexp"
	"strings"
	"unicode/utf8"

	"github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"

	"github.com/kyq/backend/internal/store"
)

// Contactos de emergencia y PIN de seguridad (US4, FR-016, research R6).

// MaxContacts is the number of emergency contacts per user.
const MaxContacts = 3

var (
	ErrTooManyContacts  = errors.New("too many contacts")
	ErrInvalidContact   = errors.New("invalid contact")
	ErrInvalidPINFormat = errors.New("pin must be 4 digits")
	ErrWrongCurrentPIN  = errors.New("current pin does not match")
	ErrPINDuringSOS     = errors.New("pin cannot change during an alert")
)

var (
	phoneE164 = regexp.MustCompile(`^\+[1-9][0-9]{6,14}$`)
	pinFormat = regexp.MustCompile(`^[0-9]{4}$`)
)

// Contact is an emergency contact (contracts: EmergencyContact).
type Contact struct {
	Name      string `json:"name"`
	PhoneE164 string `json:"phone_e164"`
}

// Contacts returns the caller's emergency contacts in order.
func (s *Service) Contacts(ctx context.Context, userID uuid.UUID) ([]Contact, error) {
	rows, err := s.Store.ListEmergencyContacts(ctx, userID)
	if err != nil {
		return nil, err
	}
	out := make([]Contact, 0, len(rows))
	for _, r := range rows {
		out = append(out, Contact{Name: r.Name, PhoneE164: r.PhoneE164})
	}
	return out, nil
}

// SetContacts replaces the caller's contacts (at most MaxContacts, phones in E.164).
func (s *Service) SetContacts(ctx context.Context, userID uuid.UUID, contacts []Contact) ([]Contact, error) {
	if len(contacts) > MaxContacts {
		return nil, ErrTooManyContacts
	}
	clean := make([]Contact, 0, len(contacts))
	for _, c := range contacts {
		c.Name = strings.TrimSpace(c.Name)
		c.PhoneE164 = strings.TrimSpace(c.PhoneE164)
		if n := utf8.RuneCountInString(c.Name); n < 2 || n > 60 || !phoneE164.MatchString(c.PhoneE164) {
			return nil, ErrInvalidContact
		}
		clean = append(clean, c)
	}
	now := s.now()
	err := s.Store.WithTx(ctx, func(q *store.Queries) error {
		if err := q.DeleteEmergencyContacts(ctx, userID); err != nil {
			return err
		}
		for i, c := range clean {
			if err := q.InsertEmergencyContact(ctx, store.InsertEmergencyContactParams{
				UserID: userID, Position: int16(i + 1), Name: c.Name, PhoneE164: c.PhoneE164, CreatedAt: now,
			}); err != nil {
				return err
			}
		}
		return nil
	})
	if err != nil {
		return nil, err
	}
	return clean, nil
}

// HasPIN reports whether the caller has a safety PIN.
func (s *Service) HasPIN(ctx context.Context, userID uuid.UUID) (bool, error) {
	_, err := s.Store.GetSafetyPin(ctx, userID)
	if store.IsNotFound(err) {
		return false, nil
	}
	return err == nil, err
}

func checkPIN(hash, pin string) bool {
	return pinFormat.MatchString(pin) && bcrypt.CompareHashAndPassword([]byte(hash), []byte(pin)) == nil
}

// SetPIN stores a new PIN with bcrypt. Changing an existing PIN needs the current one, and no
// PIN can be set during an alert: whoever holds the phone could otherwise set one and cancel.
func (s *Service) SetPIN(ctx context.Context, userID uuid.UUID, pin string, current *string) error {
	if !pinFormat.MatchString(pin) {
		return ErrInvalidPINFormat
	}
	// Tampoco se fija un PIN nuevo durante la alerta: la app lo pide cuando termina (US4-3).
	if _, err := s.Store.GetActiveSOSAlertForUser(ctx, userID); err == nil {
		return ErrPINDuringSOS
	} else if !store.IsNotFound(err) {
		return err
	}
	hash, err := bcrypt.GenerateFromPassword([]byte(pin), bcrypt.DefaultCost)
	if err != nil {
		return err
	}
	return s.Store.WithTx(ctx, func(q *store.Queries) error {
		row, err := q.GetSafetyPinForUpdate(ctx, userID)
		switch {
		case store.IsNotFound(err):
		case err != nil:
			return err
		case current == nil || !checkPIN(row.PinHash, *current):
			return ErrWrongCurrentPIN
		}
		return q.UpsertSafetyPin(ctx, store.UpsertSafetyPinParams{UserID: userID, PinHash: string(hash), UpdatedAt: s.now()})
	})
}
