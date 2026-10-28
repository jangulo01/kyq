package billing

import (
	"context"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func statuses(rows []SubscriptionRow) map[uuid.UUID]string {
	out := map[uuid.UUID]string{}
	for _, r := range rows {
		out[r.DriverID] = r.Status
	}
	return out
}

// FR-022: listado por estado con vencimiento y último pago.
func TestIntegrationAdminSubscriptionsByStatus(t *testing.T) {
	f := newFixture(t, true)
	ctx := context.Background()
	now := f.clock.now()
	active := f.newDriver(t, "+573101110010", true)
	f.setPaidUntil(t, active, now.AddDate(0, 0, 10))
	grace := f.newDriver(t, "+573101110011", true)
	f.setPaidUntil(t, grace, now.Add(-time.Hour))
	suspended := f.newDriver(t, "+573101110012", true)
	f.setPaidUntil(t, suspended, now.AddDate(0, 0, -5))
	unpaid := f.newDriver(t, "+573101110013", true)

	all, err := f.svc.Subscriptions(ctx, "")
	require.NoError(t, err)
	assert.Equal(t, map[uuid.UUID]string{active: "active", grace: "grace", suspended: "suspended", unpaid: "unpaid"}, statuses(all))

	only, err := f.svc.Subscriptions(ctx, "suspended")
	require.NoError(t, err)
	require.Len(t, only, 1)
	assert.Equal(t, suspended, only[0].DriverID)
	require.NotNil(t, only[0].PaidUntil)
	require.NotNil(t, only[0].GraceUntil)
	assert.Nil(t, only[0].LastPayment)

	_, err = f.svc.RegisterManualPayment(ctx, f.admin, suspended, ManualPayment{MethodDetail: "efectivo", Reference: "RC-001"})
	require.NoError(t, err)
	only, err = f.svc.Subscriptions(ctx, "active")
	require.NoError(t, err)
	assert.Len(t, only, 2)
	for _, r := range only {
		if r.DriverID == suspended {
			require.NotNil(t, r.LastPayment)
			assert.Equal(t, "manual", r.LastPayment.Method)
		}
	}
}

// FR-021, escenarios US5-2/3: el pago manual extiende igual que Bold y queda auditado; anularlo
// devuelve el vencimiento anterior y avisa al conductor con el motivo.
func TestIntegrationManualPaymentAndVoid(t *testing.T) {
	f := newFixture(t, true)
	ctx := context.Background()
	driver := f.newDriver(t, "+573101110014", true)
	before := f.clock.now().Add(-10 * time.Hour) // en gracia
	f.setPaidUntil(t, driver, before)

	_, err := f.svc.RegisterManualPayment(ctx, f.admin, driver, ManualPayment{MethodDetail: "efectivo"})
	assert.ErrorIs(t, err, ErrInvalidManual, "referencia obligatoria")
	_, err = f.svc.RegisterManualPayment(ctx, f.admin, uuid.New(), ManualPayment{MethodDetail: "efectivo", Reference: "RC-1"})
	assert.ErrorIs(t, err, ErrNotFound)

	manual, err := f.svc.RegisterManualPayment(ctx, f.admin, driver, ManualPayment{MethodDetail: "efectivo", Reference: "RC-1"})
	require.NoError(t, err)
	assert.Equal(t, "approved", manual.Status)
	assert.Equal(t, f.admin, manual.CreatedBy, "auditoría: quién registró")
	assert.Equal(t, "RC-1", *manual.ManualReference)
	assert.Equal(t, int64(priceMinor), manual.AmountMinor)
	want := f.clock.now().AddDate(0, 1, 0)
	assert.True(t, want.Equal(*f.paidUntil(t, driver)), "desde ahora: estaba en gracia")
	var updatedBy uuid.NullUUID
	require.NoError(t, f.st.Pool.QueryRow(ctx, "SELECT updated_by FROM subscriptions WHERE driver_id = $1", driver).Scan(&updatedBy))
	assert.Equal(t, uuid.NullUUID{UUID: f.admin, Valid: true}, updatedBy)

	_, err = f.svc.VoidPayment(ctx, f.admin, manual.ID, " ")
	assert.ErrorIs(t, err, ErrReasonRequired)
	voided, err := f.svc.VoidPayment(ctx, f.admin, manual.ID, "contracargo")
	require.NoError(t, err)
	assert.Equal(t, "voided", voided.Status)
	assert.Equal(t, "contracargo", *voided.VoidReason)
	require.NotNil(t, voided.VoidedBy)
	assert.Equal(t, f.admin, *voided.VoidedBy)
	assert.True(t, before.Equal(*f.paidUntil(t, driver)), "vuelve al vencimiento anterior")
	_, err = f.svc.VoidPayment(ctx, f.admin, manual.ID, "otra vez")
	assert.ErrorIs(t, err, ErrNotApproved)

	rows, err := f.st.ListNotices(ctx, driver)
	require.NoError(t, err)
	assert.Equal(t, "payment_voided", rows[0].Kind)
	assert.Contains(t, rows[0].Body, "contracargo")

	history, err := f.svc.DriverPayments(ctx, driver)
	require.NoError(t, err)
	require.Len(t, history, 1)
	assert.Equal(t, "voided", history[0].Status)
}

// Pagos repetidos por error: cada uno extiende un mes; anular uno que no es el último resta su
// periodo sin tocar los demás.
func TestIntegrationVoidMiddlePayment(t *testing.T) {
	f := newFixture(t, true)
	ctx := context.Background()
	driver := f.newDriver(t, "+573101110015", true)
	start := f.clock.now()
	first, err := f.svc.RegisterManualPayment(ctx, f.admin, driver, ManualPayment{MethodDetail: "efectivo", Reference: "RC-1"})
	require.NoError(t, err)
	_, err = f.svc.RegisterManualPayment(ctx, f.admin, driver, ManualPayment{MethodDetail: "efectivo", Reference: "RC-2"})
	require.NoError(t, err)
	assert.True(t, start.AddDate(0, 2, 0).Equal(*f.paidUntil(t, driver)))

	_, err = f.svc.VoidPayment(ctx, f.admin, first.ID, "pago duplicado")
	require.NoError(t, err)
	assert.True(t, start.AddDate(0, 2, 0).Add(-start.AddDate(0, 1, 0).Sub(start)).Equal(*f.paidUntil(t, driver)),
		"se resta el periodo del pago anulado")
}

// FR-013: precio por ciudad con fecha de vigencia; el conductor ve el vigente.
func TestIntegrationSubscriptionPriceEffectiveFrom(t *testing.T) {
	f := newFixture(t, false)
	ctx := context.Background()
	driver := f.newDriver(t, "+573101110016", true)

	view, err := f.svc.View(ctx, driver)
	require.NoError(t, err)
	assert.Nil(t, view.Price)
	assert.False(t, view.CanPay)
	_, err = f.svc.CreatePayment(ctx, driver)
	assert.ErrorIs(t, err, ErrPriceNotSet)

	_, err = f.svc.SetPrice(ctx, f.admin, "bogota", NewPrice{Currency: "COP", AmountMinor: 5_000_050})
	assert.ErrorIs(t, err, ErrInvalidPrice, "COP sin centavos")
	_, err = f.svc.SetPrice(ctx, f.admin, "lima", NewPrice{Currency: "PEN", AmountMinor: 5000})
	assert.ErrorIs(t, err, ErrNotFound, "ciudad sin tabla de tarifas")

	_, err = f.svc.SetPrice(ctx, f.admin, "bogota", NewPrice{Currency: "cop", AmountMinor: 5_000_000})
	require.NoError(t, err)
	next := f.clock.now().AddDate(0, 0, 3)
	_, err = f.svc.SetPrice(ctx, f.admin, "bogota", NewPrice{Currency: "COP", AmountMinor: 5_500_000, EffectiveFrom: &next})
	require.NoError(t, err)

	view, err = f.svc.View(ctx, driver)
	require.NoError(t, err)
	assert.Equal(t, &Price{AmountMinor: 5_000_000, Currency: "COP"}, view.Price, "el futuro aún no rige")
	f.clock.add(4 * 24 * time.Hour)
	view, err = f.svc.View(ctx, driver)
	require.NoError(t, err)
	assert.Equal(t, int64(5_500_000), view.Price.AmountMinor)

	var n int
	require.NoError(t, f.st.Pool.QueryRow(ctx, "SELECT count(*) FROM subscription_prices").Scan(&n))
	assert.Equal(t, 2, n)
}
