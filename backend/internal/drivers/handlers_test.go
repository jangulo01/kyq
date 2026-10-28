package drivers

import (
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

func TestDriverMe(t *testing.T) {
	st := testdb.New(t)
	ctx := context.Background()
	now := time.Date(2026, 10, 27, 12, 0, 0, 0, time.UTC)
	id := uuid.New()
	_, err := st.CreateUser(ctx, store.CreateUserParams{ID: id, PhoneE164: "+573001112233", Role: store.UserRoleDriver, DisplayName: "Carlos"})
	require.NoError(t, err)
	require.NoError(t, st.CreateDriver(ctx, store.CreateDriverParams{UserID: id, QrToken: "qr-carlos", VehiclePlate: "ABC123", VehicleDescription: "Kia"}))

	issuer := auth.NewTokenIssuer([]byte("test-secret-test-secret-test-secret!"), func() time.Time { return now })
	token, err := issuer.IssueAccess(auth.Principal{UserID: id, Role: auth.RoleDriver})
	require.NoError(t, err)
	mux := http.NewServeMux()
	(&Handlers{Store: st, Now: func() time.Time { return now }}).Register(mux, auth.RequireAuth(issuer))

	req := httptest.NewRequest(http.MethodGet, "/v1/driver/me", nil)
	req.Header.Set("Authorization", "Bearer "+token)
	rec := httptest.NewRecorder()
	mux.ServeHTTP(rec, req)
	require.Equal(t, http.StatusOK, rec.Code, rec.Body.String())

	var me Me
	require.NoError(t, json.NewDecoder(rec.Body).Decode(&me))
	assert.Equal(t, "qr-carlos", me.QRToken)
	assert.Equal(t, "suspended", me.SubscriptionStatus, "sin suscripción registrada")
	assert.False(t, me.CanGoOnline)
	require.NotNil(t, me.BlockReason)
	assert.Equal(t, "subscription_suspended", *me.BlockReason)
}
