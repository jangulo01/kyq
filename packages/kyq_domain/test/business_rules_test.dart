import 'package:kyq_domain/kyq_domain.dart';
import 'package:test/test.dart';

/// Los cinco obligatorios aprobados; los que vencen, el día [expiry].
List<GateDocument> docs(DateTime expiry) => [
  for (final t in KycDocTypes.mandatory) GateDocument(type: t, expiresAt: KycDocTypes.expires(t) ? expiry : null),
];

void main() {
  final paidUntil = DateTime.utc(2026, 11, 1);
  final subscription = Subscription(paidUntil: paidUntil);
  final farFuture = DateTime.utc(2030);

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
    OnlineDecision at(DateTime now) =>
        evaluateOnline(subscription: subscription, documents: docs(farFuture), hasTripInProgress: false, now: now);

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
      expect(subscription.statusAt(paidUntil.add(const Duration(hours: 72))), SubscriptionStatus.suspended);
    });

    test('GRACE_PERIOD permite ONLINE', () {
      final decision = evaluateOnline(
        subscription: subscription,
        documents: docs(farFuture),
        hasTripInProgress: false,
        now: paidUntil.add(const Duration(hours: 10)),
      );
      expect(decision.isAllowed, isTrue);
    });

    test('nunca corta un viaje en curso aunque la suscripción esté suspendida', () {
      final decision = evaluateOnline(
        subscription: subscription,
        documents: docs(paidUntil),
        hasTripInProgress: true,
        now: paidUntil.add(const Duration(days: 30)),
      );
      expect(decision.isAllowed, isTrue);
    });
  });

  group('RN-KYQ-016 bloqueo por vencimiento KYC', () {
    final now = paidUntil.subtract(const Duration(days: 5));

    OnlineDecision gate(List<GateDocument> documents, {DateTime? at}) =>
        evaluateOnline(subscription: subscription, documents: documents, hasTripInProgress: false, now: at ?? now);

    test('documento vencido bloquea ONLINE', () {
      final decision = gate(docs(now.subtract(const Duration(days: 1))));
      expect(decision.blockReason, OnlineBlockReason.kycExpired);
      expect(decision.documentProblems, [
        const DocumentProblem(KycDocTypes.license, DocumentProblemKind.expired),
        const DocumentProblem(KycDocTypes.mandatoryInsurance, DocumentProblemKind.expired),
        const DocumentProblem(KycDocTypes.technicalInspection, DocumentProblemKind.expired),
      ]);
    });

    test('documentos vigentes permiten ONLINE', () {
      expect(gate(docs(now.add(const Duration(days: 90)))).isAllowed, isTrue);
    });

    test('deja de valer el mismo día que vence (UTC)', () {
      final day = DateTime.utc(2026, 10, 27);
      expect(gate(docs(day), at: day.subtract(const Duration(minutes: 1))).isAllowed, isTrue);
      expect(gate(docs(day), at: day.add(const Duration(hours: 1))).isAllowed, isFalse);
    });

    test('los cinco tipos son obligatorios: falta uno, bloquea', () {
      final withoutId = docs(farFuture).where((d) => d.type != KycDocTypes.nationalId).toList();
      expect(gate(withoutId).documentProblems, [
        const DocumentProblem(KycDocTypes.nationalId, DocumentProblemKind.missing),
      ]);
    });

    test('un envío sin aprobar no cuenta; el aprobado anterior sigue valiendo (FR-007)', () {
      final soat = [
        GateDocument(type: KycDocTypes.mandatoryInsurance, expiresAt: now.add(const Duration(days: 3))),
        GateDocument(type: KycDocTypes.mandatoryInsurance, expiresAt: farFuture, approved: false),
      ];
      final all = [...docs(farFuture).where((d) => d.type != KycDocTypes.mandatoryInsurance), ...soat];
      expect(gate(all).isAllowed, isTrue);
      expect(gate(all, at: now.add(const Duration(days: 4))).documentProblems, [
        const DocumentProblem(KycDocTypes.mandatoryInsurance, DocumentProblemKind.expired),
      ]);
    });

    test('cédula y tarjeta de propiedad no vencen; revisión técnico-mecánica exenta hasta una fecha', () {
      final exemptUntil = now.add(const Duration(days: 60));
      final all = [
        // Marcadores de la migración (legacy): cédula aprobada sin fecha y revisión exenta.
        const GateDocument(type: KycDocTypes.nationalId),
        const GateDocument(type: KycDocTypes.vehicleRegistration),
        GateDocument(type: KycDocTypes.license, expiresAt: farFuture),
        GateDocument(type: KycDocTypes.mandatoryInsurance, expiresAt: farFuture),
        GateDocument(type: KycDocTypes.technicalInspection, exemptUntil: exemptUntil),
      ];
      expect(gate(all).isAllowed, isTrue);
      // Pasada la suscripción se mira la regla de documentos sola.
      expect(documentProblems(all, exemptUntil), [
        const DocumentProblem(KycDocTypes.technicalInspection, DocumentProblemKind.expired),
      ]);
      // La exención no aplica a otros tipos.
      final soatExempt = [
        ...all.where((d) => d.type != KycDocTypes.mandatoryInsurance),
        GateDocument(type: KycDocTypes.mandatoryInsurance, exemptUntil: farFuture),
      ];
      expect(gate(soatExempt).documentProblems.single.type, KycDocTypes.mandatoryInsurance);
    });
  });
}
