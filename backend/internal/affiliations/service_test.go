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

type fixedEligibility bool

func (f fixedEligibility) CanWork(context.Context, uuid.UUID) (bool, error) { return bool(f), nil }

// FR-004 (002): un conductor sin documentos o suscripción al día no recibe clientes nuevos, pero
// quien ya lo tenía elegido lo conserva.
func TestAffiliateRequiresDriverWhoCanWork(t *testing.T) {
	svc, _, passenger, _ := newService()
	ctx := context.Background()

	svc.Eligibility = fixedEligibility(false)
	_, _, err := svc.Affiliate(ctx, passenger, "qr-carlos")
	assert.ErrorIs(t, err, ErrDriverNotAvailable)

	svc.Eligibility = fixedEligibility(true)
	_, created, err := svc.Affiliate(ctx, passenger, "qr-carlos")
	require.NoError(t, err)
	assert.True(t, created)

	svc.Eligibility = fixedEligibility(false)
	_, created, err = svc.Affiliate(ctx, passenger, "qr-carlos")
	require.NoError(t, err, "volver a escanear a un conductor ya elegido no se bloquea")
	assert.False(t, created)
}

// RN-KYQ-005 (008): la afiliación registra su origen; después del viaje solo con un viaje
// terminado del propio pasajero.
func TestAffiliationSources(t *testing.T) {
	svc, repo, passenger, driver := newService()
	ctx := context.Background()

	_, created, err := svc.AffiliateFrom(ctx, passenger, "qr-carlos", SourceLink)
	require.NoError(t, err)
	assert.True(t, created)
	clients, err := svc.Clients(ctx, driver)
	require.NoError(t, err)
	assert.Equal(t, SourceLink, clients[0].Source)

	trip, other := uuid.New(), uuid.New()
	repo.AddCompletedTrip(trip, other, driver)
	_, _, err = svc.AffiliateAfterTrip(ctx, passenger, trip)
	assert.ErrorIs(t, err, ErrTripNotFound, "el viaje de otro pasajero no sirve")
	_, _, err = svc.AffiliateAfterTrip(ctx, other, uuid.New())
	assert.ErrorIs(t, err, ErrTripNotFound)
	got, created, err := svc.AffiliateAfterTrip(ctx, other, trip)
	require.NoError(t, err)
	assert.True(t, created)
	assert.Equal(t, driver, got.DriverID)

	require.NoError(t, svc.Remove(ctx, passenger, driver))
	_, created, err = svc.AffiliateAfterTrip(ctx, passenger, func() uuid.UUID { id := uuid.New(); repo.AddCompletedTrip(id, passenger, driver); return id }())
	require.NoError(t, err)
	assert.True(t, created, "reactivar cuenta como afiliación nueva")
	clients, err = svc.Clients(ctx, driver)
	require.NoError(t, err)
	sources := map[uuid.UUID]Source{}
	for _, c := range clients {
		sources[c.PassengerID] = c.Source
	}
	assert.Equal(t, SourcePostTrip, sources[passenger], "reactivar actualiza el origen")
	assert.Equal(t, SourcePostTrip, sources[other])
}

type noWork struct{}

func (noWork) CanWork(context.Context, uuid.UUID) (bool, error) { return false, nil }

// FR-015/FR-017 (008): la página del enlace solo muestra conductores que pueden recibir clientes.
func TestPublicDriver(t *testing.T) {
	svc, _, _, _ := newService()
	ctx := context.Background()
	name, err := svc.PublicDriver(ctx, "qr-carlos")
	require.NoError(t, err)
	assert.Equal(t, "Carlos", name)
	_, err = svc.PublicDriver(ctx, "otro")
	assert.ErrorIs(t, err, ErrDriverNotFound)
	svc.Eligibility = noWork{}
	_, err = svc.PublicDriver(ctx, "qr-carlos")
	assert.ErrorIs(t, err, ErrDriverNotAvailable)
}
