package cooperatives_test

import (
	"context"
	"fmt"
	"sync"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/kyq/backend/internal/cooperatives"
	"github.com/kyq/backend/internal/realtime"
	"github.com/kyq/backend/internal/store"
	"github.com/kyq/backend/internal/testdb"
)

// Pruebas de integración de cooperativas y membresías (T006, T010).

type recorder struct {
	mu   sync.Mutex
	msgs map[string][]map[string]any
}

func (r *recorder) Publish(_ context.Context, channel string, ev realtime.Event) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	if r.msgs == nil {
		r.msgs = map[string][]map[string]any{}
	}
	r.msgs[channel] = append(r.msgs[channel], ev.Data.(map[string]any))
	return nil
}

func (r *recorder) last(user uuid.UUID) map[string]any {
	r.mu.Lock()
	defer r.mu.Unlock()
	m := r.msgs["user:"+user.String()]
	if len(m) == 0 {
		return nil
	}
	return m[len(m)-1]
}

type groupSpy struct {
	mu     sync.Mutex
	left   []uuid.UUID
	closed []uuid.UUID
}

func (g *groupSpy) LeaveGroup(_ context.Context, _, driverID uuid.UUID) error {
	g.mu.Lock()
	defer g.mu.Unlock()
	g.left = append(g.left, driverID)
	return nil
}

func (g *groupSpy) CloseGroup(_ context.Context, coop uuid.UUID) error {
	g.mu.Lock()
	defer g.mu.Unlock()
	g.closed = append(g.closed, coop)
	return nil
}

type fixture struct {
	svc   *cooperatives.Service
	st    *store.Store
	pub   *recorder
	group *groupSpy
	admin uuid.UUID
	n     int
}

func setup(t *testing.T) *fixture {
	st := testdb.New(t)
	f := &fixture{st: st, pub: &recorder{}, group: &groupSpy{}, admin: uuid.New()}
	_, err := st.CreateUser(context.Background(), store.CreateUserParams{ID: f.admin, PhoneE164: "+573000000001", Role: store.UserRoleAdmin, DisplayName: "Admin"})
	require.NoError(t, err)
	now := time.Date(2026, 10, 27, 12, 0, 0, 0, time.UTC)
	f.svc = &cooperatives.Service{Store: st, Publisher: f.pub, Group: f.group, Now: func() time.Time { return now }}
	return f
}

func (f *fixture) driver(t *testing.T, name string) uuid.UUID {
	ctx := context.Background()
	f.n++
	id := uuid.New()
	_, err := f.st.CreateUser(ctx, store.CreateUserParams{ID: id, PhoneE164: fmt.Sprintf("+57310000%04d", f.n), Role: store.UserRoleDriver, DisplayName: name})
	require.NoError(t, err)
	require.NoError(t, f.st.CreateDriver(ctx, store.CreateDriverParams{UserID: id, QrToken: fmt.Sprintf("qr-coop-%010d", f.n), VehiclePlate: fmt.Sprintf("KYQ%03d", f.n), VehicleDescription: "Kia"}))
	return id
}

func (f *fixture) coop(t *testing.T, name string) cooperatives.Cooperative {
	c, err := f.svc.Create(context.Background(), f.admin, cooperatives.Input{Name: name, CityCode: "bogota"})
	require.NoError(t, err)
	return c
}

func TestIntegrationCreateAndValidate(t *testing.T) {
	f := setup(t)
	ctx := context.Background()
	nit := " 900123456-1 "
	c, err := f.svc.Create(ctx, f.admin, cooperatives.Input{Name: "  Cooperativa   Andina ", CityCode: "bogota", NIT: &nit})
	require.NoError(t, err)
	assert.Equal(t, "Cooperativa Andina", c.Name)
	assert.Equal(t, "900123456-1", *c.NIT)
	assert.Equal(t, "active", c.Status)
	assert.Zero(t, c.MembersCount)

	_, err = f.svc.Create(ctx, f.admin, cooperatives.Input{Name: "cooperativa andina", CityCode: "bogota"})
	assert.ErrorIs(t, err, cooperatives.ErrNameTaken, "FR-001: nombre único sin mayúsculas")
	_, err = f.svc.Create(ctx, f.admin, cooperatives.Input{Name: "Ab", CityCode: "bogota"})
	var invalid cooperatives.InvalidError
	assert.ErrorAs(t, err, &invalid)

	ch, err := f.st.GetGroupPTTChannel(ctx, c.ID)
	require.NoError(t, err, "FR-022: el canal de grupo nace con la cooperativa")
	assert.Equal(t, store.PttChannelTypeCOOPGROUP, ch.ChannelType)
}

