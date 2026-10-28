import 'subscription.dart';

/// Motivo por el que un conductor no puede estar ONLINE.
enum OnlineBlockReason { subscriptionSuspended, kycExpired }

/// Resultado de evaluar si un conductor puede pasar o seguir ONLINE.
class OnlineDecision {
  const OnlineDecision.allowed() : blockReason = null, documentProblems = const [];
  const OnlineDecision.blocked(OnlineBlockReason this.blockReason, {this.documentProblems = const []});

  final OnlineBlockReason? blockReason;

  /// Con [OnlineBlockReason.kycExpired], qué documentos bloquean y por qué.
  final List<DocumentProblem> documentProblems;

  bool get isAllowed => blockReason == null;
}

/// Tipos de documento obligatorios (002, FR-005), con los valores del contrato.
abstract final class KycDocTypes {
  static const nationalId = 'national_id';
  static const license = 'license';
  static const mandatoryInsurance = 'mandatory_insurance';
  static const technicalInspection = 'technical_inspection';
  static const vehicleRegistration = 'vehicle_registration';

  /// Todos deben estar aprobados y vigentes para trabajar, en este orden.
  static const mandatory = [nationalId, license, mandatoryInsurance, technicalInspection, vehicleRegistration];

  /// Cédula y tarjeta de propiedad no vencen: nunca bloquean por fecha.
  static bool expires(String type) => type != nationalId && type != vehicleRegistration;
}

/// Documento tal como lo ve la regla: un aprobado (o no) de un tipo. Las fechas son días de
/// calendario en UTC; [exemptUntil] solo cuenta en la revisión técnico-mecánica de un vehículo
/// nuevo. Los documentos de 001 migrados sin fotos (legacy) siguen contando si están aprobados.
class GateDocument {
  const GateDocument({required this.type, this.expiresAt, this.exemptUntil, this.approved = true});

  final String type;
  final DateTime? expiresAt;
  final DateTime? exemptUntil;
  final bool approved;

  /// Vigente el día [today] (00:00 UTC): deja de valer el mismo día que vence.
  bool inForce(DateTime today) {
    if (!approved) return false;
    if (!KycDocTypes.expires(type)) return true;
    final expires = expiresAt;
    if (expires != null && today.isBefore(_day(expires))) return true;
    final exempt = exemptUntil;
    return type == KycDocTypes.technicalInspection && exempt != null && today.isBefore(_day(exempt));
  }
}

enum DocumentProblemKind { missing, expired }

/// Documento obligatorio que bloquea ONLINE (RN-KYQ-016).
class DocumentProblem {
  const DocumentProblem(this.type, this.kind);

  final String type;
  final DocumentProblemKind kind;

  @override
  bool operator ==(Object other) => other is DocumentProblem && other.type == type && other.kind == kind;

  @override
  int get hashCode => Object.hash(type, kind);

  @override
  String toString() => '$type: ${kind.name}';
}

DateTime _day(DateTime d) {
  final u = d.isUtc ? d : DateTime.utc(d.year, d.month, d.day);
  return DateTime.utc(u.year, u.month, u.day);
}

/// Documentos obligatorios que no están vigentes, en el orden de [KycDocTypes.mandatory]. Falta
/// = ningún aprobado de ese tipo; vencido = hay aprobados pero ninguno vigente.
List<DocumentProblem> documentProblems(Iterable<GateDocument> documents, DateTime now) {
  final today = _day(now.toUtc());
  return [
    for (final type in KycDocTypes.mandatory)
      if (documents.where((d) => d.type == type && d.approved) case final approved
          when !approved.any((d) => d.inForce(today)))
        DocumentProblem(type, approved.isEmpty ? DocumentProblemKind.missing : DocumentProblemKind.expired),
  ];
}

/// Decide si el conductor puede pasar o seguir ONLINE. Es el espejo de
/// `backend/internal/drivers/gate.go` (`EvaluateOnline`).
///
/// - RN-KYQ-002: requiere suscripción ACTIVE o GRACE_PERIOD.
/// - RN-KYQ-003: nunca se corta un viaje en curso.
/// - RN-KYQ-016: los cinco documentos obligatorios aprobados y vigentes.
OnlineDecision evaluateOnline({
  required Subscription subscription,
  required Iterable<GateDocument> documents,
  required bool hasTripInProgress,
  required DateTime now,
}) {
  if (hasTripInProgress) return const OnlineDecision.allowed();
  if (subscription.statusAt(now) == SubscriptionStatus.suspended) {
    return const OnlineDecision.blocked(OnlineBlockReason.subscriptionSuspended);
  }
  final problems = documentProblems(documents, now);
  if (problems.isNotEmpty) return OnlineDecision.blocked(OnlineBlockReason.kycExpired, documentProblems: problems);
  return const OnlineDecision.allowed();
}
