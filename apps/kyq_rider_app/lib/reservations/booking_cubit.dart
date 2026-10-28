import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kyq_api/kyq_api.dart';

import '../request/location_source.dart';

/// Antelación mínima y máxima de una reserva (010, FR-001).
const minBookingLead = Duration(minutes: 30);
const maxBookingLead = Duration(days: 7);

@immutable
class BookingState {
  const BookingState({
    this.pickup,
    this.pickupLabel,
    this.dropoff,
    this.dropoffLabel,
    this.scheduledAt,
    this.quote,
    this.quoting = false,
    this.submitting = false,
    this.error,
    this.booked,
  });

  final GeoPoint? pickup;
  final String? pickupLabel;
  final GeoPoint? dropoff;
  final String? dropoffLabel;
  final DateTime? scheduledAt;
  final FareQuote? quote;
  final bool quoting;
  final bool submitting;
  final String? error;

  /// Reserva creada; la página vuelve atrás.
  final Reservation? booked;

  bool get canSubmit => quote != null && scheduledAt != null && !quoting && !submitting && booked == null;

  BookingState copyWith({
    GeoPoint? pickup,
    String? Function()? pickupLabel,
    GeoPoint? dropoff,
    String? Function()? dropoffLabel,
    DateTime? scheduledAt,
    FareQuote? Function()? quote,
    bool? quoting,
    bool? submitting,
    String? Function()? error,
    Reservation? booked,
  }) => BookingState(
    pickup: pickup ?? this.pickup,
    pickupLabel: pickupLabel != null ? pickupLabel() : this.pickupLabel,
    dropoff: dropoff ?? this.dropoff,
    dropoffLabel: dropoffLabel != null ? dropoffLabel() : this.dropoffLabel,
    scheduledAt: scheduledAt ?? this.scheduledAt,
    quote: quote != null ? quote() : this.quote,
    quoting: quoting ?? this.quoting,
    submitting: submitting ?? this.submitting,
    error: error != null ? error() : this.error,
    booked: booked ?? this.booked,
  );
}

/// Reservar un viaje con un Conductor Elegido (010, US1): recogida, destino, fecha y hora y la
/// tarifa sugerida con la preferencial de 008 si aplica. El conductor la acepta o la rechaza.
class BookingCubit extends Cubit<BookingState> {
  BookingCubit({
    required this._api,
    required this._location,
    required this.driverId,
    required this.driverName,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now,
       super(const BookingState());

  final KyqApiClient _api;
  final LocationSource _location;
  final String driverId;
  final String driverName;
  final DateTime Function() _now;

  /// Recogida en la ubicación actual si ya hay permiso; si no, el pasajero la busca.
  Future<void> start() async {
    try {
      if (!await _location.hasPermission()) return;
      final here = await _location.current();
      if (isClosed || state.pickup != null) return;
      emit(state.copyWith(pickup: here, pickupLabel: () => 'Mi ubicación actual'));
      await _requote();
    } on Object {
      // Sin ubicación se busca la dirección de recogida.
    }
  }

  Future<void> setPickup(Place place) async {
    emit(state.copyWith(pickup: place.point, pickupLabel: () => place.label));
    await _requote();
  }

  Future<void> setDropoff(Place place) async {
    emit(state.copyWith(dropoff: place.point, dropoffLabel: () => place.label));
    await _requote();
  }

  void setScheduledAt(DateTime at) => emit(state.copyWith(scheduledAt: at, error: () => _timeError(at)));

  String? _timeError(DateTime at) {
    final now = _now();
    if (at.isBefore(now.add(minBookingLead))) return 'Reserva con al menos 30 minutos de anticipación.';
    if (at.isAfter(now.add(maxBookingLead))) return 'Solo se puede reservar hasta 7 días antes.';
    return null;
  }

  Future<void> _requote() async {
    final pickup = state.pickup, dropoff = state.dropoff;
    if (pickup == null || dropoff == null) return;
    emit(state.copyWith(quoting: true, quote: () => null, error: () => null));
    try {
      final quote = await _api.quote(pickup, dropoff, driverId: driverId);
      if (isClosed || state.pickup != pickup || state.dropoff != dropoff) return;
      emit(state.copyWith(quoting: false, quote: () => quote));
    } on ApiException catch (e) {
      if (isClosed || state.pickup != pickup || state.dropoff != dropoff) return;
      emit(state.copyWith(quoting: false, error: () => _message(e)));
    }
  }

  Future<void> submit() async {
    final pickup = state.pickup, dropoff = state.dropoff, at = state.scheduledAt;
    if (!state.canSubmit || pickup == null || dropoff == null || at == null) return;
    final timeError = _timeError(at);
    if (timeError != null) {
      emit(state.copyWith(error: () => timeError));
      return;
    }
    emit(state.copyWith(submitting: true, error: () => null));
    try {
      final booked = await _api.createReservation(
        driverId: driverId,
        pickup: pickup,
        dropoff: dropoff,
        scheduledAt: at,
        pickupLabel: state.pickupLabel,
        dropoffLabel: state.dropoffLabel,
      );
      if (!isClosed) emit(state.copyWith(submitting: false, booked: booked));
    } on ApiException catch (e) {
      if (!isClosed) emit(state.copyWith(submitting: false, error: () => _message(e)));
    }
  }

  String _message(ApiException e) => switch (e.code) {
    'invalid_time' => 'Reserva entre 30 minutos y 7 días desde ahora.',
    'too_many_reservations' => 'Ya tienes 3 reservas activas. Cancela una para hacer otra.',
    'not_affiliated' => '$driverName ya no está en tus Conductores Elegidos.',
    'no_route' => 'No encontramos una ruta entre esos puntos. Prueba con otro destino.',
    'city_not_configured' => 'Kyq todavía no tiene tarifas para esta ciudad.',
    'network' => 'Sin conexión con el servidor. Revisa tu internet.',
    _ => 'No pudimos hacer la reserva. Inténtalo de nuevo.',
  };
}
