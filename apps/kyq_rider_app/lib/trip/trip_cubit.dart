import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_realtime/kyq_realtime.dart';

import '../app/session_user.dart';
import '../realtime/realtime_events.dart';

class TripState {
  const TripState({this.trip, this.loading = false, this.busy = false, this.driverPosition, this.error});

  final Trip? trip;
  final bool loading;

  /// Hay una acción del pasajero en curso; los botones se desactivan.
  final bool busy;

  /// Última posición del conductor recibida por `trip:{tripId}` (FR-014).
  final GeoPoint? driverPosition;
  final String? error;

  TripState copyWith({Trip? trip, bool? loading, bool? busy, GeoPoint? driverPosition, String? Function()? error}) =>
      TripState(
        trip: trip ?? this.trip,
        loading: loading ?? this.loading,
        busy: busy ?? this.busy,
        driverPosition: driverPosition ?? this.driverPosition,
        error: error != null ? error() : this.error,
      );
}

/// Estados en los que el conductor ya va hacia el pasajero o lo lleva.
const trackingStatuses = {TripStatus.accepted, TripStatus.arrived, TripStatus.inProgress};

/// Viaje del pasajero desde la solicitud hasta el resumen (FR-010a, FR-010c, FR-011, FR-013–FR-015).
///
/// La verdad está en el backend: cada evento del viaje dispara un `getTrip` en vez de aplicar el
/// cambio localmente, así ambas apps muestran siempre el mismo estado.
class TripCubit extends Cubit<TripState> {
  TripCubit({required this._api, required this.tripId, this._realtime = const NoRealtimeEvents(), this.refreshEvery})
    : super(const TripState(loading: true));

  final KyqApiClient _api;
  final RealtimeEvents _realtime;
  final String tripId;

  /// Red de seguridad por si se pierde un evento; null lo desactiva (pruebas).
  final Duration? refreshEvery;

  StreamSubscription<RealtimeEvent>? _userEvents;
  StreamSubscription<RealtimeEvent>? _locations;
  Timer? _poll;
  Timer? _retry;

  /// Espera antes de reintentar un refresco fallido con el viaje ya cargado.
  static const retryAfter = Duration(seconds: 2);

  Future<void> start() async {
    await refresh();
    if (isClosed) return;
    final session = await _api.currentSession();
    final myId = (session == null ? null : userIdFromAccessToken(session.accessToken)) ?? state.trip?.passengerId;
    if (isClosed || myId == null) return;
    _userEvents = _realtime.subscribe(Channels.user(myId)).listen(_onUserEvent, onError: (Object _) {});
    final every = refreshEvery;
    if (every != null) _poll = Timer.periodic(every, (_) => refresh());
  }

  void _onUserEvent(RealtimeEvent e) {
    final forThisTrip = switch (e) {
      TripStatusChanged(:final tripId) ||
      FareProposed(:final tripId) ||
      NegotiationRequested(:final tripId) => tripId == this.tripId,
      _ => false,
    };
    if (forThisTrip) refresh();
  }

  void _onLocation(RealtimeEvent e) {
    if (e is DriverLocation && !isClosed) {
      emit(
        state.copyWith(
          driverPosition: GeoPoint(lat: e.lat, lng: e.lng),
        ),
      );
    }
  }

  Future<void> refresh() async {
    try {
      final trip = await _api.getTrip(tripId);
      if (!isClosed) _show(trip);
    } on ApiException {
      if (isClosed) return;
      // Con el viaje ya en pantalla, un fallo suele ser la red cortada en segundo plano
      // (HyperOS lo hace): se reintenta sin molestar. Solo es error si no hay nada que mostrar.
      if (state.trip != null) {
        _retry?.cancel();
        _retry = Timer(retryAfter, refresh);
        return;
      }
      emit(state.copyWith(loading: false, error: () => 'No pudimos actualizar el viaje.'));
    }
  }

  void _show(Trip trip) {
    emit(state.copyWith(trip: trip, loading: false));
    // Posición del conductor solo mientras viene o lleva al pasajero.
    if (trackingStatuses.contains(trip.status)) {
      _locations ??= _realtime.subscribe(Channels.trip(tripId)).listen(_onLocation, onError: (Object _) {});
    } else if (trip.status == TripStatus.completed || trip.status == TripStatus.cancelled) {
      _stopLive();
    }
  }

  void _stopLive() {
    _poll?.cancel();
    _poll = null;
    _retry?.cancel();
    _retry = null;
    _locations?.cancel();
    _locations = null;
  }

  /// FARE_PENDING: confirma o rechaza la tarifa que propuso el conductor (FR-010a).
  Future<void> confirmFare({required bool accept}) => decideOpenProposal(accept: accept);

  /// Acepta o rechaza la propuesta abierta del conductor (FARE_PENDING o NEGOTIATING).
  Future<void> decideOpenProposal({required bool accept}) async {
    final proposal = state.trip?.openProposal;
    if (proposal == null) return;
    await _act(() => _api.decideProposal(tripId, proposal.id, accept: accept));
  }

  /// NEGOTIATION_PENDING: acepta negociar o mantiene la tarifa sugerida (FR-010c).
  Future<void> respondNegotiation({required bool accept}) =>
      _act(() => _api.respondNegotiation(tripId, accept: accept));

  /// NEGOTIATING: propuesta o contrapropuesta del pasajero.
  Future<void> propose(int amountMinor) => _act(() async {
    final proposal = await _api.propose(tripId, amountMinor);
    return state.trip!.copyWith(openProposal: proposal);
  });

  /// Cancela sin cargo; el backend solo lo permite antes de IN_PROGRESS.
  Future<void> cancel() => _act(() => _api.cancelTrip(tripId));

  Future<void> _act(Future<Trip> Function() action) async {
    if (state.busy || state.trip == null) return;
    emit(state.copyWith(busy: true, error: () => null));
    try {
      final trip = await action();
      if (isClosed) return;
      emit(state.copyWith(busy: false));
      _show(trip);
    } on ApiException catch (e) {
      if (isClosed) return;
      emit(state.copyWith(busy: false, error: () => _message(e)));
      // Lo más probable es que el viaje cambió (propuesta vencida, conductor canceló…).
      await refresh();
    }
  }

  String _message(ApiException e) => switch (e.code) {
    'network' => 'Sin conexión con el servidor. Revisa tu internet.',
    _ when e.statusCode == 409 => 'El viaje cambió antes de tu respuesta. Te mostramos el estado actual.',
    _ => 'No pudimos completar la acción. Inténtalo de nuevo.',
  };

  @override
  Future<void> close() async {
    _stopLive();
    await _userEvents?.cancel();
    return super.close();
  }
}
