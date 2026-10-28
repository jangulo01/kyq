package ptt_test

import (
	"context"
	"errors"
	"net/http"
	"net/http/httptest"
	"sync"
	"testing"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/kyq/backend/internal/auth"
	"github.com/kyq/backend/internal/fares"
	"github.com/kyq/backend/internal/ptt"
	"github.com/kyq/backend/internal/realtime"
	"github.com/kyq/backend/internal/store"
	"github.com/kyq/backend/internal/testdb"
	"github.com/kyq/backend/internal/trips"
)

func TestParticipantTokenListensButCannotPublish(t *testing.T) {
	lk := ptt.LiveKit{APIKey: "devkey", APISecret: "secret"}
	now := time.Now().Truncate(time.Second)
	raw, err := lk.ParticipantToken("user-1", "Ana", "trip-1", now, 15*time.Minute)
	require.NoError(t, err)

	claims := jwt.MapClaims{}
	_, err = jwt.ParseWithClaims(raw, claims, func(*jwt.Token) (any, error) { return []byte("secret"), nil })
	require.NoError(t, err)
	assert.Equal(t, "devkey", claims["iss"])
	assert.Equal(t, "user-1", claims["sub"])
	assert.EqualValues(t, now.Add(15*time.Minute).Unix(), claims["exp"], "caduca al cerrar el canal")
	video := claims["video"].(map[string]any)
	assert.Equal(t, "trip-1", video["room"])
	assert.Equal(t, true, video["roomJoin"])
	assert.Equal(t, false, video["canPublish"], "publicar audio lo concede el turno (FR-017)")
	assert.Equal(t, true, video["canSubscribe"])
	assert.Equal(t, true, video["canPublishData"], "mensajes floor.taken / floor.released")
	assert.Equal(t, []any{"microphone"}, video["canPublishSources"], "solo audio de micrófono (FR-016)")
	assert.Nil(t, video["roomCreate"], "un participante no administra salas")
}

func tokenExpiry(t *testing.T, raw string) int64 {
	t.Helper()
	claims := jwt.MapClaims{}
	_, err := jwt.ParseWithClaims(raw, claims, func(*jwt.Token) (any, error) { return []byte("secret"), nil },
		jwt.WithoutClaimsValidation())
	require.NoError(t, err)
	exp, err := claims.GetExpirationTime()
	require.NoError(t, err)
	return exp.Unix()
}

func TestAPIURLFrom(t *testing.T) {
	assert.Equal(t, "http://192.168.1.66:7880", ptt.APIURLFrom("ws://192.168.1.66:7880"))
	assert.Equal(t, "https://voice.kyq.example", ptt.APIURLFrom("wss://voice.kyq.example"))
}

type fixedRoute struct{}

func (fixedRoute) Route(context.Context, float64, float64, float64, float64) (fares.Route, error) {
	return fares.Route{DistanceM: 5200, DurationS: 900}, nil
}

type fakeRooms struct {
	mu               sync.Mutex
	created, deleted []string
	canPublish       map[string]bool // último permiso por identidad
	failDelete       bool
	failGrant        bool
	failRevoke       bool
}

func (r *fakeRooms) SetCanPublish(_ context.Context, _, identity string, canPublish bool) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	if (canPublish && r.failGrant) || (!canPublish && r.failRevoke) {
		return errors.New("livekit caído")
	}
	if r.canPublish == nil {
		r.canPublish = map[string]bool{}
	}
	r.canPublish[identity] = canPublish
	return nil
}

func (r *fakeRooms) publishes(id uuid.UUID) bool {
	r.mu.Lock()
	defer r.mu.Unlock()
	return r.canPublish[id.String()]
}

func (r *fakeRooms) CreateRoom(_ context.Context, name string) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.created = append(r.created, name)
	return nil
}

func (r *fakeRooms) DeleteRoom(_ context.Context, name string) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	if r.failDelete {
		return errors.New("livekit caído")
	}
	r.deleted = append(r.deleted, name)
	return nil
}

type recorder struct {
	mu   sync.Mutex
	msgs map[string][]string
}

func (r *recorder) Publish(_ context.Context, channel string, ev realtime.Event) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	if r.msgs == nil {
		r.msgs = map[string][]string{}
	}
	r.msgs[channel] = append(r.msgs[channel], ev.Type)
	return nil
}

type fixture struct {
	trips     *trips.Service
	ptt       *ptt.Service
	rooms     *fakeRooms
	pub       *recorder
	clock     *time.Time
	driver    uuid.UUID
	passenger uuid.UUID
}

