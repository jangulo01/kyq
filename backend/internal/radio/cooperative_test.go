package radio

import (
	"context"
	"testing"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/kyq/backend/internal/cooperatives"
	"github.com/kyq/backend/internal/ptt"
	"github.com/kyq/backend/internal/store"
)

// cooperativeOf returns the Radio conversation of the cooperative in user's list.
func (f *fixture) cooperativeOf(t *testing.T, user uuid.UUID) *Conversation {
	t.Helper()
	list, err := f.svc.List(context.Background(), user)
	require.NoError(t, err)
	for _, c := range list {
		if c.Kind == KindCooperative {
			return &c
		}
	}
	return nil
}

// FR-018: la cooperativa de 006 es una conversación de Radio que sigue sus altas, bajas y
// suspensión, y el canal de grupo de 006 habla en la misma sala y con el mismo turno.
func TestIntegrationCooperativeConversation(t *testing.T) {
	f := setup(t)
	ctx := context.Background()
	f.consent(t, f.carlos)
	coops := &cooperatives.Service{Store: f.st, Group: f.svc}
	group := &ptt.Service{Store: f.st, Radio: f.svc}
	coop, err := coops.Create(ctx, f.admin, cooperatives.Input{Name: "Cooperativa Andina", CityCode: "bogota"})
	require.NoError(t, err)
	_, err = coops.AddMember(ctx, f.admin, coop.ID, f.carlos, cooperatives.RoleCoordinator)
	require.NoError(t, err)
	_, err = coops.AddMember(ctx, f.admin, coop.ID, f.jonathan, cooperatives.RoleMember)
	require.NoError(t, err)

	c := f.cooperativeOf(t, f.carlos)
	require.NotNil(t, c, "aparece en la lista única")
	assert.Equal(t, "Cooperativa Andina", c.Title)
	assert.Equal(t, RoleModerator, *c.MyRole, "el coordinador modera")
	j := f.cooperativeOf(t, f.jonathan)
	require.NotNil(t, j)
	assert.Equal(t, c.ID, j.ID)
	assert.Equal(t, RoleMember, *j.MyRole)
	assert.Nil(t, f.cooperativeOf(t, f.pedro))

	// Desde Radio no se sale, no se borra ni se modera: lo maneja 006.
	assert.ErrorIs(t, f.svc.Leave(ctx, f.jonathan, c.ID), ErrCooperative)
	assert.ErrorIs(t, f.svc.Delete(ctx, f.carlos, c.ID), ErrCooperative)
	assert.ErrorIs(t, f.svc.Moderate(ctx, f.carlos, c.ID, f.jonathan, ModerateInput{Action: ptr(ActMute)}), ErrCooperative)

	// /v1/driver/cooperative/ptt/*: misma sala y mismo turno que Radio.
	room := mustRoom(t, f, c.ID)
	creds, err := group.GroupToken(ctx, f.jonathan)
	require.NoError(t, err)
	assert.Equal(t, room, creds.Room)
	_, err = group.TakeGroupFloor(ctx, f.jonathan)
	assert.ErrorIs(t, err, ptt.ErrGroupDenied, "sin aceptar el aviso de registro no habla")
	_, err = group.TakeGroupFloor(ctx, f.carlos)
	require.NoError(t, err)
	assert.True(t, f.rooms.publishing(room, f.carlos))
	f.consent(t, f.jonathan)
	_, err = group.TakeGroupFloor(ctx, f.jonathan)
	assert.ErrorIs(t, err, ptt.ErrBusy)
	_, err = f.svc.TakeFloor(ctx, f.jonathan, c.ID)
	assert.Error(t, err, "Radio ve el mismo turno")
	require.NoError(t, group.ReleaseGroupFloor(ctx, f.carlos))
	assert.False(t, f.rooms.publishing(room, f.carlos))

	// Baja en 006: sale de la conversación y la sala rota (FR-014).
	require.NoError(t, coops.Remove(ctx, cooperatives.Decider{UserID: f.admin, Admin: true}, coop.ID, f.jonathan))
	assert.Nil(t, f.cooperativeOf(t, f.jonathan))
	assert.Contains(t, f.rooms.removed, room+"|"+f.jonathan.String())
	assert.NotEqual(t, room, mustRoom(t, f, c.ID))
	_, err = f.svc.Token(ctx, f.jonathan, c.ID)
	assert.ErrorIs(t, err, ErrNotFound)
	_, err = group.GroupToken(ctx, f.jonathan)
	assert.ErrorIs(t, err, ptt.ErrNoCooperative)

	// Suspensión en 006: la conversación queda suspendida; al reactivar vuelve.
	suspended, active := cooperatives.StatusSuspended, cooperatives.StatusActive
	_, err = coops.Update(ctx, coop.ID, cooperatives.Patch{Status: &suspended})
	require.NoError(t, err)
	conv, err := f.st.GetRadioConversation(ctx, c.ID)
	require.NoError(t, err)
	assert.Equal(t, store.RadioConversationStatusSuspended, conv.Status)
	_, err = f.svc.TakeFloor(ctx, f.carlos, c.ID)
	assert.ErrorIs(t, err, ErrSuspended)
	_, err = group.GroupToken(ctx, f.carlos)
	assert.ErrorIs(t, err, ptt.ErrNoCooperative)

	_, err = coops.Update(ctx, coop.ID, cooperatives.Patch{Status: &active})
	require.NoError(t, err)
	c = f.cooperativeOf(t, f.carlos)
	require.NotNil(t, c)
	assert.Equal(t, "active", c.Status)
	_, err = f.svc.TakeFloor(ctx, f.carlos, c.ID)
	require.NoError(t, err)
}
