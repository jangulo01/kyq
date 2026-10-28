// Package trippay charges the agreed fare of a completed trip with Bold or records that it was
// paid in cash, and keeps the settlement ledger of each driver (spec 004, RN-KYQ-001).
//
// The rules of who may do what in which state live in Transition, a pure function; the service
// loads the payment with its row locked, applies one action and saves it.
package trippay

import (
	"errors"
	"slices"

	"github.com/kyq/backend/internal/store"
)

// Party is the caller's role in the trip.
type Party string

const (
	Passenger Party = "passenger"
	Driver    Party = "driver"
)

// Action is something a party does to the payment (research R3).
type Action string

const (
	// ReportCash is the passenger's "Pagué en efectivo" (FR-004).
	ReportCash Action = "report_cash"
	// ConfirmCash is the driver's "Recibí el efectivo" (FR-005).
	ConfirmCash Action = "confirm_cash"
	// DisputeCash is the driver's "No recibí el efectivo" after a report (FR-005).
	DisputeCash Action = "dispute_cash"
	// MarkUnpaid is the driver's "No me pagó" without a report (FR-006).
	MarkUnpaid Action = "mark_unpaid"
	// StartBold is the passenger opening the Bold checkout (FR-003).
	StartBold Action = "start_bold"
)

var (
	ErrNotFound          = errors.New("trip payment not found")
	ErrForbidden         = errors.New("action not allowed for this party")
	ErrInvalidState      = errors.New("action not allowed in the current payment status")
	ErrBoldInProgress    = errors.New("a bold payment is in progress")
	ErrMethodNotAccepted = errors.New("payment method not accepted by the driver")
	ErrNoMethod          = errors.New("at least one payment method required")
	ErrNoteRequired      = errors.New("note required")
	ErrInvalidOutcome    = errors.New("invalid outcome")
	ErrReasonRequired    = errors.New("reason required")
	ErrInvalidPayout     = errors.New("invalid payout")
	ErrExceedsBalance    = errors.New("payout exceeds balance")
)

const (
	statusPending        = store.TripPaymentStatusPending
	statusBoldInProgress = store.TripPaymentStatusBoldInProgress
	statusCashReported   = store.TripPaymentStatusCashReported
	statusPaid           = store.TripPaymentStatusPaid
	statusUnpaid         = store.TripPaymentStatusUnpaid
	statusDisputed       = store.TripPaymentStatusDisputed
	statusNeedsReview    = store.TripPaymentStatusNeedsReview
	statusVoided         = store.TripPaymentStatusVoided
)

type rule struct {
	party Party
	from  []store.TripPaymentStatus
	to    store.TripPaymentStatus
}

var rules = map[Action]rule{
	ReportCash:  {Passenger, []store.TripPaymentStatus{statusPending, statusUnpaid}, statusCashReported},
	ConfirmCash: {Driver, []store.TripPaymentStatus{statusPending, statusBoldInProgress, statusCashReported, statusUnpaid, statusDisputed}, statusPaid},
	DisputeCash: {Driver, []store.TripPaymentStatus{statusCashReported}, statusDisputed},
	MarkUnpaid:  {Driver, []store.TripPaymentStatus{statusPending}, statusUnpaid},
	StartBold:   {Passenger, []store.TripPaymentStatus{statusPending, statusUnpaid}, statusBoldInProgress},
}

// Transition returns the status after party does a in status from. With a Bold checkout in
// progress the passenger cannot report cash or open another checkout, nor the driver mark the
// trip unpaid: the answer of Bold comes first (ErrBoldInProgress).
func Transition(from store.TripPaymentStatus, a Action, party Party) (store.TripPaymentStatus, error) {
	r, ok := rules[a]
	if !ok || r.party != party {
		return from, ErrForbidden
	}
	if slices.Contains(r.from, from) {
		return r.to, nil
	}
	if from == statusBoldInProgress && (a == ReportCash || a == MarkUnpaid || a == StartBold) {
		return from, ErrBoldInProgress
	}
	return from, ErrInvalidState
}

// Settle splits a trip fare: the driver gets 100 % and Kyq 0 (RN-KYQ-001).
func Settle(fareMinor int64) (driverMinor, commissionMinor int64) {
	return fareMinor, 0
}
