package ptt_test

import (
	"context"
	"os"
	"regexp"
	"strings"
	"sync"
	"testing"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/kyq/backend/internal/cooperatives"
	"github.com/kyq/backend/internal/ptt"
	"github.com/kyq/backend/internal/store"
	"github.com/kyq/backend/internal/testdb"
)

// Canal PTT de grupo de la cooperativa (COOP_GROUP, FR-022–FR-024; T022).

type fakeGroupRooms struct {
	*fakeRooms
	gmu     sync.Mutex
	groups  map[string]int
	removed []string
}

func (r *fakeGroupRooms) CreateGroupRoom(_ context.Context, name string, max int) error {
	r.gmu.Lock()
	defer r.gmu.Unlock()
	if r.groups == nil {
		r.groups = map[string]int{}
	}
	r.groups[name] = max
	return nil
}

func (r *fakeGroupRooms) RemoveParticipant(_ context.Context, room, identity string) error {
	r.gmu.Lock()
	defer r.gmu.Unlock()
	r.removed = append(r.removed, room+"/"+identity)
	return nil
}

// DeleteRoom borra la sala; un token de esa sala ya no puede entrar porque LiveKit no crea salas
// solo (infra/livekit.yaml).
func (r *fakeGroupRooms) DeleteRoom(ctx context.Context, name string) error {
	if err := r.fakeRooms.DeleteRoom(ctx, name); err != nil {
		return err
	}
	r.gmu.Lock()
	defer r.gmu.Unlock()
	delete(r.groups, name)
	return nil
}

// live dice si un token de room todavía podría unirse: la sala existe en LiveKit.
func (r *fakeGroupRooms) live(room string) bool {
	r.gmu.Lock()
	defer r.gmu.Unlock()
	_, ok := r.groups[room]
	return ok
}

// groupClaims lee la sala y la caducidad de un token de LiveKit firmado por el fixture.
func groupClaims(t *testing.T, token string) (room string, expires time.Time) {
	var c struct {
		jwt.RegisteredClaims
		Video struct {
			Room string `json:"room"`
		} `json:"video"`
	}
	_, err := jwt.ParseWithClaims(token, &c, func(*jwt.Token) (any, error) { return []byte("secret"), nil },
		jwt.WithoutClaimsValidation())
	require.NoError(t, err)
	return c.Video.Room, c.ExpiresAt.UTC()
}

type groupFixture struct {
	ptt     *ptt.Service
	coops   *cooperatives.Service
	rooms   *fakeGroupRooms
	clock   *time.Time
	admin   uuid.UUID
	coop    cooperatives.Cooperative
	members []uuid.UUID
}

func setupGroup(t *testing.T) *groupFixture {
	st := testdb.New(t)
	ctx := context.Background()
	now := time.Date(2026, 10, 27, 12, 0, 0, 0, time.UTC)
	g := &groupFixture{rooms: &fakeGroupRooms{fakeRooms: &fakeRooms{}}, clock: &now, admin: uuid.New()}
	clock := func() time.Time { return *g.clock }
	_, err := st.CreateUser(ctx, store.CreateUserParams{ID: g.admin, PhoneE164: "+573000000001", Role: store.UserRoleAdmin, DisplayName: "Admin"})
	require.NoError(t, err)
	g.ptt = &ptt.Service{
		Store: st, LiveKit: ptt.LiveKit{APIKey: "devkey", APISecret: "secret"}, Rooms: g.rooms, Groups: g.rooms,
		PublicURL: "ws://voice.test:7880", Now: clock,
	}
	g.coops = &cooperatives.Service{Store: st, Group: g.ptt, Now: clock}
	g.coop, err = g.coops.Create(ctx, g.admin, cooperatives.Input{Name: "Cooperativa Andina", CityCode: "bogota"})
	require.NoError(t, err)
	for i, name := range []string{"Ana", "Beto", "Cami"} {
		id := uuid.New()
		_, err := st.CreateUser(ctx, store.CreateUserParams{ID: id, PhoneE164: "+57310000000" + string(rune('1'+i)), Role: store.UserRoleDriver, DisplayName: name})
		require.NoError(t, err)
		require.NoError(t, st.CreateDriver(ctx, store.CreateDriverParams{UserID: id, QrToken: "qr-group-000000" + string(rune('1'+i)), VehiclePlate: "KYQ00" + string(rune('1'+i)), VehicleDescription: "Kia"}))
		_, err = g.coops.AddMember(ctx, g.admin, g.coop.ID, id, "")
		require.NoError(t, err)
		g.members = append(g.members, id)
	}
	return g
}

