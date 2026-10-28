package radio

import (
	"context"
	"errors"
	"sync"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/stretchr/testify/require"

	"github.com/kyq/backend/internal/ptt"
	"github.com/kyq/backend/internal/realtime"
	"github.com/kyq/backend/internal/storage"
	"github.com/kyq/backend/internal/store"
	"github.com/kyq/backend/internal/testdb"
)

// fakeRooms records what Radio asks LiveKit; failPublish makes granting publish fail.
type fakeRooms struct {
	mu          sync.Mutex
	created     map[string]bool // sala → con registro
	deleted     []string
	removed     []string
	canPublish  map[string]bool // room|identity
	failPublish bool
}

func newFakeRooms() *fakeRooms {
	return &fakeRooms{created: map[string]bool{}, canPublish: map[string]bool{}}
}

func (f *fakeRooms) CreateRadioRoom(_ context.Context, name string, _ int, record bool) error {
	f.mu.Lock()
	defer f.mu.Unlock()
	f.created[name] = record
	return nil
}

func (f *fakeRooms) DeleteRoom(_ context.Context, name string) error {
	f.mu.Lock()
	defer f.mu.Unlock()
	f.deleted = append(f.deleted, name)
	return nil
}

func (f *fakeRooms) SetCanPublish(_ context.Context, room, identity string, can bool) error {
	f.mu.Lock()
	defer f.mu.Unlock()
	if can && f.failPublish {
		return errors.New("livekit caído")
	}
	f.canPublish[room+"|"+identity] = can
	return nil
}

func (f *fakeRooms) RemoveParticipant(_ context.Context, room, identity string) error {
	f.mu.Lock()
	defer f.mu.Unlock()
	f.removed = append(f.removed, room+"|"+identity)
	return nil
}

func (f *fakeRooms) publishing(room string, user uuid.UUID) bool {
	f.mu.Lock()
	defer f.mu.Unlock()
	return f.canPublish[room+"|"+user.String()]
}

type sent struct {
	channel string
	ev      realtime.Event
}

type recorder struct {
	mu   sync.Mutex
	sent []sent
}

func (r *recorder) Publish(_ context.Context, channel string, ev realtime.Event) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.sent = append(r.sent, sent{channel, ev})
	return nil
}

// events returns the events of type typ sent to user.
func (r *recorder) events(user uuid.UUID, typ string) []map[string]any {
	r.mu.Lock()
	defer r.mu.Unlock()
	var out []map[string]any
	for _, s := range r.sent {
		if s.channel == "user:"+user.String() && s.ev.Type == typ {
			d, _ := s.ev.Data.(map[string]any)
			out = append(out, d)
		}
	}
	return out
}

type fakeSMS struct {
	mu   sync.Mutex
	sent map[string][]string
}

func (f *fakeSMS) SendSMS(_ context.Context, phone, body string) error {
	f.mu.Lock()
	defer f.mu.Unlock()
	if f.sent == nil {
		f.sent = map[string][]string{}
	}
	f.sent[phone] = append(f.sent[phone], body)
	return nil
}

func (f *fakeSMS) to(phone string) []string {
	f.mu.Lock()
	defer f.mu.Unlock()
	return f.sent[phone]
}

type fixture struct {
	st                             *store.Store
	svc                            *Service
	rooms                          *fakeRooms
	pub                            *recorder
	sms                            *fakeSMS
	media, saved                   *storage.Memory
	clock                          *time.Time
	admin, carlos, jonathan, pedro uuid.UUID
	ana                            uuid.UUID
}

