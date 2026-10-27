import 'subscription.dart';

/// Motivo por el que un conductor no puede estar ONLINE.
enum OnlineBlockReason { subscriptionSuspended, kycExpired }

/// Resultado de evaluar si un conductor puede pasar o seguir ONLINE.
class OnlineDecision {
  const OnlineDecision.allowed() : blockReason = null;
  const OnlineDecision.blocked(OnlineBlockReason this.blockReason);

  final OnlineBlockReason? blockReason;

  bool get isAllowed => blockReason == null;
}

/// Decide si el conductor puede pasar o seguir ONLINE.
///
/// - RN-KYQ-002: requiere suscripción ACTIVE o GRACE_PERIOD.
/// - RN-KYQ-003: nunca se corta un viaje en curso.
/// - RN-KYQ-016: bloqueo si vence un documento KYC obligatorio.
OnlineDecision evaluateOnline({
  required Subscription subscription,
  required Iterable<DateTime> mandatoryDocumentExpirations,
  required bool hasTripInProgress,
  required DateTime now,
}) {
  if (hasTripInProgress) return const OnlineDecision.allowed();
  if (subscription.statusAt(now) == SubscriptionStatus.suspended) {
    return const OnlineDecision.blocked(OnlineBlockReason.subscriptionSuspended);
  }
  if (mandatoryDocumentExpirations.any((expiry) => !now.isBefore(expiry))) {
    return const OnlineDecision.blocked(OnlineBlockReason.kycExpired);
  }
  return const OnlineDecision.allowed();
}
