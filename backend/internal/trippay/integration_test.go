package trippay

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/http/httptest"
	"strings"
	"sync"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/kyq/backend/internal/billing"
	"github.com/kyq/backend/internal/fares"
	"github.com/kyq/backend/internal/notify"
	"github.com/kyq/backend/internal/realtime"
	"github.com/kyq/backend/internal/store"
	"github.com/kyq/backend/internal/testdb"
	"github.com/kyq/backend/internal/trips"
)

// fakeBold is the Bold "API Link de pagos" as verified against the sandbox (research 002 R1),
// served by httptest so the real billing.BoldClient is exercised.
type fakeBold struct {
	mu      sync.Mutex
	server  *httptest.Server
	links   map[string]map[string]any
	created []map[string]any
}

func newFakeBold(t *testing.T) *fakeBold {
	f := &fakeBold{links: map[string]map[string]any{}}
	f.server = httptest.NewServer(http.HandlerFunc(f.serve))
	t.Cleanup(f.server.Close)
	return f
}

func (f *fakeBold) serve(w http.ResponseWriter, r *http.Request) {
	f.mu.Lock()
	defer f.mu.Unlock()
	if r.Header.Get("Authorization") != "x-api-key test-identity" {
		w.WriteHeader(http.StatusForbidden)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	switch {
	case r.Method == http.MethodPost && r.URL.Path == "/online/link/v1":
		var body map[string]any
		_ = json.NewDecoder(r.Body).Decode(&body)
		f.created = append(f.created, body)
		id := fmt.Sprintf("LNK_TRIP%d", len(f.created))
		amount := body["amount"].(map[string]any)
		f.links[id] = map[string]any{
			"id": id, "status": billing.LinkActive, "total": amount["total_amount"], "currency": amount["currency"],
			"reference": body["reference"], "payment_method": nil, "transaction_id": nil,
		}
		_ = json.NewEncoder(w).Encode(map[string]any{
			"payload": map[string]any{"payment_link": id, "url": "https://checkout.bold.co/payment/" + id}, "errors": []any{},
		})
	case r.Method == http.MethodGet && strings.HasPrefix(r.URL.Path, "/online/link/v1/"):
		link, ok := f.links[strings.TrimPrefix(r.URL.Path, "/online/link/v1/")]
		if !ok {
			w.WriteHeader(http.StatusNotFound)
			_, _ = io.WriteString(w, `{"payload": {}, "errors": [{"errors": "Link not found", "code": "PL_000"}]}`)
			return
		}
		_ = json.NewEncoder(w).Encode(link)
	default:
		w.WriteHeader(http.StatusNotFound)
	}
}

func (f *fakeBold) set(id string, fields map[string]any) {
	f.mu.Lock()
	defer f.mu.Unlock()
	for k, v := range fields {
		f.links[id][k] = v
	}
}

func (f *fakeBold) count() int {
	f.mu.Lock()
	defer f.mu.Unlock()
	return len(f.created)
}

type recorder struct {
	mu   sync.Mutex
	msgs []string
}

func (r *recorder) Publish(_ context.Context, channel string, ev realtime.Event) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.msgs = append(r.msgs, channel+" "+ev.Type)
	return nil
}

func (r *recorder) count(channel, typ string) int {
	r.mu.Lock()
	defer r.mu.Unlock()
	n := 0
	for _, m := range r.msgs {
		if m == channel+" "+typ {
			n++
		}
	}
	return n
}

type fixedRoute struct{}

func (fixedRoute) Route(context.Context, float64, float64, float64, float64) (fares.Route, error) {
	return fares.Route{DistanceM: 5200, DurationS: 900}, nil
}

// fare is the suggested fare of fixedRoute with the Bogotá table: 14 700 COP.
const fare = 1_470_000

type fixture struct {
	st        *store.Store
	svc       *Service
	trips     *trips.Service
	billing   *billing.Service
	bold      *fakeBold
	pub       *recorder
	clock     *time.Time
	admin     uuid.UUID
	driver    uuid.UUID
	passenger uuid.UUID
}

