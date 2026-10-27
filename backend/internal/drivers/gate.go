// Package drivers holds driver profile, presence and the ONLINE gate.
package drivers

import "time"

// GracePeriod is the time a driver may keep working after paid_until (RN-KYQ-003).
const GracePeriod = 72 * time.Hour

// SubscriptionStatus mirrors the derived states in data-model.md.
type SubscriptionStatus string

const (
	SubscriptionActive      SubscriptionStatus = "active"
	SubscriptionGracePeriod SubscriptionStatus = "grace_period"
	SubscriptionSuspended   SubscriptionStatus = "suspended"
)

// Document type values match driver_documents.doc_type.
const (
	DocLicense             = "license"
	DocMandatoryInsurance  = "mandatory_insurance"
	DocVehicleRegistration = "vehicle_registration"
)

// MandatoryDocuments must all be approved and unexpired to go ONLINE.
var MandatoryDocuments = []string{DocLicense, DocMandatoryInsurance, DocVehicleRegistration}

// Document is a driver document as the gate sees it. ExpiresAt is a calendar date in UTC.
type Document struct {
	Type      string
	ExpiresAt time.Time
	Approved  bool
}

// BlockReason explains why a driver cannot go ONLINE. Empty means allowed.
type BlockReason string

const (
	BlockNone                  BlockReason = ""
	BlockSubscriptionSuspended BlockReason = "subscription_suspended"
	BlockKYCExpired            BlockReason = "kyc_expired"
)

// SubscriptionStatusAt derives the subscription state. A zero paidUntil means no subscription.
func SubscriptionStatusAt(paidUntil, now time.Time) SubscriptionStatus {
	switch {
	case paidUntil.IsZero():
		return SubscriptionSuspended
	case now.Before(paidUntil):
		return SubscriptionActive
	case now.Before(paidUntil.Add(GracePeriod)):
		return SubscriptionGracePeriod
	default:
		return SubscriptionSuspended
	}
}

// EvaluateOnline decides whether a driver may go or stay ONLINE (RN-KYQ-002, RN-KYQ-003,
// RN-KYQ-016). Mirrors packages/kyq_domain/lib/src/online_gate.dart.
func EvaluateOnline(paidUntil time.Time, docs []Document, hasTripInProgress bool, now time.Time) BlockReason {
	if hasTripInProgress {
		return BlockNone
	}
	if SubscriptionStatusAt(paidUntil, now) == SubscriptionSuspended {
		return BlockSubscriptionSuspended
	}
	nowUTC := now.UTC()
	today := time.Date(nowUTC.Year(), nowUTC.Month(), nowUTC.Day(), 0, 0, 0, 0, time.UTC)
	for _, required := range MandatoryDocuments {
		if !hasValidDocument(docs, required, today) {
			return BlockKYCExpired
		}
	}
	return BlockNone
}

func hasValidDocument(docs []Document, docType string, today time.Time) bool {
	for _, d := range docs {
		if d.Type == docType && d.Approved && today.Before(d.ExpiresAt) {
			return true
		}
	}
	return false
}
