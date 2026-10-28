package trippay

import (
	"context"
	"testing"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/kyq/backend/internal/billing"
)

// US5, FR-012, FR-013, SC-004: saldo = abonos − débitos − giros; no se gira más que el saldo;
// cada giro queda auditado y avisado.
func TestIntegrationSettlementAndPayouts(t *testing.T) {
	f := setup(t)
	ctx := context.Background()
	for range 2 {
		tripID := f.completeTrip(t)
		_, err := f.svc.PayWithBold(ctx, f.passenger, tripID)
		require.NoError(t, err)
		id := f.row(t, tripID).ID
		f.webhook(t, billing.EventSaleApproved, id, 14_700, "TX-"+id.String()[:8])
	}

	rows, err := f.svc.Settlements(ctx)
	require.NoError(t, err)
	require.Len(t, rows, 1)
	assert.Equal(t, f.driver, rows[0].DriverID)
	assert.Equal(t, "Carlos", rows[0].DisplayName)
	assert.Equal(t, int64(2*fare), rows[0].BalanceMinor)
	assert.Nil(t, rows[0].LastPayoutAt)

	for _, bad := range []NewPayout{
		{AmountMinor: 0, Currency: "COP", Reference: "TR-1"},
		{AmountMinor: 100, Currency: "pesos", Reference: "TR-1"},
		{AmountMinor: 100, Currency: "COP", Reference: "  "},
	} {
		_, err := f.svc.RegisterPayout(ctx, f.admin, f.driver, bad)
		assert.ErrorIs(t, err, ErrInvalidPayout)
	}
	_, err = f.svc.RegisterPayout(ctx, f.admin, f.driver, NewPayout{AmountMinor: 2*fare + 1, Currency: "COP", Reference: "TR-1"})
	assert.ErrorIs(t, err, ErrExceedsBalance, "US5-3")
	_, err = f.svc.RegisterPayout(ctx, f.admin, f.driver, NewPayout{AmountMinor: 100, Currency: "USD", Reference: "TR-1"})
	assert.ErrorIs(t, err, ErrExceedsBalance, "sin saldo en esa moneda")
	_, err = f.svc.RegisterPayout(ctx, f.admin, uuid.New(), NewPayout{AmountMinor: 100, Currency: "COP", Reference: "TR-1"})
	assert.ErrorIs(t, err, ErrNotFound)

	part, err := f.svc.RegisterPayout(ctx, f.admin, f.driver, NewPayout{AmountMinor: fare, Currency: "cop", Reference: " Bancolombia 123 ", Note: "primer giro"})
	require.NoError(t, err)
	assert.Equal(t, "COP", part.Currency)
	assert.Equal(t, "Bancolombia 123", part.Reference)
	assert.Equal(t, f.admin, part.CreatedBy)
	_, err = f.svc.RegisterPayout(ctx, f.admin, f.driver, NewPayout{AmountMinor: fare, Currency: "COP", Reference: "Bancolombia 124"})
	require.NoError(t, err)

	s := f.settlement(t)
	assert.Equal(t, []Balance{{Currency: "COP", CreditedMinor: 2 * fare, PaidOutMinor: 2 * fare}}, s.Balances, "saldo 0")
	require.Len(t, s.Entries, 4)
	assert.Equal(t, "payout", s.Entries[0].Kind)
	assert.Equal(t, int64(-fare), s.Entries[0].AmountMinor)
	assert.Equal(t, "Bancolombia 124", *s.Entries[0].Reference)
	assert.Len(t, s.Payments, 2)
	assert.Contains(t, f.noticeKinds(t), "payout_registered")

	rows, err = f.svc.Settlements(ctx)
	require.NoError(t, err)
	assert.Zero(t, rows[0].BalanceMinor)
	assert.NotNil(t, rows[0].LastPayoutAt)
	_, err = f.svc.RegisterPayout(ctx, f.admin, f.driver, NewPayout{AmountMinor: 1, Currency: "COP", Reference: "TR-9"})
	assert.ErrorIs(t, err, ErrExceedsBalance)
	_, err = f.svc.Settlement(ctx, uuid.New())
	assert.ErrorIs(t, err, ErrNotFound)
}
