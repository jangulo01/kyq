package auth

import (
	"context"
	"fmt"
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

	assert.ErrorIs(t, svc.RequestOTP(ctx, "3001234567", "10.0.0.1"), ErrInvalidPhone)
	for range 5 {
		require.NoError(t, svc.RequestOTP(ctx, "+573001234567", "10.0.0.1"))
	}
	assert.ErrorIs(t, svc.RequestOTP(ctx, "+573001234567", "10.0.0.1"), ErrRateLimited)
	assert.NoError(t, svc.RequestOTP(ctx, "+573009999999", "10.0.0.1"), "el límite es por teléfono")

	c.t = c.t.Add(time.Hour + time.Second)
	assert.NoError(t, svc.RequestOTP(ctx, "+573001234567", "10.0.0.1"), "la ventana es de una hora")
}

// Bombeo de SMS: muchos teléfonos distintos desde una IP, o fuera de los países atendidos.
func TestRequestOTPAgainstSMSPumping(t *testing.T) {
	svc, _, _, _ := newTestService()
	ctx := context.Background()

	assert.ErrorIs(t, svc.RequestOTP(ctx, "+447700900123", "10.0.0.2"), ErrCountryNotServed)
	assert.NoError(t, svc.RequestOTP(ctx, "+51987654321", "10.0.0.2"), "Perú está atendido")

	for i := range 20 {
		require.NoError(t, svc.RequestOTP(ctx, fmt.Sprintf("+57300000%04d", i), "10.0.0.3"))
	}
	assert.ErrorIs(t, svc.RequestOTP(ctx, "+573009999998", "10.0.0.3"), ErrRateLimited, "20 por IP y hora")
	assert.NoError(t, svc.RequestOTP(ctx, "+573009999998", "10.0.0.4"), "otra IP sigue pudiendo")
}

func TestBlockedIPDoesNotSpendPhoneBudget(t *testing.T) {
	svc, _, _, _ := newTestService()
	ctx := context.Background()
	for i := range 20 {
		require.NoError(t, svc.RequestOTP(ctx, fmt.Sprintf("+57300000%04d", i), "10.0.0.9"))
	}
	for range 10 {
		assert.ErrorIs(t, svc.RequestOTP(ctx, "+573001234567", "10.0.0.9"), ErrRateLimited)
	}
	assert.NoError(t, svc.RequestOTP(ctx, "+573001234567", "10.0.0.10"), "la víctima conserva su cupo")
}

func TestIPv6GroupedBy64(t *testing.T) {
	assert.Equal(t, ipKey("2001:db8:1:2::1"), ipKey("2001:db8:1:2:ffff::9"))
	assert.NotEqual(t, ipKey("2001:db8:1:2::1"), ipKey("2001:db8:1:3::1"))
	assert.Equal(t, "10.0.0.1", ipKey("10.0.0.1"))
}

func TestNewPhoneCapSparesExistingUsers(t *testing.T) {
	svc, repo, _, _ := newTestService()
	ctx := context.Background()
	svc.newPhoneCap = newRateLimiter(3, time.Hour) // techo pequeño para la prueba
	_, err := repo.CreateUser(ctx, User{ID: uuid.New(), Phone: "+573009990000", Role: RolePassenger, DisplayName: "Eva"})
	require.NoError(t, err)

	for i := range 3 {
		require.NoError(t, svc.RequestOTP(ctx, fmt.Sprintf("+5731000000%02d", i), fmt.Sprintf("10.2.0.%d", i)))
	}
	assert.ErrorIs(t, svc.RequestOTP(ctx, "+573100000099", "10.2.0.99"), ErrRateLimited, "techo de números nuevos")
	assert.NoError(t, svc.RequestOTP(ctx, "+573009990000", "10.2.0.100"), "un usuario existente siempre puede entrar")
}

func TestIPv6RotationWithin48IsCapped(t *testing.T) {
	svc, _, _, _ := newTestService()
	ctx := context.Background()
	for i := range 60 {
		require.NoError(t, svc.RequestOTP(ctx, fmt.Sprintf("+5731100%05d", i), fmt.Sprintf("2001:db8:1:%x::1", i)))
	}
	assert.ErrorIs(t, svc.RequestOTP(ctx, "+573119999999", "2001:db8:1:ffff::1"), ErrRateLimited,
		"rotar /64 dentro de la misma /48 no esquiva el límite")
	assert.NoError(t, svc.RequestOTP(ctx, "+573119999999", "2001:db8:2::1"), "otra /48 no se ve afectada")
}

func TestGlobalVolumeDoesNotBlock(t *testing.T) {
	svc, _, _, _ := newTestService()
	ctx := context.Background()
	for i := range 520 {
		require.NoError(t, svc.RequestOTP(ctx, fmt.Sprintf("+5730%08d", i), fmt.Sprintf("10.1.%d.%d", i/250, i%250)))
	}
}

