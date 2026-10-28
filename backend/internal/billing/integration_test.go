package billing

import (
	"bytes"
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"sync"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/kyq/backend/internal/auth"
	"github.com/kyq/backend/internal/drivers"
	"github.com/kyq/backend/internal/notify"
	"github.com/kyq/backend/internal/realtime"
	"github.com/kyq/backend/internal/store"
	"github.com/kyq/backend/internal/testdb"
)

type clock struct {
	mu sync.Mutex
	t  time.Time
}

func (c *clock) now() time.Time {
	c.mu.Lock()
	defer c.mu.Unlock()
	return c.t
}

func (c *clock) add(d time.Duration) {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.t = c.t.Add(d)
}

type nopPublisher struct{}

func (nopPublisher) Publish(context.Context, string, realtime.Event) error { return nil }

type fixture struct {
	st    *store.Store
	svc   *Service
	bold  *fakeBold
	clock *clock
	admin uuid.UUID
}

const priceMinor = 5_000_000 // 50 000 COP

func newFixture(t *testing.T, withPrice bool) *fixture {
	st := testdb.New(t)
	ctx := context.Background()
	c := &clock{t: time.Date(2026, 10, 27, 15, 0, 0, 0, time.UTC)}
	f := &fixture{st: st, bold: newFakeBold(t), clock: c, admin: uuid.New()}
	_, err := st.CreateUser(ctx, store.CreateUserParams{ID: f.admin, PhoneE164: "+573000000000", Role: store.UserRoleAdmin, DisplayName: "Admin"})
	require.NoError(t, err)
	require.NoError(t, st.UpsertFareTable(ctx, store.UpsertFareTableParams{
		CityCode: "bogota", Currency: "COP", BaseMinor: 400_000, PerKmMinor: 120_000, PerMinuteMinor: 30_000,
		MinimumMinor: 700_000, RoundingMinor: 10_000, UpdatedBy: f.admin,
	}))
	f.svc = &Service{
		Store: st, Bold: f.bold.client(), CityCode: "bogota", Now: c.now,
		Notify: &notify.Service{Store: st, Publisher: nopPublisher{}, Now: c.now},
	}
	if withPrice {
		_, err := f.svc.SetPrice(ctx, f.admin, "bogota", NewPrice{Currency: "COP", AmountMinor: priceMinor})
		require.NoError(t, err)
	}
	return f
}

// newDriver creates a driver; with documents it has the five types approved and in force.
func (f *fixture) newDriver(t *testing.T, phone string, withDocuments bool) uuid.UUID {
	ctx := context.Background()
	id := uuid.New()
	_, err := f.st.CreateUser(ctx, store.CreateUserParams{ID: id, PhoneE164: phone, Role: store.UserRoleDriver, DisplayName: "Conductor"})
	require.NoError(t, err)
	require.NoError(t, f.st.CreateDriver(ctx, store.CreateDriverParams{UserID: id, QrToken: "qr-" + id.String(), VehiclePlate: "KYQ123", VehicleDescription: "Kia"}))
	if !withDocuments {
		return id
	}
	for _, docType := range drivers.MandatoryDocuments {
		p := store.InsertDocumentParams{
			ID: uuid.New(), DriverID: id, DocType: store.DriverDocType(docType), Number: "123", Status: store.DocumentStatusApproved,
			ReviewedBy: uuid.NullUUID{UUID: f.admin, Valid: true}, ReviewedAt: pgtype.Timestamptz{Time: f.clock.now(), Valid: true},
		}
		if drivers.DocumentExpires(docType) {
			p.ExpiresAt = pgtype.Date{Time: time.Date(2030, 1, 1, 0, 0, 0, 0, time.UTC), Valid: true}
		}
		_, err := f.st.InsertDocument(ctx, p)
		require.NoError(t, err)
	}
	return id
}

func (f *fixture) paidUntil(t *testing.T, driverID uuid.UUID) *time.Time {
	pu, err := f.st.GetSubscription(context.Background(), driverID)
	if store.IsNotFound(err) {
		return nil
	}
	require.NoError(t, err)
	return &pu
}

