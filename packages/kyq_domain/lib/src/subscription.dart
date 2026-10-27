/// Estado de la suscripción mensual SaaS del conductor autónomo.
enum SubscriptionStatus { active, gracePeriod, suspended }

/// Suscripción mensual del conductor, pagada hasta [paidUntil].
class Subscription {
  const Subscription({required this.paidUntil});

  /// RN-KYQ-003: horas de gracia tras fallar la renovación.
  static const gracePeriod = Duration(hours: 72);

  final DateTime paidUntil;

  DateTime get graceUntil => paidUntil.add(gracePeriod);

  SubscriptionStatus statusAt(DateTime now) {
    if (now.isBefore(paidUntil)) return SubscriptionStatus.active;
    if (now.isBefore(graceUntil)) return SubscriptionStatus.gracePeriod;
    return SubscriptionStatus.suspended;
  }
}
