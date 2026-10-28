package kyc

import (
	"context"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/kyq/backend/internal/drivers"
	"github.com/kyq/backend/internal/storage"
	"github.com/kyq/backend/internal/store"
	"github.com/kyq/backend/internal/testdb"
)

// Research R7: la migración 00007 conserva a los conductores de 001. Sus documentos pasan a
// aprobados y los dos tipos nuevos se crean como marcadores aprobados (cédula sin vencimiento,
// técnico-mecánica exenta 60 días), así que pueden seguir poniéndose ONLINE.
func TestIntegrationMigration007KeepsDriversOf001Working(t *testing.T) {
	st, migrateTo := testdb.NewAt(t, 6)
	ctx := context.Background()
	admin, carlos, pending := uuid.New(), uuid.New(), uuid.New()
	exec := func(sql string, args ...any) {
		_, err := st.Pool.Exec(ctx, sql, args...)
		require.NoError(t, err)
	}
	exec(`INSERT INTO users (id, phone_e164, role, display_name) VALUES
	        ($1, '+573000000000', 'admin', 'Admin'),
	        ($2, '+573100000001', 'driver', 'Carlos Prueba'),
	        ($3, '+573100000009', 'driver', 'Sin documentos')`, admin, carlos, pending)
	exec(`INSERT INTO drivers (user_id, qr_token, vehicle_plate, vehicle_description) VALUES
	        ($1, 'qr-carlos', 'KYQ001', 'Kia gris'), ($2, 'qr-pending', 'KYQ002', 'Mazda')`, carlos, pending)
	exec(`INSERT INTO subscriptions (driver_id, paid_until, updated_by) VALUES ($1, now() + interval '20 days', $2)`, carlos, admin)
	exec(`INSERT INTO driver_documents (id, driver_id, doc_type, expires_at, approved_by, approved_at) VALUES
	        ($1, $4, 'license', '2030-01-31', $5, now()),
	        ($2, $4, 'mandatory_insurance', '2030-01-31', $5, now()),
	        ($3, $4, 'vehicle_registration', '2030-01-31', $5, now()),
	        ($6, $7, 'license', '2030-01-31', NULL, NULL)`,
		uuid.New(), uuid.New(), uuid.New(), carlos, admin, uuid.New(), pending)

	migrateTo(7)

	rows, err := st.ListDocumentsForDrivers(ctx, []uuid.UUID{carlos})
	require.NoError(t, err)
	assert.Len(t, rows, 5)
	now := time.Now()
	assert.Empty(t, drivers.DocumentProblems(drivers.GateDocuments(rows), now))
	profile, err := st.GetDriverProfile(ctx, carlos)
	require.NoError(t, err)
	assert.Equal(t, drivers.BlockNone, drivers.EvaluateOnline(profile.PaidUntil.Time, drivers.GateDocuments(rows), false, now),
		"Carlos sigue pudiendo ponerse ONLINE")

	all, err := st.ListDriverDocuments(ctx, carlos)
	require.NoError(t, err)
	for _, d := range all {
		assert.True(t, d.Legacy, "%s marcado como migrado", d.DocType)
		if d.DocType == store.DriverDocTypeTechnicalInspection {
			assert.WithinDuration(t, now.AddDate(0, 0, 60), d.ExemptUntil.Time, 48*time.Hour)
		}
	}
	notices, err := st.ListNotices(ctx, carlos)
	require.NoError(t, err)
	require.Len(t, notices, 1)
	assert.Equal(t, "doc_legacy", notices[0].Kind)

	pendingDocs, err := st.ListDriverDocuments(ctx, pending)
	require.NoError(t, err)
	require.Len(t, pendingDocs, 1, "sin documentos aprobados no recibe marcadores")
	assert.Equal(t, store.DocumentStatusSubmitted, pendingDocs[0].Status)

	// Ya migrado, el estado de alta de Carlos es "al día" aunque falten marca y modelo.
	ob, err := (&Service{Store: st, Objects: storage.NewMemory()}).Onboarding(ctx, carlos)
	require.NoError(t, err)
	assert.Equal(t, StatusDocumentsOK, ob.Status)
	assert.True(t, ob.CanGoOnline)
	assert.Equal(t, "active", ob.SubscriptionStatus)
}
