import 'package:flutter_test/flutter_test.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_ui/kyq_ui.dart';

TripPayment _payment(TripPaymentStatus status, {TripPaymentMethod? method}) => TripPayment(
  id: 'tp1',
  tripId: 't1',
  driverId: 'd1',
  passengerId: 'p1',
  amountMinor: 1800000,
  currency: 'COP',
  driverAmountMinor: 1800000,
  status: status,
  method: method,
  createdAt: DateTime.utc(2026, 10, 27),
);

void main() {
  test('estado del pago del viaje: cada estado tiene texto y el pagado dice el medio', () {
    for (final s in TripPaymentStatus.values) {
      expect(tripPaymentStatusLabel(_payment(s)), isNotEmpty);
    }
    expect(tripPaymentStatusLabel(_payment(TripPaymentStatus.paid, method: TripPaymentMethod.bold)), 'Pagado con Bold');
    expect(
      tripPaymentStatusLabel(_payment(TripPaymentStatus.paid, method: TripPaymentMethod.cash)),
      'Pagado en efectivo',
    );
  });

  test('movimientos del libro', () {
    expect(ledgerKindLabel(LedgerKinds.tripCredit), 'Pago con Bold');
    expect(ledgerKindLabel(LedgerKinds.payout), 'Giro de Kyq');
    expect(ledgerKindLabel('otro'), 'otro');
  });
}
