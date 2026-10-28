// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'native_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Reservation _$ReservationFromJson(Map<String, dynamic> json) => _Reservation(
  id: json['id'] as String,
  passenger: PersonRef.fromJson(json['passenger'] as Map<String, dynamic>),
  driver: PersonRef.fromJson(json['driver'] as Map<String, dynamic>),
  pickup: GeoPoint.fromJson(json['pickup'] as Map<String, dynamic>),
  dropoff: GeoPoint.fromJson(json['dropoff'] as Map<String, dynamic>),
  pickupLabel: json['pickup_label'] as String?,
  dropoffLabel: json['dropoff_label'] as String?,
  scheduledAt: DateTime.parse(json['scheduled_at'] as String),
  distanceM: (json['distance_m'] as num).toInt(),
  durationS: (json['duration_s'] as num).toInt(),
  currency: json['currency'] as String,
  fareMinor: (json['fare_minor'] as num).toInt(),
  listFareMinor: (json['list_fare_minor'] as num).toInt(),
  preferentialDiscountPct: (json['preferential_discount_pct'] as num?)?.toInt() ?? 0,
  status: $enumDecode(_$ReservationStatusEnumMap, json['status'], unknownValue: ReservationStatus.cancelled),
  cancelledByMe: json['cancelled_by_me'] as bool? ?? false,
  tripId: json['trip_id'] as String?,
  overlaps: json['overlaps'] as bool? ?? false,
);

Map<String, dynamic> _$ReservationToJson(_Reservation instance) => <String, dynamic>{
  'id': instance.id,
  'passenger': instance.passenger.toJson(),
  'driver': instance.driver.toJson(),
  'pickup': instance.pickup.toJson(),
  'dropoff': instance.dropoff.toJson(),
  'pickup_label': instance.pickupLabel,
  'dropoff_label': instance.dropoffLabel,
  'scheduled_at': instance.scheduledAt.toIso8601String(),
  'distance_m': instance.distanceM,
  'duration_s': instance.durationS,
  'currency': instance.currency,
  'fare_minor': instance.fareMinor,
  'list_fare_minor': instance.listFareMinor,
  'preferential_discount_pct': instance.preferentialDiscountPct,
  'status': _$ReservationStatusEnumMap[instance.status]!,
  'cancelled_by_me': instance.cancelledByMe,
  'trip_id': instance.tripId,
  'overlaps': instance.overlaps,
};

const _$ReservationStatusEnumMap = {
  ReservationStatus.pending: 'pending',
  ReservationStatus.confirmed: 'confirmed',
  ReservationStatus.rejected: 'rejected',
  ReservationStatus.cancelled: 'cancelled',
  ReservationStatus.expired: 'expired',
  ReservationStatus.fulfilled: 'fulfilled',
  ReservationStatus.missed: 'missed',
};

_UpcomingReservation _$UpcomingReservationFromJson(Map<String, dynamic> json) => _UpcomingReservation(
  id: json['id'] as String,
  scheduledAt: DateTime.parse(json['scheduled_at'] as String),
  status: $enumDecode(_$ReservationStatusEnumMap, json['status'], unknownValue: ReservationStatus.pending),
);

Map<String, dynamic> _$UpcomingReservationToJson(_UpcomingReservation instance) => <String, dynamic>{
  'id': instance.id,
  'scheduled_at': instance.scheduledAt.toIso8601String(),
  'status': _$ReservationStatusEnumMap[instance.status]!,
};

_ClientCard _$ClientCardFromJson(Map<String, dynamic> json) => _ClientCard(
  passengerId: json['passenger_id'] as String,
  displayName: json['display_name'] as String,
  affiliatedAt: DateTime.parse(json['affiliated_at'] as String),
  source: $enumDecodeNullable(_$AffiliationSourceEnumMap, json['source']) ?? AffiliationSource.qrScan,
  tripsTogether: (json['trips_together'] as num?)?.toInt() ?? 0,
  lastTripAt: json['last_trip_at'] == null ? null : DateTime.parse(json['last_trip_at'] as String),
  note: json['note'] as String?,
  upcomingReservations:
      (json['upcoming_reservations'] as List<dynamic>?)
          ?.map((e) => UpcomingReservation.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <UpcomingReservation>[],
);

Map<String, dynamic> _$ClientCardToJson(_ClientCard instance) => <String, dynamic>{
  'passenger_id': instance.passengerId,
  'display_name': instance.displayName,
  'affiliated_at': instance.affiliatedAt.toIso8601String(),
  'source': _$AffiliationSourceEnumMap[instance.source]!,
  'trips_together': instance.tripsTogether,
  'last_trip_at': instance.lastTripAt?.toIso8601String(),
  'note': instance.note,
  'upcoming_reservations': instance.upcomingReservations.map((e) => e.toJson()).toList(),
};

const _$AffiliationSourceEnumMap = {
  AffiliationSource.qrScan: 'qr_scan',
  AffiliationSource.postTrip: 'post_trip',
  AffiliationSource.link: 'link',
};

_Place _$PlaceFromJson(Map<String, dynamic> json) => _Place(
  label: json['label'] as String,
  detail: json['detail'] as String? ?? '',
  lat: (json['lat'] as num).toDouble(),
  lng: (json['lng'] as num).toDouble(),
);

Map<String, dynamic> _$PlaceToJson(_Place instance) => <String, dynamic>{
  'label': instance.label,
  'detail': instance.detail,
  'lat': instance.lat,
  'lng': instance.lng,
};
