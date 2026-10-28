package observability

import (
	"context"
	"errors"
	"testing"

	"github.com/getsentry/sentry-go"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestScrubStringRemovesPersonalData(t *testing.T) {
	cases := map[string]string{
		"verify +573001234567 failed":                    "verify [phone] failed",
		"celular 3001234567 sin prefijo":                 "celular [phone] sin prefijo",
		`{"phone_e164":"+573001234567","code":"123456"}`: `{"phone_e164":"[phone]","code":"[otp]"}`,
		"código: 654321":                                 "código: [otp]",
		"Authorization: Bearer abc.def":                  "Authorization: Bearer [token]",
		"token eyJhbGciOi.eyJzdWIiOiIx.c2lnbmF0dXJl":     "token [token]",
	}
	for in, want := range cases {
		assert.Equal(t, want, ScrubString(in), in)
	}
	assert.Equal(t, "viaje 01a17f43 de 5200 m", ScrubString("viaje 01a17f43 de 5200 m"), "ids y cifras normales quedan")
}

func TestScrubEventKeepsOnlyWhatIsNeeded(t *testing.T) {
	e := &sentry.Event{
		Message:    "fallo con +573001234567",
		ServerName: "api-1",
		User:       sentry.User{ID: "u1", Email: "a@b.c", IPAddress: "10.0.0.1", Name: "Ana", Username: "ana"},
		Request: &sentry.Request{
			URL: "http://api/v1/auth/otp/verify?phone=+573001234567", Method: "POST",
			Data: `{"code":"123456"}`, Headers: map[string]string{"Authorization": "Bearer x"}, Cookies: "s=1",
		},
		Exception: []sentry.Exception{{Value: "user +573200000002 not found"}},
		Contexts:  map[string]sentry.Context{"trip": {"passenger": "+573200000002", "nested": []any{"3001234567"}}},
		Tags:      map[string]string{"path": "/v1/x"},
		Breadcrumbs: []*sentry.Breadcrumb{{
			Message: "POST +573001234567",
			Data:    map[string]any{"url": "http://api/v1/trips?x=1", "body": "{}", "phone": "+573001234567"},
		}},
	}
	got := Scrub(e)
	require.NotNil(t, got)
	assert.Equal(t, sentry.User{ID: "u1"}, got.User)
	assert.Empty(t, got.ServerName)
	assert.Equal(t, &sentry.Request{URL: "http://api/v1/auth/otp/verify", Method: "POST"}, got.Request)
	assert.Equal(t, "fallo con [phone]", got.Message)
	assert.Equal(t, "user [phone] not found", got.Exception[0].Value)
	assert.Equal(t, "[phone]", got.Contexts["trip"]["passenger"])
	assert.Equal(t, []any{"[phone]"}, got.Contexts["trip"]["nested"])
	b := got.Breadcrumbs[0]
	assert.Equal(t, "POST [phone]", b.Message)
	assert.Equal(t, "http://api/v1/trips", b.Data["url"])
	assert.NotContains(t, b.Data, "body")
	assert.Equal(t, "[phone]", b.Data["phone"])
}

func TestWithoutDSNNothingIsSent(t *testing.T) {
	flush, err := Init(Options{})
	require.NoError(t, err)
	flush()
	assert.False(t, enabled.Load())
	CaptureError(context.Background(), errors.New("x"), "/v1/x") // no hace nada ni falla
}

// 002 (FR-011): ni números de documento ni URLs firmadas de las fotos llegan a Sentry.
func TestScrubDocumentNumbersAndSignedURLs(t *testing.T) {
	cases := map[string]string{
		`{"doc_type":"license","number":"1020304050"}`: `{"doc_type":"license","number":"[doc]"}`,
		"document_number=ABC-12345 rechazado":          "document_number=[doc] rechazado",
		"número: 1.020.304.050":                        "número: [doc]",
		"put http://minio:9000/kyq-kyc/kyc/a/b/front.jpg?X-Amz-Algorithm=AWS4&X-Amz-Credential=k%2F2026&X-Amz-Signature=abc failed": "put http://minio:9000/kyq-kyc/kyc/a/b/front.jpg?[signed] failed",
		"https://r2.example/kyc/x.jpg?foo=1&X-Amz-Signature=abc":                                                                    "https://r2.example/kyc/x.jpg?[signed]",
	}
	for in, want := range cases {
		assert.Equal(t, want, ScrubString(in), in)
	}
	assert.Equal(t, "pago 01a17f43 de 5000000 COP", ScrubString("pago 01a17f43 de 5000000 COP"), "ids e importes quedan")

	e := &sentry.Event{Contexts: map[string]sentry.Context{"doc": {"number": "LT0001234", "doc_type": "vehicle_registration"}}}
	got := Scrub(e)
	assert.Equal(t, "[doc]", got.Contexts["doc"]["number"])
	assert.Equal(t, "vehicle_registration", got.Contexts["doc"]["doc_type"])
}
