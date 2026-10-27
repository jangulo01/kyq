import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_realtime/kyq_realtime.dart';

import '../realtime/realtime_events.dart';
import 'location_source.dart';

/// Qué punto fija el próximo toque en el mapa.
enum RequestPoint { pickup, dropoff }

class RequestState {
  const RequestState({
    this.pickup,
    this.dropoff,
    this.editing = RequestPoint.dropoff,
    this.locating = false,
    this.needsLocationPermission = false,
    this.quote,
    this.quoting = false,
    this.requesting = false,
    this.driverFree = true,
    this.error,
    this.tripId,
  });

  final GeoPoint? pickup;
  final GeoPoint? dropoff;
  final RequestPoint editing;
  final bool locating;

  /// La página debe explicar para qué usamos la ubicación antes de pedir el permiso.
  final bool needsLocationPermission;
  final FareQuote? quote;
  final bool quoting;
  final bool requesting;

  /// Presencia en vivo del conductor: si deja de estar libre no se envía la oferta.
  final bool driverFree;
  final String? error;

  /// Viaje creado; la página navega a la espera.
  final String? tripId;

  bool get canRequest => quote != null && driverFree && !quoting && !requesting && tripId == null;

  RequestState copyWith({
    GeoPoint? pickup,
    GeoPoint? dropoff,
    RequestPoint? editing,
    bool? locating,
    bool? needsLocationPermission,
    FareQuote? Function()? quote,
    bool? quoting,
    bool? requesting,
    bool? driverFree,
    String? Function()? error,
    String? tripId,
  }) => RequestState(
    pickup: pickup ?? this.pickup,
    dropoff: dropoff ?? this.dropoff,
    editing: editing ?? this.editing,
    locating: locating ?? this.locating,
    needsLocationPermission: needsLocationPermission ?? this.needsLocationPermission,
    quote: quote != null ? quote() : this.quote,
    quoting: quoting ?? this.quoting,
    requesting: requesting ?? this.requesting,
    driverFree: driverFree ?? this.driverFree,
    error: error != null ? error() : this.error,
    tripId: tripId ?? this.tripId,
  );
}

/// Solicitud de viaje a un Conductor Elegido (FR-009, FR-010, FR-011).
class RequestCubit extends Cubit<RequestState> {
  RequestCubit({
    required this._api,
    required this._location,
    required this.driverId,
    required this.driverName,
    this._realtime = const NoRealtimeEvents(),
  }) : super(const RequestState());

  final KyqApiClient _api;
  final LocationSource _location;
  final RealtimeEvents _realtime;
  final String driverId;
  final String driverName;
  StreamSubscription<RealtimeEvent>? _presence;

  /// Escucha la presencia del conductor y usa la ubicación si ya hay permiso.
  Future<void> start() async {
    _presence = _realtime.subscribe(Channels.driverPresence(driverId)).listen(_onPresence, onError: (Object _) {});
    bool granted;
    try {
      granted = await _location.hasPermission();
    } on Object {
      granted = false;
    }
    if (isClosed) return;
    if (granted) {
      await locate();
    } else {
      emit(state.copyWith(needsLocationPermission: true));
    }
  }

  // Caso borde: el conductor se ocupa mientras el pasajero arma la solicitud; no se envía.
  void _onPresence(RealtimeEvent e) {
    if (e is! DriverPresenceChanged || e.driverId != driverId) return;
    // Nuestra propia solicitud reserva al conductor: ese cambio a ocupado no es un aviso.
    if (state.requesting || state.tripId != null) return;
    final free = e.presence == DriverPresence.free.name;
    if (free == state.driverFree) return;
    emit(state.copyWith(driverFree: free, error: () => free ? null : '$driverName acaba de dejar de estar libre.'));
  }

  /// Fija el origen en la ubicación actual, pidiendo permiso si hace falta.
  Future<void> locate() async {
    emit(state.copyWith(locating: true, needsLocationPermission: false, error: () => null));
    try {
      final here = await _location.current();
      if (isClosed) return;
      emit(state.copyWith(pickup: here, locating: false, editing: RequestPoint.dropoff));
      await _requote();
    } on LocationUnavailable catch (e) {
      if (isClosed) return;
      emit(state.copyWith(locating: false, editing: RequestPoint.pickup, error: () => e.message));
    }
  }

  void edit(RequestPoint point) => emit(state.copyWith(editing: point));

  /// Toque en el mapa: fija el punto que se está editando y vuelve a cotizar.
  Future<void> setPoint(GeoPoint point) async {
    if (state.editing == RequestPoint.pickup) {
      emit(state.copyWith(pickup: point, editing: state.dropoff == null ? RequestPoint.dropoff : RequestPoint.pickup));
    } else {
      emit(state.copyWith(dropoff: point));
    }
    await _requote();
  }

  Future<void> _requote() async {
    final pickup = state.pickup;
    final dropoff = state.dropoff;
    if (pickup == null || dropoff == null) return;
    emit(state.copyWith(quoting: true, quote: () => null, error: () => null));
    try {
      final quote = await _api.quote(pickup, dropoff);
      // Si el pasajero movió un punto mientras cotizábamos, gana la cotización más reciente.
      if (isClosed || state.pickup != pickup || state.dropoff != dropoff) return;
      emit(state.copyWith(quoting: false, quote: () => quote));
    } on ApiException catch (e) {
      if (isClosed || state.pickup != pickup || state.dropoff != dropoff) return;
      emit(state.copyWith(quoting: false, error: () => _message(e)));
    }
  }

  /// Envía la oferta exclusiva al conductor.
  Future<void> request() async {
    final pickup = state.pickup;
    final dropoff = state.dropoff;
    if (!state.canRequest || pickup == null || dropoff == null) return;
    emit(state.copyWith(requesting: true, error: () => null));
    try {
      final trip = await _api.requestTrip(driverId: driverId, pickup: pickup, dropoff: dropoff);
      if (isClosed) return;
      emit(state.copyWith(requesting: false, tripId: trip.id));
    } on ApiException catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          requesting: false,
          driverFree: e.code == 'driver_not_free' ? false : null,
          error: () => _message(e),
        ),
      );
    }
  }

  String _message(ApiException e) => switch (e.code) {
    'driver_not_free' => '$driverName ya no está libre. Inténtalo en unos minutos o pide a otro conductor.',
    'not_affiliated' => '$driverName ya no está en tus Conductores Elegidos.',
    'passenger_has_active_trip' => 'Ya tienes un viaje en curso. Termínalo o cancélalo antes de pedir otro.',
    'no_route' => 'No encontramos una ruta entre esos puntos. Prueba con otro destino.',
    'city_not_configured' => 'Kyq todavía no tiene tarifas para esta ciudad.',
    'network' => 'Sin conexión con el servidor. Revisa tu internet.',
    _ => 'No pudimos completar la solicitud. Inténtalo de nuevo.',
  };

  @override
  Future<void> close() async {
    await _presence?.cancel();
    return super.close();
  }
}
