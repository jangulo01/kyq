package billing

import (
	"context"
	"encoding/json"
	"io"
	"net/http"
	"net/http/httptest"
	"strings"
	"sync"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// FR-015, escenarios US3-1..3: un mes calendario desde el mayor entre el vencimiento y el pago.
func TestExtendFromLaterOfPaidUntilAndNow(t *testing.T) {
	now := time.Date(2026, 10, 25, 10, 0, 0, 0, time.UTC)

	from, until := Extend(nil, now)
	assert.Equal(t, now, from, "sin suscripción: desde el pago")
	assert.Equal(t, time.Date(2026, 11, 25, 10, 0, 0, 0, time.UTC), until)

	paid := time.Date(2026, 10, 30, 0, 0, 0, 0, time.UTC)
	from, until = Extend(&paid, now)
	assert.Equal(t, paid, from, "pagar antes no pierde días")
	assert.Equal(t, time.Date(2026, 11, 30, 0, 0, 0, 0, time.UTC), until)

	expired := now.AddDate(0, 0, -5)
	_, until = Extend(&expired, now)
	assert.Equal(t, time.Date(2026, 11, 25, 10, 0, 0, 0, time.UTC), until, "suspendido: un mes desde el pago")
}

// Firma del webhook: hex(HMAC-SHA256(llave secreta, base64(cuerpo))); en sandbox la llave es vacía.
func TestVerifyBoldSignature(t *testing.T) {
	body := []byte(`{"type":"SALE_APPROVED","data":{"metadata":{"reference":"x"}}}`)
	// Vectores calculados con openssl: printf '%s' "$(printf '%s' BODY | base64 -w0)" | openssl dgst -sha256 -hmac LLAVE
	const sig = "9822379f44ca4d50a2595003b606e63467f87d5d8a08cd6b0387697bc450f568"
	assert.Equal(t, sig, Sign("secreto", body))
	assert.True(t, VerifySignature("secreto", body, sig))
	assert.True(t, VerifySignature("secreto", body, strings.ToUpper(sig)), "hex sin distinguir mayúsculas")
	assert.False(t, VerifySignature("otra", body, sig), "otra llave")
	assert.False(t, VerifySignature("secreto", append(body, ' '), sig), "cuerpo alterado")
	assert.False(t, VerifySignature("secreto", body, ""), "sin firma")
	assert.False(t, VerifySignature("secreto", body, "zz"), "firma no hexadecimal")

	const sandbox = "4f0994e56c3f24693f047df1c2012e87c55a7e4eb638bb9bc014c75d9cdd44da"
	assert.True(t, VerifySignature("", body, sandbox), "sandbox: llave vacía")
	assert.False(t, VerifySignature("secreto", body, sandbox))
}

func TestAmountConversion(t *testing.T) {
	assert.Equal(t, json.Number("50000"), MajorAmount(5_000_000))
	assert.Equal(t, json.Number("1234.56"), MajorAmount(123_456))
	for in, want := range map[json.Number]int64{"50000": 5_000_000, "50000.0": 5_000_000, "1234.56": 123_456, "": 0} {
		got, err := MinorAmount(in)
		require.NoError(t, err)
		assert.Equal(t, want, got, string(in))
	}
	_, err := MinorAmount("abc")
	assert.Error(t, err)
}

// fakeBold imitates the Bold link API with the shapes observed in the sandbox: POST answers
// {"payload": {...}, "errors": []}; GET answers the link flat.
type fakeBold struct {
	mu       sync.Mutex
	links    map[string]map[string]any
	created  []map[string]any
	gets     int
	failNext bool
	server   *httptest.Server
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
		_, _ = io.WriteString(w, `{"Message":"User is not authorized"}`)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	switch {
	case r.Method == http.MethodPost && r.URL.Path == "/online/link/v1":
		if f.failNext {
			f.failNext = false
			w.WriteHeader(http.StatusInternalServerError)
			return
		}
		var body map[string]any
		_ = json.NewDecoder(r.Body).Decode(&body)
		f.created = append(f.created, body)
		id := "LNK_TEST" + string(rune('A'+len(f.created)))
		amount := body["amount"].(map[string]any)
		f.links[id] = map[string]any{
			"id": id, "status": LinkActive, "total": amount["total_amount"], "currency": amount["currency"],
			"reference": body["reference"], "payment_method": nil, "transaction_id": nil, "is_sandbox": true,
		}
		_ = json.NewEncoder(w).Encode(map[string]any{
			"payload": map[string]any{"payment_link": id, "url": "https://checkout.bold.co/payment/" + id}, "errors": []any{},
		})
	case r.Method == http.MethodGet && strings.HasPrefix(r.URL.Path, "/online/link/v1/"):
		f.gets++
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

func (f *fakeBold) client() *BoldClient {
	return &BoldClient{BaseURL: f.server.URL, IdentityKey: "test-identity"}
}

// El cliente envía el contrato verificado contra el sandbox y lee el estado plano o envuelto.
func TestBoldClientAgainstFake(t *testing.T) {
	fake := newFakeBold(t)
	c := fake.client()
	ctx := context.Background()
	exp := time.Date(2026, 10, 27, 16, 0, 0, 0, time.UTC)

	link, err := c.CreateLink(ctx, LinkRequest{Reference: "ref-1", Description: "Kyq", Currency: "COP", AmountMinor: 5_000_000, ExpiresAt: exp})
	require.NoError(t, err)
	assert.Equal(t, "LNK_TESTB", link.ID)
	assert.Equal(t, "https://checkout.bold.co/payment/LNK_TESTB", link.URL)
	sent := fake.created[0]
	assert.Equal(t, "CLOSE", sent["amount_type"])
	assert.Equal(t, map[string]any{"currency": "COP", "total_amount": float64(50000)}, sent["amount"])
	assert.Equal(t, float64(exp.UnixNano()), sent["expiration_date"], "nanosegundos")

	fake.set(link.ID, map[string]any{"status": LinkPaid, "payment_method": "CREDIT_CARD", "transaction_id": "TX1"})
	st, err := c.GetLink(ctx, link.ID)
	require.NoError(t, err)
	assert.Equal(t, LinkStatus{ID: link.ID, Status: LinkPaid, Reference: "ref-1", Currency: "COP", TotalMinor: 5_000_000, PaymentMethod: "CREDIT_CARD", TransactionID: "TX1"}, st)

	_, err = c.GetLink(ctx, "LNK_NOPE")
	assert.ErrorIs(t, err, ErrLinkNotFound)
	_, err = (&BoldClient{BaseURL: fake.server.URL, IdentityKey: "mala"}).GetLink(ctx, link.ID)
	assert.ErrorIs(t, err, ErrBoldUnavailable, "llave rechazada")
	_, err = (&BoldClient{BaseURL: "http://127.0.0.1:1"}).CreateLink(ctx, LinkRequest{})
	assert.ErrorIs(t, err, ErrBoldUnavailable)

	wrapped := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		_, _ = io.WriteString(w, `{"payload": {"id": "LNK_W", "status": "PROCESSING", "total": 1000, "currency": "COP"}, "errors": []}`)
	}))
	defer wrapped.Close()
	st, err = (&BoldClient{BaseURL: wrapped.URL}).GetLink(ctx, "LNK_W")
	require.NoError(t, err)
	assert.Equal(t, LinkProcessing, st.Status)
	assert.Equal(t, int64(100_000), st.TotalMinor)
}
