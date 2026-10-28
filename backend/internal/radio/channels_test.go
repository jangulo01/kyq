package radio

import (
	"context"
	"fmt"
	"testing"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/kyq/backend/internal/store"
)

// channel creates a channel owned by owner and returns its id.
func (f *fixture) channel(t *testing.T, owner uuid.UUID, name, mode string, passengers *string) uuid.UUID {
	t.Helper()
	c, err := f.svc.CreateChannel(context.Background(), owner, ChannelInput{Name: &name, JoinMode: &mode, PassengerRoleMax: passengers})
	require.NoError(t, err)
	return c.ID
}

// join accepts a fresh channel invitation as user.
func (f *fixture) join(t *testing.T, conv, by, user uuid.UUID) AcceptResult {
	t.Helper()
	ctx := context.Background()
	inv, err := f.svc.ChannelInvite(ctx, by, conv)
	require.NoError(t, err)
	res, err := f.svc.Accept(ctx, user, inv.Code)
	require.NoError(t, err)
	return res
}

func (f *fixture) status(t *testing.T, conv, user uuid.UUID) (store.RadioRole, store.RadioMemberStatus) {
	t.Helper()
	m, err := f.st.GetRadioMember(context.Background(), store.GetRadioMemberParams{ConversationID: conv, UserID: user})
	require.NoError(t, err)
	return m.Role, m.Status
}

func (f *fixture) setPassengers(t *testing.T, policy string) {
	t.Helper()
	require.NoError(t, f.st.UpdateRadioSettings(context.Background(), store.UpdateRadioSettingsParams{
		TrialPolicy: store.RadioTrialPolicyTrial, TrialDays: 30, PassengersInChannels: store.RadioPassengerPolicy(policy),
		RetentionDays: 30, UpdatedBy: nullID(f.admin), UpdatedAt: f.svc.now(),
	}))
	f.svc.forgetSettings()
}

// US4: crear canal con nombre único y tope de 10 por conductor (FR-015).
func TestIntegrationChannelCreate(t *testing.T) {
	f := setup(t)
	ctx := context.Background()

	conv := f.channel(t, f.carlos, "Taxistas Norte", JoinApproval, nil)
	_, err := f.svc.Token(ctx, f.carlos, conv)
	require.NoError(t, err)
	assert.True(t, f.rooms.created[mustRoom(t, f, conv)], "la sala del canal se graba (RN-KYQ-017)")

	_, err = f.svc.CreateChannel(ctx, f.jonathan, ChannelInput{Name: ptr(" Taxistas Norte ")})
	assert.ErrorIs(t, err, ErrNameTaken)
	_, err = f.svc.CreateChannel(ctx, f.jonathan, ChannelInput{Name: ptr("ab")})
	assert.ErrorIs(t, err, ErrInvalid)
	_, err = f.svc.CreateChannel(ctx, f.ana, ChannelInput{Name: ptr("Pasajeros")})
	assert.ErrorIs(t, err, ErrInvalid, "solo conductores crean canales")

	for i := 2; i <= MaxOwnedChannels; i++ {
		f.channel(t, f.carlos, fmt.Sprintf("Canal %02d", i), JoinApproval, nil)
	}
	_, err = f.svc.CreateChannel(ctx, f.carlos, ChannelInput{Name: ptr("Canal 11")})
	assert.ErrorIs(t, err, ErrChannelLimit)

	d, err := f.svc.Detail(ctx, f.carlos, conv)
	require.NoError(t, err)
	assert.Equal(t, KindChannel, d.Kind)
	assert.Equal(t, RoleOwner, *d.MyRole)
	require.Len(t, d.Members, 1)

	// Editar: solo el dueño; el nombre sigue siendo único.
	_, err = f.svc.UpdateChannel(ctx, f.carlos, conv, ChannelInput{Name: ptr("Canal 02")})
	assert.ErrorIs(t, err, ErrNameTaken)
	up, err := f.svc.UpdateChannel(ctx, f.carlos, conv, ChannelInput{Name: ptr("Taxistas del Norte"), JoinMode: ptr(JoinOpenLink)})
	require.NoError(t, err)
	assert.Equal(t, "Taxistas del Norte", up.Title)
	f.join(t, conv, f.carlos, f.jonathan)
	_, err = f.svc.UpdateChannel(ctx, f.jonathan, conv, ChannelInput{Name: ptr("Mío")})
	assert.ErrorIs(t, err, ErrNotOwner)
}

func mustRoom(t *testing.T, f *fixture, conv uuid.UUID) string {
	t.Helper()
	c, err := f.st.GetRadioConversation(context.Background(), conv)
	require.NoError(t, err)
	return c.RoomName
}

