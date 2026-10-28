package contracttest

import (
	"context"
	"encoding/json"
	"net/http"
	"strings"
	"testing"

	"github.com/getkin/kin-openapi/openapi3"
	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/kyq/backend/internal/auth"
	"github.com/kyq/backend/internal/billing"
	"github.com/kyq/backend/internal/httpapi"
	"github.com/kyq/backend/internal/notify"
	"github.com/kyq/backend/internal/store"
	"github.com/kyq/backend/internal/testdb"
	"github.com/kyq/backend/internal/trippay"
	"github.com/kyq/backend/internal/trips"
)

// The 004 view of the contract stays a valid OpenAPI document (its routes are merged in specPath).
func TestContract004ViewIsValid(t *testing.T) {
	loader := openapi3.NewLoader()
	doc, err := loader.LoadFromFile("../../../specs/004-trip-payment-cash/contracts/api.yaml")
	require.NoError(t, err)
	require.NoError(t, doc.Validate(loader.Context))
}

// TestIntegration004RoutesMatchContract walks every 004 route through the real router and checks
// requests and responses against the merged contract: cash reported, disputed and resolved;
// Bold paid by refresh and webhook; settlement, payout and void; unpaid; accepted methods.
func TestIntegration004RoutesMatchContract(t *testing.T) {
	st := testdb.New(t)
	ctx := context.Background()
	adminID, driverID, passengerID := uuid.New(), uuid.New(), uuid.New()
	for _, u := range []store.CreateUserParams{
		{ID: adminID, PhoneE164: "+573000000001", Role: store.UserRoleAdmin, DisplayName: "Admin"},
		{ID: driverID, PhoneE164: "+573100000001", Role: store.UserRoleDriver, DisplayName: "Carlos"},
		{ID: passengerID, PhoneE164: "+573200000002", Role: store.UserRolePassenger, DisplayName: "Ana"},
	} {
		_, err := st.CreateUser(ctx, u)
		require.NoError(t, err)
	}
	require.NoError(t, st.CreateDriver(ctx, store.CreateDriverParams{UserID: driverID, QrToken: "qr-carlos-0000000", VehiclePlate: "KYQ001", VehicleDescription: "Kia"}))
	require.NoError(t, st.InsertAffiliation(ctx, store.InsertAffiliationParams{PassengerID: passengerID, DriverID: driverID}))
	require.NoError(t, st.UpsertFareTable(ctx, store.UpsertFareTableParams{
		CityCode: "bogota", Currency: "COP", BaseMinor: 400_000, PerKmMinor: 120_000, PerMinuteMinor: 30_000,
		MinimumMinor: 700_000, RoundingMinor: 10_000, UpdatedBy: adminID,
	}))

	pub := &wire{}
	bold := &memBold{links: map[string]billing.LinkStatus{}}
	notices := &notify.Service{Store: st, Publisher: pub}
	tripPay := &trippay.Service{Store: st, Bold: bold, Notify: notices, Publisher: pub}
	tripService := &trips.Service{Store: st, Routes: fixedRoute{}, Publisher: pub, CityCode: "bogota", Payments: tripPay}
	billingService := &billing.Service{Store: st, Bold: bold, Notify: notices, CityCode: "bogota", References: []billing.ReferenceHandler{tripPay}}
	tokens := auth.NewTokenIssuer([]byte("test-secret-test-secret-test-secret!"), nil)
	server := httpapi.NewRouter(httpapi.Deps{
		Tokens:  tokens,
		Trips:   &trips.Handlers{Service: tripService},
		Billing: &billing.Handlers{Service: billingService, WebhookEnabled: true},
		TripPay: &trippay.Handlers{Service: tripPay},
	})
	c := load(t, server)
	bearer := func(id uuid.UUID, role string) string {
		tok, err := tokens.IssueAccess(auth.Principal{UserID: id, Role: role})
		require.NoError(t, err)
		return tok
	}
	asAdmin, asDriver, asPassenger := bearer(adminID, auth.RoleAdmin), bearer(driverID, auth.RoleDriver), bearer(passengerID, auth.RolePassenger)
	asStranger := bearer(uuid.New(), auth.RolePassenger)

	route := map[string]any{"pickup": map[string]float64{"lat": 4.60, "lng": -74.08}, "dropoff": map[string]float64{"lat": 4.65, "lng": -74.05}}
	completeTrip := func() string {
		require.NoError(t, st.SetDriverPresence(ctx, store.SetDriverPresenceParams{UserID: driverID, Presence: store.DriverPresenceFree}))
		trip := c.call(http.MethodPost, "/v1/trips", asPassenger, map[string]any{
			"driver_id": driverID, "pickup": route["pickup"], "dropoff": route["dropoff"],
		}, http.StatusCreated)
		base := "/v1/trips/" + trip["id"].(string)
		c.call(http.MethodGet, base+"/payment", asPassenger, nil, http.StatusNotFound) // aún no completado
		c.call(http.MethodPost, base+"/accept", asDriver, map[string]any{}, http.StatusOK)
		for _, step := range []string{"arrive", "start", "complete"} {
			c.call(http.MethodPost, base+"/"+step, asDriver, nil, http.StatusOK)
		}
		return base
	}

	// Efectivo: reporte, disputa y resolución (US1, FR-017).
	trip1 := completeTrip()
	payment := c.call(http.MethodGet, trip1+"/payment", asPassenger, nil, http.StatusOK)
	assert.Equal(t, "pending", payment["status"])
	assert.Equal(t, payment["amount_minor"], payment["driver_amount_minor"], "RN-KYQ-001")
	c.call(http.MethodGet, trip1+"/payment", asDriver, nil, http.StatusOK)
	c.call(http.MethodGet, trip1+"/payment", asStranger, nil, http.StatusNotFound)
	c.call(http.MethodGet, "/v1/trips/"+uuid.NewString()+"/payment", asPassenger, nil, http.StatusNotFound)
	c.call(http.MethodPost, trip1+"/payment/cash", asDriver, nil, http.StatusForbidden)
	assert.Equal(t, "cash_reported", c.call(http.MethodPost, trip1+"/payment/cash", asPassenger, nil, http.StatusOK)["status"])
	c.call(http.MethodPost, trip1+"/payment/cash", asPassenger, nil, http.StatusConflict)
	c.call(http.MethodPost, trip1+"/payment/cash-received", asPassenger, nil, http.StatusForbidden)
	assert.Equal(t, "disputed", c.call(http.MethodPost, trip1+"/payment/cash-dispute", asDriver, nil, http.StatusOK)["status"])
	c.call(http.MethodPost, trip1+"/payment/unpaid", asDriver, nil, http.StatusConflict)
	c.call(http.MethodGet, "/v1/admin/trip-payments?status=issues", asAdmin, nil, http.StatusOK)
	c.call(http.MethodGet, "/v1/admin/trip-payments", asDriver, nil, http.StatusForbidden)
	c.call(http.MethodGet, "/v1/admin/trip-payments?status=paid", asAdmin, nil, http.StatusOK)
	paymentID := payment["id"].(string)
	c.call(http.MethodPost, "/v1/admin/trip-payments/"+paymentID+"/resolve", asAdmin, map[string]any{"outcome": "paid", "note": " "}, http.StatusBadRequest)
	resolved := c.call(http.MethodPost, "/v1/admin/trip-payments/"+paymentID+"/resolve", asAdmin, map[string]any{"outcome": "paid", "note": "Se aclaró por teléfono"}, http.StatusOK)
	assert.Equal(t, "paid", resolved["status"])
	c.call(http.MethodPost, "/v1/admin/trip-payments/"+paymentID+"/resolve", asAdmin, map[string]any{"outcome": "unpaid", "note": "x"}, http.StatusConflict)
	c.call(http.MethodPost, "/v1/admin/trip-payments/"+uuid.NewString()+"/resolve", asAdmin, map[string]any{"outcome": "paid", "note": "x"}, http.StatusNotFound)

	// Bold: checkout, refresco y webhook repetido (US2).
	trip2 := completeTrip()
	c.call(http.MethodPost, trip2+"/payment/bold", asDriver, nil, http.StatusForbidden)
	started := c.call(http.MethodPost, trip2+"/payment/bold", asPassenger, nil, http.StatusOK)
	assert.Equal(t, "bold_in_progress", started["status"])
	checkout := started["checkout_url"].(string)
	c.call(http.MethodPost, trip2+"/payment/unpaid", asDriver, nil, http.StatusConflict) // bold_in_progress
	assert.Equal(t, "bold_in_progress", c.call(http.MethodPost, trip2+"/payment/refresh", asPassenger, nil, http.StatusOK)["status"])
	c.call(http.MethodPost, trip2+"/payment/refresh", asDriver, nil, http.StatusForbidden)
	linkID := checkout[strings.LastIndex(checkout, "/")+1:]
	bold.mu.Lock()
	link := bold.links[linkID]
	link.Status, link.PaymentMethod, link.TransactionID = billing.LinkPaid, "NEQUI", "TX-1"
	bold.links[linkID] = link
	bold.mu.Unlock()
	paid := c.call(http.MethodPost, trip2+"/payment/refresh", asPassenger, nil, http.StatusOK)
	assert.Equal(t, "paid", paid["status"])
	assert.Equal(t, "bold", paid["method"])
	raw, err := json.Marshal(map[string]any{
		"id": uuid.NewString(), "type": "SALE_APPROVED",
		"data": map[string]any{"payment_id": "TX-1", "payment_method": "NEQUI", "amount": map[string]any{"total": paid["amount_minor"].(float64) / 100, "currency": "COP"},
			"metadata": map[string]any{"reference": paid["id"]}},
	})
	require.NoError(t, err)
	for range 2 {
		c.callRaw(http.MethodPost, "/v1/billing/bold/webhook", map[string]string{"x-bold-signature": billing.Sign("", raw)}, raw, http.StatusOK)
	}
	c.call(http.MethodPost, trip2+"/payment/cash-received", asDriver, nil, http.StatusConflict)

	// Libro, liquidaciones y giros (US5).
	settlement := c.call(http.MethodGet, "/v1/driver/settlement", asDriver, nil, http.StatusOK)
	require.Len(t, settlement["entries"], 1, "un solo abono")
	c.call(http.MethodGet, "/v1/driver/settlement", asPassenger, nil, http.StatusForbidden)
	c.call(http.MethodGet, "/v1/admin/settlements", asAdmin, nil, http.StatusOK)
	c.call(http.MethodGet, "/v1/admin/drivers/"+driverID.String()+"/settlement", asAdmin, nil, http.StatusOK)
	c.call(http.MethodGet, "/v1/admin/drivers/"+uuid.NewString()+"/settlement", asAdmin, nil, http.StatusNotFound)
	payouts := "/v1/admin/drivers/" + driverID.String() + "/payouts"
	amount := int64(paid["amount_minor"].(float64))
	c.call(http.MethodPost, payouts, asAdmin, map[string]any{"amount_minor": amount + 1, "currency": "COP", "reference": "TR-1"}, http.StatusConflict)
	c.call(http.MethodPost, payouts, asAdmin, map[string]any{"amount_minor": 100, "currency": "COP", "reference": " "}, http.StatusBadRequest)
	c.call(http.MethodPost, "/v1/admin/drivers/"+uuid.NewString()+"/payouts", asAdmin, map[string]any{"amount_minor": 100, "currency": "COP", "reference": "TR-1"}, http.StatusNotFound)
	c.call(http.MethodPost, payouts, asAdmin, map[string]any{"amount_minor": amount, "currency": "COP", "reference": "TR-1", "note": "transferencia"}, http.StatusCreated)
	voidPath := "/v1/admin/trip-payments/" + paid["id"].(string) + "/void"
	c.call(http.MethodPost, voidPath, asAdmin, map[string]any{"reason": " "}, http.StatusBadRequest)
	assert.Equal(t, "voided", c.call(http.MethodPost, voidPath, asAdmin, map[string]any{"reason": "Reembolsado en Bold"}, http.StatusOK)["status"])
	c.call(http.MethodPost, voidPath, asAdmin, map[string]any{"reason": "otra vez"}, http.StatusConflict)

	// Pendientes y no pagado (US3).
	trip3 := completeTrip()
	c.call(http.MethodGet, "/v1/trip-payments/pending", asPassenger, nil, http.StatusOK)
	c.call(http.MethodGet, "/v1/trip-payments/pending", asDriver, nil, http.StatusForbidden)
	assert.Equal(t, "unpaid", c.call(http.MethodPost, trip3+"/payment/unpaid", asDriver, nil, http.StatusOK)["status"])

	// Medios aceptados (US4).
	c.call(http.MethodGet, "/v1/driver/payment-methods", asDriver, nil, http.StatusOK)
	c.call(http.MethodGet, "/v1/driver/payment-methods", asPassenger, nil, http.StatusForbidden)
	c.call(http.MethodPut, "/v1/driver/payment-methods", asDriver, map[string]any{"accepts_cash": false, "accepts_bold": false}, http.StatusBadRequest)
	methods := c.call(http.MethodPut, "/v1/driver/payment-methods", asDriver, map[string]any{"accepts_cash": true, "accepts_bold": false}, http.StatusOK)
	assert.Equal(t, false, methods["accepts_bold"])
}