func setup(t *testing.T) *fixture {
	st := testdb.New(t)
	ctx := context.Background()
	now := time.Date(2026, 10, 27, 12, 0, 0, 0, time.UTC)
	f := &fixture{st: st, bold: newFakeBold(t), pub: &recorder{}, clock: &now, admin: uuid.New(), driver: uuid.New(), passenger: uuid.New()}
	for _, u := range []store.CreateUserParams{
		{ID: f.admin, PhoneE164: "+573000000001", Role: store.UserRoleAdmin, DisplayName: "Admin"},
		{ID: f.driver, PhoneE164: "+573100000001", Role: store.UserRoleDriver, DisplayName: "Carlos"},
		{ID: f.passenger, PhoneE164: "+573200000002", Role: store.UserRolePassenger, DisplayName: "Ana"},
	} {
		_, err := st.CreateUser(ctx, u)
		require.NoError(t, err)
	}
	require.NoError(t, st.CreateDriver(ctx, store.CreateDriverParams{UserID: f.driver, QrToken: "qr-carlos-0000000", VehiclePlate: "KYQ001", VehicleDescription: "Kia"}))
	require.NoError(t, st.InsertAffiliation(ctx, store.InsertAffiliationParams{PassengerID: f.passenger, DriverID: f.driver}))
	require.NoError(t, st.UpsertFareTable(ctx, store.UpsertFareTableParams{
		CityCode: "bogota", Currency: "COP", BaseMinor: 400_000, PerKmMinor: 120_000, PerMinuteMinor: 30_000,
		MinimumMinor: 700_000, RoundingMinor: 10_000, UpdatedBy: f.admin,
	}))
	clock := func() time.Time { return *f.clock }
	client := &billing.BoldClient{BaseURL: f.bold.server.URL, IdentityKey: "test-identity"}
	notices := &notify.Service{Store: st, Publisher: f.pub, Now: clock}
	f.svc = &Service{Store: st, Bold: client, Notify: notices, Publisher: f.pub, Now: clock}
	f.trips = &trips.Service{Store: st, Routes: fixedRoute{}, Publisher: f.pub, CityCode: "bogota", Now: clock, Payments: f.svc}
	f.billing = &billing.Service{Store: st, Bold: client, Notify: notices, CityCode: "bogota", Now: clock, References: []billing.ReferenceHandler{f.svc}}
	return f
}

func (f *fixture) advance(d time.Duration) { *f.clock = f.clock.Add(d) }

