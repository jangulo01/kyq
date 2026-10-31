package radio

import (
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
)

func TestAccessPolicies(t *testing.T) {
	now := time.Date(2026, 10, 28, 12, 0, 0, 0, time.UTC)
	registered := now.Add(-5 * 24 * time.Hour) // 5 días de alta
	trial := Settings{TrialPolicy: PolicyTrial, TrialDays: 14}
	paid := Subject{Role: RoleDriver, CreatedAt: registered, PaidUntil: ptr(now.Add(time.Hour))}
	unpaid := Subject{Role: RoleDriver, CreatedAt: registered}

	cases := []struct {
		name     string
		sub      Subject
		settings Settings
		level    Level
		reason   string
		daysLeft *int
	}{
		{"suscripción activa", paid, trial, Full, "", nil},
		{"periodo de gracia (RN-KYQ-003)", Subject{Role: RoleDriver, CreatedAt: registered, PaidUntil: ptr(now.Add(-24 * time.Hour))}, trial, Full, "", nil},
		{"suspendido (007) aunque pague", Subject{Role: RoleDriver, Suspended: true, CreatedAt: registered, PaidUntil: ptr(now.Add(time.Hour))}, trial, None, ReasonSuspended, nil},
		{"prueba vigente: 9 días", unpaid, trial, Full, "", ptr(9)},
		{"prueba vencida", Subject{Role: RoleDriver, CreatedAt: now.Add(-15 * 24 * time.Hour)}, trial, None, ReasonTrialEnded, nil},
		{"suscripción vencida tras la gracia, en prueba", Subject{Role: RoleDriver, CreatedAt: registered, PaidUntil: ptr(now.Add(-4 * 24 * time.Hour))}, trial, Full, "", ptr(9)},
		{"solo con suscripción", unpaid, Settings{TrialPolicy: PolicySubscriptionOnly, TrialDays: 14}, None, ReasonNoSubscription, nil},
		{"solo escucha", unpaid, Settings{TrialPolicy: PolicyListenOnly, TrialDays: 14}, Listen, ReasonNoSubscription, nil},
		{"pasajero", Subject{Role: RolePassenger, CreatedAt: registered}, Settings{TrialPolicy: PolicySubscriptionOnly}, Full, "", nil},
		{"pasajero suspendido", Subject{Role: RolePassenger, Suspended: true}, trial, None, ReasonSuspended, nil},
		{"administrador no usa Radio", Subject{Role: "admin"}, trial, None, ReasonNotAllowed, nil},
	}
	for _, c := range cases {
		t.Run(c.name, func(t *testing.T) {
			d := Evaluate(c.sub, c.settings, now)
			assert.Equal(t, c.level, d.Level)
			assert.Equal(t, c.reason, d.Reason)
			assert.Equal(t, c.daysLeft, d.TrialDaysLeft)
		})
	}
}

// El último día de prueba aún cuenta como 1 día (no 0) hasta que vence.
func TestTrialLastDay(t *testing.T) {
	now := time.Date(2026, 10, 28, 12, 0, 0, 0, time.UTC)
	sub := Subject{Role: RoleDriver, CreatedAt: now.Add(-14*24*time.Hour + time.Hour)}
	d := Evaluate(sub, Settings{TrialPolicy: PolicyTrial, TrialDays: 14}, now)
	assert.Equal(t, Full, d.Level)
	assert.Equal(t, ptr(1), d.TrialDaysLeft)
}

func ptr[T any](v T) *T { return &v }
