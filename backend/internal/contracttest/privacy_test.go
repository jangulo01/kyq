package contracttest

import (
	"bytes"
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"sync"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/kyq/backend/internal/affiliations"
	"github.com/kyq/backend/internal/auth"
	"github.com/kyq/backend/internal/drivers"
	"github.com/kyq/backend/internal/fares"
	"github.com/kyq/backend/internal/httpapi"
	"github.com/kyq/backend/internal/kyc"
	"github.com/kyq/backend/internal/notify"
	"github.com/kyq/backend/internal/ptt"
	"github.com/kyq/backend/internal/realtime"
	"github.com/kyq/backend/internal/storage"
	"github.com/kyq/backend/internal/store"
	"github.com/kyq/backend/internal/testdb"
	"github.com/kyq/backend/internal/trippay"
	"github.com/kyq/backend/internal/trips"
)

type fixedRoute struct{}

func (fixedRoute) Route(context.Context, float64, float64, float64, float64) (fares.Route, error) {
	return fares.Route{DistanceM: 5200, DurationS: 900}, nil
}

type noRooms struct{}

func (noRooms) CreateRoom(context.Context, string) error                  { return nil }
func (noRooms) DeleteRoom(context.Context, string) error                  { return nil }
func (noRooms) SetCanPublish(context.Context, string, string, bool) error { return nil }

// wire records every published event as JSON.
type wire struct {
	mu     sync.Mutex
	events []string
}

func (w *wire) Publish(_ context.Context, channel string, ev realtime.Event) error {
	raw, err := json.Marshal(ev)
	if err != nil {
		return err
	}
	w.mu.Lock()
	defer w.mu.Unlock()
	w.events = append(w.events, channel+" "+string(raw))
	return nil
}

