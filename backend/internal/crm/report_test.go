package crm

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/kyq/backend/internal/auth"
	"github.com/kyq/backend/internal/store"
	"github.com/kyq/backend/internal/testdb"
)

func date(m time.Month, d int) time.Time { return time.Date(2026, m, d, 0, 0, 0, 0, time.UTC) }

func at(t time.Time) *time.Time { return &t }

func TestWeekStartIsMonday(t *testing.T) {
	assert.Equal(t, date(10, 26), weekStart(date(10, 27).Add(15*time.Hour)), "martes → lunes")
	assert.Equal(t, date(10, 26), weekStart(date(10, 26)), "lunes")
	assert.Equal(t, date(10, 19), weekStart(date(10, 25)), "domingo → lunes anterior")
}

// FR-010: crecimiento, abandono y serie semanal.
func TestSummarizeAffiliations(t *testing.T) {
	spans := []AffiliationSpan{
		{CreatedAt: date(9, 1)},                             // activa al inicio y hoy
		{CreatedAt: date(9, 1), RemovedAt: at(date(10, 7))}, // activa al inicio, baja en el periodo
		{CreatedAt: date(10, 6)},                            // nueva
		{CreatedAt: date(10, 13), RemovedAt: at(date(10, 14))},
		{CreatedAt: date(9, 1), RemovedAt: at(date(9, 15))}, // baja antes del periodo
	}
	from, end, now := date(10, 5), date(10, 19), date(10, 27) // lunes 5 a domingo 18
	a := SummarizeAffiliations(spans, from, end, now)
	assert.Equal(t, 2, a.ActiveNow)
	assert.Equal(t, 2, a.ActiveAtStart)
	assert.Equal(t, 2, a.Created)
	assert.Equal(t, 2, a.Removed)
	assert.Equal(t, 0, a.Net)
	require.NotNil(t, a.ChurnRate)
	assert.Equal(t, 0.5, *a.ChurnRate, "2 bajas / (2 activas al inicio + 2 nuevas)")
	assert.Equal(t, []Week{
		{WeekStart: "2026-10-05", Created: 1, Removed: 1, ActiveEnd: 2},
		{WeekStart: "2026-10-12", Created: 1, Removed: 1, ActiveEnd: 2},
	}, a.Weekly)

	none := SummarizeAffiliations(nil, from, end, now)
	assert.Nil(t, none.ChurnRate)
	assert.Len(t, none.Weekly, 2)
}

// FR-011: parejas que repiten.
func TestSummarizeRepeat(t *testing.T) {
	r := SummarizeRepeat([]int64{3, 1})
	assert.Equal(t, 2, r.Pairs)
	assert.Equal(t, 1, r.RepeatPairs)
	assert.Equal(t, 4, r.CompletedTrips)
	assert.Equal(t, 0.5, *r.RepeatRate)
	assert.Equal(t, 2.0, *r.AvgTripsPerPair)
	empty := SummarizeRepeat(nil)
	assert.Nil(t, empty.RepeatRate)
	assert.Nil(t, empty.AvgTripsPerPair)
}

// FR-012 (SC-008 de 001): solo cuentan las afiliaciones con 30 días cumplidos.
func TestSummarizeSC008(t *testing.T) {
	now := date(10, 27)
	rows := []AffiliationRequest{
		{CreatedAt: date(8, 10), Requested: true}, {CreatedAt: date(8, 10), Requested: true},
		{CreatedAt: date(8, 10), Requested: true}, {CreatedAt: date(8, 10), Requested: true},
		{CreatedAt: date(8, 10), Requested: false},
		{CreatedAt: date(10, 20), Requested: false}, // en curso
	}
	s := SummarizeSC008(rows, now)
	assert.Equal(t, 5, s.Matured)
	assert.Equal(t, 4, s.WithRequest30d)
	assert.Equal(t, 0.8, *s.Rate)
	assert.True(t, *s.Met, "80 % cumple la meta")
	assert.Equal(t, 1, s.Pending)
	assert.Equal(t, SC008Target, s.Target)

	s = SummarizeSC008(rows[2:], now)
	assert.Equal(t, 0.6667, *s.Rate, "4 decimales")
	assert.False(t, *s.Met)
	s = SummarizeSC008(rows[5:], now)
	assert.Nil(t, s.Rate)
	assert.Nil(t, s.Met, "sin afiliaciones maduras no se puede decir")
}

