package safety_test

import (
	"context"
	"encoding/json"
	"errors"
	"strings"
	"sync"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/stretchr/testify/require"

	"github.com/kyq/backend/internal/fares"
	"github.com/kyq/backend/internal/ptt"
	"github.com/kyq/backend/internal/realtime"
	"github.com/kyq/backend/internal/safety"
	"github.com/kyq/backend/internal/storage"
	"github.com/kyq/backend/internal/store"
	"github.com/kyq/backend/internal/testdb"
	"github.com/kyq/backend/internal/trips"
)

type fixedRoute struct{}

func (fixedRoute) Route(context.Context, float64, float64, float64, float64) (fares.Route, error) {
	return fares.Route{DistanceM: 5200, DurationS: 900}, nil
}

// fakeVoice is LiveKit in memory: rooms, publishing rights and recordings.
type fakeVoice struct {
	mu                     sync.Mutex
	rooms                  map[string]bool
	canPublish             map[string]bool // "sala/identidad" → último permiso
	egress                 map[string]string
	stopped                []string
	failRoom, failGrant    bool
	failRevoke, failDelete bool
	failEgress             bool
}

func newFakeVoice() *fakeVoice {
	return &fakeVoice{rooms: map[string]bool{}, canPublish: map[string]bool{}, egress: map[string]string{}}
}

var errDown = errors.New("livekit caído")

func (v *fakeVoice) CreateSOSRoom(_ context.Context, name string) error {
	v.mu.Lock()
	defer v.mu.Unlock()
	if v.failRoom {
		return errDown
	}
	v.rooms[name] = true
	return nil
}

func (v *fakeVoice) DeleteRoom(_ context.Context, name string) error {
	v.mu.Lock()
	defer v.mu.Unlock()
	if v.failDelete {
		return errDown
	}
	delete(v.rooms, name)
	return nil
}

func (v *fakeVoice) SetCanPublish(_ context.Context, room, identity string, canPublish bool) error {
	v.mu.Lock()
	defer v.mu.Unlock()
	if (canPublish && v.failGrant) || (!canPublish && v.failRevoke) {
		return errDown
	}
	v.canPublish[room+"/"+identity] = canPublish
	return nil
}

func (v *fakeVoice) StartAudioEgress(_ context.Context, room, filepath string) (string, error) {
	v.mu.Lock()
	defer v.mu.Unlock()
	if v.failEgress {
		return "", errDown
	}
	id := "EG_" + room
	v.egress[id] = filepath
	return id, nil
}

func (v *fakeVoice) StopEgress(_ context.Context, id string) error {
	v.mu.Lock()
	defer v.mu.Unlock()
	v.stopped = append(v.stopped, id)
	return nil
}

func (v *fakeVoice) publishes(room string, id uuid.UUID) bool {
	v.mu.Lock()
	defer v.mu.Unlock()
	return v.canPublish[room+"/"+id.String()]
}

func (v *fakeVoice) hasRoom(room string) bool {
	v.mu.Lock()
	defer v.mu.Unlock()
	return v.rooms[room]
}

type event struct {
	channel, typ, raw string
}

// recorder keeps every published event with its JSON.
type recorder struct {
	mu     sync.Mutex
	events []event
}

func (r *recorder) Publish(_ context.Context, channel string, ev realtime.Event) error {
	raw, err := json.Marshal(ev)
	if err != nil {
		return err
	}
	r.mu.Lock()
	defer r.mu.Unlock()
	r.events = append(r.events, event{channel: channel, typ: ev.Type, raw: string(raw)})
	return nil
}

func (r *recorder) types(channel string) []string {
	r.mu.Lock()
	defer r.mu.Unlock()
	var out []string
	for _, e := range r.events {
		if e.channel == channel {
			out = append(out, e.typ)
		}
	}
	return out
}

func (r *recorder) all() []event {
	r.mu.Lock()
	defer r.mu.Unlock()
	return append([]event(nil), r.events...)
}

type sms struct{ phone, body string }

type smsBox struct {
	mu   sync.Mutex
	sent []sms
}

func (b *smsBox) SendSMS(_ context.Context, phone, body string) error {
	b.mu.Lock()
	defer b.mu.Unlock()
	b.sent = append(b.sent, sms{phone, body})
	return nil
}

func (b *smsBox) to(phone string) []string {
	b.mu.Lock()
	defer b.mu.Unlock()
	var out []string
	for _, m := range b.sent {
		if m.phone == phone {
			out = append(out, m.body)
		}
	}
	return out
}

const (
	operatorPhone  = "+573000000011"
	operator2Phone = "+573000000012"
	driverPhone    = "+573100000001"
	passengerPhone = "+573200000002"
)

type fixture struct {
	st         *store.Store
	trips      *trips.Service
	svc        *safety.Service
	voice      *fakeVoice
	pub        *recorder
	sms        *smsBox
	objects    *storage.Memory
	clock      *time.Time
	operator   uuid.UUID // operador de guardia
	operator2  uuid.UUID // operador fuera de guardia
	admin      uuid.UUID // administrador sin permiso de emergencias
	driver     uuid.UUID
	passenger  uuid.UUID
	stranger   uuid.UUID
	driverName string
}

