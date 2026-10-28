package contracttest

import (
	"context"
	"encoding/json"
	"net/http"
	"strings"
	"sync"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/kyq/backend/internal/admin"
	"github.com/kyq/backend/internal/auth"
	"github.com/kyq/backend/internal/billing"
	"github.com/kyq/backend/internal/drivers"
	"github.com/kyq/backend/internal/httpapi"
	"github.com/kyq/backend/internal/kyc"
	"github.com/kyq/backend/internal/notify"
	"github.com/kyq/backend/internal/storage"
	"github.com/kyq/backend/internal/store"
	"github.com/kyq/backend/internal/telemetry"
	"github.com/kyq/backend/internal/testdb"
)

// memBold is a BoldAPI in memory: links stay ACTIVE until the test pays them.
type memBold struct {
	mu    sync.Mutex
	links map[string]billing.LinkStatus
}

func (b *memBold) CreateLink(_ context.Context, r billing.LinkRequest) (billing.Link, error) {
	b.mu.Lock()
	defer b.mu.Unlock()
	id := "LNK_" + strings.ToUpper(r.Reference[:8])
	b.links[id] = billing.LinkStatus{ID: id, Status: billing.LinkActive, Reference: r.Reference, Currency: r.Currency, TotalMinor: r.AmountMinor}
	return billing.Link{ID: id, URL: "https://checkout.bold.co/payment/" + id}, nil
}

func (b *memBold) GetLink(_ context.Context, id string) (billing.LinkStatus, error) {
	b.mu.Lock()
	defer b.mu.Unlock()
	return b.links[id], nil
}