func (f *fixture) setPaidUntil(t *testing.T, driverID uuid.UUID, pu time.Time) {
	require.NoError(t, f.st.UpsertSubscriptionPaidUntil(context.Background(), store.UpsertSubscriptionPaidUntilParams{DriverID: driverID, PaidUntil: pu}))
}

func (f *fixture) payment(t *testing.T, id uuid.UUID) store.Payment {
	p, err := f.st.GetPayment(context.Background(), id)
	require.NoError(t, err)
	return p
}

func (f *fixture) kinds(t *testing.T, driverID uuid.UUID) []string {
	rows, err := f.st.ListNotices(context.Background(), driverID)
	require.NoError(t, err)
	out := make([]string, len(rows))
	for i, n := range rows {
		out[i] = n.Kind
	}
	return out
}

func webhookBody(t *testing.T, typ string, ref uuid.UUID, total float64, currency string) []byte {
	raw, err := json.Marshal(map[string]any{
		"id": uuid.NewString(), "type": typ, "subject": "x", "source": "/payments", "spec_version": "1.0",
		"data": map[string]any{
			"payment_id": "PAY-1", "merchant_id": "M1", "created_at": "2026-10-27T15:00:00Z", "payment_method": "PSE",
			"amount":   map[string]any{"total": total, "currency": currency, "taxes": []any{}, "tip": 0},
			"metadata": map[string]any{"reference": ref.String()},
		},
	})
	require.NoError(t, err)
	return raw
}

// FR-014..FR-016, SC-005: pago con Bold confirmado por sondeo; sondeo, refresco y webhook
// repetidos extienden una sola vez; después el conductor puede ponerse ONLINE.
func TestIntegrationPayWithBoldExtendsOnce(t *testing.T) {
	f := newFixture(t, true)
	ctx := context.Background()
	driver := f.newDriver(t, "+573101112233", true)

	view, err := f.svc.View(ctx, driver)
	require.NoError(t, err)
	assert.Equal(t, "unpaid", view.Status)
	assert.Equal(t, &Price{AmountMinor: priceMinor, Currency: "COP"}, view.Price)
	assert.True(t, view.CanPay)

	p, err := f.svc.CreatePayment(ctx, driver)
	require.NoError(t, err)
	assert.Equal(t, "created", p.Status)
	require.NotNil(t, p.CheckoutURL)
	assert.Contains(t, *p.CheckoutURL, "https://checkout.bold.co/payment/LNK_")
	assert.Equal(t, p.ID.String(), f.bold.created[0]["reference"], "la referencia es el id del pago")
	assert.Equal(t, float64(f.clock.now().Add(LinkTTL).UnixNano()), f.bold.created[0]["expiration_date"])
	_, err = f.svc.CreatePayment(ctx, driver)
	assert.ErrorIs(t, err, ErrPaymentInProgress)

	n, err := f.svc.PollPayments(ctx)
	require.NoError(t, err)
	assert.Equal(t, 1, n)
	assert.Equal(t, store.PaymentStatusCreated, f.payment(t, p.ID).Status, "ACTIVE: aún sin pagar")

	link := f.payment(t, p.ID).BoldLinkID.String
	f.bold.set(link, map[string]any{"status": LinkProcessing, "payment_method": "PSE"})
	got, err := f.svc.Refresh(ctx, driver, p.ID)
	require.NoError(t, err)
	assert.Equal(t, "processing", got.Status, "PSE pendiente: pago en proceso")
	assert.Nil(t, f.paidUntil(t, driver))

	f.bold.set(link, map[string]any{"status": LinkPaid, "transaction_id": "TX-1"})
	f.clock.add(time.Minute)
	_, err = f.svc.PollPayments(ctx)
	require.NoError(t, err)
	approved := f.payment(t, p.ID)
	assert.Equal(t, store.PaymentStatusApproved, approved.Status)
	assert.Equal(t, "TX-1", approved.BoldPaymentID.String)
	assert.Equal(t, "PSE", approved.PaymentMethodDetail.String)
	want := f.clock.now().AddDate(0, 1, 0)
	require.NotNil(t, f.paidUntil(t, driver))
	assert.True(t, want.Equal(*f.paidUntil(t, driver)), "un mes desde el pago")
	assert.True(t, approved.CoversUntil.Time.Equal(want))

	// Repeticiones: refresco, sondeo y webhook duplicados no vuelven a extender.
	_, err = f.svc.Refresh(ctx, driver, p.ID)
	require.NoError(t, err)
	_, err = f.svc.PollPayments(ctx)
	require.NoError(t, err)
	body := webhookBody(t, EventSaleApproved, p.ID, 50000, "COP")
	for range 2 {
		require.NoError(t, f.svc.HandleWebhook(ctx, body, Sign("", body)))
	}
	assert.True(t, want.Equal(*f.paidUntil(t, driver)), "se extendió una sola vez")
	assert.Equal(t, []string{"payment_approved"}, f.kinds(t, driver))

	profile, err := f.st.GetDriverProfile(ctx, driver)
	require.NoError(t, err)
	docs, err := f.st.ListDocumentsForDrivers(ctx, []uuid.UUID{driver})
	require.NoError(t, err)
	assert.Equal(t, drivers.BlockNone, drivers.EvaluateOnline(profile.PaidUntil.Time, drivers.GateDocuments(docs), false, f.clock.now()))

	view, err = f.svc.View(ctx, driver)
	require.NoError(t, err)
	assert.Equal(t, "active", view.Status)
	require.Len(t, view.Payments, 1)
	assert.Nil(t, view.Payments[0].CheckoutURL, "sin checkout una vez aprobado")
	assert.NotNil(t, view.Payments[0].CoversFrom)
}

