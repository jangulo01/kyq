package affiliations

import (
	"context"
	"testing"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func newService() (*Service, *MemRepo, uuid.UUID, uuid.UUID) {
	repo := NewMemRepo()
	driver := uuid.New()
	repo.AddDriver(ChosenDriver{DriverID: driver, DisplayName: "Carlos", VehicleDescription: "Kia gris", Presence: "free"}, "qr-carlos")
	return NewService(repo), repo, uuid.New(), driver
}

// RN-KYQ-005: la afiliación por QR deja al pasajero en la cartera del conductor.
func TestAffiliateByQR(t *testing.T) {
	svc, _, passenger, driver := newService()
	ctx := context.Background()

	got, created, err := svc.Affiliate(ctx, passenger, "qr-carlos")
	require.NoError(t, err)
	assert.True(t, created)
	assert.Equal(t, driver, got.DriverID)

	chosen, err := svc.ChosenDrivers(ctx, passenger)
	require.NoError(t, err)
	require.Len(t, chosen, 1)

	clients, err := svc.Clients(ctx, driver)
	require.NoError(t, err)
	require.Len(t, clients, 1)
	assert.Equal(t, passenger, clients[0].PassengerID)
}

func TestRescanDoesNotDuplicate(t *testing.T) {
	svc, _, passenger, _ := newService()
	ctx := context.Background()
	_, _, err := svc.Affiliate(ctx, passenger, "qr-carlos")
	require.NoError(t, err)

	_, created, err := svc.Affiliate(ctx, passenger, "qr-carlos")
	require.NoError(t, err)
	assert.False(t, created, "re-escanear no crea otro vínculo")
	chosen, _ := svc.ChosenDrivers(ctx, passenger)
	assert.Len(t, chosen, 1)
}

func TestUnknownQR(t *testing.T) {
	svc, _, passenger, _ := newService()
	_, _, err := svc.Affiliate(context.Background(), passenger, "no-existe")
	assert.ErrorIs(t, err, ErrDriverNotFound)
}

func TestRemoveAndReactivate(t *testing.T) {
	svc, _, passenger, driver := newService()
	ctx := context.Background()
	_, _, err := svc.Affiliate(ctx, passenger, "qr-carlos")
	require.NoError(t, err)

	require.NoError(t, svc.Remove(ctx, passenger, driver))
	chosen, _ := svc.ChosenDrivers(ctx, passenger)
	assert.Empty(t, chosen, "eliminado deja de verse")
	clients, _ := svc.Clients(ctx, driver)
	assert.Empty(t, clients, "y sale de la cartera")
	ok, _ := svc.IsAffiliated(ctx, passenger, driver)
	assert.False(t, ok, "y ya no puede ver su presencia")

	_, created, err := svc.Affiliate(ctx, passenger, "qr-carlos")
	require.NoError(t, err)
	assert.True(t, created, "re-escanear tras eliminar lo reactiva")
	ok, _ = svc.IsAffiliated(ctx, passenger, driver)
	assert.True(t, ok)
}

func TestRemoveUnknownIsNotFound(t *testing.T) {
	svc, _, passenger, driver := newService()
	assert.ErrorIs(t, svc.Remove(context.Background(), passenger, driver), ErrNotAffiliated)
}