func setup(t *testing.T) *fixture {
	t.Helper()
	st := testdb.New(t)
	ctx := context.Background()
	now := time.Now().UTC().Truncate(time.Second)
	f := &fixture{
		st: st, rooms: newFakeRooms(), pub: &recorder{}, sms: &fakeSMS{},
		media: storage.NewMemory(), saved: storage.NewMemory(), clock: &now,
		admin: uuid.New(), carlos: uuid.New(), jonathan: uuid.New(), pedro: uuid.New(), ana: uuid.New(),
	}
	for _, u := range []store.CreateUserParams{
		{ID: f.admin, PhoneE164: "+573000000001", Role: store.UserRoleAdmin, DisplayName: "Admin"},
		{ID: f.carlos, PhoneE164: "+573100000001", Role: store.UserRoleDriver, DisplayName: "Carlos"},
		{ID: f.jonathan, PhoneE164: "+573100000002", Role: store.UserRoleDriver, DisplayName: "Jonathan"},
		{ID: f.pedro, PhoneE164: "+573100000003", Role: store.UserRoleDriver, DisplayName: "Pedro"},
		{ID: f.ana, PhoneE164: "+573200000001", Role: store.UserRolePassenger, DisplayName: "Ana"},
	} {
		_, err := st.CreateUser(ctx, u)
		require.NoError(t, err)
	}
	for i, d := range []uuid.UUID{f.carlos, f.jonathan, f.pedro} {
		require.NoError(t, st.CreateDriver(ctx, store.CreateDriverParams{
			UserID: d, QrToken: "qr-radio-000000" + string(rune('1'+i)), VehiclePlate: "KYQ10" + string(rune('1'+i)), VehicleDescription: "Kia",
		}))
	}
	// Carlos y Jonathan pagan; Pedro no tiene suscripción (FR-005).
	for _, d := range []uuid.UUID{f.carlos, f.jonathan} {
		require.NoError(t, st.UpsertSubscription(ctx, store.UpsertSubscriptionParams{DriverID: d, PaidUntil: now.Add(30 * 24 * time.Hour), UpdatedBy: nullID(f.admin)}))
	}
	// El reloj empieza después del alta real de los usuarios (created_at = now() en la base).
	*f.clock = time.Now().UTC().Truncate(time.Second).Add(time.Second)
	f.svc = &Service{
		Store: st, LiveKit: ptt.LiveKit{APIKey: "devkey", APISecret: "secret"}, Rooms: f.rooms, VoiceURL: "ws://livekit.test",
		Publisher: f.pub, Media: MemoryMedia{Memory: f.media, SavedBucket: f.saved}, Saved: f.saved, SMS: f.sms,
		Record: true, PublicBaseURL: "https://kyq.test", PlayDriverURL: "https://play.test/driver", PlayRiderURL: "https://play.test/rider",
		Now: func() time.Time { return *f.clock }, Go: func(fn func()) { fn() },
	}
	return f
}

func (f *fixture) advance(d time.Duration) { *f.clock = f.clock.Add(d) }

// consent accepts the recording notice for each user (FR-013).
func (f *fixture) consent(t *testing.T, users ...uuid.UUID) {
	t.Helper()
	for _, u := range users {
		require.NoError(t, f.svc.Consent(context.Background(), u))
	}
}

// contact makes a and b contacts by QR and returns their conversation.
func (f *fixture) contact(t *testing.T, a, b uuid.UUID) uuid.UUID {
	t.Helper()
	ctx := context.Background()
	inv, err := f.svc.InviteContact(ctx, a, ContactInviteInput{})
	require.NoError(t, err)
	res, err := f.svc.Accept(ctx, b, inv.Code)
	require.NoError(t, err)
	return res.Conversation.ID
}

// voice records one message from user: turn, audio, release and egress.
func (f *fixture) voice(t *testing.T, user, conv uuid.UUID, length time.Duration) uuid.UUID {
	t.Helper()
	ctx := context.Background()
	fl, err := f.svc.TakeFloor(ctx, user, conv)
	require.NoError(t, err)
	c, err := f.st.GetRadioConversation(ctx, conv)
	require.NoError(t, err)
	f.svc.TrackPublished(ctx, c.RoomName, user.String())
	egress := "EG_" + fl.MessageID.String()
	f.svc.EgressStarted(ctx, c.RoomName, egress)
	f.advance(length)
	require.NoError(t, f.svc.ReleaseFloor(ctx, user, conv))
	key := "radio/" + c.RoomName + "/TR_" + fl.MessageID.String() + ".ogg"
	f.media.Put(key, []byte("ogg"), "audio/ogg")
	f.svc.EgressEnded(ctx, c.RoomName, egress, key, length.Milliseconds(), 3, false)
	return fl.MessageID
}

// newDriver registers a driver with an active subscription, as after signing up by OTP.
func (f *fixture) newDriver(t *testing.T, phone, name string) uuid.UUID {
	t.Helper()
	ctx := context.Background()
	id := uuid.New()
	_, err := f.st.CreateUser(ctx, store.CreateUserParams{ID: id, PhoneE164: phone, Role: store.UserRoleDriver, DisplayName: name})
	require.NoError(t, err)
	require.NoError(t, f.st.CreateDriver(ctx, store.CreateDriverParams{
		UserID: id, QrToken: "qr-" + id.String()[:12], VehiclePlate: "KYQ" + id.String()[:3], VehicleDescription: "Kia",
	}))
	require.NoError(t, f.st.UpsertSubscription(ctx, store.UpsertSubscriptionParams{DriverID: id, PaidUntil: f.clock.Add(30 * 24 * time.Hour), UpdatedBy: nullID(f.admin)}))
	return id
}