func setup(t *testing.T) *fixture {
	st := testdb.New(t)
	ctx := context.Background()
	f := &fixture{rooms: &fakeRooms{}, pub: &recorder{}, driver: uuid.New(), passenger: uuid.New()}
	now := time.Date(2026, 10, 27, 12, 0, 0, 0, time.UTC)
	f.clock = &now
	clock := func() time.Time { return *f.clock }
	admin := uuid.New()
	mustUser := func(id uuid.UUID, phone string, role store.UserRole, name string) {
		_, err := st.CreateUser(ctx, store.CreateUserParams{ID: id, PhoneE164: phone, Role: role, DisplayName: name})
		require.NoError(t, err)
	}
	mustUser(admin, "+573000000001", store.UserRoleAdmin, "Admin")
	mustUser(f.driver, "+573100000001", store.UserRoleDriver, "Carlos")
	mustUser(f.passenger, "+573200000002", store.UserRolePassenger, "Ana")
	require.NoError(t, st.CreateDriver(ctx, store.CreateDriverParams{UserID: f.driver, QrToken: "qr-carlos-0000000", VehiclePlate: "KYQ001", VehicleDescription: "Kia"}))
	require.NoError(t, st.InsertAffiliation(ctx, store.InsertAffiliationParams{PassengerID: f.passenger, DriverID: f.driver}))
	require.NoError(t, st.SetDriverPresence(ctx, store.SetDriverPresenceParams{UserID: f.driver, Presence: store.DriverPresenceFree}))
	require.NoError(t, st.UpsertFareTable(ctx, store.UpsertFareTableParams{
		CityCode: "bogota", Currency: "COP", BaseMinor: 400_000, PerKmMinor: 120_000, PerMinuteMinor: 30_000,
		MinimumMinor: 700_000, RoundingMinor: 10_000, UpdatedBy: admin,
	}))
	f.trips = &trips.Service{Store: st, Routes: fixedRoute{}, CityCode: "bogota", Now: clock}
	f.ptt = &ptt.Service{
		Store: st, LiveKit: ptt.LiveKit{APIKey: "devkey", APISecret: "secret"}, Rooms: f.rooms,
		PublicURL: "ws://voice.test:7880", Publisher: f.pub, Now: clock,
	}
	return f
}

func (f *fixture) advance(d time.Duration) { *f.clock = f.clock.Add(d) }

// acceptedTrip returns a trip the driver has just accepted.
func (f *fixture) acceptedTrip(t *testing.T) uuid.UUID {
	ctx := context.Background()
	trip, err := f.trips.Request(ctx, f.passenger, f.driver, trips.Point{Lat: 4.60, Lng: -74.08}, trips.Point{Lat: 4.65, Lng: -74.05})
	require.NoError(t, err)
	_, err = f.ptt.Token(ctx, f.passenger, trip.ID)
	assert.ErrorIs(t, err, ptt.ErrNotOpen, "sin canal antes de aceptar (RN-KYQ-009)")
	f.act(t, f.driver, trip.ID, func(tr *trips.Trip, p trips.Party, now time.Time) error { return tr.Accept(p, nil, now) })
	return trip.ID
}

func (f *fixture) act(t *testing.T, user, tripID uuid.UUID, op func(*trips.Trip, trips.Party, time.Time) error) {
	_, err := f.trips.Act(context.Background(), user, tripID, op)
	require.NoError(t, err)
}