// US4-2: entrada con aprobación, moderación por rol y rotación de sala al expulsar (FR-016, FR-014).
func TestIntegrationChannelModeration(t *testing.T) {
	f := setup(t)
	ctx := context.Background()
	f.consent(t, f.carlos, f.jonathan, f.pedro)
	conv := f.channel(t, f.carlos, "Taxistas Norte", JoinApproval, nil)

	res := f.join(t, conv, f.carlos, f.jonathan)
	assert.True(t, res.Pending)
	assert.NotEmpty(t, f.pub.events(f.carlos, EventMember), "el dueño recibe la solicitud")
	_, err := f.svc.TakeFloor(ctx, f.jonathan, conv)
	assert.Error(t, err, "pendiente no habla")

	// Pedro (sin suscripción, en prueba) entra y pide; se rechaza.
	f.join(t, conv, f.carlos, f.pedro)
	require.NoError(t, f.svc.Moderate(ctx, f.carlos, conv, f.pedro, ModerateInput{Action: ptr(ActReject)}))
	_, st := f.status(t, conv, f.pedro)
	assert.Equal(t, store.RadioMemberStatusRejected, st)

	require.NoError(t, f.svc.Moderate(ctx, f.carlos, conv, f.jonathan, ModerateInput{Action: ptr(ActApprove)}))
	_, st = f.status(t, conv, f.jonathan)
	assert.Equal(t, store.RadioMemberStatusActive, st)

	// Moderador: lo nombra solo el dueño; no actúa sobre el dueño ni sobre otro moderador.
	assert.ErrorIs(t, f.svc.Moderate(ctx, f.jonathan, conv, f.pedro, ModerateInput{Action: ptr(ActApprove)}), ErrNotModerator)
	require.NoError(t, f.svc.Moderate(ctx, f.carlos, conv, f.jonathan, ModerateInput{Role: ptr(RoleModerator)}))
	assert.ErrorIs(t, f.svc.Moderate(ctx, f.jonathan, conv, f.carlos, ModerateInput{Action: ptr(ActMute)}), ErrNotModerator)

	// Silenciar impide hablar; quitar el silencio lo devuelve.
	f.join(t, conv, f.jonathan, f.pedro)
	require.NoError(t, f.svc.Moderate(ctx, f.jonathan, conv, f.pedro, ModerateInput{Action: ptr(ActApprove)}))
	require.NoError(t, f.svc.Moderate(ctx, f.jonathan, conv, f.pedro, ModerateInput{Action: ptr(ActMute)}))
	_, err = f.svc.TakeFloor(ctx, f.pedro, conv)
	assert.ErrorIs(t, err, ErrMuted)
	require.NoError(t, f.svc.Moderate(ctx, f.jonathan, conv, f.pedro, ModerateInput{Action: ptr(ActUnmute)}))

	// Expulsar: sale de la sala, la sala rota y todos se reconectan (FR-014).
	old := mustRoom(t, f, conv)
	require.NoError(t, f.svc.Moderate(ctx, f.jonathan, conv, f.pedro, ModerateInput{Action: ptr(ActRemove)}))
	assert.Contains(t, f.rooms.removed, old+"|"+f.pedro.String())
	assert.Contains(t, f.rooms.deleted, old)
	assert.NotEqual(t, old, mustRoom(t, f, conv))
	rotated := false
	for _, e := range f.pub.events(f.carlos, EventMember) {
		rotated = rotated || e["change"] == "room_rotated"
	}
	assert.True(t, rotated)
	_, err = f.svc.Token(ctx, f.pedro, conv)
	assert.ErrorIs(t, err, ErrNotFound)

	// Bloquear: no vuelve a entrar ni con un enlace nuevo.
	require.NoError(t, f.svc.Moderate(ctx, f.carlos, conv, f.pedro, ModerateInput{Action: ptr(ActBlock)}))
	inv, err := f.svc.ChannelInvite(ctx, f.carlos, conv)
	require.NoError(t, err)
	_, err = f.svc.Accept(ctx, f.pedro, inv.Code)
	assert.ErrorIs(t, err, ErrBlocked)

	// Moderadores ven las solicitudes y bloqueados; un miembro no.
	d, err := f.svc.Detail(ctx, f.carlos, conv)
	require.NoError(t, err)
	assert.Len(t, d.Members, 3)
}

// US4: salir; el dueño que sale deja el canal al moderador o miembro más antiguo; vacío se borra.
func TestIntegrationChannelLeave(t *testing.T) {
	f := setup(t)
	ctx := context.Background()
	conv := f.channel(t, f.carlos, "Taxistas Norte", JoinOpenLink, nil)
	res := f.join(t, conv, f.carlos, f.jonathan)
	assert.False(t, res.Pending, "enlace abierto: entra directo")

	old := mustRoom(t, f, conv)
	require.NoError(t, f.svc.Leave(ctx, f.carlos, conv))
	role, _ := f.status(t, conv, f.jonathan)
	assert.Equal(t, store.RadioRoleOwner, role)
	_, st := f.status(t, conv, f.carlos)
	assert.Equal(t, store.RadioMemberStatusRemoved, st)
	assert.NotEqual(t, old, mustRoom(t, f, conv), "la sala rota al salir")

	require.NoError(t, f.svc.Leave(ctx, f.jonathan, conv))
	c, err := f.st.GetRadioConversation(ctx, conv)
	require.NoError(t, err)
	assert.True(t, c.DeletedAt.Valid, "canal vacío se borra")
	for _, u := range []uuid.UUID{f.carlos, f.jonathan} {
		list, err := f.svc.List(ctx, u)
		require.NoError(t, err)
		assert.Empty(t, list)
	}
}

