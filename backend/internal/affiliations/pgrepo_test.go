package affiliations

import (
	"context"
	"testing"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/kyq/backend/internal/store"
	"github.com/kyq/backend/internal/testdb"
)

// Misma secuencia que service_test.go, contra PostgreSQL real.
func TestPgRepoAffiliationLifecycle(t *testing.T) {
	st := testdb.New(t)
	ctx := context.Background()
	driverID, passengerID := uuid.New(), uuid.New()
	_, err := st.CreateUser(ctx, store.CreateUserParams{ID: driverID, PhoneE164: "+573001112233", Role: store.UserRoleDriver, DisplayName: "Carlos"})
	require.NoError(t, err)
	require.NoError(t, st.CreateDriver(ctx, store.CreateDriverParams{UserID: driverID, QrToken: "qr-carlos", VehiclePlate: "ABC123", VehicleDescription: "Kia gris"}))
	_, err = st.CreateUser(ctx, store.CreateUserParams{ID: passengerID, PhoneE164: "+573004445566", Role: store.UserRolePassenger, DisplayName: "Ana"})
	require.NoError(t, err)

	svc := NewService(NewPgRepo(st.Queries))

	d, created, err := svc.Affiliate(ctx, passengerID, "qr-carlos")
	require.NoError(t, err)
	assert.True(t, created)
	assert.Equal(t, "offline", d.Presence)

	_, created, err = svc.Affiliate(ctx, passengerID, "qr-carlos")
	require.NoError(t, err)
	assert.False(t, created)

	clients, err := svc.Clients(ctx, driverID)
	require.NoError(t, err)
	require.Len(t, clients, 1)
	assert.Equal(t, "Ana", clients[0].DisplayName)

	require.NoError(t, svc.Remove(ctx, passengerID, driverID))
	assert.ErrorIs(t, svc.Remove(ctx, passengerID, driverID), ErrNotAffiliated)
	chosen, err := svc.ChosenDrivers(ctx, passengerID)
	require.NoError(t, err)
	assert.Empty(t, chosen)

	_, created, err = svc.Affiliate(ctx, passengerID, "qr-carlos")
	require.NoError(t, err)
	assert.True(t, created)

	_, _, err = svc.Affiliate(ctx, passengerID, "otro")
	assert.ErrorIs(t, err, ErrDriverNotFound)
}
