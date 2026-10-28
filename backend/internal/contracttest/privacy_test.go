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
	tripService := &trips.Service{Store: st, Routes: fixedRoute{}, Publisher: pub, CityCode: "bogota"}
	server := httpapi.NewRouter(httpapi.Deps{
		Tokens:   tokens,
		Affils:   &affiliations.Handlers{Service: affiliations.NewService(affiliations.NewPgRepo(st.Queries))},
		Drivers:  &drivers.Handlers{Store: st},
		Presence: &drivers.Presence{Store: st, Routes: fixedRoute{}, Publisher: pub},
		Trips:    &trips.Handlers{Service: tripService},
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
