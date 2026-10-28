package safety_test

import (
	"context"
	"encoding/base64"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/kyq/backend/internal/safety"
	"github.com/kyq/backend/internal/store"
	"github.com/kyq/backend/internal/trips"
)

func TestIntegrationShareLinkIsUnguessableAndPrivate(t *testing.T) {
	f := setup(t)
	ctx := context.Background()
	requested := f.trip(t, trips.StatusRequested)
	_, err := f.svc.Share(ctx, f.passenger, requested)
	assert.ErrorIs(t, err, safety.ErrShareUnavailable, "se comparte desde que el viaje está aceptado")
	_, err = f.trips.Act(ctx, f.passenger, requested, func(tr *trips.Trip, p trips.Party, now time.Time) error { return tr.Cancel(p, now) })
	require.NoError(t, err)

	tripID := f.trip(t, trips.StatusAccepted)
	_, err = f.svc.Share(ctx, f.stranger, tripID)
	assert.ErrorIs(t, err, safety.ErrNotFound)

	link, err := f.svc.Share(ctx, f.passenger, tripID)
	require.NoError(t, err)
	raw, err := base64.RawURLEncoding.DecodeString(link.Token)
	require.NoError(t, err)
	assert.Len(t, raw, 16, "128 bits aleatorios (FR-015)")
	assert.Equal(t, "https://kyq.test/s/"+link.Token, link.URL)
	again, err := f.svc.Share(ctx, f.passenger, tripID)
	require.NoError(t, err)
	assert.Equal(t, link.Token, again.Token, "un enlace por persona y viaje")
	byDriver, err := f.svc.Share(ctx, f.driver, tripID)
	require.NoError(t, err)
	assert.NotEqual(t, link.Token, byDriver.Token)

	_, err = f.svc.Shared(ctx, "AAAAAAAAAAAAAAAAAAAAAA")
	assert.ErrorIs(t, err, safety.ErrNotFound)
	_, err = f.svc.Shared(ctx, "corto")
	assert.ErrorIs(t, err, safety.ErrNotFound)

	view, err := f.svc.Shared(ctx, link.Token)
	require.NoError(t, err)
	assert.Equal(t, "ACCEPTED", view.Status)
	assert.Nil(t, view.Location, "sin ubicación del conductor todavía")
	require.NoError(t, f.st.SetDriverLocation(ctx, store.SetDriverLocationParams{Lat: 4.62, Lng: -74.06, RecordedAt: *f.clock, UserID: f.driver}))
	view, err = f.svc.Shared(ctx, link.Token)
	require.NoError(t, err)
	require.NotNil(t, view.Location)
	assert.InDelta(t, 4.62, view.Location.Lat, 1e-9)
	assert.Equal(t, f.driverName, view.DriverName)
	assert.Equal(t, "KYQ001", view.VehiclePlate)

	// FR-015: ni teléfonos ni documentos ni pagos.
	body, err := json.Marshal(view)
	require.NoError(t, err)
	for _, forbidden := range []string{driverPhone, passengerPhone, "phone", "document", "fare", "Ana", f.passenger.String(), f.driver.String()} {
		assert.NotContains(t, string(body), forbidden)
	}

	// FR-014: «Viaje finalizado» sin ubicación y nada 15 min después.
	f.finish(t, tripID)
	view, err = f.svc.Shared(ctx, link.Token)
	require.NoError(t, err)
	assert.True(t, view.Finished)
	assert.Equal(t, "FINISHED", view.Status)
	assert.Nil(t, view.Location)
	_, err = f.svc.Share(ctx, f.passenger, tripID)
	assert.ErrorIs(t, err, safety.ErrShareUnavailable)
	f.advance(safety.ShareGrace - time.Second)
	_, err = f.svc.Shared(ctx, link.Token)
	require.NoError(t, err)
	f.advance(time.Second)
	_, err = f.svc.Shared(ctx, link.Token)
	assert.ErrorIs(t, err, safety.ErrShareExpired)
}

func TestSharedPageIsPublicAndNotIndexed(t *testing.T) {
	mux := http.NewServeMux()
	deny := func(http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) { w.WriteHeader(http.StatusUnauthorized) })
	}
	(&safety.Handlers{Service: &safety.Service{}, MapStyleURL: "https://tiles.test/style.json"}).Register(mux, deny)
	rec := httptest.NewRecorder()
	mux.ServeHTTP(rec, httptest.NewRequest(http.MethodGet, "/s/AAAAAAAAAAAAAAAAAAAAAA", nil))
	require.Equal(t, http.StatusOK, rec.Code, "sin cuenta ni token")
	assert.True(t, strings.HasPrefix(rec.Header().Get("Content-Type"), "text/html"))
	assert.Equal(t, "no-store", rec.Header().Get("Cache-Control"))
	assert.Contains(t, rec.Header().Get("X-Robots-Tag"), "noindex")
	assert.Equal(t, "no-referrer", rec.Header().Get("Referrer-Policy"))
	page := rec.Body.String()
	assert.Contains(t, page, `data-tiles="https://tiles.test/style.json"`)
	assert.Contains(t, page, "maplibre-gl@4.7.1", "versión fijada")
	assert.Contains(t, page, `integrity="sha384-`)
	assert.Contains(t, page, "3000", "sondeo cada 3 s")

	rec = httptest.NewRecorder()
	mux.ServeHTTP(rec, httptest.NewRequest(http.MethodGet, "/v1/ops/sos", nil))
	assert.Equal(t, http.StatusUnauthorized, rec.Code, "la consola sí exige token")
}