// TestIntegrationNoPhoneNumbersReachTheOtherParty runs a whole trip through the real router and
// checks that neither party's phone appears in any response or realtime event (FR-020). Only the
// admin endpoints return phones, and they are not part of this flow.
func TestIntegrationNoPhoneNumbersReachTheOtherParty(t *testing.T) {
	st := testdb.New(t)
	ctx := context.Background()
	const driverPhone, passengerPhone = "+573100000001", "+573200000002"
	driver, passenger, admin := uuid.New(), uuid.New(), uuid.New()
	for _, u := range []store.CreateUserParams{
		{ID: admin, PhoneE164: "+573000000001", Role: store.UserRoleAdmin, DisplayName: "Admin"},
		{ID: driver, PhoneE164: driverPhone, Role: store.UserRoleDriver, DisplayName: "Carlos"},
		{ID: passenger, PhoneE164: passengerPhone, Role: store.UserRolePassenger, DisplayName: "Ana"},
	} {
		_, err := st.CreateUser(ctx, u)
		require.NoError(t, err)
	}
	require.NoError(t, st.CreateDriver(ctx, store.CreateDriverParams{UserID: driver, QrToken: "qr-carlos-0000000", VehiclePlate: "KYQ001", VehicleDescription: "Kia"}))
	require.NoError(t, st.SetDriverPresence(ctx, store.SetDriverPresenceParams{UserID: driver, Presence: store.DriverPresenceFree}))
	require.NoError(t, st.UpsertFareTable(ctx, store.UpsertFareTableParams{
		CityCode: "bogota", Currency: "COP", BaseMinor: 400_000, PerKmMinor: 120_000, PerMinuteMinor: 30_000,
		MinimumMinor: 700_000, RoundingMinor: 10_000, UpdatedBy: admin,
	}))

	// FR-011 (002): el conductor tiene documentos con número y fotos en el bucket privado.
	const docNumber = "1020304050"
	docID := uuid.New()
	_, err := st.InsertDocument(ctx, store.InsertDocumentParams{
		ID: docID, DriverID: driver, DocType: store.DriverDocTypeNationalID, Number: docNumber,
		Status: store.DocumentStatusApproved, ReviewedBy: uuid.NullUUID{UUID: admin, Valid: true},
	})
	require.NoError(t, err)
	photoKey := kyc.ObjectKey(driver, docID, "front")
	require.NoError(t, st.InsertDocumentPhoto(ctx, store.InsertDocumentPhotoParams{DocumentID: docID, Side: store.DocumentSideFront, ObjectKey: photoKey}))
	objects := storage.NewMemory()
	objects.Put(photoKey, []byte("jpeg"), "image/jpeg")

	pub := &wire{}
	tokens := auth.NewTokenIssuer([]byte("test-secret-test-secret-test-secret!"), nil)
	// 004: el pago del viaje tampoco expone teléfonos a la otra parte.
	tripPay := &trippay.Service{Store: st, Notify: &notify.Service{Store: st, Publisher: pub}, Publisher: pub}
	tripService := &trips.Service{Store: st, Routes: fixedRoute{}, Publisher: pub, CityCode: "bogota", Payments: tripPay}
	server := httpapi.NewRouter(httpapi.Deps{
		Tokens:   tokens,
		Affils:   &affiliations.Handlers{Service: affiliations.NewService(affiliations.NewPgRepo(st.Queries))},
		Drivers:  &drivers.Handlers{Store: st},
		Presence: &drivers.Presence{Store: st, Routes: fixedRoute{}, Publisher: pub},
		Trips:    &trips.Handlers{Service: tripService},
		TripPay:  &trippay.Handlers{Service: tripPay},
		KYC:      &kyc.Handlers{Service: &kyc.Service{Store: st, Objects: objects, Notify: &notify.Service{Store: st, Publisher: pub}}},
		PTT: &ptt.Handlers{Service: &ptt.Service{
			Store: st, LiveKit: ptt.LiveKit{APIKey: "devkey", APISecret: "secret"}, Rooms: noRooms{}, Publisher: pub,
		}},
	})
	bearer := func(id uuid.UUID, role string) string {
		tok, err := tokens.IssueAccess(auth.Principal{UserID: id, Role: role})
		require.NoError(t, err)
		return tok
	}
	asDriver, asPassenger := bearer(driver, auth.RoleDriver), bearer(passenger, auth.RolePassenger)

	var bodies, passengerBodies []string
	call := func(method, path, token string, body any) map[string]any {
		var raw []byte
		if body != nil {
			var err error
			raw, err = json.Marshal(body)
			require.NoError(t, err)
		}
		req := httptest.NewRequest(method, path, bytes.NewReader(raw))
		req.Header.Set("Authorization", "Bearer "+token)
		req.Header.Set("Content-Type", "application/json")
		rec := httptest.NewRecorder()
		server.ServeHTTP(rec, req)
		require.Less(t, rec.Code, 300, "%s %s: %s", method, path, rec.Body.String())
		bodies = append(bodies, method+" "+path+" "+rec.Body.String())
		if token == asPassenger {
			passengerBodies = append(passengerBodies, method+" "+path+" "+rec.Body.String())
		}
		var out map[string]any
		_ = json.Unmarshal(rec.Body.Bytes(), &out)
		return out
	}

	route := map[string]any{"pickup": map[string]float64{"lat": 4.60, "lng": -74.08}, "dropoff": map[string]float64{"lat": 4.65, "lng": -74.05}}
	call(http.MethodPost, "/v1/affiliations", asPassenger, map[string]string{"qr_token": "qr-carlos-0000000"})
	call(http.MethodGet, "/v1/affiliations", asPassenger, nil)
	call(http.MethodGet, "/v1/driver/clients", asDriver, nil)
	call(http.MethodGet, "/v1/driver/me", asDriver, nil)
	call(http.MethodPost, "/v1/fares/quote", asPassenger, route)
	trip := call(http.MethodPost, "/v1/trips", asPassenger, map[string]any{
		"driver_id": driver, "pickup": route["pickup"], "dropoff": route["dropoff"],
	})
	base := "/v1/trips/" + trip["id"].(string)
	call(http.MethodPost, base+"/accept", asDriver, map[string]any{})
	for _, tok := range []string{asDriver, asPassenger} {
		call(http.MethodGet, base, tok, nil)
		call(http.MethodGet, "/v1/trips/active", tok, nil)
		call(http.MethodPost, base+"/ptt/token", tok, nil)
	}
	call(http.MethodPost, "/v1/driver/location", asDriver, map[string]any{
		"lat": 4.61, "lng": -74.07, "recorded_at": time.Now().UTC().Format(time.RFC3339),
	})
	for _, step := range []string{"arrive", "start", "complete"} {
		call(http.MethodPost, base+"/"+step, asDriver, nil)
	}
	call(http.MethodGet, "/v1/trip-payments/pending", asPassenger, nil)
	call(http.MethodPost, base+"/payment/cash", asPassenger, nil)
	call(http.MethodPost, base+"/payment/cash-received", asDriver, nil)
	for _, tok := range []string{asDriver, asPassenger} {
		call(http.MethodGet, base+"/payment", tok, nil)
	}
	call(http.MethodGet, "/v1/driver/settlement", asDriver, nil)

	require.NotEmpty(t, pub.events)
	for _, seen := range append(bodies, pub.events...) {
		for _, phone := range []string{driverPhone, passengerPhone, strings.TrimPrefix(driverPhone, "+57"), strings.TrimPrefix(passengerPhone, "+57")} {
			assert.NotContains(t, seen, phone)
		}
		assert.NotContains(t, seen, "phone", "ningún campo de teléfono fuera de admin")
	}

	// FR-011: ni el número ni las fotos (claves u URLs firmadas) de los documentos llegan al
	// pasajero, y no viajan en eventos en tiempo real.
	require.NotEmpty(t, passengerBodies)
	for _, seen := range append(passengerBodies, pub.events...) {
		assert.NotContains(t, seen, docNumber)
		assert.NotContains(t, seen, "kyc/")
		assert.NotContains(t, seen, "X-Amz")
		assert.NotContains(t, seen, docID.String())
	}
	for _, path := range []string{"/v1/driver/onboarding", "/v1/admin/kyc/drivers/" + driver.String(), "/v1/admin/kyc/queue"} {
		req := httptest.NewRequest(http.MethodGet, path, nil)
		req.Header.Set("Authorization", "Bearer "+asPassenger)
		rec := httptest.NewRecorder()
		server.ServeHTTP(rec, req)
		assert.Equal(t, http.StatusForbidden, rec.Code, path)
		assert.NotContains(t, rec.Body.String(), docNumber)
	}
}