func setup(t *testing.T) *fixture {
	t.Helper()
	st := testdb.New(t)
	ctx := context.Background()
	now := time.Date(2026, 10, 27, 22, 0, 0, 0, time.UTC)
	f := &fixture{
		st: st, voice: newFakeVoice(), pub: &recorder{}, sms: &smsBox{}, objects: storage.NewMemory(), clock: &now,
		operator: uuid.New(), operator2: uuid.New(), admin: uuid.New(), driver: uuid.New(), passenger: uuid.New(),
		stranger: uuid.New(), driverName: "Carlos",
	}
	clock := func() time.Time { return *f.clock }
	for _, u := range []store.CreateUserParams{
		{ID: f.operator, PhoneE164: operatorPhone, Role: store.UserRoleAdmin, DisplayName: "Operadora Lucía"},
		{ID: f.operator2, PhoneE164: operator2Phone, Role: store.UserRoleAdmin, DisplayName: "Operador Juan"},
		{ID: f.admin, PhoneE164: "+573000000013", Role: store.UserRoleAdmin, DisplayName: "Admin"},
		{ID: f.driver, PhoneE164: driverPhone, Role: store.UserRoleDriver, DisplayName: f.driverName},
		{ID: f.passenger, PhoneE164: passengerPhone, Role: store.UserRolePassenger, DisplayName: "Ana"},
		{ID: f.stranger, PhoneE164: "+573200000003", Role: store.UserRolePassenger, DisplayName: "Otro"},
	} {
		_, err := st.CreateUser(ctx, u)
		require.NoError(t, err)
	}
	require.NoError(t, st.GrantEmergencyOperator(ctx, store.GrantEmergencyOperatorParams{UserID: f.operator, OnDuty: true}))
	require.NoError(t, st.GrantEmergencyOperator(ctx, store.GrantEmergencyOperatorParams{UserID: f.operator2, OnDuty: false}))
	require.NoError(t, st.CreateDriver(ctx, store.CreateDriverParams{UserID: f.driver, QrToken: "qr-carlos-0000000", VehiclePlate: "KYQ001", VehicleDescription: "Kia Picanto gris"}))
	require.NoError(t, st.InsertAffiliation(ctx, store.InsertAffiliationParams{PassengerID: f.passenger, DriverID: f.driver}))
	require.NoError(t, st.SetDriverPresence(ctx, store.SetDriverPresenceParams{UserID: f.driver, Presence: store.DriverPresenceFree}))
	require.NoError(t, st.UpsertFareTable(ctx, store.UpsertFareTableParams{
		CityCode: "bogota", Currency: "COP", BaseMinor: 400_000, PerKmMinor: 120_000, PerMinuteMinor: 30_000,
		MinimumMinor: 700_000, RoundingMinor: 10_000, UpdatedBy: f.admin,
	}))
	f.trips = &trips.Service{Store: st, Routes: fixedRoute{}, CityCode: "bogota", Now: clock}
	f.svc = &safety.Service{
		Store: st, LiveKit: ptt.LiveKit{APIKey: "devkey", APISecret: "secret"}, Voice: f.voice, VoiceURL: "ws://voice.test:7880",
		Publisher: f.pub, SMS: f.sms, Recordings: f.objects, Record: true, PublicBaseURL: "https://kyq.test/",
		Now: clock, Go: func(fn func()) { fn() },
	}
	return f
}

func (f *fixture) advance(d time.Duration) { *f.clock = f.clock.Add(d) }

// trip returns a trip moved to status (REQUESTED, ACCEPTED, ARRIVED, IN_PROGRESS, COMPLETED).
func (f *fixture) trip(t *testing.T, status trips.Status) uuid.UUID {
	t.Helper()
	ctx := context.Background()
	trip, err := f.trips.Request(ctx, f.passenger, f.driver, trips.Point{Lat: 4.60, Lng: -74.08}, trips.Point{Lat: 4.65, Lng: -74.05})
	require.NoError(t, err)
	steps := []func(*trips.Trip, trips.Party, time.Time) error{
		func(tr *trips.Trip, p trips.Party, now time.Time) error { return tr.Accept(p, nil, now) },
		(*trips.Trip).Arrive, (*trips.Trip).Start, (*trips.Trip).Complete,
	}
	order := []trips.Status{trips.StatusAccepted, trips.StatusArrived, trips.StatusInProgress, trips.StatusCompleted}
	for i, want := range order {
		if status == trips.StatusRequested {
			break
		}
		_, err := f.trips.Act(ctx, f.driver, trip.ID, steps[i])
		require.NoError(t, err)
		if want == status {
			break
		}
	}
	return trip.ID
}

func (f *fixture) finish(t *testing.T, tripID uuid.UUID) {
	t.Helper()
	for _, step := range []func(*trips.Trip, trips.Party, time.Time) error{(*trips.Trip).Arrive, (*trips.Trip).Start, (*trips.Trip).Complete} {
		_, err := f.trips.Act(context.Background(), f.driver, tripID, step)
		require.NoError(t, err)
	}
}

func (f *fixture) raise(t *testing.T, user, tripID uuid.UUID) safety.RaiseResult {
	t.Helper()
	out, _, err := f.svc.Raise(context.Background(), user, tripID, &safety.Point{Lat: 4.61, Lng: -74.07, RecordedAt: *f.clock})
	require.NoError(t, err)
	return out
}

// sosLeaks returns the SOS events that reached a channel other than the console's or the
// raiser's own (FR-006).
func (f *fixture) sosLeaks(raiser uuid.UUID) []event {
	var out []event
	for _, e := range f.pub.all() {
		if e.channel == realtime.OpsSOSChannel || strings.HasPrefix(e.channel, "sos:") || e.channel == "user:"+raiser.String() {
			continue
		}
		if strings.HasPrefix(e.typ, "sos.") || strings.Contains(e.raw, "alert_id") {
			out = append(out, e)
		}
	}
	return out
}
