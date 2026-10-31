package control

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/kyq/backend/internal/auth"
	"github.com/kyq/backend/internal/hexgrid"
	"github.com/kyq/backend/internal/store"
	"github.com/kyq/backend/internal/testdb"
)

// T016: la instantánea con base real a partir de conductores, viajes y solicitudes sembrados.
func TestIntegrationTowerSnapshot(t *testing.T) {
	st := testdb.New(t)
	ctx := context.Background()
	at := time.Now().UTC().Truncate(time.Second)
	admin, passenger, passenger2 := uuid.New(), uuid.New(), uuid.New()
	free, busy, offline := uuid.New(), uuid.New(), uuid.New()
	for i, u := range []store.CreateUserParams{
		{ID: admin, PhoneE164: "+573000000000", Role: store.UserRoleAdmin, DisplayName: "Admin"},
		{ID: passenger, PhoneE164: "+573200000001", Role: store.UserRolePassenger, DisplayName: "Ana"},
		{ID: passenger2, PhoneE164: "+573200000002", Role: store.UserRolePassenger, DisplayName: "Luz"},
		{ID: free, PhoneE164: "+573100000001", Role: store.UserRoleDriver, DisplayName: "Carlos"},
		{ID: busy, PhoneE164: "+573100000002", Role: store.UserRoleDriver, DisplayName: "Diana"},
		{ID: offline, PhoneE164: "+573100000003", Role: store.UserRoleDriver, DisplayName: "Elkin"},
	} {
		_, err := st.CreateUser(ctx, u)
		require.NoError(t, err)
		if i >= 3 {
			require.NoError(t, st.CreateDriver(ctx, store.CreateDriverParams{UserID: u.ID, QrToken: "qr-" + u.ID.String(), VehiclePlate: "ABC12" + string(rune('0'+i)), VehicleDescription: "Kia"}))
		}
	}
	require.NoError(t, st.UpsertFareTable(ctx, store.UpsertFareTableParams{
		CityCode: "bogota", Currency: "COP", BaseMinor: 400_000, PerKmMinor: 120_000, PerMinuteMinor: 30_000,
		MinimumMinor: 700_000, RoundingMinor: 10_000, UpdatedBy: admin,
	}))
	for _, d := range []struct {
		id       uuid.UUID
		presence store.DriverPresence
		at       time.Time
		p        [2]float64
	}{
		{free, store.DriverPresenceFree, at, [2]float64{centro.Lat, centro.Lng}},
		{busy, store.DriverPresenceBusy, at.Add(-5 * time.Minute), [2]float64{chapinero.Lat, chapinero.Lng}},
		{offline, store.DriverPresenceOffline, at, [2]float64{usaquen.Lat, usaquen.Lng}},
	} {
		require.NoError(t, st.SetDriverLocation(ctx, store.SetDriverLocationParams{Lat: d.p[0], Lng: d.p[1], RecordedAt: d.at, UserID: d.id}))
		require.NoError(t, st.SetDriverPresence(ctx, store.SetDriverPresenceParams{UserID: d.id, Presence: d.presence}))
	}
	trip := func(passengerID, driverID uuid.UUID, p hexgrid.Point, status store.TripStatus, created time.Time, reason store.TripCancelReason) {
		id := uuid.New()
		require.NoError(t, st.InsertTrip(ctx, store.InsertTripParams{
			ID: id, PassengerID: passengerID, DriverID: driverID, RequestedDriverID: driverID, CityCode: "bogota", Currency: "COP",
			PickupLat: p.Lat, PickupLng: p.Lng, DropoffLat: p.Lat + 0.01, DropoffLng: p.Lng + 0.01,
			RouteDistanceM: 1000, RouteDurationS: 300, SuggestedFareMinor: 800_000, Status: status, CreatedAt: created,
		}))
		if reason != "" {
			require.NoError(t, st.UpdateTrip(ctx, store.UpdateTripParams{
				ID: id, Status: status, DriverID: driverID, CancelReason: store.NullTripCancelReason{TripCancelReason: reason, Valid: true},
				CancelledAt: pgtype.Timestamptz{Time: created.Add(time.Minute), Valid: true},
			}))
		}
	}
	trip(passenger, busy, usaquen, store.TripStatusINPROGRESS, at.Add(-20*time.Minute), "")
	trip(passenger2, offline, usaquen, store.TripStatusCANCELLED, at.Add(-30*time.Minute), store.TripCancelReasonOfferExpired)
	trip(passenger2, offline, usaquen, store.TripStatusCANCELLED, at.Add(-3*time.Hour), store.TripCancelReasonOfferExpired)

	issuer := auth.NewTokenIssuer([]byte("test-secret-test-secret-test-secret!"), nil)
	mux := http.NewServeMux()
	(&Handlers{Store: st, Now: func() time.Time { return at }}).Register(mux, auth.RequireAuth(issuer))
	get := func(id uuid.UUID, role, path string) *httptest.ResponseRecorder {
		tok, err := issuer.IssueAccess(auth.Principal{UserID: id, Role: role})
		require.NoError(t, err)
		req := httptest.NewRequest(http.MethodGet, path, nil)
		req.Header.Set("Authorization", "Bearer "+tok)
		rec := httptest.NewRecorder()
		mux.ServeHTTP(rec, req)
		return rec
	}

	rec := get(admin, auth.RoleAdmin, "/v1/admin/tower")
	require.Equal(t, http.StatusOK, rec.Code, rec.Body.String())
	var s Snapshot
	require.NoError(t, json.NewDecoder(rec.Body).Decode(&s))
	assert.Equal(t, 8, s.Resolution)
	assert.Equal(t, Totals{Online: 2, Free: 1, Busy: 1, Stale: 1, ActiveTrips: 1, Requests: 2, UnservedRequests: 1}, s.Totals)
	cells := byCell(s)
	assert.Equal(t, 1, cells[cellOf(t, centro, 8)].FreeDrivers)
	assert.Equal(t, 1, cells[cellOf(t, chapinero, 8)].ActiveTrips, "en la posición de Diana")
	assert.Equal(t, LevelNoSupply, cells[cellOf(t, usaquen, 8)].Level)
	assert.Len(t, s.Drivers, 2, "el OFFLINE no aparece")

	rec = get(admin, auth.RoleAdmin, "/v1/admin/tower?res=6")
	require.Equal(t, http.StatusOK, rec.Code)
	for _, bad := range []string{"5", "10", "x"} {
		assert.Equal(t, http.StatusBadRequest, get(admin, auth.RoleAdmin, "/v1/admin/tower?res="+bad).Code, bad)
	}
	assert.Equal(t, http.StatusForbidden, get(passenger, auth.RolePassenger, "/v1/admin/tower").Code)
	assert.Equal(t, http.StatusForbidden, get(free, auth.RoleDriver, "/v1/admin/tower").Code)

	// 009: el conductor ocupado y su hexágono llevan el viaje activo (FR-001).
	var tripID uuid.UUID
	for _, d := range s.Drivers {
		if d.DriverID == busy {
			require.NotNil(t, d.ActiveTripID)
			tripID = *d.ActiveTripID
		} else {
			assert.Nil(t, d.ActiveTripID)
		}
	}
	assert.Equal(t, []uuid.UUID{tripID}, cells[cellOf(t, chapinero, 8)].TripIDs)

	// Detalle del viaje: sin teléfonos, con pasos, posición y SOS (FR-002), y auditado (FR-004).
	_, err := st.InsertSOSAlert(ctx, store.InsertSOSAlertParams{
		ID: uuid.New(), TripID: uuid.NullUUID{UUID: tripID, Valid: true}, RaisedBy: passenger, RaisedRole: store.SosRolePassenger,
		RoomName: "sos-test", CreatedAt: at,
	})
	require.NoError(t, err)
	rec = get(admin, auth.RoleAdmin, "/v1/admin/trips/"+tripID.String())
	require.Equal(t, http.StatusOK, rec.Code, rec.Body.String())
	assert.NotContains(t, rec.Body.String(), "+57", "FR-002: sin teléfonos")
	var in Inspection
	require.NoError(t, json.NewDecoder(rec.Body).Decode(&in))
	assert.True(t, in.Active)
	assert.Equal(t, "Ana", in.Passenger.DisplayName)
	assert.Equal(t, "Diana", in.Driver.DisplayName)
	assert.Equal(t, "ABC124", in.VehiclePlate)
	assert.Equal(t, "REQUESTED", in.Steps[0].Status)
	require.NotNil(t, in.DriverPosition)
	assert.InDelta(t, chapinero.Lat, in.DriverPosition.Lat, 1e-9)
	assert.True(t, in.DriverPosition.Stale, "ubicación de hace 5 min")
	require.NotNil(t, in.OpenSos)
	assert.Equal(t, "open", in.OpenSos.Status)
	assert.Nil(t, in.Payment)
	audit, err := st.ListTripInspections(ctx, tripID)
	require.NoError(t, err)
	require.Len(t, audit, 1)
	assert.Equal(t, admin, audit[0].AdminID)

	assert.Equal(t, http.StatusForbidden, get(passenger, auth.RolePassenger, "/v1/admin/trips/"+tripID.String()).Code)
	assert.Equal(t, http.StatusNotFound, get(admin, auth.RoleAdmin, "/v1/admin/trips/"+uuid.NewString()).Code)
	assert.Equal(t, http.StatusNotFound, get(admin, auth.RoleAdmin, "/v1/admin/trips/x").Code)

	// La huella cambia cuando cambia la presencia.
	before, err := st.TowerFingerprint(ctx, at.Add(-RequestWindow))
	require.NoError(t, err)
	require.NoError(t, st.SetDriverPresence(ctx, store.SetDriverPresenceParams{UserID: free, Presence: store.DriverPresenceOffline}))
	after, err := st.TowerFingerprint(ctx, at.Add(-RequestWindow))
	require.NoError(t, err)
	assert.False(t, sameFingerprint(before, after))
	assert.Equal(t, int64(1), after.Online)
}