// RN-KYQ-002/003, escenario US3-3: pagar suspendido reactiva al instante, un mes desde el pago.
// US3-2: pagar antes del vencimiento no pierde días.
func TestIntegrationPaymentFromSuspendedAndEarly(t *testing.T) {
	f := newFixture(t, true)
	ctx := context.Background()
	suspended := f.newDriver(t, "+573101110001", true)
	f.setPaidUntil(t, suspended, f.clock.now().AddDate(0, 0, -5))
	early := f.newDriver(t, "+573101110002", true)
	paidEarly := f.clock.now().AddDate(0, 0, 5)
	f.setPaidUntil(t, early, paidEarly)

	for _, d := range []uuid.UUID{suspended, early} {
		p, err := f.svc.CreatePayment(ctx, d)
		require.NoError(t, err)
		body := webhookBody(t, EventSaleApproved, p.ID, 50000, "COP")
		require.NoError(t, f.svc.HandleWebhook(ctx, body, Sign("", body)))
	}
	assert.True(t, f.clock.now().AddDate(0, 1, 0).Equal(*f.paidUntil(t, suspended)))
	assert.Equal(t, drivers.SubscriptionActive, drivers.SubscriptionStatusAt(*f.paidUntil(t, suspended), f.clock.now()))
	assert.True(t, paidEarly.AddDate(0, 1, 0).Equal(*f.paidUntil(t, early)))
}

