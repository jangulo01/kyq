package drivers

import (
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
)

var (
	now       = time.Date(2026, 10, 27, 15, 0, 0, 0, time.UTC)
	nextYear  = time.Date(2027, 10, 27, 0, 0, 0, 0, time.UTC)
	validDocs = []Document{
		{Type: DocLicense, ExpiresAt: nextYear, Approved: true},
		{Type: DocMandatoryInsurance, ExpiresAt: nextYear, Approved: true},
		{Type: DocVehicleRegistration, ExpiresAt: nextYear, Approved: true},
	}
)

func withDoc(d Document) []Document {
	docs := make([]Document, 0, len(validDocs))
	for _, v := range validDocs {
		if v.Type == d.Type {
			v = d
		}
		docs = append(docs, v)
	}
	return docs
}

// RN-KYQ-002: ONLINE requiere suscripción ACTIVE o GRACE_PERIOD.
func TestRN002SubscriptionGatesOnline(t *testing.T) {
	assert.Equal(t, BlockNone, EvaluateOnline(now.Add(24*time.Hour), validDocs, false, now))
	assert.Equal(t, BlockSubscriptionSuspended, EvaluateOnline(now.Add(-73*time.Hour), validDocs, false, now))
	assert.Equal(t, BlockSubscriptionSuspended, EvaluateOnline(time.Time{}, validDocs, false, now), "sin suscripción")
}

// RN-KYQ-003: gracia de 72 h y nunca cortar un viaje en curso.
func TestRN003GracePeriodAndTripInProgress(t *testing.T) {
	paid := now.Add(-10 * time.Hour)
	assert.Equal(t, SubscriptionGracePeriod, SubscriptionStatusAt(paid, now))
	assert.Equal(t, BlockNone, EvaluateOnline(paid, validDocs, false, now))

	assert.Equal(t, SubscriptionGracePeriod, SubscriptionStatusAt(now.Add(-71*time.Hour-59*time.Minute), now))
	assert.Equal(t, SubscriptionSuspended, SubscriptionStatusAt(now.Add(-72*time.Hour), now))
	assert.Equal(t, SubscriptionActive, SubscriptionStatusAt(now.Add(time.Second), now))

	expired := now.Add(-30 * 24 * time.Hour)
	assert.Equal(t, BlockNone, EvaluateOnline(expired, nil, true, now), "viaje en curso nunca se corta")
}

// RN-KYQ-016: bloqueo si falta, no está aprobado o vence un documento obligatorio.
func TestRN016MandatoryDocuments(t *testing.T) {
	paid := now.Add(24 * time.Hour)
	today := time.Date(2026, 10, 27, 0, 0, 0, 0, time.UTC)

	assert.Equal(t, BlockKYCExpired, EvaluateOnline(paid, validDocs[:2], false, now), "falta un documento")
	assert.Equal(t, BlockKYCExpired, EvaluateOnline(paid, withDoc(Document{Type: DocLicense, ExpiresAt: nextYear, Approved: false}), false, now), "sin aprobar")
	assert.Equal(t, BlockKYCExpired, EvaluateOnline(paid, withDoc(Document{Type: DocLicense, ExpiresAt: today, Approved: true}), false, now), "vence hoy")
	assert.Equal(t, BlockNone, EvaluateOnline(paid, withDoc(Document{Type: DocLicense, ExpiresAt: today.AddDate(0, 0, 1), Approved: true}), false, now), "vence mañana")
}

func TestSuspensionTakesPrecedenceOverKYC(t *testing.T) {
	assert.Equal(t, BlockSubscriptionSuspended, EvaluateOnline(now.Add(-100*time.Hour), nil, false, now))
}
