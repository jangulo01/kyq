package admin

import (
	"bytes"
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/kyq/backend/internal/auth"
	"github.com/kyq/backend/internal/store"
	"github.com/kyq/backend/internal/testdb"
)

func TestAdminDriverLifecycle(t *testing.T) {
	st := testdb.New(t)
	ctx := context.Background()
	now := time.Date(2026, 10, 27, 12, 0, 0, 0, time.UTC)
	adminID := uuid.New()
	_, err := st.CreateUser(ctx, store.CreateUserParams{ID: adminID, PhoneE164: "+573000000000", Role: store.UserRoleAdmin, DisplayName: "Admin"})
	require.NoError(t, err)

	issuer := auth.NewTokenIssuer([]byte("test-secret-test-secret-test-secret!"), func() time.Time { return now })
	adminToken, err := issuer.IssueAccess(auth.Principal{UserID: adminID, Role: auth.RoleAdmin})
	require.NoError(t, err)
	passengerToken, err := issuer.IssueAccess(auth.Principal{UserID: uuid.New(), Role: auth.RolePassenger})
	require.NoError(t, err)

	mux := http.NewServeMux()
	(&Handlers{Store: st, Now: func() time.Time { return now }}).Register(mux, auth.RequireAuth(issuer))

	do := func(token, method, path string, body any) *httptest.ResponseRecorder {
		var buf bytes.Buffer
		if body != nil {
			require.NoError(t, json.NewEncoder(&buf).Encode(body))
		}
		req := httptest.NewRequest(method, path, &buf)
		req.Header.Set("Authorization", "Bearer "+token)
		rec := httptest.NewRecorder()
		mux.ServeHTTP(rec, req)
		return rec
	}

	assert.Equal(t, http.StatusForbidden, do(passengerToken, http.MethodGet, "/v1/admin/drivers", nil).Code)

	rec := do(adminToken, http.MethodPost, "/v1/admin/drivers", map[string]string{
		"phone_e164": "+573001112233", "display_name": "Carlos", "vehicle_plate": "abc123", "vehicle_description": "Kia Picanto gris",
	})
	require.Equal(t, http.StatusCreated, rec.Code, rec.Body.String())
	var created struct {
		DriverID uuid.UUID `json:"driver_id"`
		QRToken  string    `json:"qr_token"`
	}
	require.NoError(t, json.NewDecoder(rec.Body).Decode(&created))
	assert.Len(t, created.QRToken, 22, "128 bits en base64url")

	dup := do(adminToken, http.MethodPost, "/v1/admin/drivers", map[string]string{
		"phone_e164": "+573001112233", "display_name": "Otro", "vehicle_plate": "x", "vehicle_description": "y",
	})
	assert.Equal(t, http.StatusConflict, dup.Code)

	base := "/v1/admin/drivers/" + created.DriverID.String()
	require.Equal(t, http.StatusOK, do(adminToken, http.MethodPut, base+"/subscription", map[string]any{"paid_until": now.Add(30 * 24 * time.Hour)}).Code)
	for _, doc := range []string{"license", "mandatory_insurance"} {
		require.Equal(t, http.StatusOK, do(adminToken, http.MethodPut, base+"/documents/"+doc, map[string]any{"expires_at": "2027-06-30", "approved": true}).Code)
	}

	list := func() DriverSummary {
		rec := do(adminToken, http.MethodGet, "/v1/admin/drivers", nil)
		require.Equal(t, http.StatusOK, rec.Code)
		var out []DriverSummary
		require.NoError(t, json.NewDecoder(rec.Body).Decode(&out))
		require.Len(t, out, 1)
		return out[0]
	}
	d := list()
	assert.Equal(t, "ABC123", d.VehiclePlate)
	assert.Equal(t, "active", d.SubscriptionStatus)
	assert.False(t, d.CanGoOnline, "falta un documento")
	require.NotNil(t, d.BlockReason)
	assert.Equal(t, "kyc_expired", *d.BlockReason)

	require.Equal(t, http.StatusOK, do(adminToken, http.MethodPut, base+"/documents/vehicle_registration", map[string]any{"expires_at": "2027-06-30", "approved": true}).Code)
	assert.True(t, list().CanGoOnline)

	assert.Equal(t, http.StatusBadRequest, do(adminToken, http.MethodPut, base+"/documents/passport", map[string]any{"expires_at": "2027-06-30", "approved": true}).Code)
	assert.Equal(t, http.StatusNotFound, do(adminToken, http.MethodPut, "/v1/admin/drivers/"+uuid.NewString()+"/subscription", map[string]any{"paid_until": now}).Code)
}
