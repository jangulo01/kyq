import 'package:kyq_api/kyq_api.dart';

/// Motivo de cancelación (`cancel_reason` del modelo de datos) visto por el conductor.
String cancelReasonMessage(String? reason) => switch (reason) {
  'passenger' => 'El pasajero canceló el viaje.',
  'driver' => 'Cancelaste el viaje.',
  'offer_expired' => 'La oferta venció sin respuesta.',
  'offer_rejected' => 'Rechazaste la oferta.',
  'fare_rejected' => 'El pasajero no aceptó la nueva tarifa.',
  'negotiation_failed' => 'La negociación terminó sin acuerdo.',
  _ => 'El viaje se canceló.',
};

/// Mensaje para errores de las acciones del viaje.
String tripErrorMessage(ApiException e) => switch (e.code) {
  'expired' => 'Se agotó el tiempo para responder.',
  'invalid_transition' => 'El viaje ya cambió de estado.',
  'no_open_proposal' => 'Esa propuesta ya no está abierta.',
  'not_found' => 'Este viaje ya no existe.',
  'network' => 'Sin conexión con el servidor. Inténtalo de nuevo.',
  _ => e.message.isEmpty ? 'No se pudo completar la acción.' : e.message,
};
