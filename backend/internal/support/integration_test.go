package support

import (
	"context"
	"sync"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/kyq/backend/internal/fares"
	"github.com/kyq/backend/internal/notify"
	"github.com/kyq/backend/internal/realtime"
	"github.com/kyq/backend/internal/store"
	"github.com/kyq/backend/internal/testdb"
	"github.com/kyq/backend/internal/trippay"
	"github.com/kyq/backend/internal/trips"
)

type recorder struct {
	mu   sync.Mutex
	sent []string
}

func (r *recorder) Publish(_ context.Context, channel string, ev realtime.Event) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.sent = append(r.sent, channel+" "+ev.Type)
	return nil
}

func (r *recorder) count(entry string) int {
	r.mu.Lock()
	defer r.mu.Unlock()
	n := 0
	for _, s := range r.sent {
		if s == entry {
			n++
		}
	}
	return n
}

type fixedRoute struct{}

func (fixedRoute) Route(context.Context, float64, float64, float64, float64) (fares.Route, error) {
	return fares.Route{DistanceM: 5200, DurationS: 900}, nil
}

type fixture struct {
	st                      *store.Store
	svc                     *Service
	pay                     *trippay.Service
	trips                   *trips.Service
	pub                     *recorder
	clock                   *time.Time
	admin, driver, ana, luz uuid.UUID
}

func setup(t *testing.T) *fixture {
	st := testdb.New(t)
	ctx := context.Background()
	now := time.Date(2026, 10, 28, 12, 0, 0, 0, time.UTC)
	f := &fixture{st: st, pub: &recorder{}, clock: &now, admin: uuid.New(), driver: uuid.New(), ana: uuid.New(), luz: uuid.New()}
	for _, u := range []store.CreateUserParams{
		{ID: f.admin, PhoneE164: "+573000000001", Role: store.UserRoleAdmin, DisplayName: "Admin"},
		{ID: f.driver, PhoneE164: "+573100000001", Role: store.UserRoleDriver, DisplayName: "Carlos"},
		{ID: f.ana, PhoneE164: "+573200000002", Role: store.UserRolePassenger, DisplayName: "Ana"},
		{ID: f.luz, PhoneE164: "+573200000003", Role: store.UserRolePassenger, DisplayName: "Luz"},
	} {
		_, err := st.CreateUser(ctx, u)
		require.NoError(t, err)
	}
	require.NoError(t, st.CreateDriver(ctx, store.CreateDriverParams{UserID: f.driver, QrToken: "qr-carlos-0000000", VehiclePlate: "KYQ001", VehicleDescription: "Kia"}))
	require.NoError(t, st.InsertAffiliation(ctx, store.InsertAffiliationParams{PassengerID: f.ana, DriverID: f.driver}))
	require.NoError(t, st.UpsertFareTable(ctx, store.UpsertFareTableParams{
		CityCode: "bogota", Currency: "COP", BaseMinor: 400_000, PerKmMinor: 120_000, PerMinuteMinor: 30_000,
		MinimumMinor: 700_000, RoundingMinor: 10_000, UpdatedBy: f.admin,
	}))
	clock := func() time.Time { return *f.clock }
	f.pay = &trippay.Service{Store: st, Notify: &notify.Service{Store: st, Publisher: f.pub, Now: clock}, Publisher: f.pub, Now: clock}
	f.svc = &Service{Store: st, Publisher: f.pub, Payments: f.pay, Now: clock}
	f.pay.Cases = f.svc
	f.trips = &trips.Service{Store: st, Routes: fixedRoute{}, Publisher: f.pub, CityCode: "bogota", Now: clock, Payments: f.pay}
	return f
}

func (f *fixture) advance(d time.Duration) { *f.clock = f.clock.Add(d) }

func (f *fixture) completeTrip(t *testing.T) uuid.UUID {
	ctx := context.Background()
	require.NoError(t, f.st.SetDriverPresence(ctx, store.SetDriverPresenceParams{UserID: f.driver, Presence: store.DriverPresenceFree}))
	trip, err := f.trips.Request(ctx, f.ana, f.driver, trips.Point{Lat: 4.60, Lng: -74.08}, trips.Point{Lat: 4.65, Lng: -74.05})
	require.NoError(t, err)
	for _, step := range []func(*trips.Trip, trips.Party, time.Time) error{
		func(t *trips.Trip, p trips.Party, now time.Time) error { return t.Accept(p, nil, now) },
		(*trips.Trip).Arrive, (*trips.Trip).Start, (*trips.Trip).Complete,
	} {
		_, err := f.trips.Act(ctx, f.driver, trip.ID, step)
		require.NoError(t, err)
	}
	return trip.ID
}