// T022: el informe con base real coincide con los valores calculados a mano (escenarios US3).
func TestIntegrationCrmReport(t *testing.T) {
	st := testdb.New(t)
	ctx := context.Background()
	exec := func(sql string, args ...any) {
		_, err := st.Pool.Exec(ctx, sql, args...)
		require.NoError(t, err)
	}
	admin, d1, d2 := uuid.New(), uuid.New(), uuid.New()
	passengers := make([]uuid.UUID, 7)
	users := []store.CreateUserParams{
		{ID: admin, PhoneE164: "+573000000000", Role: store.UserRoleAdmin, DisplayName: "Admin"},
		{ID: d1, PhoneE164: "+573100000001", Role: store.UserRoleDriver, DisplayName: "Carlos"},
		{ID: d2, PhoneE164: "+573100000002", Role: store.UserRoleDriver, DisplayName: "Diana"},
	}
	for i := range passengers {
		passengers[i] = uuid.New()
		users = append(users, store.CreateUserParams{
			ID: passengers[i], PhoneE164: "+57320000000" + string(rune('0'+i)), Role: store.UserRolePassenger, DisplayName: "Pasajero",
		})
	}
	for _, u := range users {
		_, err := st.CreateUser(ctx, u)
		require.NoError(t, err)
	}
	for _, d := range []uuid.UUID{d1, d2} {
		require.NoError(t, st.CreateDriver(ctx, store.CreateDriverParams{UserID: d, QrToken: "qr-" + d.String()}))
	}
	require.NoError(t, st.UpsertFareTable(ctx, store.UpsertFareTableParams{
		CityCode: "bogota", Currency: "COP", BaseMinor: 1, PerKmMinor: 1, PerMinuteMinor: 1, MinimumMinor: 1, RoundingMinor: 1, UpdatedBy: admin,
	}))
	affiliate := func(p, d uuid.UUID, created time.Time, removed *time.Time) {
		exec(`INSERT INTO affiliations (passenger_id, driver_id, source, created_at, removed_at) VALUES ($1, $2, 'qr_scan', $3, $4)`, p, d, created, removed)
	}
	trip := func(p, d uuid.UUID, created time.Time, status string) {
		exec(`INSERT INTO trips (id, passenger_id, driver_id, city_code, currency, pickup_lat, pickup_lng, dropoff_lat,
		        dropoff_lng, route_distance_m, route_duration_s, suggested_fare_minor, status, created_at, completed_at,
		        cancelled_at, cancel_reason)
		      VALUES ($1, $2, $3, 'bogota', 'COP', 4.6, -74.08, 4.65, -74.05, 1000, 300, 800000, $4::trip_status, $5,
		        CASE WHEN $4 = 'COMPLETED' THEN $5::timestamptz + interval '20 minutes' END,
		        CASE WHEN $4 = 'CANCELLED' THEN $5::timestamptz + interval '1 minute' END,
		        CASE WHEN $4 = 'CANCELLED' THEN 'offer_expired'::trip_cancel_reason END)`,
			uuid.New(), p, d, status, created)
	}
	for i := range 5 {
		affiliate(passengers[i], d1, date(8, 10), nil)
	}
	affiliate(passengers[5], d1, date(10, 20), nil)           // en curso para SC-008
	affiliate(passengers[6], d2, date(7, 1), at(date(9, 15))) // activa al inicio, baja en el periodo
	trip(passengers[0], d1, date(8, 15), "COMPLETED")         // tres completados: pareja que repite
	trip(passengers[0], d1, date(9, 1), "COMPLETED")
	trip(passengers[0], d1, date(9, 20), "COMPLETED")
	trip(passengers[1], d1, date(8, 15), "COMPLETED")
	trip(passengers[2], d1, date(8, 15), "CANCELLED") // pidió (aunque no se hizo)
	trip(passengers[3], d1, date(8, 20), "CANCELLED")
	trip(passengers[4], d1, date(9, 25), "CANCELLED") // fuera de los 30 días

	now := date(10, 27).Add(12 * time.Hour)
	issuer := auth.NewTokenIssuer([]byte("test-secret-test-secret-test-secret!"), nil)
	mux := http.NewServeMux()
	(&Handlers{Store: st, Moderation: &Moderation{Store: st}, Now: func() time.Time { return now }}).Register(mux, auth.RequireAuth(issuer))
	get := func(id uuid.UUID, role, path string, out any) int {
		tok, err := issuer.IssueAccess(auth.Principal{UserID: id, Role: role})
		require.NoError(t, err)
		req := httptest.NewRequest(http.MethodGet, path, nil)
		req.Header.Set("Authorization", "Bearer "+tok)
		rec := httptest.NewRecorder()
		mux.ServeHTTP(rec, req)
		if out != nil && rec.Code == http.StatusOK {
			require.NoError(t, json.NewDecoder(rec.Body).Decode(out))
		}
		return rec.Code
	}

	var r Report
	require.Equal(t, http.StatusOK, get(admin, auth.RoleAdmin, "/v1/admin/crm?from=2026-08-01&to=2026-10-27", &r))
	assert.Equal(t, "2026-08-01", r.From)
	assert.Equal(t, "2026-10-27", r.To)
	a := r.Affiliations
	assert.Equal(t, 6, a.ActiveNow)
	assert.Equal(t, 1, a.ActiveAtStart)
	assert.Equal(t, 6, a.Created)
	assert.Equal(t, 1, a.Removed)
	assert.Equal(t, 5, a.Net)
	assert.InDelta(t, 1.0/7.0, *a.ChurnRate, 0.0001)
	assert.Equal(t, "2026-07-27", a.Weekly[0].WeekStart, "la serie empieza el lunes de la semana de from")

	assert.Equal(t, Repeat{Pairs: 2, RepeatPairs: 1, RepeatRate: new(0.5), CompletedTrips: 4, AvgTripsPerPair: new(2.0)}, r.Repeat)
	assert.Equal(t, 5, r.SC008.Matured)
	assert.Equal(t, 4, r.SC008.WithRequest30d)
	assert.Equal(t, 0.8, *r.SC008.Rate)
	assert.True(t, *r.SC008.Met)
	assert.Equal(t, 1, r.SC008.Pending)

	require.Len(t, r.ChurnedDrivers, 1)
	assert.Equal(t, ChurnedDriver{DriverID: d2, DisplayName: "Diana", Removed: 1, ActiveNow: 0}, r.ChurnedDrivers[0])
	require.Len(t, r.InactiveChosenDrivers, 1, "Carlos tiene afiliados y su último viaje fue hace más de 30 días")
	inactive := r.InactiveChosenDrivers[0]
	assert.Equal(t, d1, inactive.DriverID)
	assert.Equal(t, int64(6), inactive.ActiveAffiliations)
	require.NotNil(t, inactive.LastCompletedAt)
	assert.True(t, inactive.LastCompletedAt.Equal(date(9, 20).Add(20*time.Minute)))

	// Por defecto: las últimas 12 semanas hasta hoy.
	require.Equal(t, http.StatusOK, get(admin, auth.RoleAdmin, "/v1/admin/crm", &r))
	assert.Equal(t, "2026-10-27", r.To)
	assert.Equal(t, "2026-08-05", r.From)
	for _, bad := range []string{"?from=2026-10-27&to=2026-10-01", "?from=2025-01-01&to=2026-10-27", "?to=ayer"} {
		assert.Equal(t, http.StatusBadRequest, get(admin, auth.RoleAdmin, "/v1/admin/crm"+bad, nil), bad)
	}
	assert.Equal(t, http.StatusForbidden, get(d1, auth.RoleDriver, "/v1/admin/crm", nil))
}