// TestIntegrationSharedTripAndSOSKeepPrivacy (003, FR-006, FR-015, SC-006): el enlace público del
// viaje no expone teléfonos, documentos ni pagos, y los eventos SOS solo llegan a la consola y a
// quien pidió ayuda; la otra parte del viaje no recibe nada.
func TestIntegrationSharedTripAndSOSKeepPrivacy(t *testing.T) {
	pub := &wire{}
	f := newSafetyFixture(t, pub)
	ctx := context.Background()
	const driverPhone, passengerPhone, contactPhone = "+573100000001", "+573200000002", "+573001110001"
	tripID := f.acceptedTrip(t).String()
	require.NoError(t, f.st.SetDriverLocation(ctx, store.SetDriverLocationParams{Lat: 4.61, Lng: -74.07, RecordedAt: time.Now(), UserID: f.driver}))

	call := func(method, path, token string, body any) (int, string) {
		var raw []byte
		if body != nil {
			var err error
			raw, err = json.Marshal(body)
			require.NoError(t, err)
		}
		req := httptest.NewRequest(method, path, bytes.NewReader(raw))
		if token != "" {
			req.Header.Set("Authorization", "Bearer "+token)
		}
		req.Header.Set("Content-Type", "application/json")
		rec := httptest.NewRecorder()
		f.server.ServeHTTP(rec, req)
		return rec.Code, rec.Body.String()
	}
	code, _ := call(http.MethodPut, "/v1/me/emergency-contacts", f.asPx, map[string]any{"contacts": []map[string]string{
		{"name": "Mamá", "phone_e164": contactPhone},
	}})
	require.Equal(t, http.StatusOK, code)

	code, body := call(http.MethodPost, "/v1/trips/"+tripID+"/share", f.asPx, nil)
	require.Equal(t, http.StatusOK, code, body)
	var link struct{ Token string }
	require.NoError(t, json.Unmarshal([]byte(body), &link))
	var public []string
	for _, path := range []string{"/v1/share/" + link.Token, "/s/" + link.Token} {
		code, body := call(http.MethodGet, path, "", nil)
		require.Equal(t, http.StatusOK, code, path)
		public = append(public, body)
	}
	assert.Contains(t, public[0], "KYQ001", "placa visible")

	code, body = call(http.MethodPost, "/v1/trips/"+tripID+"/sos", f.asPx, map[string]any{"location": map[string]float64{"lat": 4.61, "lng": -74.07}})
	require.Equal(t, http.StatusCreated, code, body)
	var raised struct{ Alert struct{ ID string } }
	require.NoError(t, json.Unmarshal([]byte(body), &raised))
	code, _ = call(http.MethodPost, "/v1/sos/"+raised.Alert.ID+"/locations", f.asPx, map[string]any{"points": []map[string]float64{{"lat": 4.62, "lng": -74.06}}})
	require.Equal(t, http.StatusOK, code)
	code, _ = call(http.MethodPost, "/v1/ops/sos/"+raised.Alert.ID+"/claim", f.asOperator, nil)
	require.Equal(t, http.StatusOK, code)
	code, _ = call(http.MethodPost, "/v1/ops/sos/"+raised.Alert.ID+"/close", f.asOperator, map[string]string{"outcome": "resolved"})
	require.Equal(t, http.StatusNoContent, code)

	// Lo que ve el conductor durante el SOS del pasajero: nada del SOS.
	for _, path := range []string{"/v1/sos/active", "/v1/trips/" + tripID} {
		_, body := call(http.MethodGet, path, f.asDriver, nil)
		assert.NotContains(t, body, raised.Alert.ID, path)
		assert.NotContains(t, body, "sos", path)
	}

	require.NotEmpty(t, pub.events)
	for _, seen := range append(public, pub.events...) {
		for _, phone := range []string{driverPhone, passengerPhone, contactPhone, strings.TrimPrefix(driverPhone, "+57"), strings.TrimPrefix(passengerPhone, "+57")} {
			assert.NotContains(t, seen, phone)
		}
		assert.NotContains(t, seen, "phone")
		assert.NotContains(t, seen, "kyc/")
	}
	for _, seen := range public {
		assert.NotContains(t, seen, "fare", "ni datos de pago en el enlace público")
		assert.NotContains(t, seen, f.passenger.String())
	}
	for _, ev := range pub.events {
		channel := strings.SplitN(ev, " ", 2)[0]
		if strings.Contains(ev, raised.Alert.ID) || strings.Contains(ev, `"type":"sos.`) {
			assert.True(t, channel == realtime.OpsSOSChannel || channel == "sos:"+raised.Alert.ID || channel == "user:"+f.passenger.String(),
				"evento SOS fuera de la consola: %s", ev)
		}
	}
}