// TestIntegration002RoutesMatchContract walks the 002 flow through the real router and checks
// every request and response against the merged contract: sign-up as driver, vehicle,
// documents, review, price, Bold payment, webhook, notices, admin billing and costs.
func TestIntegration002RoutesMatchContract(t *testing.T) {
	st := testdb.New(t)
	ctx := context.Background()
	now := time.Now()
	adminID, passengerID := uuid.New(), uuid.New()
	for _, u := range []store.CreateUserParams{
		{ID: adminID, PhoneE164: "+573000000000", Role: store.UserRoleAdmin, DisplayName: "Admin"},
		{ID: passengerID, PhoneE164: "+573200000002", Role: store.UserRolePassenger, DisplayName: "Ana"},
	} {
		_, err := st.CreateUser(ctx, u)
		require.NoError(t, err)
	}
	require.NoError(t, st.UpsertFareTable(ctx, store.UpsertFareTableParams{
		CityCode: "bogota", Currency: "COP", BaseMinor: 400_000, PerKmMinor: 120_000, PerMinuteMinor: 30_000,
		MinimumMinor: 700_000, RoundingMinor: 10_000, UpdatedBy: adminID,
	}))

	tokens := auth.NewTokenIssuer([]byte("test-secret-test-secret-test-secret!"), nil)
	objects := storage.NewMemory()
	notices := &notify.Service{Store: st, Publisher: &wire{}}
	bold := &memBold{links: map[string]billing.LinkStatus{}}
	billingService := &billing.Service{Store: st, Bold: bold, Notify: notices, CityCode: "bogota"}
	server := httpapi.NewRouter(httpapi.Deps{
		Tokens:  tokens,
		Auth:    auth.NewHandlers(auth.NewService(auth.NewPgRepo(st), auth.DevOTP{Code: "123456"}, tokens, nil)),
		Admin:   &admin.Handlers{Store: st},
		Drivers: &drivers.Handlers{Store: st},
		KYC:     &kyc.Handlers{Service: &kyc.Service{Store: st, Objects: objects, Notify: notices}},
		Billing: &billing.Handlers{Service: billingService, WebhookEnabled: true},
		Notices: &notify.Handlers{Service: notices},
		Costs:   &telemetry.CostHandlers{Store: st, CityCode: "bogota"},
	})
	c := load(t, server)
	bearer := func(id uuid.UUID, role string) string {
		tok, err := tokens.IssueAccess(auth.Principal{UserID: id, Role: role})
		require.NoError(t, err)
		return tok
	}
	asAdmin, asPassenger := bearer(adminID, auth.RoleAdmin), bearer(passengerID, auth.RolePassenger)

	// Alta como conductor (FR-001, FR-003).
	c.call(http.MethodPost, "/v1/auth/otp/verify", "", map[string]string{"phone_e164": "+573200000002", "code": "123456", "role": "driver"}, http.StatusConflict)
	session := c.call(http.MethodPost, "/v1/auth/otp/verify", "",
		map[string]string{"phone_e164": "+573101112233", "code": "123456", "display_name": "Luis", "role": "driver"}, http.StatusOK)
	require.Equal(t, "driver", session["role"])
	asDriver := session["access_token"].(string)
	p, err := tokens.ParseAccess(asDriver)
	require.NoError(t, err)
	driverID := p.UserID

	onboarding := c.call(http.MethodGet, "/v1/driver/onboarding", asDriver, nil, http.StatusOK)
	assert.Equal(t, "profile_incomplete", onboarding["status"])
	c.call(http.MethodGet, "/v1/driver/onboarding", asPassenger, nil, http.StatusForbidden)
	c.call(http.MethodPost, "/v1/driver/documents", asDriver, map[string]any{"doc_type": "national_id", "number": "1020304050", "sides": []string{"front"}}, http.StatusConflict)
	c.call(http.MethodPut, "/v1/driver/vehicle", asDriver, map[string]any{"plate": "AB1", "brand": "Kia", "model": "Picanto", "color": "Gris", "year": 2022}, http.StatusBadRequest)
	c.call(http.MethodPut, "/v1/driver/vehicle", asDriver, map[string]any{"plate": "KYQ12D", "brand": "Kia", "model": "Picanto", "color": "Gris", "year": 2022}, http.StatusOK)

	docs := []map[string]any{
		{"doc_type": "national_id", "number": "1020304050", "sides": []string{"front", "back"}},
		{"doc_type": "license", "number": "1020304050", "expires_at": "2030-01-31", "sides": []string{"front", "back"}},
		{"doc_type": "mandatory_insurance", "number": "SOAT-998877", "expires_at": "2030-06-30", "sides": []string{"front"}},
		{"doc_type": "technical_inspection", "number": "RTM-123", "expires_at": "2030-09-30", "sides": []string{"front"}},
		{"doc_type": "vehicle_registration", "number": "LT0001234", "sides": []string{"front"}},
	}
	c.call(http.MethodPost, "/v1/driver/documents", asDriver, map[string]any{"doc_type": "license", "number": "1", "sides": []string{"front"}}, http.StatusBadRequest)
	docIDs := map[string]string{}
	for i, d := range docs {
		created := c.call(http.MethodPost, "/v1/driver/documents", asDriver, d, http.StatusCreated)
		doc := created["document"].(map[string]any)
		id := doc["id"].(string)
		docIDs[d["doc_type"].(string)] = id
		if i == 0 {
			c.call(http.MethodPost, "/v1/driver/documents/"+id+"/submit", asDriver, nil, http.StatusConflict)
		}
		for _, side := range d["sides"].([]string) {
			objects.Put(kyc.ObjectKey(driverID, uuid.MustParse(id), side), []byte("jpeg"), "image/jpeg")
		}
		c.call(http.MethodPost, "/v1/driver/documents/"+id+"/submit", asDriver, nil, http.StatusOK)
	}
	c.call(http.MethodPost, "/v1/driver/documents/"+uuid.NewString()+"/submit", asDriver, nil, http.StatusNotFound)
	assert.Equal(t, "in_review", c.call(http.MethodGet, "/v1/driver/onboarding", asDriver, nil, http.StatusOK)["status"])

	// Revisión (FR-008, FR-009).
	c.call(http.MethodGet, "/v1/admin/kyc/queue", asAdmin, nil, http.StatusOK)
	c.call(http.MethodGet, "/v1/admin/kyc/queue", asDriver, nil, http.StatusForbidden)
	c.call(http.MethodGet, "/v1/admin/kyc/drivers/"+driverID.String(), asAdmin, nil, http.StatusOK)
	c.call(http.MethodGet, "/v1/admin/kyc/drivers/"+uuid.NewString(), asAdmin, nil, http.StatusNotFound)
	soat := docIDs["mandatory_insurance"]
	c.call(http.MethodPost, "/v1/admin/kyc/documents/"+soat+"/review", asAdmin, map[string]any{"decision": "reject"}, http.StatusBadRequest)
	c.call(http.MethodPost, "/v1/admin/kyc/documents/"+soat+"/review", asAdmin, map[string]any{"decision": "reject", "reason": "Foto borrosa"}, http.StatusOK)
	c.call(http.MethodPost, "/v1/admin/kyc/documents/"+soat+"/review", asAdmin, map[string]any{"decision": "approve"}, http.StatusConflict)
	for docType, id := range docIDs {
		if docType == "mandatory_insurance" {
			continue
		}
		body := map[string]any{"decision": "approve"}
		if docType == "technical_inspection" {
			body["expires_at"] = nil
			body["exempt_until"] = "2027-03-01"
		}
		c.call(http.MethodPost, "/v1/admin/kyc/documents/"+id+"/review", asAdmin, body, http.StatusOK)
	}
	me := c.call(http.MethodGet, "/v1/driver/me", asDriver, nil, http.StatusOK)
	assert.Equal(t, []any{map[string]any{"doc_type": "mandatory_insurance", "problem": "missing"}}, me["blocked_documents"])
	resent := c.call(http.MethodPost, "/v1/driver/documents", asDriver, docs[2], http.StatusCreated)["document"].(map[string]any)["id"].(string)
	objects.Put(kyc.ObjectKey(driverID, uuid.MustParse(resent), "front"), []byte("jpeg"), "image/jpeg")
	c.call(http.MethodPost, "/v1/driver/documents/"+resent+"/submit", asDriver, nil, http.StatusOK)
	c.call(http.MethodPost, "/v1/admin/kyc/documents/"+resent+"/review", asAdmin, map[string]any{"decision": "approve", "number": "SOAT-998878"}, http.StatusOK)
	assert.Equal(t, "documents_ok", c.call(http.MethodGet, "/v1/driver/onboarding", asDriver, nil, http.StatusOK)["status"])

	// Precio y pago con Bold (FR-013..FR-016).
	c.call(http.MethodPost, "/v1/driver/payments", asDriver, nil, http.StatusConflict) // price_not_set
	c.call(http.MethodPut, "/v1/admin/subscription-prices/bogota", asAdmin, map[string]any{"currency": "COP", "amount_minor": 5_000_050}, http.StatusBadRequest)
	c.call(http.MethodPut, "/v1/admin/subscription-prices/lima", asAdmin, map[string]any{"currency": "PEN", "amount_minor": 5000}, http.StatusNotFound)
	c.call(http.MethodPut, "/v1/admin/subscription-prices/bogota", asAdmin, map[string]any{
		"currency": "COP", "amount_minor": 5_000_000, "effective_from": now.Add(-time.Minute).UTC().Format(time.RFC3339),
	}, http.StatusOK)
	sub := c.call(http.MethodGet, "/v1/driver/subscription", asDriver, nil, http.StatusOK)
	assert.Equal(t, "unpaid", sub["status"])
	assert.Equal(t, true, sub["can_pay"])
	payment := c.call(http.MethodPost, "/v1/driver/payments", asDriver, nil, http.StatusCreated)
	paymentID := payment["id"].(string)
	c.call(http.MethodPost, "/v1/driver/payments", asDriver, nil, http.StatusConflict) // payment_in_progress
	assert.Equal(t, "created", c.call(http.MethodPost, "/v1/driver/payments/"+paymentID+"/refresh", asDriver, nil, http.StatusOK)["status"])
	c.call(http.MethodPost, "/v1/driver/payments/"+uuid.NewString()+"/refresh", asDriver, nil, http.StatusNotFound)

	webhook := map[string]any{
		"id": uuid.NewString(), "type": "SALE_APPROVED",
		"data": map[string]any{"payment_id": "PAY-1", "payment_method": "CREDIT_CARD", "amount": map[string]any{"total": 50000, "currency": "COP"},
			"metadata": map[string]any{"reference": paymentID}},
	}
	raw, err := json.Marshal(webhook)
	require.NoError(t, err)
	c.callRaw(http.MethodPost, "/v1/billing/bold/webhook", map[string]string{"x-bold-signature": "00"}, raw, http.StatusUnauthorized)
	c.callRaw(http.MethodPost, "/v1/billing/bold/webhook", map[string]string{"x-bold-signature": billing.Sign("", raw)}, raw, http.StatusOK)
	c.callRaw(http.MethodPost, "/v1/billing/bold/webhook", map[string]string{"x-bold-signature": billing.Sign("", raw)}, raw, http.StatusOK)
	sub = c.call(http.MethodGet, "/v1/driver/subscription", asDriver, nil, http.StatusOK)
	assert.Equal(t, "active", sub["status"])
	assert.Equal(t, true, c.call(http.MethodGet, "/v1/driver/me", asDriver, nil, http.StatusOK)["can_go_online"])

	// Avisos.
	c.call(http.MethodGet, "/v1/driver/notices", asDriver, nil, http.StatusOK)
	rows, err := st.ListNotices(ctx, driverID)
	require.NoError(t, err)
	require.NotEmpty(t, rows)
	c.call(http.MethodPost, "/v1/driver/notices/"+rows[0].ID.String()+"/read", asDriver, nil, http.StatusNoContent)
	c.call(http.MethodPost, "/v1/driver/notices/"+uuid.NewString()+"/read", asDriver, nil, http.StatusNotFound)

	// Panel de suscripciones y pagos (FR-021, FR-022).
	c.call(http.MethodGet, "/v1/admin/subscriptions?status=active", asAdmin, nil, http.StatusOK)
	c.call(http.MethodGet, "/v1/admin/drivers/"+driverID.String()+"/payments", asAdmin, nil, http.StatusOK)
	c.call(http.MethodGet, "/v1/admin/drivers/"+uuid.NewString()+"/payments", asAdmin, nil, http.StatusNotFound)
	c.call(http.MethodPost, "/v1/admin/drivers/"+driverID.String()+"/payments", asAdmin, map[string]any{"method_detail": "efectivo", "reference": " "}, http.StatusBadRequest)
	manual := c.call(http.MethodPost, "/v1/admin/drivers/"+driverID.String()+"/payments", asAdmin, map[string]any{"method_detail": "efectivo", "reference": "RC-1"}, http.StatusCreated)
	c.call(http.MethodPost, "/v1/admin/payments/"+manual["id"].(string)+"/void", asAdmin, map[string]any{"reason": "contracargo"}, http.StatusOK)
	c.call(http.MethodPost, "/v1/admin/payments/"+manual["id"].(string)+"/void", asAdmin, map[string]any{"reason": "contracargo"}, http.StatusConflict)
	c.call(http.MethodPost, "/v1/admin/payments/"+uuid.NewString()+"/void", asAdmin, map[string]any{"reason": "x"}, http.StatusNotFound)

	// Rutas de 001 que el panel sigue usando.
	c.call(http.MethodPut, "/v1/admin/drivers/"+driverID.String()+"/documents/national_id", asAdmin, map[string]any{"approved": true}, http.StatusOK)
	c.call(http.MethodGet, "/v1/admin/drivers", asAdmin, nil, http.StatusOK)

	// Costos (RN-KYQ-004).
	c.call(http.MethodPut, "/v1/admin/cost-rates", asAdmin, map[string]any{"concept": "voice_minute", "currency": "COP", "unit_cost_micro": 40_000_000, "effective_from": "2026-10-01"}, http.StatusOK)
	c.call(http.MethodGet, "/v1/admin/cost-rates", asAdmin, nil, http.StatusOK)
	c.call(http.MethodGet, "/v1/driver/costs", asDriver, nil, http.StatusOK)
	c.call(http.MethodGet, "/v1/driver/costs?month=2026-13", asDriver, nil, http.StatusBadRequest)
	c.call(http.MethodGet, "/v1/admin/costs?month=2026-10", asAdmin, nil, http.StatusOK)
}
