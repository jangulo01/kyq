package kyc

import (
	"context"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/kyq/backend/internal/drivers"
	"github.com/kyq/backend/internal/store"
)

func (f *fixture) notices(t *testing.T, driverID uuid.UUID) []store.Notice {
	rows, err := f.st.ListNotices(context.Background(), driverID)
	require.NoError(t, err)
	return rows
}

func (f *fixture) gate(t *testing.T, driverID uuid.UUID) []drivers.DocumentProblem {
	rows, err := f.st.ListDocumentsForDrivers(context.Background(), []uuid.UUID{driverID})
	require.NoError(t, err)
	return drivers.DocumentProblems(drivers.GateDocuments(rows), f.clock.t)
}

// FR-008, FR-009, FR-012, RN-KYQ-016: rechazar exige motivo y avisa; aprobar con correcciones
// deja auditoría y, con los cinco aprobados, el conductor queda al día.
func TestIntegrationReviewDocuments(t *testing.T) {
	f := newFixture(t)
	ctx := context.Background()
	driver := f.newDriver(t, "+573101112233")
	_, err := f.svc.SetVehicle(ctx, driver, testVehicle)
	require.NoError(t, err)
	docs := map[string]Document{}
	for _, in := range allDocuments() {
		docs[in.DocType] = f.upload(t, driver, in)
	}
	soat := docs["mandatory_insurance"]

	_, err = f.svc.ReviewDocument(ctx, f.admin, soat.ID, Review{Decision: "reject", Reason: "  "})
	assert.ErrorIs(t, err, ErrReasonRequired)
	rejected, err := f.svc.ReviewDocument(ctx, f.admin, soat.ID, Review{Decision: "reject", Reason: "Foto borrosa"})
	require.NoError(t, err)
	assert.Equal(t, "rejected", rejected.Status)
	_, err = f.svc.ReviewDocument(ctx, f.admin, soat.ID, Review{Decision: "approve"})
	assert.ErrorIs(t, err, ErrNotSubmitted, "solo se revisa lo que está en revisión")

	notices := f.notices(t, driver)
	require.Len(t, notices, 1)
	assert.Equal(t, "doc_rejected", notices[0].Kind)
	assert.Contains(t, notices[0].Body, "Foto borrosa")
	assert.NotContains(t, notices[0].Body, "SOAT-998877", "sin números de documento en avisos")
	require.NotEmpty(t, f.pub.events)
	assert.Contains(t, f.pub.events[0], "user:"+driver.String())
	assert.Contains(t, f.pub.events[0], `"notice.created"`)

	_, err = f.svc.ReviewDocument(ctx, f.admin, docs["license"].ID, Review{Decision: "approve", ExemptUntil: OptionalDate{Set: true, Valid: true, Time: time.Now()}})
	assert.ErrorIs(t, err, ErrExemptNotAllowed)
	fixed := "1020304051"
	approved, err := f.svc.ReviewDocument(ctx, f.admin, docs["license"].ID, Review{
		Decision: "approve", Number: &fixed, ExpiresAt: OptionalDate{Set: true, Valid: true, Time: time.Date(2031, 1, 31, 0, 0, 0, 0, time.UTC)},
	})
	require.NoError(t, err)
	assert.Equal(t, "1020304051", approved.Number, "el admin corrige el número")
	assert.Equal(t, "2031-01-31", *approved.ExpiresAt)
	row, err := f.st.GetDocumentForUpdate(ctx, docs["license"].ID)
	require.NoError(t, err)
	assert.Equal(t, f.admin, row.ReviewedBy.UUID, "auditoría: quién")
	assert.True(t, row.ReviewedAt.Time.Equal(f.clock.t), "auditoría: cuándo")

	// Vehículo nuevo: revisión técnico-mecánica exenta hasta una fecha.
	_, err = f.svc.ReviewDocument(ctx, f.admin, docs["technical_inspection"].ID, Review{
		Decision: "approve", ExpiresAt: OptionalDate{Set: true}, ExemptUntil: OptionalDate{Set: true, Valid: true, Time: time.Date(2027, 3, 1, 0, 0, 0, 0, time.UTC)},
	})
	require.NoError(t, err)
	for _, t2 := range []string{"national_id", "vehicle_registration"} {
		_, err = f.svc.ReviewDocument(ctx, f.admin, docs[t2].ID, Review{Decision: "approve"})
		require.NoError(t, err)
	}

	ob, err := f.svc.Onboarding(ctx, driver)
	require.NoError(t, err)
	assert.Equal(t, StatusDocumentsPending, ob.Status, "falta reenviar el SOAT")
	slot := ob.Documents[2]
	require.Equal(t, "mandatory_insurance", slot.DocType)
	require.NotNil(t, slot.Latest)
	assert.Equal(t, "Foto borrosa", *slot.Latest.RejectReason)
	assert.Equal(t, 1, slot.RejectedCount)
	assert.Equal(t, []drivers.DocumentProblem{{Type: "mandatory_insurance", Problem: "missing"}}, ob.BlockedDocuments)

	resent := f.upload(t, driver, allDocuments()[2])
	_, err = f.svc.ReviewDocument(ctx, f.admin, resent.ID, Review{Decision: "approve"})
	require.NoError(t, err)
	ob, err = f.svc.Onboarding(ctx, driver)
	require.NoError(t, err)
	assert.Equal(t, StatusDocumentsOK, ob.Status)
	assert.Empty(t, ob.BlockedDocuments)
	assert.False(t, ob.CanGoOnline, "aún sin suscripción")
	last := f.notices(t, driver)[0]
	assert.Equal(t, "doc_approved", last.Kind)
	assert.Contains(t, last.Body, "al día")

	file, err := f.svc.File(ctx, driver)
	require.NoError(t, err)
	assert.Equal(t, StatusDocumentsOK, file.Status)
	require.NotNil(t, file.Documents[1].Current)
	assert.Len(t, file.Documents[1].Current.Photos, 2, "el admin ve las fotos con URL firmada")
	assert.Contains(t, file.Documents[1].Current.Photos[0].URL, "op=get")
}