func TestIntegrationChannelLifecycle(t *testing.T) {
	f := setup(t)
	ctx := context.Background()
	tripID := f.acceptedTrip(t)
	room := "trip-" + tripID.String()

	creds, err := f.ptt.Token(ctx, f.passenger, tripID)
	require.NoError(t, err)
	assert.Equal(t, room, creds.Room)
	assert.Equal(t, "ws://voice.test:7880", creds.URL)
	assert.Nil(t, creds.ClosesAt, "abierto mientras dura el viaje")
	assert.Contains(t, f.rooms.created, room)

	_, err = f.ptt.Token(ctx, uuid.New(), tripID)
	assert.ErrorIs(t, err, ptt.ErrNotFound, "solo los dos participantes")

	// Turno exclusivo (FR-017).
	expires, err := f.ptt.TakeFloor(ctx, f.passenger, tripID)
	require.NoError(t, err)
	assert.True(t, f.clock.Add(ptt.FloorTTL).Equal(expires), "turno de 60 s")
	assert.True(t, f.rooms.publishes(f.passenger), "LiveKit deja publicar a quien tiene el turno")
	assert.False(t, f.rooms.publishes(f.driver))
	_, err = f.ptt.TakeFloor(ctx, f.driver, tripID)
	assert.ErrorIs(t, err, ptt.ErrBusy)
	assert.False(t, f.rooms.publishes(f.driver), "sin turno no hay permiso")
	_, err = f.ptt.TakeFloor(ctx, f.passenger, tripID)
	assert.NoError(t, err, "quien tiene el turno puede renovarlo")

	require.NoError(t, f.ptt.ReleaseFloor(ctx, f.driver, tripID), "soltar un turno ajeno no hace nada")
	_, err = f.ptt.TakeFloor(ctx, f.driver, tripID)
	assert.ErrorIs(t, err, ptt.ErrBusy)
	require.NoError(t, f.ptt.ReleaseFloor(ctx, f.passenger, tripID))
	assert.False(t, f.rooms.publishes(f.passenger), "soltar retira el permiso")
	_, err = f.ptt.TakeFloor(ctx, f.driver, tripID)
	require.NoError(t, err)

	// Un turno caducado se retira aunque la app no llame a DELETE.
	f.advance(ptt.FloorTTL + time.Second)
	expiredCount, err := f.ptt.ExpireFloors(ctx)
	require.NoError(t, err)
	assert.Equal(t, 1, expiredCount)
	assert.False(t, f.rooms.publishes(f.driver))
	_, err = f.ptt.TakeFloor(ctx, f.passenger, tripID)
	assert.NoError(t, err, "un turno caducado queda libre")

	// Al completar sigue abierto 15 min (RN-KYQ-014).
	for _, step := range []func(*trips.Trip, trips.Party, time.Time) error{(*trips.Trip).Arrive, (*trips.Trip).Start, (*trips.Trip).Complete} {
		f.act(t, f.driver, tripID, step)
	}
	completedAt := *f.clock
	creds, err = f.ptt.Token(ctx, f.driver, tripID)
	require.NoError(t, err)
	require.NotNil(t, creds.ClosesAt)
	assert.Equal(t, completedAt.Add(trips.PTTCloseDelay), creds.ClosesAt.UTC())
	assert.Equal(t, f.clock.Add(ptt.TokenTTL).Unix(), tokenExpiry(t, creds.Token), "tokens cortos")

	f.advance(trips.PTTCloseDelay - 2*time.Minute)
	creds, err = f.ptt.Token(ctx, f.driver, tripID)
	require.NoError(t, err)
	assert.Equal(t, creds.ClosesAt.Unix(), tokenExpiry(t, creds.Token), "nunca más allá del cierre")

	f.advance(2*time.Minute - time.Second)
	n, err := f.ptt.CloseDue(ctx)
	require.NoError(t, err)
	assert.Zero(t, n)

	f.advance(time.Second)
	f.rooms.failDelete = true
	n, err = f.ptt.CloseDue(ctx)
	require.NoError(t, err)
	assert.Zero(t, n, "si LiveKit no borra la sala el canal sigue pendiente")
	f.rooms.failDelete = false
	n, err = f.ptt.CloseDue(ctx)
	require.NoError(t, err)
	assert.Equal(t, 1, n)
	assert.Contains(t, f.rooms.deleted, room)
	assert.Contains(t, f.pub.msgs["user:"+f.passenger.String()], "ptt.closed")
	assert.Contains(t, f.pub.msgs["user:"+f.driver.String()], "ptt.closed")

	_, err = f.ptt.Token(ctx, f.passenger, tripID)
	assert.ErrorIs(t, err, ptt.ErrClosed)
	_, err = f.ptt.TakeFloor(ctx, f.passenger, tripID)
	assert.ErrorIs(t, err, ptt.ErrClosed)
	n, err = f.ptt.CloseDue(ctx)
	require.NoError(t, err)
	assert.Zero(t, n, "se cierra una sola vez")
}