// FR-003: un conductor, una cooperativa y una solicitud a la vez.
func TestIntegrationOneCooperativePerDriver(t *testing.T) {
	f := setup(t)
	ctx := context.Background()
	a, b := f.coop(t, "Cooperativa Andina"), f.coop(t, "Cooperativa Sur")
	d := f.driver(t, "Beto")

	m, err := f.svc.RequestJoin(ctx, d, a.ID)
	require.NoError(t, err)
	assert.Equal(t, "pending", m.Status)
	_, err = f.svc.RequestJoin(ctx, d, b.ID)
	assert.ErrorIs(t, err, cooperatives.ErrAlreadyInCooperative, "una solicitud a la vez")
	_, err = f.svc.AddMember(ctx, f.admin, b.ID, d, "")
	assert.ErrorIs(t, err, cooperatives.ErrAlreadyInCooperative, "el admin tampoco lo mete en otra")

	require.NoError(t, f.svc.Withdraw(ctx, d))
	_, err = f.svc.AddMember(ctx, f.admin, b.ID, d, "")
	require.NoError(t, err)
	_, err = f.svc.RequestJoin(ctx, d, a.ID)
	assert.ErrorIs(t, err, cooperatives.ErrAlreadyInCooperative, "miembro de una: debe salir antes")

	require.NoError(t, f.svc.Leave(ctx, d))
	assert.Contains(t, f.group.left, d, "FR-024: al salir deja el canal de grupo")
	_, err = f.svc.RequestJoin(ctx, d, a.ID)
	assert.NoError(t, err)
}

func TestIntegrationDecideRequests(t *testing.T) {
	f := setup(t)
	ctx := context.Background()
	c := f.coop(t, "Cooperativa Andina")
	d1, d2 := f.driver(t, "Beto"), f.driver(t, "Cami")
	m1, err := f.svc.RequestJoin(ctx, d1, c.ID)
	require.NoError(t, err)
	m2, err := f.svc.RequestJoin(ctx, d2, c.ID)
	require.NoError(t, err)

	admin := cooperatives.Decider{UserID: f.admin, Admin: true}
	assert.ErrorIs(t, f.svc.Decide(ctx, admin, m2.ID, false, " "), cooperatives.ErrReasonRequired, "FR-005: rechazar exige motivo")
	require.NoError(t, f.svc.Decide(ctx, admin, m1.ID, true, ""))
	assert.ErrorIs(t, f.svc.Decide(ctx, admin, m1.ID, true, ""), cooperatives.ErrNotPending)
	require.NoError(t, f.svc.Decide(ctx, admin, m2.ID, false, "Placa no coincide"))
	assert.Equal(t, "active", f.pub.last(d1)["status"], "FR-008: aviso en vivo al conductor")

	mine, err := f.svc.Mine(ctx, d2)
	require.NoError(t, err)
	require.NotNil(t, mine.Membership)
	assert.Equal(t, "rejected", mine.Membership.Status)
	assert.Equal(t, "Placa no coincide", *mine.Membership.RejectReason, "el conductor ve el motivo")

	detail, err := f.svc.Detail(ctx, c.ID)
	require.NoError(t, err)
	assert.Len(t, detail.Members, 1)
	assert.Empty(t, detail.Requests)
	assert.Equal(t, 1, detail.Cooperative.MembersCount)
}

