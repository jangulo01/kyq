package radio

import (
	"context"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/kyq/backend/internal/cooperatives"
	"github.com/kyq/backend/internal/store"
)

// fakeSOS opens alerts without trip directly in the database, as safety would.
type fakeSOS struct {
	st     *store.Store
	raised []uuid.UUID
}

func (f *fakeSOS) RaiseFromRadio(ctx context.Context, userID, conversationID uuid.UUID, _, _ *float64) (uuid.UUID, *uuid.UUID, error) {
	f.raised = append(f.raised, conversationID)
	id := uuid.New()
	a, err := f.st.InsertRadioSOSAlert(ctx, store.InsertRadioSOSAlertParams{
		ID: id, RaisedBy: userID, RaisedRole: store.SosRoleDriver, RoomName: "sos-" + id.String(), CreatedAt: time.Now(),
		RadioConversationID: nullID(conversationID),
	})
	return a.ID, nil, err
}

// US9, FR-030/031: Emergencia abre el SOS de 003 y deja el aviso con la ubicación en la
// conversación y en la cooperativa, que suena aunque estén en Ocupado; sin aviso de registro
// aceptado también funciona.
func TestIntegrationRadioEmergency(t *testing.T) {
	f := setup(t)
	ctx := context.Background()
	sos := &fakeSOS{st: f.st}
	f.svc.SOS = sos
	f.consent(t, f.jonathan)
	conv := f.contact(t, f.carlos, f.jonathan)
	coops := &cooperatives.Service{Store: f.st, Group: f.svc}
	coop, err := coops.Create(ctx, f.admin, cooperatives.Input{Name: "Cooperativa Andina", CityCode: "bogota"})
	require.NoError(t, err)
	for _, d := range []uuid.UUID{f.carlos, f.pedro} {
		_, err = coops.AddMember(ctx, f.admin, coop.ID, d, cooperatives.RoleMember)
		require.NoError(t, err)
	}
	_, err = f.svc.UpdateMe(ctx, f.jonathan, MeUpdate{Status: ptr(StatusBusy)})
	require.NoError(t, err)

	_, err = f.svc.Emergency(ctx, f.carlos, conv, ptr(200.0), ptr(0.0))
	assert.ErrorIs(t, err, ErrInvalid)
	out, err := f.svc.Emergency(ctx, f.carlos, conv, ptr(4.61), ptr(-74.07))
	require.NoError(t, err, "Carlos no aceptó el aviso de registro y aun así puede pedir ayuda")
	assert.Equal(t, []uuid.UUID{conv}, sos.raised)
	assert.Nil(t, out.TripID)

	got := f.pub.events(f.jonathan, EventEmergency)
	require.Len(t, got, 1)
	assert.Equal(t, false, got[0]["silent"], "suena en Ocupado")
	pedro := f.pub.events(f.pedro, EventEmergency)
	require.Len(t, pedro, 1, "también la cooperativa")
	hist, err := f.svc.History(ctx, f.jonathan, conv, nil, 10)
	require.NoError(t, err)
	require.Len(t, hist, 1)
	assert.Equal(t, MessageEmergency, hist[0].Kind)
	assert.InDelta(t, 4.61, *hist[0].Lat, 1e-9)

	_, err = f.svc.Emergency(ctx, f.ana, conv, ptr(4.61), ptr(-74.07))
	assert.ErrorIs(t, err, ErrNotFound, "solo quien participa")

	// Sin GPS también se pide ayuda.
	_, err = f.svc.Emergency(ctx, f.jonathan, conv, nil, nil)
	require.NoError(t, err)
}
