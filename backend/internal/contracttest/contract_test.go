// Package contracttest checks real handler responses against contracts/api.yaml.
package contracttest

import (
	"bytes"
	"context"
	"encoding/json"
	"io"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/getkin/kin-openapi/openapi3"
	"github.com/getkin/kin-openapi/openapi3filter"
	"github.com/getkin/kin-openapi/routers"
	"github.com/getkin/kin-openapi/routers/legacy"
	"github.com/stretchr/testify/require"

	"github.com/kyq/backend/internal/auth"
	"github.com/kyq/backend/internal/httpapi"
	"github.com/kyq/backend/internal/realtime"
)

const specPath = "../../../specs/001-chosen-driver-trip-ptt/contracts/api.yaml"

type contract struct {
	t      *testing.T
	router routers.Router
	server http.Handler
}

func load(t *testing.T, server http.Handler) *contract {
	t.Helper()
	loader := openapi3.NewLoader()
	doc, err := loader.LoadFromFile(specPath)
	require.NoError(t, err)
	require.NoError(t, doc.Validate(loader.Context))
	r, err := legacy.NewRouter(doc)
	require.NoError(t, err)
	return &contract{t: t, router: r, server: server}
}

// call sends the request to the real handler, validates request and response against the
// contract and returns the decoded response.
func (c *contract) call(method, path, token string, body any, wantStatus int) map[string]any {
	c.t.Helper()
	var raw []byte
	if body != nil {
		var err error
		raw, err = json.Marshal(body)
		require.NoError(c.t, err)
	}
	newReq := func() *http.Request {
		req := httptest.NewRequest(method, "http://localhost:8080"+path, bytes.NewReader(raw))
		if body != nil {
			req.Header.Set("Content-Type", "application/json")
		}
		if token != "" {
			req.Header.Set("Authorization", "Bearer "+token)
		}
		return req
	}

	req := newReq()
	route, params, err := c.router.FindRoute(req)
	require.NoError(c.t, err, "ruta fuera del contrato: %s %s", method, path)
	in := &openapi3filter.RequestValidationInput{
		Request: req, PathParams: params, Route: route,
		Options: &openapi3filter.Options{AuthenticationFunc: openapi3filter.NoopAuthenticationFunc},
	}
	require.NoError(c.t, openapi3filter.ValidateRequest(context.Background(), in), "petición fuera del contrato")

	rec := httptest.NewRecorder()
	c.server.ServeHTTP(rec, newReq())
	require.Equal(c.t, wantStatus, rec.Code, rec.Body.String())

	respBody := rec.Body.Bytes()
	out := &openapi3filter.ResponseValidationInput{
		RequestValidationInput: in,
		Status:                 rec.Code,
		Header:                 rec.Header(),
		Body:                   io.NopCloser(bytes.NewReader(respBody)),
		Options:                &openapi3filter.Options{IncludeResponseStatus: true},
	}
	require.NoError(c.t, openapi3filter.ValidateResponse(context.Background(), out), "respuesta fuera del contrato")

	var decoded map[string]any
	if len(respBody) > 0 {
		require.NoError(c.t, json.Unmarshal(respBody, &decoded))
	}
	return decoded
}

func TestAuthAndRealtimeMatchContract(t *testing.T) {
	now := func() time.Time { return time.Date(2026, 10, 27, 12, 0, 0, 0, time.UTC) }
	tokens := auth.NewTokenIssuer([]byte("test-secret-test-secret-test-secret!"), now)
	server := httpapi.NewRouter(httpapi.Deps{
		Tokens: tokens,
		Auth:   auth.NewHandlers(auth.NewService(auth.NewMemRepo(), auth.DevOTP{Code: "123456"}, tokens, now)),
		Realtime: &realtime.Handlers{
			Tokens: realtime.Tokens{Secret: []byte("centrifugo-secret"), Now: now},
		},
	})
	c := load(t, server)

	c.call(http.MethodPost, "/v1/auth/otp/request", "", map[string]string{"phone_e164": "+573001234567"}, http.StatusNoContent)
	c.call(http.MethodPost, "/v1/auth/otp/request", "", map[string]string{"phone_e164": "300"}, http.StatusBadRequest)
	c.call(http.MethodPost, "/v1/auth/otp/verify", "", map[string]string{"phone_e164": "+573001234567", "code": "000000"}, http.StatusUnauthorized)

	session := c.call(http.MethodPost, "/v1/auth/otp/verify", "",
		map[string]string{"phone_e164": "+573001234567", "code": "123456", "display_name": "Ana"}, http.StatusOK)
	access := session["access_token"].(string)

	refreshed := c.call(http.MethodPost, "/v1/auth/refresh", "", map[string]string{"refresh_token": session["refresh_token"].(string)}, http.StatusOK)
	require.NotEqual(t, session["refresh_token"], refreshed["refresh_token"])
	c.call(http.MethodPost, "/v1/auth/refresh", "", map[string]string{"refresh_token": "otro"}, http.StatusUnauthorized)

	c.call(http.MethodPost, "/v1/realtime/token", access, nil, http.StatusOK)
	c.call(http.MethodPost, "/v1/realtime/subscription-token", access, map[string]string{"channel": "trip:0192f0c4-0000-7000-8000-000000000000"}, http.StatusForbidden)
}