// FR-007, escenario US2-6: el aprobado anterior sigue vigente mientras el nuevo está en revisión
// y queda reemplazado al aprobar el nuevo.
func TestIntegrationRenewalKeepsPreviousApproved(t *testing.T) {
	f := newFixture(t)
	ctx := context.Background()
	driver := f.newDriver(t, "+573101112233")
	_, err := f.svc.SetVehicle(ctx, driver, testVehicle)
	require.NoError(t, err)
	for _, in := range allDocuments() {
		d := f.upload(t, driver, in)
		_, err := f.svc.ReviewDocument(ctx, f.admin, d.ID, Review{Decision: "approve"})
		require.NoError(t, err)
	}
	assert.Empty(t, f.gate(t, driver))

	renewal := allDocuments()[2]
	renewal.ExpiresAt = date("2028-06-30")
	newSOAT := f.upload(t, driver, renewal)
	assert.Empty(t, f.gate(t, driver), "sigue trabajando con el anterior")
	ob, err := f.svc.Onboarding(ctx, driver)
	require.NoError(t, err)
	assert.Equal(t, StatusDocumentsOK, ob.Status)
	require.NotNil(t, ob.Documents[2].Current)
	require.NotNil(t, ob.Documents[2].Latest, "la renovación en revisión se muestra junto al vigente")
	assert.Equal(t, "submitted", ob.Documents[2].Latest.Status)

	_, err = f.svc.ReviewDocument(ctx, f.admin, newSOAT.ID, Review{Decision: "approve"})
	require.NoError(t, err)
	rows, err := f.st.ListDriverDocuments(ctx, driver)
	require.NoError(t, err)
	approved, superseded := 0, 0
	for _, r := range rows {
		if r.DocType != store.DriverDocTypeMandatoryInsurance {
			continue
		}
		switch r.Status {
		case store.DocumentStatusApproved:
			approved++
			assert.Equal(t, "2028-06-30", r.ExpiresAt.Time.Format(time.DateOnly))
		case store.DocumentStatusSuperseded:
			superseded++
		}
	}
	assert.Equal(t, 1, approved)
	assert.Equal(t, 1, superseded)
}

