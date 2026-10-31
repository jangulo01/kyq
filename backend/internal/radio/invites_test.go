package radio

import (
	"context"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/kyq/backend/internal/auth"
	"github.com/kyq/backend/internal/store"
)

func (f *fixture) get(t *testing.T, method, path string) (int, string) {
	t.Helper()
	mux := http.NewServeMux()
	(&Handlers{Service: f.svc}).Register(mux, func(h http.Handler) http.Handler { return h })
	rec := httptest.NewRecorder()
	mux.ServeHTTP(rec, httptest.NewRequest(method, path, nil))
	return rec.Code, rec.Body.String()
}

// phoneInvite returns the code of the last invitation sent by SMS to phone.
func (f *fixture) phoneInvite(t *testing.T, phone string) string {
	t.Helper()
	sms := f.sms.to(phone)
	require.NotEmpty(t, sms)
	last := sms[len(sms)-1]
	i := strings.Index(last, "/r/")
	require.Positive(t, i)
	return last[i+3 : i+13]
}

// US10, R9: la página del enlace abre la app o la tienda con el código, vence a los 14 días y
// la invitación por teléfono sirve una sola vez.
func TestIntegrationInvitePage(t *testing.T) {
	f := setup(t)
	ctx := context.Background()

	inv, err := f.svc.InviteContact(ctx, f.carlos, ContactInviteInput{})
	require.NoError(t, err)
	code, body := f.get(t, http.MethodGet, "/r/"+inv.Code)
	require.Equal(t, http.StatusOK, code)
	assert.Contains(t, body, "kyq://radio/"+inv.Code)
	assert.Contains(t, body, "https://play.test/driver?referrer=radio%3D"+inv.Code)
	assert.Contains(t, body, "Carlos")
	assert.NotContains(t, body, "+57", "sin teléfonos")

	// Canal con pasajeros: la invitación lleva a Kyq Conductor (los pasajeros entran desde su app).
	f.setPassengers(t, PassengersAllRoles)
	conv := f.channel(t, f.carlos, "Taxistas Norte", JoinOpenLink, ptr(RoleListener))
	chInv, err := f.svc.ChannelInvite(ctx, f.carlos, conv)
	require.NoError(t, err)
	_, body = f.get(t, http.MethodGet, "/r/"+chInv.Code)
	assert.Contains(t, body, "Taxistas Norte")

	// 14 días.
	f.advance(InviteTTL)
	_, err = f.svc.Preview(ctx, inv.Code)
	assert.ErrorIs(t, err, ErrInviteExpired)
	code, body = f.get(t, http.MethodGet, "/r/"+inv.Code)
	assert.Equal(t, http.StatusOK, code)
	assert.NotContains(t, body, "kyq://radio/")
	_, err = f.svc.Accept(ctx, f.jonathan, inv.Code)
	assert.ErrorIs(t, err, ErrInviteExpired)

	// Con teléfono: una sola vez.
	_, err = f.svc.InviteContact(ctx, f.carlos, ContactInviteInput{PhoneE164: "+573100000002"})
	require.NoError(t, err)
	phoneCode := f.phoneInvite(t, "+573100000002")
	_, err = f.svc.Accept(ctx, f.jonathan, phoneCode)
	require.NoError(t, err)
	_, err = f.svc.Accept(ctx, f.pedro, phoneCode)
	assert.ErrorIs(t, err, ErrInviteExpired)

	// Baja: sin cuenta, desde el enlace del SMS; no llegan más invitaciones.
	_, err = f.svc.InviteContact(ctx, f.carlos, ContactInviteInput{PhoneE164: "+573005550009"})
	require.NoError(t, err)
	optCode := f.phoneInvite(t, "+573005550009")
	code, body = f.get(t, http.MethodGet, "/r/"+optCode+"/baja")
	assert.Equal(t, http.StatusOK, code)
	assert.Contains(t, body, "¿Dejar de recibir invitaciones?")
	code, body = f.get(t, http.MethodPost, "/r/"+optCode+"/baja")
	assert.Equal(t, http.StatusOK, code)
	assert.Contains(t, body, "Listo")
	out, err := f.st.IsRadioOptedOut(ctx, "+573005550009")
	require.NoError(t, err)
	assert.True(t, out)
	_, err = f.svc.InviteContact(ctx, f.jonathan, ContactInviteInput{PhoneE164: "+573005550009"})
	require.NoError(t, err)
	assert.Len(t, f.sms.to("+573005550009"), 1, "FR-035: no se le vuelve a escribir")
}

// T030, R9: quien se registra con un teléfono invitado entra solo al contacto o canal.
func TestIntegrationInvitesAppliedOnOTP(t *testing.T) {
	f := setup(t)
	ctx := context.Background()
	authSvc := auth.NewService(auth.NewPgRepo(f.st), auth.DevOTP{Code: "123456"}, auth.NewTokenIssuer([]byte("secreto-de-prueba-0123456789abcdef"), nil), nil)
	authSvc.Invites = f.svc

	const phone = "+573005550010"
	_, err := f.svc.InviteContact(ctx, f.carlos, ContactInviteInput{PhoneE164: phone})
	require.NoError(t, err)
	// Se registra como conductor y queda en los contactos de Carlos sin abrir el enlace.
	tokens, err := authSvc.VerifyOTP(ctx, phone, "123456", "Luis", auth.RoleDriver)
	require.NoError(t, err)
	require.Len(t, tokens.RadioInvitesApplied, 1)
	p, err := auth.NewTokenIssuer([]byte("secreto-de-prueba-0123456789abcdef"), nil).ParseAccess(tokens.AccessToken)
	require.NoError(t, err)
	list, err := f.svc.List(ctx, p.UserID)
	require.NoError(t, err)
	require.Len(t, list, 1)
	assert.Equal(t, "Carlos", list[0].Title)
	assert.Equal(t, tokens.RadioInvitesApplied[0], list[0].ID)

	// Ya aplicada: el siguiente login no la repite.
	again, err := authSvc.VerifyOTP(ctx, phone, "123456", "", "")
	require.NoError(t, err)
	assert.Empty(t, again.RadioInvitesApplied)

	// Invitación de contacto a un teléfono que termina siendo pasajero: no se aplica.
	const rider = "+573005550011"
	_, err = f.svc.InviteContact(ctx, f.carlos, ContactInviteInput{PhoneE164: rider})
	require.NoError(t, err)
	tk, err := authSvc.VerifyOTP(ctx, rider, "123456", "Marta", "")
	require.NoError(t, err)
	assert.Empty(t, tk.RadioInvitesApplied)
	n, err := f.st.ListPendingRadioInvitesForPhone(ctx, store.ListPendingRadioInvitesForPhoneParams{PhoneE164: text(rider), ExpiresAt: f.svc.now()})
	require.NoError(t, err)
	assert.Len(t, n, 1, "sigue pendiente")
}
