package trippay

import (
	"testing"

	"github.com/stretchr/testify/assert"

	"github.com/kyq/backend/internal/store"
)

// research R3: quién puede hacer qué en cada estado del pago.
func TestTransitionTable(t *testing.T) {
	all := []store.TripPaymentStatus{
		statusPending, statusBoldInProgress, statusCashReported, statusPaid, statusUnpaid, statusDisputed, statusNeedsReview, statusVoided,
	}
	allowed := map[Action]map[store.TripPaymentStatus]store.TripPaymentStatus{
		ReportCash:  {statusPending: statusCashReported, statusUnpaid: statusCashReported},
		ConfirmCash: {statusPending: statusPaid, statusBoldInProgress: statusPaid, statusCashReported: statusPaid, statusUnpaid: statusPaid, statusDisputed: statusPaid},
		DisputeCash: {statusCashReported: statusDisputed},
		MarkUnpaid:  {statusPending: statusUnpaid},
		StartBold:   {statusPending: statusBoldInProgress, statusUnpaid: statusBoldInProgress},
	}
	owner := map[Action]Party{ReportCash: Passenger, ConfirmCash: Driver, DisputeCash: Driver, MarkUnpaid: Driver, StartBold: Passenger}
	for a, ok := range allowed {
		for _, from := range all {
			to, err := Transition(from, a, owner[a])
			if want, yes := ok[from]; yes {
				assert.NoError(t, err, "%s desde %s", a, from)
				assert.Equal(t, want, to, "%s desde %s", a, from)
				continue
			}
			if from == statusBoldInProgress && a != ConfirmCash && a != DisputeCash {
				assert.ErrorIs(t, err, ErrBoldInProgress, "%s con Bold en curso: primero la respuesta de Bold", a)
				continue
			}
			assert.ErrorIs(t, err, ErrInvalidState, "%s desde %s", a, from)
		}
	}
}

// FR-008: solo el pasajero paga o reporta; solo el conductor confirma, disputa o marca no pagado.
func TestTransitionWrongPartyIsForbidden(t *testing.T) {
	for a, party := range map[Action]Party{
		ReportCash: Driver, StartBold: Driver, ConfirmCash: Passenger, DisputeCash: Passenger, MarkUnpaid: Passenger,
	} {
		_, err := Transition(statusPending, a, party)
		assert.ErrorIs(t, err, ErrForbidden, "%s por %s", a, party)
	}
	_, err := Transition(statusPending, Action("pay_twice"), Passenger)
	assert.ErrorIs(t, err, ErrForbidden)
}

// RN-KYQ-001: el conductor recibe el 100 % de la tarifa y Kyq no cobra comisión.
func TestSettleGivesDriverAllOfTheFare(t *testing.T) {
	for _, fare := range []int64{1, 700_000, 1_800_000, 12_345_678} {
		driver, commission := Settle(fare)
		assert.Equal(t, fare, driver)
		assert.Zero(t, commission)
	}
}

func TestFormatMoney(t *testing.T) {
	assert.Equal(t, "$ 18.000 COP", formatMoney(1_800_000, "COP"))
	assert.Equal(t, "$ 1.234.567,89 COP", formatMoney(123_456_789, "COP"))
	assert.Equal(t, "$ 0,05 COP", formatMoney(5, "COP"))
	assert.Equal(t, "-$ 500 COP", formatMoney(-50_000, "COP"))
}