// FR-016/FR-017 y casos borde: firma inválida, importe distinto, rechazo, orden inverso,
// documentos sin aprobar, precio cambiado durante el pago y Bold caído.
func TestIntegrationPaymentEdgeCases(t *testing.T) {
	f := newFixture(t, true)
	ctx := context.Background()

	noDocs := f.newDriver(t, "+573101110003", false)
	_, err := f.svc.CreatePayment(ctx, noDocs)
	assert.ErrorIs(t, err, ErrDocumentsNotOK)

	driver := f.newDriver(t, "+573101110004", true)
	f.bold.failNext = true
	_, err = f.svc.CreatePayment(ctx, driver)
	assert.ErrorIs(t, err, ErrBoldUnavailable)
	payments, err := f.st.ListPaymentsForDriver(ctx, driver)
	require.NoError(t, err)
	assert.Empty(t, payments, "un pago que no llegó a Bold no queda en curso")

	// Rechazado por Bold: se puede reintentar.
	p1, err := f.svc.CreatePayment(ctx, driver)
	require.NoError(t, err)
	f.bold.set(f.payment(t, p1.ID).BoldLinkID.String, map[string]any{"status": LinkRejected})
	got, err := f.svc.Refresh(ctx, driver, p1.ID)
	require.NoError(t, err)
	assert.Equal(t, "rejected", got.Status)
	assert.Contains(t, f.kinds(t, driver), "payment_rejected")

	// Firma inválida: nada cambia.
	p2, err := f.svc.CreatePayment(ctx, driver)
	require.NoError(t, err, "tras un rechazo se puede pagar otra vez")
	body := webhookBody(t, EventSaleApproved, p2.ID, 50000, "COP")
	assert.ErrorIs(t, f.svc.HandleWebhook(ctx, body, Sign("otra", body)), ErrInvalidSignature)
	assert.Equal(t, store.PaymentStatusCreated, f.payment(t, p2.ID).Status)

	// El precio cambia con el pago en curso: se respeta el precio con el que empezó.
	_, err = f.svc.SetPrice(ctx, f.admin, "bogota", NewPrice{Currency: "COP", AmountMinor: 6_000_000})
	require.NoError(t, err)
	// Llega primero el rechazo y luego la aprobación (orden inverso): manda lo aprobado.
	rejected := webhookBody(t, EventSaleRejected, p2.ID, 50000, "COP")
	require.NoError(t, f.svc.HandleWebhook(ctx, rejected, Sign("", rejected)))
	require.NoError(t, f.svc.HandleWebhook(ctx, body, Sign("", body)))
	assert.Equal(t, store.PaymentStatusApproved, f.payment(t, p2.ID).Status)
	// Y un rechazo tardío no deshace la aprobación.
	require.NoError(t, f.svc.HandleWebhook(ctx, rejected, Sign("", rejected)))
	assert.Equal(t, store.PaymentStatusApproved, f.payment(t, p2.ID).Status)
	pu := *f.paidUntil(t, driver)

	// Importe distinto: queda para revisión sin extender.
	f.clock.add(time.Hour)
	p3, err := f.svc.CreatePayment(ctx, driver)
	require.NoError(t, err)
	assert.Equal(t, int64(6_000_000), p3.AmountMinor, "precio nuevo para el pago nuevo")
	wrong := webhookBody(t, EventSaleApproved, p3.ID, 1000, "COP")
	require.NoError(t, f.svc.HandleWebhook(ctx, wrong, Sign("", wrong)))
	p3row := f.payment(t, p3.ID)
	assert.Equal(t, store.PaymentStatusNeedsReview, p3row.Status)
	assert.Contains(t, p3row.ReviewNote.String, "100000 COP")
	assert.True(t, pu.Equal(*f.paidUntil(t, driver)), "no se extiende")

	// Referencia desconocida: se acepta y se ignora (Bold no reintenta).
	unknown := webhookBody(t, EventSaleApproved, uuid.New(), 50000, "COP")
	assert.NoError(t, f.svc.HandleWebhook(ctx, unknown, Sign("", unknown)))

	// Bold anula un pago aprobado: se resta su periodo.
	voided := webhookBody(t, EventVoidApproved, p2.ID, 50000, "COP")
	require.NoError(t, f.svc.HandleWebhook(ctx, voided, Sign("", voided)))
	assert.Equal(t, store.PaymentStatusVoided, f.payment(t, p2.ID).Status)
	assert.Nil(t, f.paidUntil(t, driver), "era su único pago: vuelve a sin suscripción")
}

// Enlaces caducados: el sondeo los marca y el conductor puede crear otro pago.
func TestIntegrationExpiredLinks(t *testing.T) {
	f := newFixture(t, true)
	ctx := context.Background()
	driver := f.newDriver(t, "+573101110005", true)
	p, err := f.svc.CreatePayment(ctx, driver)
	require.NoError(t, err)
	f.bold.set(f.payment(t, p.ID).BoldLinkID.String, map[string]any{"status": LinkExpired})
	f.clock.add(LinkTTL + time.Minute)
	_, err = f.svc.PollPayments(ctx)
	require.NoError(t, err)
	assert.Equal(t, store.PaymentStatusExpired, f.payment(t, p.ID).Status)

	p2, err := f.svc.CreatePayment(ctx, driver)
	require.NoError(t, err)
	f.clock.add(3 * time.Hour)
	_, err = f.svc.PollPayments(ctx)
	require.NoError(t, err)
	assert.Equal(t, store.PaymentStatusExpired, f.payment(t, p2.ID).Status, "más de 2 h en curso: caduca sin consultar")

	// El sandbox de Bold sigue diciendo ACTIVE tras caducar: pasado el plazo se da por caducado.
	p3, err := f.svc.CreatePayment(ctx, driver)
	require.NoError(t, err)
	f.bold.set(f.payment(t, p3.ID).BoldLinkID.String, map[string]any{"status": "ACTIVE"})
	f.clock.add(LinkTTL)
	_, err = f.svc.PollPayments(ctx)
	require.NoError(t, err)
	assert.NotEqual(t, store.PaymentStatusExpired, f.payment(t, p3.ID).Status, "dentro del margen sigue en curso")
	f.clock.add(linkExpiryMargin + time.Second)
	_, err = f.svc.PollPayments(ctx)
	require.NoError(t, err)
	assert.Equal(t, store.PaymentStatusExpired, f.payment(t, p3.ID).Status)
}

