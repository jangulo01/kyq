package auth

import (
	"context"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/kyq/backend/internal/testdb"
)

// FR-001 (002): el alta como conductor crea usuario, conductor y QR en una transacción.
func TestIntegrationDriverSignUpCreatesDriverProfile(t *testing.T) {
	st := testdb.New(t)
	ctx := context.Background()
	now := func() time.Time { return time.Date(2026, 10, 27, 12, 0, 0, 0, time.UTC) }
	issuer := NewTokenIssuer([]byte("test-secret-test-secret-test-secret!"), now)
	svc := NewService(NewPgRepo(st), DevOTP{Code: devCode}, issuer, now)

	tokens, err := svc.VerifyOTP(ctx, "+573101112233", devCode, "Luis Pérez", RoleDriver)
	require.NoError(t, err)
	p, err := issuer.ParseAccess(tokens.AccessToken)
	require.NoError(t, err)
	assert.Equal(t, RoleDriver, p.Role)

	profile, err := st.GetDriverProfile(ctx, p.UserID)
	require.NoError(t, err, "existe el perfil de conductor")
	assert.Len(t, profile.QrToken, 22, "QR de 128 bits")
	assert.False(t, profile.PaidUntil.Valid, "sin suscripción")

	_, err = svc.VerifyOTP(ctx, "+573200000002", devCode, "Ana", "")
	require.NoError(t, err)
	_, err = svc.VerifyOTP(ctx, "+573200000002", devCode, "", RoleDriver)
	assert.ErrorIs(t, err, ErrPhoneHasOtherRole)
}
