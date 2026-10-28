package drivers

import (
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

var (
	now       = time.Date(2026, 10, 27, 15, 0, 0, 0, time.UTC)
	nextYear  = time.Date(2027, 10, 27, 0, 0, 0, 0, time.UTC)
	validDocs = []Document{
		{Type: DocNationalID, Approved: true},
		{Type: DocLicense, ExpiresAt: nextYear, Approved: true},
		{Type: DocMandatoryInsurance, ExpiresAt: nextYear, Approved: true},
		{Type: DocTechnicalInspection, ExpiresAt: nextYear, Approved: true},
		{Type: DocVehicleRegistration, Approved: true},
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

	assert.Equal(t, BlockKYCExpired, EvaluateOnline(paid, validDocs[:4], false, now), "falta un documento")
	assert.Equal(t, BlockKYCExpired, EvaluateOnline(paid, withDoc(Document{Type: DocLicense, ExpiresAt: nextYear, Approved: false}), false, now), "sin aprobar")
	assert.Equal(t, BlockKYCExpired, EvaluateOnline(paid, withDoc(Document{Type: DocLicense, ExpiresAt: today, Approved: true}), false, now), "vence hoy")
	assert.Equal(t, BlockNone, EvaluateOnline(paid, withDoc(Document{Type: DocLicense, ExpiresAt: today.AddDate(0, 0, 1), Approved: true}), false, now), "vence mañana")
}

func TestSuspensionTakesPrecedenceOverKYC(t *testing.T) {
	assert.Equal(t, BlockSubscriptionSuspended, EvaluateOnline(now.Add(-100*time.Hour), nil, false, now))
}

// RN-KYQ-016 (002): los cinco tipos son obligatorios; cédula y tarjeta de propiedad no vencen;
// la revisión técnico-mecánica puede estar exenta hasta una fecha.
func TestRN016FiveDocumentTypesAndExemption(t *testing.T) {
	paid := now.Add(24 * time.Hour)
	today := Today(now)

	for _, missing := range MandatoryDocuments {
		var docs []Document
		for _, d := range validDocs {
			if d.Type != missing {
				docs = append(docs, d)
			}
		}
		assert.Equal(t, BlockKYCExpired, EvaluateOnline(paid, docs, false, now), "sin %s", missing)
		assert.Equal(t, []DocumentProblem{{Type: missing, Problem: "missing"}}, DocumentProblems(docs, now))
	}

	old := today.AddDate(-5, 0, 0)
	assert.Equal(t, BlockNone, EvaluateOnline(paid, withDoc(Document{Type: DocNationalID, ExpiresAt: old, Approved: true}), false, now),
		"la cédula no bloquea por fecha")
	assert.Equal(t, BlockNone, EvaluateOnline(paid, withDoc(Document{Type: DocVehicleRegistration, ExpiresAt: old, Approved: true}), false, now),
		"la tarjeta de propiedad no bloquea por fecha")

	exempt := Document{Type: DocTechnicalInspection, ExemptUntil: today.AddDate(0, 0, 10), Approved: true}
	assert.Equal(t, BlockNone, EvaluateOnline(paid, withDoc(exempt), false, now), "vehículo nuevo exento")
	exempt.ExemptUntil = today
	assert.Equal(t, BlockKYCExpired, EvaluateOnline(paid, withDoc(exempt), false, now), "la exención termina")

	soat := withDoc(Document{Type: DocMandatoryInsurance, ExpiresAt: today, Approved: true})
	problems := DocumentProblems(soat, now)
	require.Len(t, problems, 1)
	assert.Equal(t, "SOAT vencido: envía el nuevo", problems[0].Message())

	assert.True(t, Document{Type: DocLicense, ExpiresAt: today.AddDate(0, 0, 1), Approved: true}.InForce(today))
	assert.False(t, Document{Type: DocNationalID}.InForce(today), "sin aprobar nunca vale")
}
