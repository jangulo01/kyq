package kyc

import (
	"bytes"
	"context"
	"encoding/json"
	"strings"
	"sync"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/kyq/backend/internal/notify"
	"github.com/kyq/backend/internal/realtime"
	"github.com/kyq/backend/internal/storage"
	"github.com/kyq/backend/internal/store"
	"github.com/kyq/backend/internal/testdb"
)

type clock struct{ t time.Time }

func (c *clock) now() time.Time { return c.t }

type recorder struct {
	mu     sync.Mutex
	events []string
}

func (r *recorder) Publish(_ context.Context, channel string, ev realtime.Event) error {
	raw, _ := json.Marshal(ev)
	r.mu.Lock()
	defer r.mu.Unlock()
	r.events = append(r.events, channel+" "+string(raw))
	return nil
}

type fixture struct {
	st      *store.Store
	svc     *Service
	objects *storage.Memory
	pub     *recorder
	clock   *clock
	admin   uuid.UUID
}

func newFixture(t *testing.T) *fixture {
	st := testdb.New(t)
	c := &clock{t: time.Date(2026, 10, 27, 15, 0, 0, 0, time.UTC)}
	pub := &recorder{}
	objects := storage.NewMemory()
	f := &fixture{
		st: st, objects: objects, pub: pub, clock: c,
		svc: &Service{
			Store: st, Objects: objects, Now: c.now,
			Notify: &notify.Service{Store: st, Publisher: pub, Now: c.now},
		},
		admin: uuid.New(),
	}
	_, err := st.CreateUser(context.Background(), store.CreateUserParams{ID: f.admin, PhoneE164: "+573000000000", Role: store.UserRoleAdmin, DisplayName: "Admin"})
	require.NoError(t, err)
	return f
}

func (f *fixture) newDriver(t *testing.T, phone string) uuid.UUID {
	id := uuid.New()
	ctx := context.Background()
	_, err := f.st.CreateUser(ctx, store.CreateUserParams{ID: id, PhoneE164: phone, Role: store.UserRoleDriver, DisplayName: "Conductor"})
	require.NoError(t, err)
	require.NoError(t, f.st.CreateDriver(ctx, store.CreateDriverParams{UserID: id, QrToken: "qr-" + id.String()}))
	return id
}

var testVehicle = Vehicle{Plate: "kyq 12d", Brand: "Kia", Model: "Picanto", Color: "Gris", Year: 2022}

func date(s string) *string { return &s }

func (f *fixture) upload(t *testing.T, driverID uuid.UUID, in NewDocument) Document {
	ctx := context.Background()
	doc, uploads, err := f.svc.CreateDocument(ctx, driverID, in)
	require.NoError(t, err)
	for _, u := range uploads {
		f.objects.Put(ObjectKey(driverID, doc.ID, u.Side), bytes.Repeat([]byte{0xff}, 1000), "image/jpeg")
	}
	doc, err = f.svc.Submit(ctx, driverID, doc.ID)
	require.NoError(t, err)
	return doc
}

func allDocuments() []NewDocument {
	return []NewDocument{
		{DocType: "national_id", Number: "1020304050", Sides: []string{"front", "back"}},
		{DocType: "license", Number: "1020304050", ExpiresAt: date("2030-01-31"), Sides: []string{"front", "back"}},
		{DocType: "mandatory_insurance", Number: "SOAT-998877", ExpiresAt: date("2027-06-30"), Sides: []string{"front"}},
		{DocType: "technical_inspection", Number: "RTM-123", ExpiresAt: date("2027-09-30"), Sides: []string{"front"}},
		{DocType: "vehicle_registration", Number: "LT0001234", Sides: []string{"front", "back"}},
	}
}