// FR-010, FR-027: avisos a 15 y 3 días y el día del vencimiento, una sola vez cada uno; SMS
// desde 3 días.
func TestIntegrationExpiryNotices(t *testing.T) {
	f := newFixture(t)
	ctx := context.Background()
	driver := f.newDriver(t, "+573101112233")
	_, err := f.svc.SetVehicle(ctx, driver, testVehicle)
	require.NoError(t, err)
	for _, in := range allDocuments() {
		if in.DocType == "mandatory_insurance" {
			in.ExpiresAt = date("2026-11-11") // 15 días después del reloj
		}
		d := f.upload(t, driver, in)
		_, err := f.svc.ReviewDocument(ctx, f.admin, d.ID, Review{Decision: "approve"})
		require.NoError(t, err)
	}
	before := len(f.notices(t, driver))
	sms := &fakeSMS{}
	f.svc.Notify.SMS = sms

	n, err := f.svc.CheckExpiries(ctx)
	require.NoError(t, err)
	assert.Equal(t, 1, n)
	n, err = f.svc.CheckExpiries(ctx)
	require.NoError(t, err)
	assert.Zero(t, n, "deduplicado")
	early := f.notices(t, driver)[0]
	assert.Equal(t, "doc_expiring", early.Kind)
	assert.False(t, early.Sms)

	f.clock.t = f.clock.t.AddDate(0, 0, 12) // faltan 3 días
	n, err = f.svc.CheckExpiries(ctx)
	require.NoError(t, err)
	assert.Equal(t, 1, n)
	late := f.notices(t, driver)[0]
	assert.True(t, late.Sms, "a 3 días también por SMS")
	sent, err := f.svc.Notify.SendPendingSMS(ctx)
	require.NoError(t, err)
	assert.Equal(t, 1, sent)

	f.clock.t = f.clock.t.AddDate(0, 0, 3) // día del vencimiento
	n, err = f.svc.CheckExpiries(ctx)
	require.NoError(t, err)
	assert.Equal(t, 1, n)
	expired := f.notices(t, driver)[0]
	assert.Equal(t, "doc_expired", expired.Kind)
	assert.Contains(t, expired.Body, "SOAT vencido: envía el nuevo")
	assert.Equal(t, []drivers.DocumentProblem{{Type: "mandatory_insurance", Problem: "expired"}}, f.gate(t, driver))
	assert.Len(t, f.notices(t, driver), before+3)

	sent, err = f.svc.Notify.SendPendingSMS(ctx)
	require.NoError(t, err)
	assert.Equal(t, 1, sent)
	assert.Equal(t, []string{"+573101112233", "+573101112233"}, sms.to)
	sent, err = f.svc.Notify.SendPendingSMS(ctx)
	require.NoError(t, err)
	assert.Zero(t, sent, "cada SMS se envía una vez")
}

type fakeSMS struct{ to []string }

func (s *fakeSMS) SendSMS(_ context.Context, phone, _ string) error {
	s.to = append(s.to, phone)
	return nil
}

// FR-008: la cola va del envío más antiguo al más reciente.
func TestIntegrationQueueOldestFirst(t *testing.T) {
	f := newFixture(t)
	ctx := context.Background()
	var ids []uuid.UUID
	for i, phone := range []string{"+573101110001", "+573101110002", "+573101110003"} {
		d := f.newDriver(t, phone)
		ids = append(ids, d)
		_, err := f.svc.SetVehicle(ctx, d, testVehicle)
		require.NoError(t, err)
		f.clock.t = f.clock.t.Add(time.Duration(3-i) * time.Hour) // cada uno envía después del anterior
		f.upload(t, d, allDocuments()[0])
		f.upload(t, d, allDocuments()[1])
	}
	q, err := f.svc.Queue(ctx)
	require.NoError(t, err)
	require.Len(t, q, 3)
	assert.Equal(t, ids[0], q[0].DriverID)
	assert.Equal(t, int64(2), q[0].PendingDocuments)
	assert.True(t, q[0].OldestSubmittedAt.Before(q[2].OldestSubmittedAt))
}