// US2: abrir, conversar con notas internas, estados, bandeja y cierre automático.
func TestIntegrationSupportCaseLifecycle(t *testing.T) {
	f := setup(t)
	ctx := context.Background()
	tripID := f.completeTrip(t)

	_, err := f.svc.Open(ctx, f.ana, "x", "Dejé mi sombrilla en el carro", nil)
	assert.ErrorIs(t, err, ErrInvalidTopic)
	_, err = f.svc.Open(ctx, f.ana, TopicLostItem, "corto", nil)
	assert.ErrorIs(t, err, ErrInvalidText, "FR-005: al menos 10 caracteres")
	_, err = f.svc.Open(ctx, f.luz, TopicTrip, "No es mi viaje pero lo intento", &tripID)
	assert.ErrorIs(t, err, ErrInvalidTrip, "el viaje no es suyo")

	c, err := f.svc.Open(ctx, f.ana, TopicLostItem, "Dejé mi sombrilla roja en el asiento de atrás", &tripID)
	require.NoError(t, err)
	assert.Equal(t, StatusOpen, c.Status)
	assert.Equal(t, "Ana", c.User.DisplayName)
	assert.Equal(t, "passenger", c.UserRole)
	assert.Equal(t, tripID, *c.TripID)
	assert.True(t, c.AwaitingReply)
	require.Len(t, c.Messages, 1)
	assert.True(t, c.Messages[0].Mine)
	assert.Equal(t, 1, f.pub.count("admin:support support.case"))

	trips, err := f.svc.RecentTrips(ctx, f.driver)
	require.NoError(t, err)
	require.Len(t, trips, 1)
	assert.Equal(t, "Ana", trips[0].OtherParty)

	_, err = f.svc.UserCase(ctx, f.luz, c.ID)
	assert.ErrorIs(t, err, ErrNotFound, "FR-011: solo sus casos")
	mine, err := f.svc.UserCases(ctx, f.luz)
	require.NoError(t, err)
	assert.Empty(t, mine)

	inbox, err := f.svc.Inbox(ctx, Filter{Unanswered: true})
	require.NoError(t, err)
	require.Len(t, inbox, 1)

	// Nota interna: no la ve el usuario y el caso sigue sin respuesta (FR-006).
	f.advance(time.Minute)
	_, err = f.svc.AdminReply(ctx, f.admin, c.ID, "Revisar con el conductor", true)
	require.NoError(t, err)
	inbox, err = f.svc.Inbox(ctx, Filter{Unanswered: true})
	require.NoError(t, err)
	assert.Len(t, inbox, 1)
	d, err := f.svc.AdminReply(ctx, f.admin, c.ID, "Ya hablamos con Carlos: la tiene guardada.", false)
	require.NoError(t, err)
	assert.Equal(t, StatusInProgress, d.Status)
	require.NotNil(t, d.AssignedTo)
	assert.Equal(t, f.admin, d.AssignedTo.ID)
	assert.Len(t, d.Messages, 3)
	u, err := f.svc.UserCase(ctx, f.ana, c.ID)
	require.NoError(t, err)
	assert.Len(t, u.Messages, 2, "FR-006: sin la nota interna")
	assert.False(t, u.AwaitingReply)
	inbox, err = f.svc.Inbox(ctx, Filter{Unanswered: true})
	require.NoError(t, err)
	assert.Empty(t, inbox)
	mineAdmin, err := f.svc.Inbox(ctx, Filter{AssignedTo: f.admin})
	require.NoError(t, err)
	assert.Len(t, mineAdmin, 1)

	// Responder un caso resuelto lo reabre; uno cerrado no admite mensajes (FR-007).
	_, err = f.svc.SetStatus(ctx, f.admin, c.ID, StatusResolved)
	require.NoError(t, err)
	u, err = f.svc.UserReply(ctx, f.ana, c.ID, "¿Dónde la recojo?")
	require.NoError(t, err)
	assert.Equal(t, StatusOpen, u.Status)
	assert.Nil(t, u.ResolvedAt)
	_, err = f.svc.SetStatus(ctx, f.admin, c.ID, "x")
	assert.ErrorIs(t, err, ErrInvalidStatus)
	_, err = f.svc.SetStatus(ctx, f.admin, c.ID, StatusClosed)
	require.NoError(t, err)
	_, err = f.svc.UserReply(ctx, f.ana, c.ID, "Hola otra vez")
	assert.ErrorIs(t, err, ErrCaseClosed)
	_, err = f.svc.SetStatus(ctx, f.admin, c.ID, StatusOpen)
	assert.ErrorIs(t, err, ErrCaseClosed)
	inbox, err = f.svc.Inbox(ctx, Filter{})
	require.NoError(t, err)
	assert.Empty(t, inbox, "los cerrados no están en la bandeja por defecto")
	inbox, err = f.svc.Inbox(ctx, Filter{Status: StatusClosed})
	require.NoError(t, err)
	assert.Len(t, inbox, 1)

	_, err = f.svc.Assign(ctx, f.admin, c.ID, f.ana)
	assert.ErrorIs(t, err, ErrInvalidAssignee)

	// FR-012: resuelto sin respuesta en 7 días se cierra.
	other, err := f.svc.Open(ctx, f.luz, TopicAccount, "No puedo cambiar mi nombre en la app", nil)
	require.NoError(t, err)
	_, err = f.svc.SetStatus(ctx, f.admin, other.ID, StatusResolved)
	require.NoError(t, err)
	f.advance(6 * 24 * time.Hour)
	n, err := f.svc.CloseStale(ctx)
	require.NoError(t, err)
	assert.Zero(t, n)
	f.advance(2 * 24 * time.Hour)
	n, err = f.svc.CloseStale(ctx)
	require.NoError(t, err)
	assert.Equal(t, 1, n)
	u, err = f.svc.UserCase(ctx, f.luz, other.ID)
	require.NoError(t, err)
	assert.Equal(t, StatusClosed, u.Status)

	_, err = f.svc.ResolvePayment(ctx, f.admin, other.ID, OutcomePaid, "nota")
	assert.ErrorIs(t, err, ErrNotPaymentCase)

	// Un viaje de hace más de 30 días ya no se asocia.
	f.advance(23 * 24 * time.Hour)
	_, err = f.svc.Open(ctx, f.ana, TopicTrip, "Me cobraron de más en ese viaje", &tripID)
	assert.ErrorIs(t, err, ErrInvalidTrip)
}

