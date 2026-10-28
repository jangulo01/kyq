// Eventos de specs/001-chosen-driver-trip-ptt/contracts/realtime.md y `notice.created` de 002.

/// Nombres de canal autorizados por el backend.
abstract final class Channels {
  static String user(String userId) => 'user:$userId';
  static String driverPresence(String driverId) => 'driver_presence:$driverId';
  static String trip(String tripId) => 'trip:$tripId';
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
      'notice.created' => NoticeCreated(
        at,
        noticeId: (data['id'] ?? data['notice_id']) as String,
        kind: data['kind'] as String? ?? '',
        title: data['title'] as String? ?? '',
        body: data['body'] as String? ?? '',
      ),
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
}

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

final class UnknownEvent extends RealtimeEvent {
  const UnknownEvent(super.occurredAt, {required this.type, required this.data});

  final String type;
  final Map<String, dynamic> data;
}