func TestIntegrationGroupTokenOnlyForActiveMembers(t *testing.T) {
	g := setupGroup(t)
	ctx := context.Background()
	room := cooperatives.RoomName(g.coop.ID)

	creds, err := g.ptt.GroupToken(ctx, g.members[0])
	require.NoError(t, err)
	assert.Equal(t, room, creds.Room)
	assert.Nil(t, creds.ClosesAt, "el canal de grupo no cierra solo")
	assert.Equal(t, ptt.GroupMaxParticipants, g.rooms.groups[room], "sala para el grupo, no de 2")

	_, err = g.ptt.GroupToken(ctx, uuid.New())
	assert.ErrorIs(t, err, ptt.ErrNoCooperative, "sin cooperativa no hay canal")

	suspended := "suspended"
	_, err = g.coops.Update(ctx, g.coop.ID, cooperatives.Patch{Status: &suspended})
	require.NoError(t, err)
	_, err = g.ptt.GroupToken(ctx, g.members[0])
	assert.ErrorIs(t, err, ptt.ErrNoCooperative, "cooperativa suspendida: sin canal (FR-024)")
	assert.Contains(t, g.rooms.deleted, room, "al suspender se cierra la sala")
}

func TestIntegrationGroupFloorIsSingle(t *testing.T) {
	g := setupGroup(t)
	ctx := context.Background()
	a, b := g.members[0], g.members[1]

	_, err := g.ptt.TakeGroupFloor(ctx, a)
	require.NoError(t, err)
	assert.True(t, g.rooms.publishes(a), "el turno concede publicar")
	_, err = g.ptt.TakeGroupFloor(ctx, b)
	assert.ErrorIs(t, err, ptt.ErrBusy, "FR-023: un solo turno para todo el grupo")
	assert.False(t, g.rooms.publishes(b))

	require.NoError(t, g.ptt.ReleaseGroupFloor(ctx, b), "soltar sin turno no cambia nada")
	require.NoError(t, g.ptt.ReleaseGroupFloor(ctx, a))
	assert.False(t, g.rooms.publishes(a))
	_, err = g.ptt.TakeGroupFloor(ctx, b)
	require.NoError(t, err)

	*g.clock = g.clock.Add(ptt.FloorTTL + time.Second)
	n, err := g.ptt.ExpireGroupFloors(ctx)
	require.NoError(t, err)
	assert.Equal(t, 1, n, "el turno caduca a los 60 s")
	assert.False(t, g.rooms.publishes(b))
}

func TestIntegrationRemovedMemberLosesGroupChannel(t *testing.T) {
	g := setupGroup(t)
	ctx := context.Background()
	c := g.members[2]
	room := cooperatives.RoomName(g.coop.ID)
	_, err := g.ptt.TakeGroupFloor(ctx, c)
	require.NoError(t, err)

	require.NoError(t, g.coops.Remove(ctx, cooperatives.Decider{UserID: g.admin, Admin: true}, g.coop.ID, c))
	assert.Contains(t, g.rooms.removed, room+"/"+c.String(), "FR-024: sale de la sala")
	assert.False(t, g.rooms.publishes(c), "pierde el permiso de publicar")
	_, err = g.ptt.GroupToken(ctx, c)
	assert.ErrorIs(t, err, ptt.ErrNoCooperative, "no puede volver a entrar")
	_, err = g.ptt.TakeGroupFloor(ctx, g.members[0])
	assert.NoError(t, err, "el turno quedó libre para el resto")

	// Al retirar a c la sala rotó: quien sale después está en la sala nueva.
	current, err := g.ptt.GroupToken(ctx, g.members[1])
	require.NoError(t, err)
	require.NoError(t, g.coops.Leave(ctx, g.members[1]))
	assert.Contains(t, g.rooms.removed, current.Room+"/"+g.members[1].String(), "salir también lo saca")
}