// US2, FR-010, SC-002: la disputa de 004 abre un caso de pago para los dos y la resolución
// coincide en las dos pantallas, se resuelva desde el caso o desde 004.
func TestIntegrationPaymentDisputeCase(t *testing.T) {
	f := setup(t)
	ctx := context.Background()

	tripID := f.completeTrip(t)
	_, err := f.pay.Act(ctx, f.ana, tripID, trippay.ReportCash)
	require.NoError(t, err)
	assert.Empty(t, mustCases(t, f, f.driver), "reportar efectivo no abre caso")
	v, err := f.pay.Act(ctx, f.driver, tripID, trippay.DisputeCash)
	require.NoError(t, err)

	cases := mustCases(t, f, f.driver)
	require.Len(t, cases, 1)
	c := cases[0]
	assert.Equal(t, TopicPayment, c.Topic)
	assert.Equal(t, v.ID, *c.TripPaymentID)
	assert.Equal(t, "Carlos", c.User.DisplayName)
	assert.Equal(t, "Ana", c.Counterpart.DisplayName)
	require.Len(t, mustCases(t, f, f.ana), 1, "visible para el pasajero")
	assert.Equal(t, 1, f.pub.count("user:"+f.ana.String()+" support.case"))
	d, err := f.svc.UserCase(ctx, f.ana, c.ID)
	require.NoError(t, err)
	require.Len(t, d.Messages, 1)
	assert.Equal(t, AuthorSystem, d.Messages[0].AuthorKind)
	assert.Contains(t, d.Messages[0].Body, "no recibió")

	// El pasajero contesta en el caso y el administrador lo resuelve como pagado.
	_, err = f.svc.UserReply(ctx, f.ana, c.ID, "Le pagué con un billete de 20 000")
	require.NoError(t, err)
	_, err = f.svc.ResolvePayment(ctx, f.admin, c.ID, OutcomePaid, " ")
	assert.ErrorIs(t, err, trippay.ErrNoteRequired)
	d, err = f.svc.ResolvePayment(ctx, f.admin, c.ID, OutcomePaid, "El conductor encontró el billete")
	require.NoError(t, err)
	assert.Equal(t, StatusResolved, d.Status)
	assert.Contains(t, d.Messages[len(d.Messages)-1].Body, "pagado en efectivo")
	pv, err := f.pay.Get(ctx, f.driver, tripID)
	require.NoError(t, err)
	assert.Equal(t, "paid", pv.Status, "SC-002: misma resolución en 004")

	// "No me pagó" resuelto desde la pantalla de pagos de 004: el caso también.
	trip2 := f.completeTrip(t)
	v2, err := f.pay.Act(ctx, f.driver, trip2, trippay.MarkUnpaid)
	require.NoError(t, err)
	c2, err := f.st.GetSupportCaseByPayment(ctx, uuid.NullUUID{UUID: v2.ID, Valid: true})
	require.NoError(t, err)
	assert.Equal(t, store.SupportStatusOpen, c2.Status)
	_, err = f.pay.Resolve(ctx, f.admin, v2.ID, trippay.ResolveUnpaid, "El pasajero no respondió")
	require.NoError(t, err)
	c2, err = f.st.GetSupportCaseByPayment(ctx, uuid.NullUUID{UUID: v2.ID, Valid: true})
	require.NoError(t, err)
	assert.Equal(t, store.SupportStatusResolved, c2.Status)

	// Y si después el conductor confirma el efectivo, el caso (ya resuelto) recibe la nota.
	trip3 := f.completeTrip(t)
	v3, err := f.pay.Act(ctx, f.driver, trip3, trippay.MarkUnpaid)
	require.NoError(t, err)
	_, err = f.pay.Act(ctx, f.driver, trip3, trippay.ConfirmCash)
	require.NoError(t, err)
	c3, err := f.st.GetSupportCaseByPayment(ctx, uuid.NullUUID{UUID: v3.ID, Valid: true})
	require.NoError(t, err)
	assert.Equal(t, store.SupportStatusResolved, c3.Status, "el conductor confirmó: se resuelve")
}

func mustCases(t *testing.T, f *fixture, user uuid.UUID) []Case {
	out, err := f.svc.UserCases(context.Background(), user)
	require.NoError(t, err)
	return out
}