// FR-019, FR-027, RN-KYQ-002/003: recordatorios a 5 y 1 días y al entrar en gracia, por SMS,
// una sola vez por periodo.
func TestIntegrationSubscriptionReminders(t *testing.T) {
	f := newFixture(t, true)
	ctx := context.Background()
	driver := f.newDriver(t, "+573101110006", true)
	pu := f.clock.now().Add(5*24*time.Hour - time.Hour)
	f.setPaidUntil(t, driver, pu)

	for _, step := range []struct {
		advance time.Duration
		want    string
	}{
		{0, "sub_expiring"},
		{4 * 24 * time.Hour, "sub_expiring"},
		{24 * time.Hour, "sub_grace"},
	} {
		f.clock.add(step.advance)
		n, err := f.svc.SendReminders(ctx)
		require.NoError(t, err)
		assert.Equal(t, 1, n)
		n, err = f.svc.SendReminders(ctx)
		require.NoError(t, err)
		assert.Zero(t, n, "deduplicado")
		rows, err := f.st.ListNotices(ctx, driver)
		require.NoError(t, err)
		assert.Equal(t, step.want, rows[0].Kind)
		assert.True(t, rows[0].Sms)
	}
	keys, err := f.st.ListNotices(ctx, driver)
	require.NoError(t, err)
	assert.Len(t, keys, 3)

	// Fuera de la gracia ya no hay más recordatorios.
	f.clock.add(drivers.GracePeriod)
	n, err := f.svc.SendReminders(ctx)
	require.NoError(t, err)
	assert.Zero(t, n)
}

// El webhook es público, responde 200 a repetidos y 401 a firmas inválidas; sin Bold no existe.
func TestIntegrationWebhookEndpoint(t *testing.T) {
	f := newFixture(t, true)
	ctx := context.Background()
	driver := f.newDriver(t, "+573101110007", true)
	p, err := f.svc.CreatePayment(ctx, driver)
	require.NoError(t, err)

	issuer := auth.NewTokenIssuer([]byte("test-secret-test-secret-test-secret!"), nil)
	mux := http.NewServeMux()
	(&Handlers{Service: f.svc, WebhookEnabled: true}).Register(mux, auth.RequireAuth(issuer))
	post := func(body []byte, sig string) int {
		req := httptest.NewRequest(http.MethodPost, "/v1/billing/bold/webhook", bytes.NewReader(body))
		req.Header.Set("x-bold-signature", sig)
		rec := httptest.NewRecorder()
		mux.ServeHTTP(rec, req)
		return rec.Code
	}
	body := webhookBody(t, EventSaleApproved, p.ID, 50000, "COP")
	assert.Equal(t, http.StatusUnauthorized, post(body, "00"))
	assert.Equal(t, http.StatusOK, post(body, Sign("", body)))
	assert.Equal(t, http.StatusOK, post(body, Sign("", body)), "repetido")
	assert.Equal(t, store.PaymentStatusApproved, f.payment(t, p.ID).Status)

	closed := http.NewServeMux()
	(&Handlers{Service: f.svc}).Register(closed, auth.RequireAuth(issuer))
	req := httptest.NewRequest(http.MethodPost, "/v1/billing/bold/webhook", bytes.NewReader(body))
	rec := httptest.NewRecorder()
	closed.ServeHTTP(rec, req)
	assert.Equal(t, http.StatusNotFound, rec.Code)
}
