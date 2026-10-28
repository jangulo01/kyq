package billing

import (
	"context"
	"encoding/json"
	"fmt"

	"github.com/google/uuid"

	"github.com/kyq/backend/internal/store"
)

// Webhook event types sent by Bold.
const (
	EventSaleApproved = "SALE_APPROVED"
	EventSaleRejected = "SALE_REJECTED"
	EventVoidApproved = "VOID_APPROVED"
	EventVoidRejected = "VOID_REJECTED"
)

// WebhookEvent is the part of a Bold notification Kyq reads.
type WebhookEvent struct {
	ID   string `json:"id"`
	Type string `json:"type"`
	Data struct {
		PaymentID     string `json:"payment_id"`
		PaymentMethod string `json:"payment_method"`
		Amount        struct {
			Total    json.Number `json:"total"`
			Currency string      `json:"currency"`
		} `json:"amount"`
		Metadata struct {
			Reference string `json:"reference"`
		} `json:"metadata"`
	} `json:"data"`
}

// Confirmation is a result Bold confirmed for a reference that is not a subscription payment.
type Confirmation struct {
	Outcome       Outcome
	TotalMinor    int64
	Currency      string
	Detail        string // CREDIT_CARD, PSE, NEQUI…
	BoldPaymentID string
}

// ReferenceHandler applies a signed Bold webhook for a reference it owns. It returns false when
// the reference is not its own.
type ReferenceHandler interface {
	HandleBoldConfirmation(ctx context.Context, reference uuid.UUID, c Confirmation) (bool, error)
}

// HandleWebhook verifies and applies a Bold notification. Unknown references and event types are
// accepted and ignored so Bold does not retry them; repeated notifications are idempotent.
// References that are not subscription payments go to s.References (trip payments, 004).
func (s *Service) HandleWebhook(ctx context.Context, body []byte, signature string) error {
	if !VerifySignature(s.WebhookSecret, body, signature) {
		return ErrInvalidSignature
	}
	var ev WebhookEvent
	if err := json.Unmarshal(body, &ev); err != nil {
		return fmt.Errorf("decode bold webhook: %w", err)
	}
	paymentID, err := uuid.Parse(ev.Data.Metadata.Reference)
	if err != nil {
		s.logger().WarnContext(ctx, "bold webhook without kyq reference", "type", ev.Type)
		return nil
	}
	total, err := MinorAmount(ev.Data.Amount.Total)
	if err != nil {
		return fmt.Errorf("bold webhook total: %w", err)
	}
	if _, err := s.Store.GetPayment(ctx, paymentID); store.IsNotFound(err) {
		return s.delegate(ctx, paymentID, ev, total)
	} else if err != nil {
		return err
	}
	o := outcome{totalMinor: total, currency: ev.Data.Amount.Currency, detail: ev.Data.PaymentMethod, boldPaymentID: ev.Data.PaymentID}
	switch ev.Type {
	case EventSaleApproved:
		o.status = store.PaymentStatusApproved
	case EventSaleRejected:
		o.status = store.PaymentStatusRejected
	case EventVoidApproved:
		o.status, o.voidReason = store.PaymentStatusVoided, "anulado en Bold"
	default:
		s.logger().InfoContext(ctx, "bold webhook ignored", "type", ev.Type, "payment_id", paymentID)
		return nil
	}
	return s.apply(ctx, paymentID, o)
}

// delegate offers a webhook with an unknown reference to s.References.
func (s *Service) delegate(ctx context.Context, reference uuid.UUID, ev WebhookEvent, total int64) error {
	c := Confirmation{TotalMinor: total, Currency: ev.Data.Amount.Currency, Detail: ev.Data.PaymentMethod, BoldPaymentID: ev.Data.PaymentID}
	switch ev.Type {
	case EventSaleApproved:
		c.Outcome = OutcomeApproved
	case EventSaleRejected:
		c.Outcome = OutcomeRejected
	case EventVoidApproved:
		c.Outcome = OutcomeVoided
	default:
		s.logger().InfoContext(ctx, "bold webhook ignored", "type", ev.Type, "reference", reference)
		return nil
	}
	for _, h := range s.References {
		handled, err := h.HandleBoldConfirmation(ctx, reference, c)
		if err != nil || handled {
			return err
		}
	}
	s.logger().WarnContext(ctx, "bold webhook for unknown payment", "type", ev.Type, "payment_id", reference)
	return nil
}
