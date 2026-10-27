import 'package:kyq_domain/kyq_domain.dart';
import 'package:test/test.dart';

void main() {
  final paidUntil = DateTime.utc(2026, 11, 1);
  final subscription = Subscription(paidUntil: paidUntil);

  group('RN-KYQ-001 cero comisión', () {
    test('el conductor recibe el 100 % de la tarifa', () {
      final settlement = TripSettlement.forFare(1250000);
      expect(settlement.driverMinorUnits, 1250000);
      expect(settlement.platformCommissionMinorUnits, 0);
    });

    test('rechaza tarifas negativas', () {
      expect(() => TripSettlement.forFare(-1), throwsArgumentError);
    });
  });

  group('RN-KYQ-002 acceso condicionado a suscripción', () {
    OnlineDecision at(DateTime now) => evaluateOnline(
          subscription: subscription,
          mandatoryDocumentExpirations: const [],
          hasTripInProgress: false,
          now: now,
        );

    test('ACTIVE permite ONLINE', () {
      expect(at(paidUntil.subtract(const Duration(days: 1))).isAllowed, isTrue);
    });

    test('SUSPENDED bloquea ONLINE', () {
      final decision = at(paidUntil.add(const Duration(hours: 73)));
      expect(decision.blockReason, OnlineBlockReason.subscriptionSuspended);
    });
  });

  group('RN-KYQ-003 periodo de gracia de 72 h', () {
    test('estado durante y después de la gracia', () {
      expect(subscription.statusAt(paidUntil), SubscriptionStatus.gracePeriod);
      expect(
        subscription.statusAt(paidUntil.add(const Duration(hours: 71, minutes: 59))),
        SubscriptionStatus.gracePeriod,
      );
      expect(
        subscription.statusAt(paidUntil.add(const Duration(hours: 72))),
        SubscriptionStatus.suspended,
      );
    });

    test('GRACE_PERIOD permite ONLINE', () {
      final decision = evaluateOnline(
        subscription: subscription,
        mandatoryDocumentExpirations: const [],
        hasTripInProgress: false,
        now: paidUntil.add(const Duration(hours: 10)),
      );
      expect(decision.isAllowed, isTrue);
    });

    test('nunca corta un viaje en curso aunque la suscripción esté suspendida', () {
      final decision = evaluateOnline(
        subscription: subscription,
        mandatoryDocumentExpirations: [paidUntil],
        hasTripInProgress: true,
        now: paidUntil.add(const Duration(days: 30)),
      );
      expect(decision.isAllowed, isTrue);
    });
  });

  group('RN-KYQ-016 bloqueo por vencimiento KYC', () {
    final now = paidUntil.subtract(const Duration(days: 5));

    test('documento vencido bloquea ONLINE', () {
      final decision = evaluateOnline(
        subscription: subscription,
        mandatoryDocumentExpirations: [now.subtract(const Duration(days: 1))],
        hasTripInProgress: false,
        now: now,
      );
      expect(decision.blockReason, OnlineBlockReason.kycExpired);
    });

    test('documentos vigentes permiten ONLINE', () {
      final decision = evaluateOnline(
        subscription: subscription,
        mandatoryDocumentExpirations: [now.add(const Duration(days: 90))],
        hasTripInProgress: false,
        now: now,
      );
      expect(decision.isAllowed, isTrue);
    });
  });
}
