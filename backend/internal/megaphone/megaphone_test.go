package megaphone

import (
	"context"
	"sync"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/kyq/backend/internal/hexgrid"
	"github.com/kyq/backend/internal/realtime"
	"github.com/kyq/backend/internal/store"
	"github.com/kyq/backend/internal/testdb"
)

type fakeVoice struct {
	mu      sync.Mutex
	created []string
	deleted []string
	tokens  map[string]bool // identidad → puede hablar
}

func (f *fakeVoice) CreateGroupRoom(_ context.Context, name string, _ int) error {
	f.mu.Lock()
	defer f.mu.Unlock()
	f.created = append(f.created, name)
	return nil
}

func (f *fakeVoice) DeleteRoom(_ context.Context, name string) error {
	f.mu.Lock()
	defer f.mu.Unlock()
	f.deleted = append(f.deleted, name)
	return nil
}

func (f *fakeVoice) BroadcastToken(identity, _, _ string, speaker bool, _ time.Time, _ time.Duration) (string, error) {
	f.mu.Lock()
	defer f.mu.Unlock()
	f.tokens[identity] = speaker
	return "tok-" + identity, nil
}

type recorder struct {
	mu   sync.Mutex
	sent []string
}

func (r *recorder) Publish(_ context.Context, channel string, ev realtime.Event) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.sent = append(r.sent, channel+" "+ev.Type)
	return nil
}

var (
	centro    = hexgrid.Point{Lat: 4.5981, Lng: -74.0760}
	chapinero = hexgrid.Point{Lat: 4.6486, Lng: -74.0628}
)

func cell(t *testing.T, p hexgrid.Point, res int) string {
	c, err := hexgrid.CellAt(p, res)
	require.NoError(t, err)
	return c.String()
}

func TestParseCells(t *testing.T) {
	a, b := cell(t, centro, 8), cell(t, chapinero, 7)
	for _, bad := range [][]string{nil, {}, {"zz"}, {a, b}, {cell(t, centro, 5)}} {
		_, _, err := parseCells(bad)
		assert.ErrorIs(t, err, ErrInvalidCells, bad)
	}
	set, res, err := parseCells([]string{a, cell(t, chapinero, 8)})
	require.NoError(t, err)
	assert.Equal(t, 8, res)
	assert.Len(t, set, 2)
}

// US3: solo los conductores de la zona elegida lo reciben; se registra y se corta a los 60 s.
func TestIntegrationMegaphoneReachesOnlyTheZone(t *testing.T) {
	st := testdb.New(t)
	ctx := context.Background()
	now := time.Now().UTC().Truncate(time.Second)
	admin, inZone, outZone, stale, offline := uuid.New(), uuid.New(), uuid.New(), uuid.New(), uuid.New()
	_, err := st.CreateUser(ctx, store.CreateUserParams{ID: admin, PhoneE164: "+573000000000", Role: store.UserRoleAdmin, DisplayName: "Admin"})
	require.NoError(t, err)
	for i, d := range []struct {
		id       uuid.UUID
		p        hexgrid.Point
		age      time.Duration
		presence store.DriverPresence
	}{
		{inZone, centro, time.Minute, store.DriverPresenceFree},
		{outZone, chapinero, time.Minute, store.DriverPresenceBusy},
		{stale, centro, 10 * time.Minute, store.DriverPresenceFree},
		{offline, centro, time.Minute, store.DriverPresenceOffline},
	} {
		_, err := st.CreateUser(ctx, store.CreateUserParams{ID: d.id, PhoneE164: "+57310000000" + string(rune('1'+i)), Role: store.UserRoleDriver, DisplayName: "C" + string(rune('A'+i))})
		require.NoError(t, err)
		require.NoError(t, st.CreateDriver(ctx, store.CreateDriverParams{UserID: d.id, QrToken: "qr-mega-00000000" + string(rune('1'+i)), VehiclePlate: "KYQ00" + string(rune('1'+i)), VehicleDescription: "Kia"}))
		require.NoError(t, st.SetDriverLocation(ctx, store.SetDriverLocationParams{Lat: d.p.Lat, Lng: d.p.Lng, RecordedAt: now.Add(-d.age), UserID: d.id}))
		require.NoError(t, st.SetDriverPresence(ctx, store.SetDriverPresenceParams{UserID: d.id, Presence: d.presence}))
	}
	voice := &fakeVoice{tokens: map[string]bool{}}
	pub := &recorder{}
	clock := now
	svc := &Service{Store: st, Voice: voice, VoiceURL: "wss://lk.test", Publisher: pub, Now: func() time.Time { return clock }}

	_, err = svc.Start(ctx, admin, []string{cell(t, hexgrid.Point{Lat: 4.75, Lng: -74.1}, 8)})
	assert.ErrorIs(t, err, ErrNoRecipients)

	s, err := svc.Start(ctx, admin, []string{cell(t, centro, 8)})
	require.NoError(t, err)
	assert.Equal(t, 1, s.Recipients, "SC-004: solo el de la zona, con ubicación reciente y ONLINE")
	assert.Equal(t, "wss://lk.test", s.URL)
	assert.Equal(t, map[string]bool{admin.String(): true, inZone.String(): false}, voice.tokens, "el conductor solo escucha")
	assert.Equal(t, []string{"user:" + inZone.String() + " megaphone.started"}, pub.sent)
	assert.Equal(t, now.Add(MaxDuration), s.EndsAt)

	_, err = svc.Start(ctx, admin, []string{cell(t, centro, 8)})
	assert.ErrorIs(t, err, ErrOnAir, "uno a la vez por administrador")

	clock = now.Add(30 * time.Second)
	n, err := svc.ExpireDue(ctx)
	require.NoError(t, err)
	assert.Zero(t, n)
	clock = now.Add(MaxDuration + time.Second)
	n, err = svc.ExpireDue(ctx)
	require.NoError(t, err)
	assert.Equal(t, 1, n, "FR-013: se corta a los 60 s")
	assert.Equal(t, voice.created, voice.deleted)
	assert.Contains(t, pub.sent, "user:"+inZone.String()+" megaphone.ended")
	assert.ErrorIs(t, svc.End(ctx, s.BroadcastID), ErrNotFound)

	log, err := svc.List(ctx, 10)
	require.NoError(t, err)
	require.Len(t, log, 1)
	assert.Equal(t, "Admin", log[0].AdminName)
	assert.Equal(t, 1, log[0].Recipients)
	assert.Equal(t, 8, log[0].Resolution)
	require.NotNil(t, log[0].DurationS)
	assert.Equal(t, 61, *log[0].DurationS)
}