// FR-015: tope de 200 miembros activos.
func TestIntegrationChannelFull(t *testing.T) {
	f := setup(t)
	ctx := context.Background()
	conv := f.channel(t, f.carlos, "Grande", JoinOpenLink, nil)
	now := f.svc.now()
	for i := 1; i < MaxChannelMembers; i++ {
		id := uuid.New()
		_, err := f.st.CreateUser(ctx, store.CreateUserParams{ID: id, PhoneE164: fmt.Sprintf("+5735%08d", i), Role: store.UserRoleDriver, DisplayName: "Conductor"})
		require.NoError(t, err)
		_, err = f.st.UpsertRadioMember(ctx, store.UpsertRadioMemberParams{
			ConversationID: conv, UserID: id, Role: store.RadioRoleMember, Status: store.RadioMemberStatusActive, Listening: true, JoinedAt: now,
		})
		require.NoError(t, err)
	}
	inv, err := f.svc.ChannelInvite(ctx, f.carlos, conv)
	require.NoError(t, err)
	_, err = f.svc.Accept(ctx, f.jonathan, inv.Code)
	assert.ErrorIs(t, err, ErrChannelFull)
}

// FR-017: pasajeros en canales según el panel y el dueño; al restringir se degradan o salen.
func TestIntegrationChannelPassengerPolicy(t *testing.T) {
	f := setup(t)
	ctx := context.Background()

	// Por defecto el panel no admite pasajeros en canales.
	_, err := f.svc.CreateChannel(ctx, f.carlos, ChannelInput{Name: ptr("Con clientes"), PassengerRoleMax: ptr(RoleMember)})
	assert.ErrorIs(t, err, ErrPassengersClosed)

	f.setPassengers(t, PassengersAllRoles)
	conv := f.channel(t, f.carlos, "Con clientes", JoinOpenLink, ptr(RoleMember))
	closed := f.channel(t, f.carlos, "Solo conductores", JoinOpenLink, nil)

	f.join(t, conv, f.carlos, f.ana)
	role, st := f.status(t, conv, f.ana)
	assert.Equal(t, store.RadioRoleMember, role)
	assert.Equal(t, store.RadioMemberStatusActive, st)
	inv, err := f.svc.ChannelInvite(ctx, f.carlos, closed)
	require.NoError(t, err)
	_, err = f.svc.Accept(ctx, f.ana, inv.Code)
	assert.ErrorIs(t, err, ErrPassengersClosed, "el dueño no admite pasajeros")
	// Un pasajero no sube a moderador si el dueño solo admite miembros.
	assert.ErrorIs(t, f.svc.Moderate(ctx, f.carlos, conv, f.ana, ModerateInput{Role: ptr(RoleModerator)}), ErrPassengersClosed)

	// El panel restringe a solo escucha: el pasajero queda como oyente.
	f.setPassengers(t, PassengersListenOnly)
	require.NoError(t, f.svc.ApplyPassengerPolicy(ctx))
	role, _ = f.status(t, conv, f.ana)
	assert.Equal(t, store.RadioRoleListener, role)
	changes := map[any]bool{}
	for _, e := range f.pub.events(f.ana, EventMember) {
		changes[e["change"]] = true
	}
	assert.True(t, changes["role_by_policy"])

	// El panel cierra los canales a pasajeros: sale y la sala rota.
	old := mustRoom(t, f, conv)
	f.setPassengers(t, PassengersNone)
	require.NoError(t, f.svc.ApplyPassengerPolicy(ctx))
	_, st = f.status(t, conv, f.ana)
	assert.Equal(t, store.RadioMemberStatusRemoved, st)
	assert.NotEqual(t, old, mustRoom(t, f, conv))
	for _, e := range f.pub.events(f.ana, EventMember) {
		changes[e["change"]] = true
	}
	assert.True(t, changes["removed_by_policy"])

	// El dueño que deja de admitir pasajeros también los saca.
	f.setPassengers(t, PassengersAllRoles)
	f.join(t, conv, f.carlos, f.ana)
	_, err = f.svc.UpdateChannel(ctx, f.carlos, conv, ChannelInput{SetPassengerRole: true})
	require.NoError(t, err)
	_, st = f.status(t, conv, f.ana)
	assert.Equal(t, store.RadioMemberStatusRemoved, st)
}