func TestIntegrationCoordinatorPermissions(t *testing.T) {
	f := setup(t)
	ctx := context.Background()
	c, other := f.coop(t, "Cooperativa Andina"), f.coop(t, "Cooperativa Sur")
	coord, member, member2, applicant, foreign := f.driver(t, "Ana"), f.driver(t, "Beto"), f.driver(t, "Cami"), f.driver(t, "Dani"), f.driver(t, "Eva")
	for _, d := range []uuid.UUID{coord, member, member2} {
		_, err := f.svc.AddMember(ctx, f.admin, c.ID, d, "")
		require.NoError(t, err)
	}
	require.NoError(t, f.svc.SetRole(ctx, c.ID, coord, cooperatives.RoleCoordinator))
	req, err := f.svc.RequestJoin(ctx, applicant, c.ID)
	require.NoError(t, err)
	foreignReq, err := f.svc.RequestJoin(ctx, foreign, other.ID)
	require.NoError(t, err)

	asMember := cooperatives.Decider{UserID: member}
	assert.ErrorIs(t, f.svc.Decide(ctx, asMember, req.ID, true, ""), cooperatives.ErrForbidden, "un miembro no decide")
	asCoord := cooperatives.Decider{UserID: coord}
	assert.ErrorIs(t, f.svc.Decide(ctx, asCoord, foreignReq.ID, true, ""), cooperatives.ErrMembershipNotFound, "ni ve solicitudes de otra cooperativa")

	mine, err := f.svc.Mine(ctx, coord)
	require.NoError(t, err)
	assert.Equal(t, "coordinator", mine.Membership.Role)
	assert.Len(t, mine.Requests, 1, "FR-007: el coordinador ve las solicitudes")
	assert.Len(t, mine.Members, 3)
	require.NoError(t, f.svc.Decide(ctx, asCoord, req.ID, true, ""))

	memberView, err := f.svc.Mine(ctx, member)
	require.NoError(t, err)
	assert.Empty(t, memberView.Requests, "un miembro no ve solicitudes")

	assert.ErrorIs(t, f.svc.Remove(ctx, asCoord, uuid.Nil, coord), cooperatives.ErrForbidden, "no se retira a sí mismo")
	require.NoError(t, f.svc.SetRole(ctx, c.ID, member2, cooperatives.RoleCoordinator))
	assert.ErrorIs(t, f.svc.Remove(ctx, asCoord, uuid.Nil, member2), cooperatives.ErrForbidden, "no retira a otro coordinador")
	assert.ErrorIs(t, f.svc.Remove(ctx, asMember, uuid.Nil, applicant), cooperatives.ErrForbidden)
	require.NoError(t, f.svc.Remove(ctx, asCoord, uuid.Nil, member))
	assert.Equal(t, "removed", f.pub.last(member)["status"])
	assert.Contains(t, f.group.left, member)
}

func TestIntegrationSuspendAndList(t *testing.T) {
	f := setup(t)
	ctx := context.Background()
	c := f.coop(t, "Cooperativa Andina")
	f.coop(t, "Cooperativa Sur")
	suspended := cooperatives.StatusSuspended
	updated, err := f.svc.Update(ctx, c.ID, cooperatives.Patch{Status: &suspended})
	require.NoError(t, err)
	assert.Equal(t, "suspended", updated.Status)
	assert.Contains(t, f.group.closed, c.ID, "suspender cierra el canal de grupo")

	all, err := f.svc.List(ctx, false)
	require.NoError(t, err)
	assert.Len(t, all, 2)
	active, err := f.svc.List(ctx, true)
	require.NoError(t, err)
	require.Len(t, active, 1, "los conductores solo ven cooperativas activas")
	assert.Equal(t, "Cooperativa Sur", active[0].Name)

	_, err = f.svc.RequestJoin(ctx, f.driver(t, "Beto"), c.ID)
	assert.ErrorIs(t, err, cooperatives.ErrNotFound, "no se pide entrar a una suspendida")
	bad := "cerrada"
	_, err = f.svc.Update(ctx, c.ID, cooperatives.Patch{Status: &bad})
	var invalid cooperatives.InvalidError
	assert.ErrorAs(t, err, &invalid)
}