func TestRateLimiterSweepsStaleKeys(t *testing.T) {
	l := newRateLimiter(1, time.Minute)
	start := time.Date(2026, 1, 1, 0, 0, 0, 0, time.UTC)
	for i := range sweepEvery - 1 {
		l.allow(fmt.Sprint(i), start)
	}
	l.allow("nuevo", start.Add(2*time.Minute))
	assert.Equal(t, 1, l.size(), "las claves caducadas se eliminan")
}

func TestVerifyOTP(t *testing.T) {
	svc, repo, _, issuer := newTestService()
	ctx := context.Background()

	_, err := svc.VerifyOTP(ctx, "+573001234567", "000000", "Ana", "")
	assert.ErrorIs(t, err, ErrInvalidCode)

	_, err = svc.VerifyOTP(ctx, "+573001234567", devCode, " ", "")
	assert.ErrorIs(t, err, ErrDisplayNameRequired, "un teléfono nuevo necesita nombre")

	tokens, err := svc.VerifyOTP(ctx, "+573001234567", devCode, "Ana", "")
	require.NoError(t, err)
	assert.Equal(t, RolePassenger, tokens.Role, "los registros nuevos son pasajeros")
	p, err := issuer.ParseAccess(tokens.AccessToken)
	require.NoError(t, err)
	user, err := repo.GetUserByPhone(ctx, "+573001234567")
	require.NoError(t, err)
	assert.Equal(t, user.ID, p.UserID)

	again, err := svc.VerifyOTP(ctx, "+573001234567", devCode, "", "")
	require.NoError(t, err, "un usuario existente no necesita nombre")
	assert.Equal(t, RolePassenger, again.Role)
}

func TestVerifyOTPKeepsExistingRole(t *testing.T) {
	svc, repo, _, _ := newTestService()
	ctx := context.Background()
	_, err := repo.CreateUser(ctx, User{ID: uuid.New(), Phone: "+573005555555", Role: RoleDriver, DisplayName: "Luis"})
	require.NoError(t, err)

	tokens, err := svc.VerifyOTP(ctx, "+573005555555", devCode, "", "")
	require.NoError(t, err)
	assert.Equal(t, RoleDriver, tokens.Role)
}

func TestAccessTokenExpiresAfter15Minutes(t *testing.T) {
	svc, _, c, issuer := newTestService()
	tokens, err := svc.VerifyOTP(context.Background(), "+573001234567", devCode, "Ana", "")
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
	first, err := svc.VerifyOTP(ctx, "+573001234567", devCode, "Ana", "")
	require.NoError(t, err)

	second, err := svc.Refresh(ctx, first.RefreshToken)
	require.NoError(t, err)
	assert.NotEqual(t, first.RefreshToken, second.RefreshToken, "cada refresco emite un token nuevo")

	_, err = svc.Refresh(ctx, first.RefreshToken)
	assert.ErrorIs(t, err, ErrInvalidRefreshToken, "reutilizar un token rotado falla")
	_, err = svc.Refresh(ctx, second.RefreshToken)
	assert.ErrorIs(t, err, ErrInvalidRefreshToken, "la reutilización revoca todas las sesiones")

	third, err := svc.VerifyOTP(ctx, "+573001234567", devCode, "", "")
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

// FR-001/FR-003 (002): alta autónoma como conductor y un rol por teléfono.
func TestVerifyOTPDriverSignUpAndOneRolePerPhone(t *testing.T) {
	svc, repo, _, _ := newTestService()
	ctx := context.Background()

	_, err := svc.VerifyOTP(ctx, "+573101112233", devCode, "Luis", "admin")
	assert.ErrorIs(t, err, ErrInvalidRole, "nadie se registra como admin")

	tokens, err := svc.VerifyOTP(ctx, "+573101112233", devCode, "Luis", RoleDriver)
	require.NoError(t, err)
	assert.Equal(t, RoleDriver, tokens.Role)
	u, err := repo.GetUserByPhone(ctx, "+573101112233")
	require.NoError(t, err)
	assert.Equal(t, RoleDriver, u.Role)

	again, err := svc.VerifyOTP(ctx, "+573101112233", devCode, "", RoleDriver)
	require.NoError(t, err, "el conductor vuelve a entrar con su rol")
	assert.Equal(t, RoleDriver, again.Role)

	_, err = svc.VerifyOTP(ctx, "+573200000002", devCode, "Ana", "")
	require.NoError(t, err)
	_, err = svc.VerifyOTP(ctx, "+573200000002", devCode, "", RoleDriver)
	assert.ErrorIs(t, err, ErrPhoneHasOtherRole, "un pasajero no se registra como conductor")
	_, err = svc.VerifyOTP(ctx, "+573101112233", devCode, "", RolePassenger)
	assert.ErrorIs(t, err, ErrPhoneHasOtherRole)

	rec := httptest.NewRecorder()
	writeAuthError(rec, httptest.NewRequest(http.MethodPost, "/", nil), ErrPhoneHasOtherRole)
	assert.Equal(t, http.StatusConflict, rec.Code)
	assert.Contains(t, rec.Body.String(), "phone_has_other_role")
}