// Un miembro retirado conserva su token, pero no le sirve: la sala rota al retirarlo o al salir
// alguien (la vieja se borra), y los tokens de grupo duran poco.
func TestIntegrationRemovedMemberCannotRejoinWithOldToken(t *testing.T) {
	g := setupGroup(t)
	ctx := context.Background()
	c := g.members[2]
	old, err := g.ptt.GroupToken(ctx, c)
	require.NoError(t, err)
	room, expires := groupClaims(t, old.Token)
	assert.Equal(t, old.Room, room)
	assert.Equal(t, g.clock.Add(ptt.GroupTokenTTL), expires, "token de grupo corto")
	assert.Less(t, ptt.GroupTokenTTL, ptt.TokenTTL)
	assert.True(t, g.rooms.live(old.Room))

	require.NoError(t, g.coops.Remove(ctx, cooperatives.Decider{UserID: g.admin, Admin: true}, g.coop.ID, c))
	assert.Contains(t, g.rooms.deleted, old.Room, "la sala vieja se borra")
	assert.False(t, g.rooms.live(old.Room), "su token apunta a una sala que ya no existe y nadie la recrea")
	_, err = g.ptt.GroupToken(ctx, c)
	assert.ErrorIs(t, err, ptt.ErrNoCooperative)

	fresh, err := g.ptt.GroupToken(ctx, g.members[0])
	require.NoError(t, err)
	assert.NotEqual(t, old.Room, fresh.Room, "el resto entra a una sala nueva")
	assert.True(t, strings.HasPrefix(fresh.Room, cooperatives.RoomName(g.coop.ID)+"-"), fresh.Room)
	assert.True(t, g.rooms.live(fresh.Room))
	_, err = g.ptt.TakeGroupFloor(ctx, g.members[0])
	require.NoError(t, err, "el turno funciona en la sala nueva")

	// Salir por cuenta propia también rota la sala y libera el turno de la vieja.
	require.NoError(t, g.coops.Leave(ctx, g.members[1]))
	assert.False(t, g.rooms.live(fresh.Room))
	again, err := g.ptt.GroupToken(ctx, g.members[0])
	require.NoError(t, err)
	assert.NotEqual(t, fresh.Room, again.Room)
	_, err = g.ptt.TakeGroupFloor(ctx, g.members[0])
	require.NoError(t, err)

	// Suspender la cooperativa la cierra; al reactivarla la sala es otra.
	suspended, active := "suspended", "active"
	_, err = g.coops.Update(ctx, g.coop.ID, cooperatives.Patch{Status: &suspended})
	require.NoError(t, err)
	assert.False(t, g.rooms.live(again.Room))
	_, err = g.coops.Update(ctx, g.coop.ID, cooperatives.Patch{Status: &active})
	require.NoError(t, err)
	reopened, err := g.ptt.GroupToken(ctx, g.members[0])
	require.NoError(t, err)
	assert.NotEqual(t, again.Room, reopened.Room)
}

// La rotación de salas depende de que LiveKit no cree salas al recibir un token (RN-KYQ-014).
func TestLiveKitAutoCreateIsOff(t *testing.T) {
	raw, err := os.ReadFile("../../../infra/livekit.yaml")
	require.NoError(t, err)
	// En Windows git puede dejar el archivo con CRLF: se normaliza para comprobar la regla, no el formato.
	text := strings.ReplaceAll(string(raw), "\r\n", "\n")
	assert.Regexp(t, regexp.MustCompile(`(?m)^room:\n(?:[ \t]+.*\n)*?[ \t]+auto_create:[ \t]*false[ \t]*$`), text)
}
