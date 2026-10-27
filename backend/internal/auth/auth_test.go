package auth

import (
	"context"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

const devCode = "123456"

type clock struct{ t time.Time }

func (c *clock) now() time.Time { return c.t }

func newTestService() (*Service, *MemRepo, *clock, *TokenIssuer) {
	c := &clock{t: time.Date(2026, 10, 27, 12, 0, 0, 0, time.UTC)}
	repo := NewMemRepo()
	issuer := NewTokenIssuer([]byte("test-secret-test-secret-test-secret!"), c.now)
	return NewService(repo, DevOTP{Code: devCode}, issuer, c.now), repo, c, issuer
}

func TestRequestOTPValidatesPhoneAndRateLimits(t *testing.T) {
	svc, _, c, _ := newTestService()
	ctx := context.Background()

	assert.ErrorIs(t, svc.RequestOTP(ctx, "3001234567"), ErrInvalidPhone)
	for range 5 {
		require.NoError(t, svc.RequestOTP(ctx, "+573001234567"))
	}
	assert.ErrorIs(t, svc.RequestOTP(ctx, "+573001234567"), ErrRateLimited)
	assert.NoError(t, svc.RequestOTP(ctx, "+573009999999"), "el límite es por teléfono")

	c.t = c.t.Add(time.Hour + time.Second)
	assert.NoError(t, svc.RequestOTP(ctx, "+573001234567"), "la ventana es de una hora")
}

func TestVerifyOTP(t *testing.T) {
	svc, repo, _, issuer := newTestService()
	ctx := context.Background()

	_, err := svc.VerifyOTP(ctx, "+573001234567", "000000", "Ana")
	assert.ErrorIs(t, err, ErrInvalidCode)

	_, err = svc.VerifyOTP(ctx, "+573001234567", devCode, " ")
	assert.ErrorIs(t, err, ErrDisplayNameRequired, "un teléfono nuevo necesita nombre")

	tokens, err := svc.VerifyOTP(ctx, "+573001234567", devCode, "Ana")
	require.NoError(t, err)
	assert.Equal(t, RolePassenger, tokens.Role, "los registros nuevos son pasajeros")
	p, err := issuer.ParseAccess(tokens.AccessToken)
	require.NoError(t, err)
	user, err := repo.GetUserByPhone(ctx, "+573001234567")
	require.NoError(t, err)
	assert.Equal(t, user.ID, p.UserID)

	again, err := svc.VerifyOTP(ctx, "+573001234567", devCode, "")
	require.NoError(t, err, "un usuario existente no necesita nombre")
	assert.Equal(t, RolePassenger, again.Role)
}

func TestVerifyOTPKeepsExistingRole(t *testing.T) {
	svc, repo, _, _ := newTestService()
	ctx := context.Background()
	_, err := repo.CreateUser(ctx, User{ID: uuid.New(), Phone: "+573005555555", Role: RoleDriver, DisplayName: "Luis"})
	require.NoError(t, err)

	tokens, err := svc.VerifyOTP(ctx, "+573005555555", devCode, "")
	require.NoError(t, err)
	assert.Equal(t, RoleDriver, tokens.Role)
}

func TestAccessTokenExpiresAfter15Minutes(t *testing.T) {
	svc, _, c, issuer := newTestService()
	tokens, err := svc.VerifyOTP(context.Background(), "+573001234567", devCode, "Ana")
	require.NoError(t, err)

	c.t = c.t.Add(14 * time.Minute)
	_, err = issuer.ParseAccess(tokens.AccessToken)
	assert.NoError(t, err)

	c.t = c.t.Add(2 * time.Minute)
	_, err = issuer.ParseAccess(tokens.AccessToken)
	assert.Error(t, err)
}

func TestRefreshRotationAndReuseDetection(t *testing.T) {
	svc, _, c, _ := newTestService()
	ctx := context.Background()
	first, err := svc.VerifyOTP(ctx, "+573001234567", devCode, "Ana")
	require.NoError(t, err)

	second, err := svc.Refresh(ctx, first.RefreshToken)
	require.NoError(t, err)
	assert.NotEqual(t, first.RefreshToken, second.RefreshToken, "cada refresco emite un token nuevo")

	_, err = svc.Refresh(ctx, first.RefreshToken)
	assert.ErrorIs(t, err, ErrInvalidRefreshToken, "reutilizar un token rotado falla")
	_, err = svc.Refresh(ctx, second.RefreshToken)
	assert.ErrorIs(t, err, ErrInvalidRefreshToken, "la reutilización revoca todas las sesiones")

	third, err := svc.VerifyOTP(ctx, "+573001234567", devCode, "")
	require.NoError(t, err)
	c.t = c.t.Add(30*24*time.Hour + time.Second)
	_, err = svc.Refresh(ctx, third.RefreshToken)
	assert.ErrorIs(t, err, ErrInvalidRefreshToken, "caduca a los 30 días")

	_, err = svc.Refresh(ctx, "desconocido")
	assert.ErrorIs(t, err, ErrInvalidRefreshToken)
}

func TestRequireAuthAndRole(t *testing.T) {
	_, _, _, issuer := newTestService()
	ok := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) { w.WriteHeader(http.StatusOK) })
	h := RequireAuth(issuer)(RequireRole(RoleAdmin)(ok))

	call := func(token string) int {
		req := httptest.NewRequest(http.MethodGet, "/", nil)
		if token != "" {
			req.Header.Set("Authorization", "Bearer "+token)
		}
		rec := httptest.NewRecorder()
		h.ServeHTTP(rec, req)
		return rec.Code
	}

	admin, err := issuer.IssueAccess(Principal{UserID: uuid.New(), Role: RoleAdmin})
	require.NoError(t, err)
	passenger, err := issuer.IssueAccess(Principal{UserID: uuid.New(), Role: RolePassenger})
	require.NoError(t, err)

	assert.Equal(t, http.StatusUnauthorized, call(""))
	assert.Equal(t, http.StatusUnauthorized, call("basura"))
	assert.Equal(t, http.StatusForbidden, call(passenger))
	assert.Equal(t, http.StatusOK, call(admin))
}