// FR-001/FR-002/FR-005/FR-006: vehículo obligatorio, URLs firmadas por lado, fotos completas
// antes de pasar a revisión y estado de alta derivado.
func TestIntegrationOnboardingFlow(t *testing.T) {
	f := newFixture(t)
	ctx := context.Background()
	driver := f.newDriver(t, "+573101112233")

	ob, err := f.svc.Onboarding(ctx, driver)
	require.NoError(t, err)
	assert.Equal(t, StatusProfileIncomplete, ob.Status)
	assert.Nil(t, ob.Vehicle)
	assert.Len(t, ob.Documents, 5)
	assert.Equal(t, "unpaid", ob.SubscriptionStatus)
	assert.False(t, ob.CanGoOnline)

	_, _, err = f.svc.CreateDocument(ctx, driver, allDocuments()[1])
	assert.ErrorIs(t, err, ErrVehicleRequired, "vehículo antes de documentos")

	bad := testVehicle
	bad.Plate = "AB123"
	_, err = f.svc.SetVehicle(ctx, driver, bad)
	assert.ErrorIs(t, err, ErrInvalidVehicle)
	bad = testVehicle
	bad.Year = 2028
	_, err = f.svc.SetVehicle(ctx, driver, bad)
	assert.ErrorIs(t, err, ErrInvalidVehicle, "año máximo: el siguiente")
	v, err := f.svc.SetVehicle(ctx, driver, testVehicle)
	require.NoError(t, err)
	assert.Equal(t, "KYQ12D", v.Plate)

	ob, err = f.svc.Onboarding(ctx, driver)
	require.NoError(t, err)
	assert.Equal(t, StatusDocumentsPending, ob.Status)
	require.NotNil(t, ob.Vehicle)
	assert.Equal(t, 2022, ob.Vehicle.Year)

	noExpiry := allDocuments()[1]
	noExpiry.ExpiresAt = nil
	_, _, err = f.svc.CreateDocument(ctx, driver, noExpiry)
	assert.ErrorIs(t, err, ErrExpiresRequired, "la licencia exige vencimiento")
	expired := allDocuments()[2]
	expired.ExpiresAt = date("2026-10-27")
	_, _, err = f.svc.CreateDocument(ctx, driver, expired)
	assert.ErrorIs(t, err, ErrAlreadyExpired)
	backOnly := allDocuments()[0]
	backOnly.Sides = []string{"back"}
	_, _, err = f.svc.CreateDocument(ctx, driver, backOnly)
	assert.ErrorIs(t, err, ErrInvalidSides)

	doc, uploads, err := f.svc.CreateDocument(ctx, driver, allDocuments()[1])
	require.NoError(t, err)
	assert.Equal(t, "uploading", doc.Status)
	require.Len(t, uploads, 2)
	assert.Equal(t, "front", uploads[0].Side)
	assert.Contains(t, uploads[0].URL, ObjectKey(driver, doc.ID, "front"))
	assert.NotContains(t, uploads[0].URL, "1020304050", "el número no va en la clave del objeto")

	_, err = f.svc.Submit(ctx, driver, doc.ID)
	assert.ErrorIs(t, err, ErrPhotosMissing)
	f.objects.Put(ObjectKey(driver, doc.ID, "front"), []byte("jpeg"), "image/jpeg")
	_, err = f.svc.Submit(ctx, driver, doc.ID)
	assert.ErrorIs(t, err, ErrPhotosMissing, "falta el reverso")
	f.objects.Put(ObjectKey(driver, doc.ID, "back"), bytes.Repeat([]byte{1}, MaxPhotoBytes+1), "image/jpeg")
	_, err = f.svc.Submit(ctx, driver, doc.ID)
	assert.ErrorIs(t, err, ErrPhotoInvalid, "más de 2 MB")
	assert.False(t, f.objects.Has(ObjectKey(driver, doc.ID, "back")), "la foto inválida se borra")

	other := f.newDriver(t, "+573109998877")
	f.objects.Put(ObjectKey(driver, doc.ID, "back"), []byte("jpeg"), "image/jpeg")
	_, err = f.svc.Submit(ctx, other, doc.ID)
	assert.ErrorIs(t, err, ErrNotFound, "solo el dueño confirma")
	submitted, err := f.svc.Submit(ctx, driver, doc.ID)
	require.NoError(t, err)
	assert.Equal(t, "submitted", submitted.Status)
	assert.Len(t, submitted.Photos, 2, "el conductor ve sus fotos")
	_, err = f.svc.Submit(ctx, driver, doc.ID)
	assert.ErrorIs(t, err, ErrNotUploading)
	_, _, err = f.svc.CreateDocument(ctx, driver, allDocuments()[1])
	assert.ErrorIs(t, err, ErrDocumentInReview)

	// Una subida a medias se descarta al empezar otra del mismo tipo.
	first, _, err := f.svc.CreateDocument(ctx, driver, allDocuments()[0])
	require.NoError(t, err)
	f.objects.Put(ObjectKey(driver, first.ID, "front"), []byte("jpeg"), "image/jpeg")
	second, _, err := f.svc.CreateDocument(ctx, driver, allDocuments()[0])
	require.NoError(t, err)
	assert.NotEqual(t, first.ID, second.ID)
	assert.False(t, f.objects.Has(ObjectKey(driver, first.ID, "front")))

	for _, in := range allDocuments() {
		if in.DocType == "license" {
			continue
		}
		f.upload(t, driver, in)
	}
	ob, err = f.svc.Onboarding(ctx, driver)
	require.NoError(t, err)
	assert.Equal(t, StatusInReview, ob.Status, "los cinco enviados")
	assert.False(t, ob.CanGoOnline)
	for _, slot := range ob.Documents {
		require.NotNil(t, slot.Latest, slot.DocType)
		assert.Equal(t, "submitted", slot.Latest.Status)
		assert.Nil(t, slot.Current)
	}
}

func TestPlateAndNumberFormats(t *testing.T) {
	for plate, ok := range map[string]bool{"ABC123": true, "ABC12D": true, "abc 123": true, "AB1234": false, "ABCD12": false} {
		v := testVehicle
		v.Plate = plate
		v.normalize()
		assert.Equal(t, ok, v.validate(time.Date(2026, 1, 1, 0, 0, 0, 0, time.UTC)) == nil, plate)
	}
	assert.True(t, numberPattern.MatchString("1.020.304-5"))
	assert.False(t, numberPattern.MatchString(strings.Repeat("9", 41)))
	assert.False(t, numberPattern.MatchString("<script>"))
}
