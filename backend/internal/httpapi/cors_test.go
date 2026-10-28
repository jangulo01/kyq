package httpapi

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestCORSOnlyForAllowedOrigins(t *testing.T) {
	h := NewRouter(Deps{CORSOrigins: []string{"http://localhost:8090"}})
	call := func(method, origin string, preflight bool) *httptest.ResponseRecorder {
		req := httptest.NewRequest(method, "/healthz", nil)
		if origin != "" {
			req.Header.Set("Origin", origin)
		}
		if preflight {
			req.Header.Set("Access-Control-Request-Method", "GET")
		}
		rec := httptest.NewRecorder()
		h.ServeHTTP(rec, req)
		return rec
	}

	ok := call(http.MethodGet, "http://localhost:8090", false)
	assert.Equal(t, http.StatusOK, ok.Code)
	assert.Equal(t, "http://localhost:8090", ok.Header().Get("Access-Control-Allow-Origin"))

	pre := call(http.MethodOptions, "http://localhost:8090", true)
	assert.Equal(t, http.StatusNoContent, pre.Code)
	assert.Contains(t, pre.Header().Get("Access-Control-Allow-Headers"), "Authorization")

	other := call(http.MethodGet, "https://evil.example", false)
	assert.Empty(t, other.Header().Get("Access-Control-Allow-Origin"), "otro origen no recibe permiso")

	off := NewRouter(Deps{})
	rec := httptest.NewRecorder()
	req := httptest.NewRequest(http.MethodGet, "/healthz", nil)
	req.Header.Set("Origin", "http://localhost:8090")
	off.ServeHTTP(rec, req)
	assert.Empty(t, rec.Header().Get("Access-Control-Allow-Origin"), "sin lista no hay CORS")
}
