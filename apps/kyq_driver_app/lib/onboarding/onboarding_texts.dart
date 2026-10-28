import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_ui/kyq_ui.dart';

/// Explicación del estado de alta cuando aún no puede trabajar, o null si los documentos están
/// al día.
String? onboardingBlockMessage(OnboardingStatus? status) => switch (status) {
  OnboardingStatus.profileIncomplete => 'Completa los datos de tu vehículo para enviar tus documentos.',
  OnboardingStatus.documentsPending => 'Envía tus documentos para poder conectarte.',
  OnboardingStatus.inReview => 'En revisión: te avisaremos cuando un administrador apruebe tus documentos.',
  OnboardingStatus.documentsOk || null => null,
};

/// Motivo de bloqueo del ONLINE (`block_reason` de `/v1/driver/me` o código de error de
/// `/v1/driver/presence`). Con 002 el motivo puede nombrar el documento (RN-KYQ-016).
String blockReasonMessage(String? reason) {
  final r = reason ?? '';
  if (r.startsWith('subscription')) {
    return 'Tu suscripción no está activa. Paga tu mensualidad en "Mi suscripción" para conectarte.';
  }
  for (final type in DocType.values) {
    if (r.contains(docTypeToApi(type))) {
      return '${docTypeLabel(type)} vencido o sin aprobar: envía el nuevo en "Mis documentos".';
    }
  }
  return 'Algún documento obligatorio falta, está en revisión o venció. Revisa "Mis documentos".';
}

/// Por qué no puede conectarse: con `blocked_documents` (002) nombra el documento, como el
/// backend ("SOAT vencido: envía el nuevo").
String accountBlockMessage(DriverMe me) {
  final blocked = me.blockedDocuments;
  if (me.blockReason == 'subscription_suspended' || blocked.isEmpty) return blockReasonMessage(me.blockReason);
  final first = blocked.first;
  final label = docTypeLabel(first.docType);
  final text = first.problem == BlockedDocumentProblem.expired
      ? '$label vencido: envía el nuevo en "Mis documentos".'
      : 'Falta $label aprobado: envíalo desde "Mis documentos".';
  return blocked.length == 1 ? text : '$text Y ${blocked.length - 1} documento(s) más.';
}

/// Estado de un documento visto por el conductor.
({String label, DocumentVisualState state}) documentStatusLabel(OnboardingDocument d) {
  final latest = d.latest;
  final current = d.current;
  if (latest == null && current == null) return (label: 'Pendiente', state: DocumentVisualState.missing);
  final doc = latest ?? current!;
  if (doc.status == DocumentStatus.approved && doc.expired) {
    return (label: 'Vencido', state: DocumentVisualState.bad);
  }
  // Migrado de 001 o marcador sin fotos: vale por ahora, pero falta el documento real.
  if (doc.status == DocumentStatus.approved && doc.legacy) {
    return (label: 'Sube tu documento', state: DocumentVisualState.missing);
  }
  return switch (doc.status) {
    DocumentStatus.uploading => (label: 'Subida sin terminar', state: DocumentVisualState.missing),
    DocumentStatus.submitted => (label: 'En revisión', state: DocumentVisualState.waiting),
    DocumentStatus.approved || DocumentStatus.superseded => (label: 'Aprobado', state: DocumentVisualState.ok),
    DocumentStatus.rejected => (label: 'Rechazado', state: DocumentVisualState.bad),
  };
}

enum DocumentVisualState { missing, waiting, ok, bad }
