// Eventos de specs/001-chosen-driver-trip-ptt/contracts/realtime.md, `notice.created` de 002,
// `preconsult.*` de 005, los `sos.*` de 003 y `trip_payment.*` de 004.

/// Nombres de canal autorizados por el backend.
abstract final class Channels {
  static String user(String userId) => 'user:$userId';
  static String driverPresence(String driverId) => 'driver_presence:$driverId';
  static String trip(String tripId) => 'trip:$tripId';

  /// Torre de control del panel (007): solo admins.
  static const adminTower = 'admin:tower';

  /// Bandeja de soporte del panel (009): solo admins.
  static const adminSupport = 'admin:support';

  /// Cola de la consola de emergencias (solo operadores, 003).
  static const opsSos = 'ops:sos';

  /// Ubicación en vivo de una alerta (solo operadores, 003).
  static String sos(String alertId) => 'sos:$alertId';
}

/// Evento recibido por un canal. [occurredAt] viene del sobre común.
sealed class RealtimeEvent {
  const RealtimeEvent(this.occurredAt);

  final DateTime occurredAt;

  /// Decodifica el sobre `{type, occurred_at, data}`. Tipos desconocidos devuelven [UnknownEvent]
  /// para que versiones nuevas del backend no rompan apps antiguas.
  factory RealtimeEvent.fromEnvelope(Map<String, dynamic> json) {
    final type = json['type'] as String? ?? '';
    final at = DateTime.parse(json['occurred_at'] as String);
    final data = (json['data'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
    return switch (type) {
      'driver.presence' => DriverPresenceChanged(
        at,
        driverId: data['driver_id'] as String,
        presence: data['presence'] as String,
        busyUntilEstimate: _date(data['busy_until_estimate']),
      ),
      'trip.offer' => TripOffered(
        at,
        tripId: data['trip_id'] as String,
        passengerName: data['passenger_name'] as String,
        pickup: _point(data['pickup']),
        dropoff: _point(data['dropoff']),
        distanceM: data['distance_m'] as int,
        durationS: data['duration_s'] as int,
        suggestedFareMinor: data['suggested_fare_minor'] as int,
        currency: data['currency'] as String,
        expiresAt: DateTime.parse(data['expires_at'] as String),
        delegated: data['delegated'] as bool? ?? false,
        canDelegate: data['can_delegate'] as bool? ?? false,
        cooperativeName: data['cooperative_name'] as String?,
        requestedDriverName: data['requested_driver_name'] as String?,
        origin: offerOriginFromApi(data['origin'] as String?),
        loyalClient: data['loyal_client'] as bool? ?? false,
        tripsTogether: data['trips_together'] as int? ?? 0,
        pickupDistanceM: data['pickup_distance_m'] as int?,
        preferentialDiscountPct: data['preferential_discount_pct'] as int? ?? 0,
      ),
      'trip.delegated' => TripDelegated(
        at,
        tripId: data['trip_id'] as String,
        cooperativeName: data['cooperative_name'] as String?,
        reason: data['reason'] as String? ?? '',
        expiresAt: _date(data['expires_at']),
      ),
      'cooperative.membership' => CooperativeMembershipChanged(
        at,
        membershipId: data['membership_id'] as String,
        cooperativeId: data['cooperative_id'] as String,
        status: data['status'] as String,
        role: data['role'] as String? ?? 'member',
      ),
      'trip.offer_closed' => TripOfferClosed(at, tripId: data['trip_id'] as String, reason: data['reason'] as String),
      'trip.status' => TripStatusChanged(
        at,
        tripId: data['trip_id'] as String,
        status: data['status'] as String,
        agreedFareMinor: data['agreed_fare_minor'] as int?,
        cancelReason: data['cancel_reason'] as String?,
      ),
      'trip.fare_proposal' => FareProposed(
        at,
        tripId: data['trip_id'] as String,
        proposalId: data['proposal_id'] as String,
        proposedBy: data['proposed_by'] as String,
        amountMinor: data['amount_minor'] as int,
        expiresAt: DateTime.parse(data['expires_at'] as String),
      ),
      'trip.negotiation_requested' => NegotiationRequested(
        at,
        tripId: data['trip_id'] as String,
        expiresAt: DateTime.parse(data['expires_at'] as String),
      ),
      'trip.location' => DriverLocation(
        at,
        lat: (data['lat'] as num).toDouble(),
        lng: (data['lng'] as num).toDouble(),
        heading: (data['heading'] as num?)?.toDouble(),
        speedMps: (data['speed_mps'] as num?)?.toDouble(),
      ),
      'ptt.closed' => PttClosed(at, tripId: data['trip_id'] as String),
      'preconsult.opened' => PreconsultOpened(
        at,
        preconsultId: data['preconsult_id'] as String,
        passengerId: data['passenger_id'] as String,
        passengerName: data['passenger_name'] as String? ?? '',
        joinDeadline: DateTime.parse(data['join_deadline'] as String),
        closesAt: DateTime.parse(data['closes_at'] as String),
      ),
      'preconsult.joined' => PreconsultJoined(at, preconsultId: data['preconsult_id'] as String),
      'preconsult.closed' => PreconsultClosed(
        at,
        preconsultId: data['preconsult_id'] as String,
        reason: data['reason'] as String? ?? '',
      ),
      'notice.created' => NoticeCreated(
        at,
        noticeId: (data['id'] ?? data['notice_id']) as String,
        kind: data['kind'] as String? ?? '',
        title: data['title'] as String? ?? '',
        body: data['body'] as String? ?? '',
      ),
      'tower.changed' => TowerChanged(at),
      'sos.created' => SosCreated(
        at,
        alertId: data['alert_id'] as String,
        tripId: data['trip_id'] as String,
        raisedRole: data['raised_role'] as String,
        raisedByName: data['raised_by_name'] as String? ?? '',
      ),
      'sos.claimed' => SosClaimed(
        at,
        alertId: data['alert_id'] as String,
        operatorId: data['operator_id'] as String,
        operatorName: data['operator_name'] as String? ?? '',
      ),
      'sos.released' => SosReleased(at, alertId: data['alert_id'] as String),
      'sos.cancel_attempt' => SosCancelAttempt(
        at,
        alertId: data['alert_id'] as String,
        failedAttempts: data['failed_attempts'] as int? ?? 0,
        locked: data['locked'] as bool? ?? false,
      ),
      'sos.escalated' => SosEscalated(at, alertId: data['alert_id'] as String),
      'sos.closed' => SosClosed(
        at,
        alertId: data['alert_id'] as String,
        status: data['status'] as String?,
        outcome: data['outcome'] as String?,
      ),
      'sos.location' => SosLocationUpdate(
        at,
        alertId: data['alert_id'] as String,
        lat: (data['lat'] as num).toDouble(),
        lng: (data['lng'] as num).toDouble(),
        accuracyM: (data['accuracy_m'] as num?)?.toDouble(),
        at: DateTime.parse(data['at'] as String),
      ),
      'trip_payment.updated' => TripPaymentUpdated(
        at,
        tripId: data['trip_id'] as String,
        paymentId: data['payment_id'] as String,
        status: data['status'] as String,
        method: data['method'] as String?,
      ),
      'trip_payment.reminder' => TripPaymentReminder(
        at,
        tripId: data['trip_id'] as String,
        paymentId: data['payment_id'] as String,
        amountMinor: data['amount_minor'] as int,
        currency: data['currency'] as String,
      ),
      'support.case' => SupportCaseChanged(
        at,
        caseId: data['case_id'] as String,
        status: data['status'] as String? ?? '',
      ),
      'megaphone.started' => MegaphoneStarted(
        at,
        broadcastId: data['broadcast_id'] as String,
        url: data['url'] as String,
        token: data['token'] as String,
        endsAt: DateTime.parse(data['ends_at'] as String),
      ),
      'megaphone.ended' => MegaphoneEnded(at, broadcastId: data['broadcast_id'] as String),
      _ => UnknownEvent(at, type: type, data: data),
    };
  }
}

typedef LatLng = ({double lat, double lng});

LatLng _point(Object? v) {
  final m = (v! as Map).cast<String, dynamic>();
  return (lat: (m['lat'] as num).toDouble(), lng: (m['lng'] as num).toDouble());
}

DateTime? _date(Object? v) => v == null ? null : DateTime.parse(v as String);

final class DriverPresenceChanged extends RealtimeEvent {
  const DriverPresenceChanged(
    super.occurredAt, {
    required this.driverId,
    required this.presence,
    this.busyUntilEstimate,
  });

  final String driverId;

  /// `offline`, `free` o `busy`.
  final String presence;
  final DateTime? busyUntilEstimate;
}

final class TripOffered extends RealtimeEvent {
  const TripOffered(
    super.occurredAt, {
    required this.tripId,
    required this.passengerName,
    required this.pickup,
    required this.dropoff,
    required this.distanceM,
    required this.durationS,
    required this.suggestedFareMinor,
    required this.currency,
    required this.expiresAt,
    this.delegated = false,
    this.canDelegate = false,
    this.cooperativeName,
    this.requestedDriverName,
    this.origin = OfferOrigin.chosenDriver,
    this.loyalClient = false,
    this.tripsTogether = 0,
    this.pickupDistanceM,
    this.preferentialDiscountPct = 0,
  });

  final String tripId;
  final String passengerName;
  final LatLng pickup;
  final LatLng dropoff;
  final int distanceM;
  final int durationS;
  final int suggestedFareMinor;
  final String currency;
  final DateTime expiresAt;

  /// 006: la oferta llega derivada desde el Conductor Elegido [requestedDriverName].
  final bool delegated;

  /// 006: el conductor puede pasarla a su cooperativa (RN-KYQ-008).
  final bool canDelegate;
  final String? cooperativeName;
  final String? requestedDriverName;

  /// 008: por qué le llega la oferta (etiqueta de la tarjeta).
  final OfferOrigin origin;

  /// 008: el pasajero lo tiene como Conductor Elegido ("⭐ Cliente de tu cartera").
  final bool loyalClient;

  /// 008: viajes completados juntos.
  final int tripsTogether;

  /// 008: distancia en metros hasta la recogida, si se conoce su ubicación.
  final int? pickupDistanceM;

  /// 008: descuento preferencial ya aplicado a [suggestedFareMinor] (RN-KYQ-013).
  final int preferentialDiscountPct;
}

/// 008: origen de una oferta de viaje.
enum OfferOrigin { chosenDriver, cooperative, zonePool }

/// Interpreta el campo `origin` de `trip.offer`; si falta, la oferta viene de su cartera.
OfferOrigin offerOriginFromApi(String? v) => switch (v) {
  'cooperative' => OfferOrigin.cooperative,
  'zone_pool' => OfferOrigin.zonePool,
  _ => OfferOrigin.chosenDriver,
};

/// 006: la solicitud del pasajero pasó a un compañero de la cooperativa (RN-KYQ-008).
final class TripDelegated extends RealtimeEvent {
  const TripDelegated(
    super.occurredAt, {
    required this.tripId,
    required this.reason,
    this.cooperativeName,
    this.expiresAt,
  });

  final String tripId;

  /// `offer_rejected`, `offer_expired` o `delegated`.
  final String reason;
  final String? cooperativeName;
  final DateTime? expiresAt;
}

/// 006: cambió la membresía del conductor en una cooperativa (aprobada, rechazada, retirado…).
final class CooperativeMembershipChanged extends RealtimeEvent {
  const CooperativeMembershipChanged(
    super.occurredAt, {
    required this.membershipId,
    required this.cooperativeId,
    required this.status,
    required this.role,
  });

  final String membershipId;
  final String cooperativeId;

  /// `pending`, `active`, `rejected`, `cancelled`, `left` o `removed`.
  final String status;

  /// `member` o `coordinator`.
  final String role;
}

final class TripOfferClosed extends RealtimeEvent {
  const TripOfferClosed(super.occurredAt, {required this.tripId, required this.reason});

  final String tripId;
  final String reason;
}

final class TripStatusChanged extends RealtimeEvent {
  const TripStatusChanged(
    super.occurredAt, {
    required this.tripId,
    required this.status,
    this.agreedFareMinor,
    this.cancelReason,
  });

  final String tripId;

  /// Valor de `TripStatus` del contrato, p. ej. `ACCEPTED`.
  final String status;
  final int? agreedFareMinor;
  final String? cancelReason;
}

final class FareProposed extends RealtimeEvent {
  const FareProposed(
    super.occurredAt, {
    required this.tripId,
    required this.proposalId,
    required this.proposedBy,
    required this.amountMinor,
    required this.expiresAt,
  });

  final String tripId;
  final String proposalId;

  /// `driver` o `passenger`.
  final String proposedBy;
  final int amountMinor;
  final DateTime expiresAt;
}

final class NegotiationRequested extends RealtimeEvent {
  const NegotiationRequested(super.occurredAt, {required this.tripId, required this.expiresAt});

  final String tripId;
  final DateTime expiresAt;
}

final class DriverLocation extends RealtimeEvent {
  const DriverLocation(super.occurredAt, {required this.lat, required this.lng, this.heading, this.speedMps});

  final double lat;
  final double lng;
  final double? heading;
  final double? speedMps;
}

final class PttClosed extends RealtimeEvent {
  const PttClosed(super.occurredAt, {required this.tripId});

  final String tripId;
}

/// Un cliente abrió una consulta de voz con el conductor (005, RN-KYQ-010).
final class PreconsultOpened extends RealtimeEvent {
  const PreconsultOpened(
    super.occurredAt, {
    required this.preconsultId,
    required this.passengerId,
    required this.passengerName,
    required this.joinDeadline,
    required this.closesAt,
  });

  final String preconsultId;
  final String passengerId;
  final String passengerName;
  final DateTime joinDeadline;
  final DateTime closesAt;
}

/// La app del conductor se unió a la consulta: el pasajero ya puede hablar (005).
final class PreconsultJoined extends RealtimeEvent {
  const PreconsultJoined(super.occurredAt, {required this.preconsultId});

  final String preconsultId;
}

/// La consulta se cerró; [reason] es el motivo del contrato, p. ej. `missed` (005).
final class PreconsultClosed extends RealtimeEvent {
  const PreconsultClosed(super.occurredAt, {required this.preconsultId, required this.reason});

  final String preconsultId;
  final String reason;
}

/// Aviso nuevo para el conductor (documentos, pagos) en `user:{id}` (002, R5).
final class NoticeCreated extends RealtimeEvent {
  const NoticeCreated(
    super.occurredAt, {
    required this.noticeId,
    required this.kind,
    required this.title,
    required this.body,
  });

  final String noticeId;

  /// p. ej. `doc_rejected`, `payment_approved`.
  final String kind;
  final String title;
  final String body;
}

/// Algo cambió en la torre de control (007): el panel vuelve a pedir la instantánea. No lleva
/// datos.
final class TowerChanged extends RealtimeEvent {
  const TowerChanged(super.occurredAt);
}

/// Alerta SOS nueva en la cola de la consola (`ops:sos`, 003).
final class SosCreated extends RealtimeEvent {
  const SosCreated(
    super.occurredAt, {
    required this.alertId,
    required this.tripId,
    required this.raisedRole,
    required this.raisedByName,
  });

  final String alertId;
  final String tripId;

  /// `passenger` o `driver`.
  final String raisedRole;
  final String raisedByName;
}

final class SosClaimed extends RealtimeEvent {
  const SosClaimed(super.occurredAt, {required this.alertId, required this.operatorId, required this.operatorName});

  final String alertId;
  final String operatorId;
  final String operatorName;
}

final class SosReleased extends RealtimeEvent {
  const SosReleased(super.occurredAt, {required this.alertId});

  final String alertId;
}

/// Intento de cancelar sin el PIN correcto (posible coacción, FR-005).
final class SosCancelAttempt extends RealtimeEvent {
  const SosCancelAttempt(super.occurredAt, {required this.alertId, required this.failedAttempts, required this.locked});

  final String alertId;
  final int failedAttempts;
  final bool locked;
}

/// 60 s sin operador: se avisó por SMS a los de guardia (FR-011).
final class SosEscalated extends RealtimeEvent {
  const SosEscalated(super.occurredAt, {required this.alertId});

  final String alertId;
}

/// Alerta cerrada por el operador o cancelada con PIN. También llega a `user:{id}` de quien la
/// activó para que deje de enviar su ubicación.
final class SosClosed extends RealtimeEvent {
  const SosClosed(super.occurredAt, {required this.alertId, this.status, this.outcome});

  final String alertId;

  /// `closed` o `cancelled_by_user`.
  final String? status;
  final String? outcome;
}

/// Ubicación a 1 Hz de una alerta (`sos:{alertId}`).
final class SosLocationUpdate extends RealtimeEvent {
  const SosLocationUpdate(
    super.occurredAt, {
    required this.alertId,
    required this.lat,
    required this.lng,
    this.accuracyM,
    required this.at,
  });

  final String alertId;
  final double lat;
  final double lng;
  final double? accuracyM;
  final DateTime at;
}

/// El pago de un viaje cambió de estado (004): ambas apps recargan el pago.
final class TripPaymentUpdated extends RealtimeEvent {
  const TripPaymentUpdated(
    super.occurredAt, {
    required this.tripId,
    required this.paymentId,
    required this.status,
    this.method,
  });

  final String tripId;
  final String paymentId;

  /// p. ej. `cash_reported`, `paid`.
  final String status;

  /// `bold` o `cash`.
  final String? method;
}

/// Recordatorio al pasajero de un viaje sin pagar (004, FR-015).
final class TripPaymentReminder extends RealtimeEvent {
  const TripPaymentReminder(
    super.occurredAt, {
    required this.tripId,
    required this.paymentId,
    required this.amountMinor,
    required this.currency,
  });

  final String tripId;
  final String paymentId;
  final int amountMinor;
  final String currency;
}

/// 009: un caso de soporte cambió (mensaje nuevo o estado); no trae texto: hay que pedirlo.
final class SupportCaseChanged extends RealtimeEvent {
  const SupportCaseChanged(super.occurredAt, {required this.caseId, required this.status});

  final String caseId;
  final String status;
}

/// 009: comunicado de Kyq por el megáfono a la zona del conductor; [token] solo deja escuchar.
final class MegaphoneStarted extends RealtimeEvent {
  const MegaphoneStarted(
    super.occurredAt, {
    required this.broadcastId,
    required this.url,
    required this.token,
    required this.endsAt,
  });

  final String broadcastId;
  final String url;
  final String token;
  final DateTime endsAt;
}

/// 009: terminó el comunicado.
final class MegaphoneEnded extends RealtimeEvent {
  const MegaphoneEnded(super.occurredAt, {required this.broadcastId});

  final String broadcastId;
}

final class UnknownEvent extends RealtimeEvent {
  const UnknownEvent(super.occurredAt, {required this.type, required this.data});

  final String type;
  final Map<String, dynamic> data;
}