func TestIntegrationFailedRevokeKeepsTheFloorUntilTheSweeperRevokes(t *testing.T) {
	f := setup(t)
	ctx := context.Background()
	tripID := f.acceptedTrip(t)
	_, err := f.ptt.TakeFloor(ctx, f.passenger, tripID)
	require.NoError(t, err)

	f.rooms.failRevoke = true
	assert.ErrorIs(t, f.ptt.ReleaseFloor(ctx, f.passenger, tripID), ptt.ErrUnavailable)
	assert.True(t, f.rooms.publishes(f.passenger), "LiveKit no retiró el permiso")
	_, err = f.ptt.TakeFloor(ctx, f.driver, tripID)
	assert.ErrorIs(t, err, ptt.ErrBusy, "el turno sigue registrado mientras el permiso siga dado")

	f.advance(ptt.FloorTTL + time.Second)
	n, err := f.ptt.ExpireFloors(ctx)
	require.NoError(t, err)
	assert.Zero(t, n, "sin retirada confirmada no se libera")
	_, err = f.ptt.TakeFloor(ctx, f.driver, tripID)
	assert.ErrorIs(t, err, ptt.ErrBusy, "ni siquiera caducado")

	f.rooms.failRevoke = false
	n, err = f.ptt.ExpireFloors(ctx)
	require.NoError(t, err)
	assert.Equal(t, 1, n)
	assert.False(t, f.rooms.publishes(f.passenger))
	_, err = f.ptt.TakeFloor(ctx, f.driver, tripID)
	assert.NoError(t, err)
}

func TestIntegrationFailedGrantDoesNotKeepTheFloor(t *testing.T) {
	f := setup(t)
	ctx := context.Background()
	tripID := f.acceptedTrip(t)

	f.rooms.failGrant = true
	_, err := f.ptt.TakeFloor(ctx, f.passenger, tripID)
	assert.ErrorIs(t, err, ptt.ErrUnavailable)
	f.rooms.failGrant = false
	_, err = f.ptt.TakeFloor(ctx, f.driver, tripID)
	assert.NoError(t, err, "con el permiso retirado el turno se soltó")

	// Si tampoco se puede retirar, el turno queda hasta que el barrido lo confirme.
	require.NoError(t, f.ptt.ReleaseFloor(ctx, f.driver, tripID))
	f.rooms.failGrant, f.rooms.failRevoke = true, true
	_, err = f.ptt.TakeFloor(ctx, f.passenger, tripID)
	assert.ErrorIs(t, err, ptt.ErrUnavailable)
	f.rooms.failGrant, f.rooms.failRevoke = false, false
	_, err = f.ptt.TakeFloor(ctx, f.driver, tripID)
	assert.ErrorIs(t, err, ptt.ErrBusy)
}

func TestIntegrationCancelClosesChannelAtOnce(t *testing.T) {
	f := setup(t)
	ctx := context.Background()
	tripID := f.acceptedTrip(t)
	f.act(t, f.passenger, tripID, (*trips.Trip).Cancel)

	_, err := f.ptt.Token(ctx, f.driver, tripID)
	assert.ErrorIs(t, err, ptt.ErrClosed, "el canal se cierra al cancelar")
	n, err := f.ptt.CloseDue(ctx)
	require.NoError(t, err)
	assert.Equal(t, 1, n)
}

func TestIntegrationHTTPStatuses(t *testing.T) {
	f := setup(t)
	tokens := auth.NewTokenIssuer([]byte("test-secret-test-secret-test-secret!"), func() time.Time { return *f.clock })
	mux := http.NewServeMux()
	(&ptt.Handlers{Service: f.ptt}).Register(mux, auth.RequireAuth(tokens))
	bearer := func(id uuid.UUID, role string) string {
		tok, err := tokens.IssueAccess(auth.Principal{UserID: id, Role: role})
		require.NoError(t, err)
		return tok
	}
	passenger, driver := bearer(f.passenger, auth.RolePassenger), bearer(f.driver, auth.RoleDriver)
	stranger := bearer(uuid.New(), auth.RolePassenger)
	call := func(method, path, token string) int {
		req := httptest.NewRequest(method, path, nil)
		req.Header.Set("Authorization", "Bearer "+token)
		rec := httptest.NewRecorder()
		mux.ServeHTTP(rec, req)
		return rec.Code
	}

	tripID := f.acceptedTrip(t)
	base := "/v1/trips/" + tripID.String() + "/ptt/"
	assert.Equal(t, http.StatusOK, call(http.MethodPost, base+"token", driver))
	assert.Equal(t, http.StatusNotFound, call(http.MethodPost, base+"token", stranger))
	assert.Equal(t, http.StatusOK, call(http.MethodPost, base+"floor", passenger))
	assert.Equal(t, http.StatusConflict, call(http.MethodPost, base+"floor", driver))
	assert.Equal(t, http.StatusNoContent, call(http.MethodDelete, base+"floor", passenger))
	assert.Equal(t, http.StatusOK, call(http.MethodPost, base+"floor", driver))

	f.act(t, f.passenger, tripID, (*trips.Trip).Cancel)
	assert.Equal(t, http.StatusGone, call(http.MethodPost, base+"token", passenger))
	assert.Equal(t, http.StatusGone, call(http.MethodPost, base+"floor", passenger))
}
