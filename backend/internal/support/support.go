// Package support implements the support and dispute center (spec 009, US2): cases opened from
// both apps, a text conversation with internal notes, the inbox of the panel and the payment
// cases that mirror the cash disputes of 004.
package support

import (
	"errors"
	"strings"
	"time"
	"unicode/utf8"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"

	"github.com/kyq/backend/internal/store"
)

// Temas de un caso (FR-005).
const (
	TopicTrip     = "trip"
	TopicPayment  = "payment"
	TopicLostItem = "lost_item"
	TopicSafety   = "safety"
	TopicAccount  = "account"
	TopicOther    = "other"
)

// Estados de un caso (FR-007).
const (
	StatusOpen        = "open"
	StatusInProgress  = "in_progress"
	StatusWaitingUser = "waiting_user"
	StatusResolved    = "resolved"
	StatusClosed      = "closed"
)

// Autores de un mensaje.
const (
	AuthorUser   = "user"
	AuthorAdmin  = "admin"
	AuthorSystem = "system"
)

// Límites (FR-005, FR-006, FR-012).
const (
	MinDescription = 10
	MaxText        = 2000
	TripWindow     = 30 * 24 * time.Hour
	AutoCloseAfter = 7 * 24 * time.Hour
	maxSubject     = 80
)

var (
	// ErrInvalidTopic: el tema no es uno de los de FR-005.
	ErrInvalidTopic = errors.New("invalid topic")
	// ErrInvalidText: descripción de 10 a 2 000 caracteres o mensaje de 1 a 2 000.
	ErrInvalidText = errors.New("invalid text")
	// ErrInvalidTrip: el viaje no es del usuario o tiene más de 30 días.
	ErrInvalidTrip = errors.New("invalid trip")
	// ErrNotFound: el caso no existe o no es del usuario (FR-011).
	ErrNotFound = errors.New("case not found")
	// ErrCaseClosed: un caso cerrado no admite mensajes ni cambios (FR-007).
	ErrCaseClosed = errors.New("case closed")
	// ErrInvalidStatus: estado desconocido.
	ErrInvalidStatus = errors.New("invalid status")
	// ErrInvalidAssignee: solo se asigna a administradores.
	ErrInvalidAssignee = errors.New("invalid assignee")
	// ErrNotPaymentCase: la resolución de pago solo vale en casos de una disputa de 004.
	ErrNotPaymentCase = errors.New("not a payment case")
)

var topics = map[string]bool{
	TopicTrip: true, TopicPayment: true, TopicLostItem: true, TopicSafety: true, TopicAccount: true, TopicOther: true,
}

var statuses = map[string]bool{
	StatusOpen: true, StatusInProgress: true, StatusWaitingUser: true, StatusResolved: true, StatusClosed: true,
}

// PersonRef is a participant of a case, without contact data.
type PersonRef struct {
	ID          uuid.UUID `json:"id"`
	DisplayName string    `json:"display_name"`
}

// Case is contracts: SupportCase.
type Case struct {
	ID                uuid.UUID  `json:"id"`
	Topic             string     `json:"topic"`
	Subject           string     `json:"subject"`
	Status            string     `json:"status"`
	User              PersonRef  `json:"user"`
	UserRole          string     `json:"user_role"`
	Counterpart       *PersonRef `json:"counterpart"`
	TripID            *uuid.UUID `json:"trip_id"`
	TripPaymentID     *uuid.UUID `json:"trip_payment_id"`
	AssignedTo        *PersonRef `json:"assigned_to"`
	CreatedAt         time.Time  `json:"created_at"`
	LastMessageAt     time.Time  `json:"last_message_at"`
	LastUserMessageAt *time.Time `json:"last_user_message_at"`
	// AwaitingReply: el último mensaje visible es del usuario (bandeja "sin respuesta", FR-008).
	AwaitingReply bool       `json:"awaiting_reply"`
	ResolvedAt    *time.Time `json:"resolved_at"`
	ClosedAt      *time.Time `json:"closed_at"`
}