// completeTrip runs a whole trip at the suggested fare and returns its id.
func (f *fixture) completeTrip(t *testing.T) uuid.UUID {
	ctx := context.Background()
	require.NoError(t, f.st.SetDriverPresence(ctx, store.SetDriverPresenceParams{UserID: f.driver, Presence: store.DriverPresenceFree}))
	trip, err := f.trips.Request(ctx, f.passenger, f.driver, trips.Point{Lat: 4.60, Lng: -74.08}, trips.Point{Lat: 4.65, Lng: -74.05})
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

func (f *fixture) row(t *testing.T, tripID uuid.UUID) store.TripPayment {
	r, err := f.st.GetTripPaymentByTrip(context.Background(), tripID)
	require.NoError(t, err)
	return r.TripPayment
}

func (f *fixture) noticeKinds(t *testing.T) []string {
	rows, err := f.st.ListNotices(context.Background(), f.driver)
	require.NoError(t, err)
	out := make([]string, len(rows))
	for i, n := range rows {
		out[i] = n.Kind
	}
	return out
}

func (f *fixture) settlement(t *testing.T) DriverSettlement {
	s, err := f.svc.Settlement(context.Background(), f.driver)
	require.NoError(t, err)
	return s
}

func (f *fixture) webhook(t *testing.T, typ string, ref uuid.UUID, totalPesos float64, paymentID string) {
	raw, err := json.Marshal(map[string]any{
		"id": uuid.NewString(), "type": typ,
		"data": map[string]any{
			"payment_id": paymentID, "payment_method": "PSE",
			"amount":   map[string]any{"total": totalPesos, "currency": "COP"},
			"metadata": map[string]any{"reference": ref.String()},
		},
	})
	require.NoError(t, err)
	require.NoError(t, f.billing.HandleWebhook(context.Background(), raw, billing.Sign("", raw)))
}

// US1, FR-001, FR-004, FR-005, FR-008: el pago se abre al completar; el pasajero reporta efectivo
// y el conductor lo confirma; cada parte solo hace lo suyo; el efectivo no pasa por el libro.
func TestIntegrationCashReportedAndConfirmed(t *testing.T) {
	f := setup(t)
	ctx := context.Background()
	tripID := f.completeTrip(t)

	v, err := f.svc.Get(ctx, f.passenger, tripID)
	require.NoError(t, err)
	assert.Equal(t, "pending", v.Status)
	assert.Equal(t, int64(fare), v.AmountMinor, "la tarifa acordada")
	assert.Equal(t, int64(fare), v.DriverAmountMinor, "RN-KYQ-001: 100 % para el conductor")
	assert.Zero(t, v.PlatformCommissionMinor, "RN-KYQ-001: comisión 0")
	assert.Equal(t, []string{"bold", "cash"}, v.AcceptedMethods)
	assert.Equal(t, "Carlos", v.DriverName)
	assert.Equal(t, "Ana", v.PassengerName)

	_, err = f.svc.Get(ctx, uuid.New(), tripID)
	assert.ErrorIs(t, err, ErrNotFound, "terceros no ven el pago")
	_, err = f.svc.Act(ctx, f.driver, tripID, ReportCash)
	assert.ErrorIs(t, err, ErrForbidden)

	f.advance(time.Minute)
	v, err = f.svc.Act(ctx, f.passenger, tripID, ReportCash)
	require.NoError(t, err)
	assert.Equal(t, "cash_reported", v.Status)
	require.NotNil(t, v.CashReportedAt)
	assert.Equal(t, *f.clock, v.CashReportedAt.UTC())
	assert.Contains(t, f.noticeKinds(t), "trip_cash_reported")
	assert.Equal(t, 1, f.pub.count("user:"+f.driver.String(), "trip_payment.updated"))
	assert.Equal(t, 1, f.pub.count("user:"+f.passenger.String(), "trip_payment.updated"))

	_, err = f.svc.Act(ctx, f.passenger, tripID, ConfirmCash)
	assert.ErrorIs(t, err, ErrForbidden)
	v, err = f.svc.Act(ctx, f.driver, tripID, ConfirmCash)
	require.NoError(t, err)
	assert.Equal(t, "paid", v.Status)
	assert.Equal(t, "cash", *v.Method)
	assert.NotNil(t, v.CashConfirmedAt)
	assert.NotNil(t, v.CashReportedAt, "ambos reportes quedan registrados")
	_, err = f.svc.Act(ctx, f.driver, tripID, ConfirmCash)
	assert.ErrorIs(t, err, ErrInvalidState)
	assert.Empty(t, f.settlement(t).Entries, "el efectivo no pasa por el libro")
}

// US1-4, FR-017: el conductor disputa un reporte; el panel lo ve y lo resuelve con nota.
func TestIntegrationCashDisputeResolvedByAdmin(t *testing.T) {
	f := setup(t)
	ctx := context.Background()
	tripID := f.completeTrip(t)

	_, err := f.svc.Act(ctx, f.driver, tripID, DisputeCash)
	assert.ErrorIs(t, err, ErrInvalidState, "sin reporte no hay nada que disputar")
	_, err = f.svc.Act(ctx, f.passenger, tripID, ReportCash)
	require.NoError(t, err)
	v, err := f.svc.Act(ctx, f.driver, tripID, DisputeCash)
	require.NoError(t, err)
	assert.Equal(t, "disputed", v.Status)
	assert.NotNil(t, v.DisputedAt)

	issues, err := f.svc.AdminList(ctx, StatusIssues)
	require.NoError(t, err)
	require.Len(t, issues, 1)
	assert.Equal(t, v.ID, issues[0].ID)
	paid, err := f.svc.AdminList(ctx, "paid")
	require.NoError(t, err)
	assert.Empty(t, paid)

	_, err = f.svc.Resolve(ctx, f.admin, v.ID, ResolvePaid, " ")
	assert.ErrorIs(t, err, ErrNoteRequired)
	_, err = f.svc.Resolve(ctx, f.admin, v.ID, "maybe", "nota")
	assert.ErrorIs(t, err, ErrInvalidOutcome)
	a, err := f.svc.Resolve(ctx, f.admin, v.ID, ResolvePaid, "El conductor encontró el billete")
	require.NoError(t, err)
	assert.Equal(t, "paid", a.Status)
	assert.Equal(t, f.admin, *a.ResolvedBy)
	assert.Equal(t, "El conductor encontró el billete", *a.ResolutionNote)
	_, err = f.svc.Resolve(ctx, f.admin, v.ID, ResolveUnpaid, "otra")
	assert.ErrorIs(t, err, ErrInvalidState)
	_, err = f.svc.Resolve(ctx, f.admin, uuid.New(), ResolvePaid, "nota")
	assert.ErrorIs(t, err, ErrNotFound)
}

// US4, FR-018: medios aceptados (al menos uno), copiados al completar; el conductor puede
// confirmar efectivo sin reporte.
func TestIntegrationAcceptedMethods(t *testing.T) {
	f := setup(t)
	ctx := context.Background()

	m, err := f.svc.Methods(ctx, f.driver)
	require.NoError(t, err)
	assert.Equal(t, PaymentMethods{AcceptsCash: true, AcceptsBold: true, BoldAvailable: true}, m, "por defecto ambos")
	_, err = f.svc.SetMethods(ctx, f.driver, false, false)
	assert.ErrorIs(t, err, ErrNoMethod)
	_, err = f.svc.SetMethods(ctx, f.driver, false, true)
	require.NoError(t, err)

	onlyBold := f.completeTrip(t)
	_, err = f.svc.SetMethods(ctx, f.driver, true, true)
	require.NoError(t, err)
	v, err := f.svc.Get(ctx, f.passenger, onlyBold)
	require.NoError(t, err)
	assert.Equal(t, []string{"bold"}, v.AcceptedMethods, "el viaje conserva los medios que tenía al completarse")
	_, err = f.svc.Act(ctx, f.passenger, onlyBold, ReportCash)
	assert.ErrorIs(t, err, ErrMethodNotAccepted)
	v, err = f.svc.Act(ctx, f.driver, onlyBold, ConfirmCash)
	require.NoError(t, err)
	assert.Equal(t, "paid", v.Status, "US1-5: el conductor confirma sin esperar el reporte")

	noBold := &Service{Store: f.st, Notify: f.svc.Notify}
	v, err = noBold.Get(ctx, f.passenger, onlyBold)
	require.NoError(t, err)
	assert.Empty(t, v.AcceptedMethods, "sin Bold en Kyq y sin efectivo del conductor no hay medio que ofrecer")
}

// US2, FR-003, FR-009, FR-011, SC-003, RN-KYQ-001: Bold por la tarifa exacta; sondeo, refresco
// y webhook repetidos abonan el 100 % una sola vez.
func TestIntegrationBoldPaymentCreditsDriverOnce(t *testing.T) {
	f := setup(t)
	ctx := context.Background()
	tripID := f.completeTrip(t)

	_, err := f.svc.PayWithBold(ctx, f.driver, tripID)
	assert.ErrorIs(t, err, ErrForbidden)
	v, err := f.svc.PayWithBold(ctx, f.passenger, tripID)
	require.NoError(t, err)
	assert.Equal(t, "bold_in_progress", v.Status)
	require.NotNil(t, v.CheckoutURL)
	assert.Equal(t, "https://checkout.bold.co/payment/LNK_TRIP1", *v.CheckoutURL)
	sent := f.bold.created[0]
	assert.Equal(t, v.ID.String(), sent["reference"], "la referencia es el id del pago del viaje")
	assert.Equal(t, map[string]any{"currency": "COP", "total_amount": float64(14_700)}, sent["amount"], "valor fijado por el servidor")
	assert.Equal(t, float64(f.clock.Add(billing.LinkTTL).UnixNano()), sent["expiration_date"])

	again, err := f.svc.PayWithBold(ctx, f.passenger, tripID)
	require.NoError(t, err)
	assert.Equal(t, *v.CheckoutURL, *again.CheckoutURL, "el enlace vigente se reutiliza")
	assert.Equal(t, 1, f.bold.count())
	_, err = f.svc.Act(ctx, f.driver, tripID, MarkUnpaid)
	assert.ErrorIs(t, err, ErrBoldInProgress)

	f.bold.set("LNK_TRIP1", map[string]any{"status": billing.LinkProcessing, "payment_method": "PSE"})
	n, err := f.svc.PollPayments(ctx)
	require.NoError(t, err)
	assert.Equal(t, 1, n)
	_, err = f.svc.Act(ctx, f.passenger, tripID, ReportCash)
	assert.ErrorIs(t, err, ErrBoldInProgress, "US2-6: PSE en proceso")

	f.advance(40 * time.Second)
	f.bold.set("LNK_TRIP1", map[string]any{"status": billing.LinkPaid, "transaction_id": "TX-1"})
	v, err = f.svc.Refresh(ctx, f.passenger, tripID)
	require.NoError(t, err)
	assert.Equal(t, "paid", v.Status)
	assert.Equal(t, "bold", *v.Method)
	assert.Equal(t, "PSE", *v.PaymentMethodDetail)
	assert.Nil(t, v.CheckoutURL)
	assert.Contains(t, f.noticeKinds(t), "trip_payment_paid")

	f.webhook(t, billing.EventSaleApproved, v.ID, 14_700, "TX-1")
	f.webhook(t, billing.EventSaleApproved, v.ID, 14_700, "TX-1")
	_, err = f.svc.PollPayments(ctx)
	require.NoError(t, err)

	s := f.settlement(t)
	require.Len(t, s.Entries, 1, "un solo abono")
	assert.Equal(t, "trip_credit", s.Entries[0].Kind)
	assert.Equal(t, int64(fare), s.Entries[0].AmountMinor, "RN-KYQ-001: se abona el 100 %")
	assert.Equal(t, []Balance{{Currency: "COP", CreditedMinor: fare, BalanceMinor: fare}}, s.Balances)
	assert.Equal(t, tripID, *s.Entries[0].TripID)
	assert.Empty(t, f.row(t, tripID).ReviewNote.String)
}

// US2-4, edge cases: rechazo y caducidad devuelven a pendiente; con un enlace sin pagar el pasajero
// puede pasar a efectivo; si Bold aprueba después, gana Bold y se abona.
func TestIntegrationBoldRejectedThenLateApprovalWins(t *testing.T) {
	f := setup(t)
	ctx := context.Background()
	tripID := f.completeTrip(t)

	_, err := f.svc.PayWithBold(ctx, f.passenger, tripID)
	require.NoError(t, err)
	f.bold.set("LNK_TRIP1", map[string]any{"status": billing.LinkRejected})
	v, err := f.svc.Refresh(ctx, f.passenger, tripID)
	require.NoError(t, err)
	assert.Equal(t, "pending", v.Status)
	assert.Nil(t, v.Method)

	v, err = f.svc.PayWithBold(ctx, f.passenger, tripID)
	require.NoError(t, err)
	assert.Equal(t, "https://checkout.bold.co/payment/LNK_TRIP2", *v.CheckoutURL, "nuevo intento, nuevo enlace")

	v, err = f.svc.Act(ctx, f.passenger, tripID, ReportCash)
	require.NoError(t, err)
	assert.Equal(t, "cash_reported", v.Status, "el enlace seguía sin pagar: pasa a efectivo")
	assert.Nil(t, v.CheckoutURL)

	f.webhook(t, billing.EventSaleApproved, v.ID, 14_700, "TX-LATE")
	v, err = f.svc.Get(ctx, f.driver, tripID)
	require.NoError(t, err)
	assert.Equal(t, "paid", v.Status)
	assert.Equal(t, "bold", *v.Method, "Bold es dinero verificable: gana al reporte de efectivo")
	assert.NotNil(t, v.CashReportedAt)
	assert.Len(t, f.settlement(t).Entries, 1)

	// Caducidad: un enlace que nadie paga se cierra con el sondeo pasado el plazo.
	other := f.completeTrip(t)
	_, err = f.svc.PayWithBold(ctx, f.passenger, other)
	require.NoError(t, err)
	f.advance(billing.LinkTTL + 3*time.Minute)
	_, err = f.svc.PollPayments(ctx)
	require.NoError(t, err)
	assert.Equal(t, statusPending, f.row(t, other).Status)
}

// FR-010, edge cases: valor distinto → en revisión sin abono; segundo cobro de un viaje pagado →
// nota para reembolsar, sin abono.
func TestIntegrationBoldMismatchAndSecondCharge(t *testing.T) {
	f := setup(t)
	ctx := context.Background()
	tripID := f.completeTrip(t)
	_, err := f.svc.PayWithBold(ctx, f.passenger, tripID)
	require.NoError(t, err)
	id := f.row(t, tripID).ID

	f.webhook(t, billing.EventSaleApproved, id, 1_000, "TX-SMALL")
	p := f.row(t, tripID)
	assert.Equal(t, statusNeedsReview, p.Status)
	assert.Contains(t, p.ReviewNote.String, "se esperaba $ 14.700 COP")
	assert.Empty(t, f.settlement(t).Entries)
	issues, err := f.svc.AdminList(ctx, StatusIssues)
	require.NoError(t, err)
	assert.Len(t, issues, 1)
	a, err := f.svc.Void(ctx, f.admin, id, "Reembolsado en Bold")
	require.NoError(t, err)
	assert.Equal(t, "voided", a.Status)
	assert.Empty(t, f.settlement(t).Entries, "no hubo abono que debitar")

	cash := f.completeTrip(t)
	_, err = f.svc.Act(ctx, f.driver, cash, ConfirmCash)
	require.NoError(t, err)
	f.webhook(t, billing.EventSaleApproved, f.row(t, cash).ID, 14_700, "TX-DOUBLE")
	p = f.row(t, cash)
	assert.Equal(t, statusPaid, p.Status)
	assert.Equal(t, store.TripPaymentMethodCash, p.Method.TripPaymentMethod)
	assert.Contains(t, p.ReviewNote.String, "reembolsar en Bold")
	assert.Empty(t, f.settlement(t).Entries, "un viaje se abona una vez como máximo")
}

// US5-5, FR-014: anular un pago con Bold (admin o Bold) debita el abono una vez.
func TestIntegrationVoidDebitsCredit(t *testing.T) {
	f := setup(t)
	ctx := context.Background()
	pay := func() uuid.UUID {
		tripID := f.completeTrip(t)
		_, err := f.svc.PayWithBold(ctx, f.passenger, tripID)
		require.NoError(t, err)
		id := f.row(t, tripID).ID
		f.webhook(t, billing.EventSaleApproved, id, 14_700, "TX-"+id.String()[:8])
		return id
	}

	byAdmin := pay()
	_, err := f.svc.Void(ctx, f.admin, byAdmin, "")
	assert.ErrorIs(t, err, ErrReasonRequired)
	a, err := f.svc.Void(ctx, f.admin, byAdmin, "Reembolsado al pasajero")
	require.NoError(t, err)
	assert.Equal(t, "voided", a.Status)
	assert.Equal(t, f.admin, *a.VoidedBy)
	_, err = f.svc.Void(ctx, f.admin, byAdmin, "otra vez")
	assert.ErrorIs(t, err, ErrInvalidState)

	byBold := pay()
	f.webhook(t, billing.EventVoidApproved, byBold, 14_700, "")
	f.webhook(t, billing.EventVoidApproved, byBold, 14_700, "")
	p, err := f.st.GetTripPayment(ctx, byBold)
	require.NoError(t, err)
	assert.Equal(t, statusVoided, p.Status)
	assert.Equal(t, "anulado en Bold", p.VoidReason.String)

	s := f.settlement(t)
	assert.Len(t, s.Entries, 4, "dos abonos y dos débitos")
	assert.Equal(t, []Balance{{Currency: "COP", CreditedMinor: 2 * fare, DebitedMinor: 2 * fare}}, s.Balances)
	assert.Contains(t, f.noticeKinds(t), "trip_payment_voided")

	cash := f.completeTrip(t)
	_, err = f.svc.Act(ctx, f.driver, cash, ConfirmCash)
	require.NoError(t, err)
	_, err = f.svc.Void(ctx, f.admin, f.row(t, cash).ID, "x")
	assert.ErrorIs(t, err, ErrInvalidState, "el efectivo no se anula")
}

// US3, FR-006, FR-015, FR-016: recordatorio único a los 10 min; "no me pagó"; el pasajero aún
// puede pagar y el caso se cierra.
func TestIntegrationReminderAndUnpaid(t *testing.T) {
	f := setup(t)
	ctx := context.Background()
	tripID := f.completeTrip(t)
	passengerCh := "user:" + f.passenger.String()

	pending, err := f.svc.PendingForPassenger(ctx, f.passenger)
	require.NoError(t, err)
	require.Len(t, pending, 1)
	assert.Equal(t, tripID, pending[0].TripID)

	f.advance(9 * time.Minute)
	n, err := f.svc.SendReminders(ctx)
	require.NoError(t, err)
	assert.Zero(t, n)
	f.advance(time.Minute)
	n, err = f.svc.SendReminders(ctx)
	require.NoError(t, err)
	assert.Equal(t, 1, n)
	n, err = f.svc.SendReminders(ctx)
	require.NoError(t, err)
	assert.Zero(t, n, "una sola vez")
	assert.Equal(t, 1, f.pub.count(passengerCh, "trip_payment.reminder"))
	assert.Contains(t, f.noticeKinds(t), "trip_payment_pending")
	assert.True(t, f.row(t, tripID).RemindedAt.Valid)

	_, err = f.svc.Act(ctx, f.passenger, tripID, MarkUnpaid)
	assert.ErrorIs(t, err, ErrForbidden)
	v, err := f.svc.Act(ctx, f.driver, tripID, MarkUnpaid)
	require.NoError(t, err)
	assert.Equal(t, "unpaid", v.Status)
	issues, err := f.svc.AdminList(ctx, StatusIssues)
	require.NoError(t, err)
	assert.Len(t, issues, 1)

	_, err = f.svc.PayWithBold(ctx, f.passenger, tripID)
	require.NoError(t, err)
	f.advance(billing.LinkTTL + 3*time.Minute)
	_, err = f.svc.PollPayments(ctx)
	require.NoError(t, err)
	assert.Equal(t, statusUnpaid, f.row(t, tripID).Status, "el enlace caducado vuelve a no pagado")

	_, err = f.svc.PayWithBold(ctx, f.passenger, tripID)
	require.NoError(t, err)
	f.bold.set("LNK_TRIP2", map[string]any{"status": billing.LinkPaid, "payment_method": "NEQUI", "transaction_id": "TX-2"})
	v, err = f.svc.Refresh(ctx, f.passenger, tripID)
	require.NoError(t, err)
	assert.Equal(t, "paid", v.Status)
	assert.NotNil(t, v.UnpaidMarkedAt, "el no pagado queda registrado")
	pending, err = f.svc.PendingForPassenger(ctx, f.passenger)
	require.NoError(t, err)
	assert.Empty(t, pending)
	issues, err = f.svc.AdminList(ctx, StatusIssues)
	require.NoError(t, err)
	assert.Empty(t, issues, "sale de las incidencias")
}

// Viajes de 001 sin gancho de pago: el viaje se completa como antes y no tiene pago.
func TestIntegrationTripWithoutOpenerHasNoPayment(t *testing.T) {
	f := setup(t)
	f.trips.Payments = nil
	tripID := f.completeTrip(t)
	_, err := f.svc.Get(context.Background(), f.passenger, tripID)
	assert.ErrorIs(t, err, ErrNotFound)
}
