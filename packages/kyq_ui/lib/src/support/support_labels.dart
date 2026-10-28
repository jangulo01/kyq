import 'package:kyq_api/kyq_api.dart';

/// Nombre de un tema de soporte para personas (009 FR-005).
String supportTopicLabel(SupportTopic t) => switch (t) {
  SupportTopic.trip => 'Un viaje',
  SupportTopic.payment => 'Un pago',
  SupportTopic.lostItem => 'Objeto olvidado',
  SupportTopic.safety => 'Seguridad',
  SupportTopic.account => 'Mi cuenta',
  SupportTopic.other => 'Otro',
};

/// Estado de un caso para el usuario (009 FR-007).
String supportStatusLabel(SupportStatus s) => switch (s) {
  SupportStatus.open => 'Abierto',
  SupportStatus.inProgress => 'En atención',
  SupportStatus.waitingUser => 'Esperando tu respuesta',
  SupportStatus.resolved => 'Resuelto',
  SupportStatus.closed => 'Cerrado',
};