// Message is contracts: SupportMessage. Internal notes only reach admins (FR-006).
type Message struct {
	ID         uuid.UUID `json:"id"`
	AuthorKind string    `json:"author_kind"`
	AuthorName *string   `json:"author_name"`
	Mine       bool      `json:"mine"`
	Body       string    `json:"body"`
	Internal   bool      `json:"internal"`
	CreatedAt  time.Time `json:"created_at"`
}

// Detail is a case with its conversation (contracts: SupportCaseDetail).
type Detail struct {
	Case
	Messages []Message `json:"messages"`
}

// Filter is the inbox filter of the panel (FR-008).
type Filter struct {
	Status        string
	Topic         string
	AssignedTo    uuid.UUID
	Unanswered    bool
	IncludeClosed bool
}

// RecentTrip is a trip the user can attach to a case (FR-005).
type RecentTrip struct {
	ID        uuid.UUID `json:"id"`
	Status    string    `json:"status"`
	CreatedAt time.Time `json:"created_at"`
	// OtherParty es el conductor para el pasajero y el pasajero para el conductor.
	OtherParty string `json:"other_party"`
}

func caseOf(sc store.SupportCase, userName string, counterpart, assigned pgtype.Text) Case {
	c := Case{
		ID: sc.ID, Topic: string(sc.Topic), Subject: sc.Subject, Status: string(sc.Status),
		User: PersonRef{ID: sc.UserID, DisplayName: userName}, UserRole: string(sc.UserRole),
		TripID: uuidPtr(sc.TripID), TripPaymentID: uuidPtr(sc.TripPaymentID),
		CreatedAt: sc.CreatedAt, LastMessageAt: sc.LastMessageAt, LastUserMessageAt: timePtr(sc.LastUserMessageAt),
		AwaitingReply: sc.LastAuthorIsUser && sc.Status != store.SupportStatusClosed,
		ResolvedAt:    timePtr(sc.ResolvedAt), ClosedAt: timePtr(sc.ClosedAt),
	}
	if sc.CounterpartID.Valid {
		c.Counterpart = &PersonRef{ID: sc.CounterpartID.UUID, DisplayName: counterpart.String}
	}
	if sc.AssignedTo.Valid {
		c.AssignedTo = &PersonRef{ID: sc.AssignedTo.UUID, DisplayName: assigned.String}
	}
	return c
}

// visibleTo reports whether userID may see the case (FR-011).
func visibleTo(sc store.SupportCase, userID uuid.UUID) bool {
	return sc.UserID == userID || (sc.CounterpartID.Valid && sc.CounterpartID.UUID == userID)
}

// subjectOf takes the first line of the description, cut at a word boundary.
func subjectOf(description string) string {
	line, _, _ := strings.Cut(strings.TrimSpace(description), "\n")
	line = strings.Join(strings.Fields(line), " ")
	if utf8.RuneCountInString(line) <= maxSubject {
		return line
	}
	r := []rune(line)[:maxSubject]
	if i := strings.LastIndex(string(r), " "); i > maxSubject/2 {
		return string(r)[:i] + "…"
	}
	return string(r) + "…"
}

func validText(body string, minLen int) (string, error) {
	body = strings.TrimSpace(body)
	if n := utf8.RuneCountInString(body); n < minLen || n > MaxText {
		return "", ErrInvalidText
	}
	return body, nil
}

func uuidPtr(u uuid.NullUUID) *uuid.UUID {
	if !u.Valid {
		return nil
	}
	return &u.UUID
}

func timePtr(t pgtype.Timestamptz) *time.Time {
	if !t.Valid {
		return nil
	}
	return &t.Time
}

func ts(t time.Time) pgtype.Timestamptz { return pgtype.Timestamptz{Time: t, Valid: true} }
