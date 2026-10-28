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
	DocNationalID          = "national_id"
	DocLicense             = "license"
	DocMandatoryInsurance  = "mandatory_insurance"
	DocTechnicalInspection = "technical_inspection"
	DocVehicleRegistration = "vehicle_registration"
)

// MandatoryDocuments must all be approved and in force to go ONLINE (FR-005).
var MandatoryDocuments = []string{
	DocNationalID, DocLicense, DocMandatoryInsurance, DocTechnicalInspection, DocVehicleRegistration,
}

// DocumentExpires reports whether a document type has an expiry date. National ID and vehicle
// registration never block by date.
func DocumentExpires(docType string) bool {
	return docType != DocNationalID && docType != DocVehicleRegistration
}

// DocumentLabel is the Spanish name shown to drivers.
func DocumentLabel(docType string) string {
	switch docType {
	case DocNationalID:
		return "Cédula"
	case DocLicense:
		return "Licencia de conducción"
	case DocMandatoryInsurance:
		return "SOAT"
	case DocTechnicalInspection:
		return "Revisión técnico-mecánica"
	case DocVehicleRegistration:
		return "Tarjeta de propiedad"
	}
	return docType
}

// Document is a driver document as the gate sees it: the latest approved one of its type. Dates
// are calendar dates in UTC; a zero ExpiresAt means no expiry date. ExemptUntil only applies to
// the technical inspection of a new vehicle.
type Document struct {
	Type        string
	ExpiresAt   time.Time
	ExemptUntil time.Time
	Approved    bool
}

// InForce reports whether d lets the driver work on day today (00:00 UTC). A document is no
// longer valid on its expiry day.
func (d Document) InForce(today time.Time) bool {
	if !d.Approved {
		return false
	}
	if !DocumentExpires(d.Type) {
		return true
	}
	if !d.ExpiresAt.IsZero() && today.Before(d.ExpiresAt) {
		return true
	}
	return d.Type == DocTechnicalInspection && !d.ExemptUntil.IsZero() && today.Before(d.ExemptUntil)
}

// DocumentProblem is why one mandatory document blocks going ONLINE.
type DocumentProblem struct {
	Type    string `json:"doc_type"`
	Problem string `json:"problem"` // missing | expired
}

// Message is the reason shown to the driver, e.g. "SOAT vencido: envía el nuevo".
func (p DocumentProblem) Message() string {
	if p.Problem == "expired" {
		return DocumentLabel(p.Type) + " vencido: envía el nuevo"
	}
	return "Falta " + DocumentLabel(p.Type) + " aprobado: envíalo desde Documentos"
}

// DocumentProblems lists, in MandatoryDocuments order, the mandatory documents not in force
// (RN-KYQ-016).
func DocumentProblems(docs []Document, now time.Time) []DocumentProblem {
	today := Today(now)
	var out []DocumentProblem
	for _, required := range MandatoryDocuments {
		found, valid := false, false
		for _, d := range docs {
			if d.Type != required || !d.Approved {
				continue
			}
			found = true
			if d.InForce(today) {
				valid = true
			}
		}
		switch {
		case valid:
		case found:
			out = append(out, DocumentProblem{Type: required, Problem: "expired"})
		default:
			out = append(out, DocumentProblem{Type: required, Problem: "missing"})
		}
	}
	return out
}

// Today is the calendar day of now in UTC, at 00:00.
func Today(now time.Time) time.Time {
	u := now.UTC()
	return time.Date(u.Year(), u.Month(), u.Day(), 0, 0, 0, 0, time.UTC)
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
	if len(DocumentProblems(docs, now)) > 0 {
		return BlockKYCExpired
	}
	return BlockNone
}

// Billing states of a subscription as the driver app and the admin panel show them (002).
const (
	BillingActive    = "active"
	BillingGrace     = "grace"
	BillingSuspended = "suspended"
	BillingUnpaid    = "unpaid" // nunca ha tenido suscripción
)

// BillingStatus derives the 002 subscription state; paidUntil nil means it never had one.
func BillingStatus(paidUntil *time.Time, now time.Time) string {
	if paidUntil == nil {
		return BillingUnpaid
	}
	switch SubscriptionStatusAt(*paidUntil, now) {
	case SubscriptionActive:
		return BillingActive
	case SubscriptionGracePeriod:
		return BillingGrace
	}
	return BillingSuspended
}
