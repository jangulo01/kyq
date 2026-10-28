package telemetry_test

import (
	"context"
	"net/http"
	"net/http/httptest"
	"sync"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/kyq/backend/internal/store"
	"github.com/kyq/backend/internal/telemetry"
	"github.com/kyq/backend/internal/testdb"
)

type usageLog struct {
	mu    sync.Mutex
	voice map[uuid.UUID]int64
}

func (u *usageLog) Add(driverID uuid.UUID, kind telemetry.Kind, n int64) {
	u.mu.Lock()
	defer u.mu.Unlock()
	if kind == telemetry.VoiceSeconds {
		u.voice[driverID] += n
	}
}

// Los segundos de voz de una pre-consulta (sala pre-{id}) cuentan en el coste del conductor
// (specs/005-ptt-extras, research R10; constitución VII).
func TestIntegrationPreconsultVoiceCountsForTheDriver(t *testing.T) {
	st := testdb.New(t)
	ctx := context.Background()
	driver, passenger := uuid.New(), uuid.New()
	for _, u := range []store.CreateUserParams{
		{ID: driver, PhoneE164: "+573100000001", Role: store.UserRoleDriver, DisplayName: "Carlos"},
		{ID: passenger, PhoneE164: "+573200000002", Role: store.UserRolePassenger, DisplayName: "Ana"},
	} {
		_, err := st.CreateUser(ctx, u)
		require.NoError(t, err)
	}
	require.NoError(t, st.CreateDriver(ctx, store.CreateDriverParams{UserID: driver, QrToken: "qr-carlos-0000000", VehiclePlate: "KYQ001", VehicleDescription: "Kia"}))
	id := uuid.New()
	now := time.Now()
	require.NoError(t, st.InsertPreconsult(ctx, store.InsertPreconsultParams{
		ID: id, PassengerID: passenger, DriverID: driver, RoomName: "pre-" + id.String(), OpenedAt: now,
		JoinDeadline: now.Add(30 * time.Second), ClosesAt: now.Add(2 * time.Minute),
	}))

	usage := &usageLog{voice: map[uuid.UUID]int64{}}
	mux := http.NewServeMux()
	(&telemetry.LiveKitWebhook{APIKey: "devkey", APISecret: "secret", Store: st, Usage: usage}).Register(mux)
	for _, body := range [][]byte{
		participantLeft("pre-"+id.String(), 1000, 1040),
		participantLeft("pre-"+id.String(), 1000, 1020),
		participantLeft("pre-"+uuid.NewString(), 1000, 1060), // consulta desconocida: no cuenta
	} {
		w := httptest.NewRecorder()
		mux.ServeHTTP(w, signed(t, "secret", body))
		assert.Equal(t, http.StatusOK, w.Code)
	}
	assert.Equal(t, map[uuid.UUID]int64{driver: 60}, usage.voice)
}
