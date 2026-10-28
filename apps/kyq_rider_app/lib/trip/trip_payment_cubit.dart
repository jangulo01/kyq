import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_realtime/kyq_realtime.dart';

import '../realtime/realtime_events.dart';
import 'checkout_launcher.dart';

class TripPaymentState {
  const TripPaymentState({this.payment, this.loading = false, this.missing = false, this.busy = false, this.message});

  final TripPayment? payment;
  final bool loading;

  /// El viaje no tiene pago registrado (anterior a 004): se paga por fuera, como en 001.
  final bool missing;

  /// Abriendo el checkout o enviando el reporte.
  final bool busy;
  final String? message;

  TripPaymentState copyWith({TripPayment? payment, bool? loading, bool? missing, bool? busy, String? message}) =>
      TripPaymentState(
        payment: payment ?? this.payment,
        loading: loading ?? this.loading,
        missing: missing ?? this.missing,
        busy: busy ?? this.busy,
        message: message,
      );
}

/// Pago del viaje del pasajero al terminar (004, FR-002–FR-004): Bold o "Pagué en efectivo".
///
/// Bold confirma al backend; la app pregunta al volver de la Custom Tab y cada [pollInterval]
/// mientras el pago esté en curso (máximo [pollTimeout]). Los cambios del conductor llegan por
/// `trip_payment.updated` en `user:{passengerId}`.
class TripPaymentCubit extends Cubit<TripPaymentState> {
  TripPaymentCubit({
    required this._api,
    required this.tripId,
    this._checkout = const CustomTabCheckout(),
    this._realtime = const NoRealtimeEvents(),
    this.pollInterval = const Duration(seconds: 4),
    this.pollTimeout = const Duration(minutes: 2),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now,
       super(const TripPaymentState(loading: true));

  final KyqApiClient _api;
  final CheckoutLauncher _checkout;
  final RealtimeEvents _realtime;
  final String tripId;
  final Duration pollInterval;
  final Duration pollTimeout;
  final DateTime Function() _now;

  StreamSubscription<RealtimeEvent>? _events;
  Timer? _poll;
  DateTime? _pollUntil;
  bool _refreshing = false;

  Future<void> load() async {
    try {
      final payment = await _api.tripPayment(tripId);
      if (isClosed) return;
      if (payment == null) {
        emit(state.copyWith(loading: false, missing: true, message: state.message));
        return;
      }
      _show(payment, message: state.message);
      _events ??= _realtime.subscribe(Channels.user(payment.passengerId)).listen(_onEvent, onError: (Object _) {});
      if (payment.status == TripPaymentStatus.boldInProgress && _poll == null) _startPolling();
    } on ApiException {
      if (!isClosed) emit(state.copyWith(loading: false, message: 'No pudimos cargar el pago del viaje.'));
    }
  }

  void _onEvent(RealtimeEvent e) {
    if (e is TripPaymentUpdated && e.tripId == tripId) unawaited(load());
  }

  /// Abre el checkout de Bold por la tarifa acordada (FR-003).
  Future<void> payWithBold() async {
    if (state.busy) return;
    emit(state.copyWith(busy: true));
    try {
      final payment = await _api.payTripWithBold(tripId);
      if (isClosed) return;
      _show(payment);
      _startPolling();
      await _open(payment);
    } on ApiException catch (e) {
      await _failed(e);
    }
  }

  /// Vuelve a abrir el checkout en curso (si el pasajero cerró la pestaña).
  Future<void> continueBold() async {
    final payment = state.payment;
    if (payment == null || state.busy) return;
    emit(state.copyWith(busy: true));
    await _open(payment);
  }

  /// "Pagué en efectivo" (FR-004).
  Future<void> reportCash() async {
    if (state.busy) return;
    emit(state.copyWith(busy: true));
    try {
      final payment = await _api.reportCashPayment(tripId);
      if (!isClosed) _show(payment);
    } on ApiException catch (e) {
      await _failed(e);
    }
  }

  /// La app volvió a primer plano (normalmente, al cerrar la Custom Tab).
  Future<void> onResumed() async {
    if (state.payment?.status != TripPaymentStatus.boldInProgress) return;
    _startPolling();
    await refresh();
  }

  /// Pregunta ya a Bold por el pago en curso.
  Future<void> refresh() async {
    final before = state.payment;
    if (before == null || _refreshing || isClosed) return;
    _refreshing = true;
    try {
      final payment = await _api.refreshTripPayment(tripId);
      if (isClosed) return;
      final failed =
          before.status == TripPaymentStatus.boldInProgress &&
          (payment.status == TripPaymentStatus.pending || payment.status == TripPaymentStatus.unpaid);
      _show(
        payment,
        message: failed ? 'El pago con Bold no se completó. Puedes intentarlo otra vez o pagar en efectivo.' : null,
      );
    } on ApiException {
      // Sin red se reintenta en el siguiente sondeo.
    } finally {
      _refreshing = false;
    }
  }

  Future<void> _open(TripPayment payment) async {
    final url = payment.checkoutUrl;
    final opened = url != null && await _checkout.open(url);
    if (isClosed) return;
    emit(state.copyWith(busy: false, message: opened ? null : 'No pudimos abrir la página de pago. Reintenta.'));
  }

  void _show(TripPayment payment, {String? message}) {
    emit(state.copyWith(payment: payment, loading: false, missing: false, busy: false, message: message));
    if (payment.status != TripPaymentStatus.boldInProgress) _stopPolling();
  }

  Future<void> _failed(ApiException e) async {
    if (isClosed) return;
    emit(state.copyWith(busy: false, message: _message(e)));
    // Lo más probable es que el pago cambió (el conductor confirmó, Bold respondió…).
    if (e.code != 'network') await load();
  }

  void _startPolling() {
    _pollUntil = _now().add(pollTimeout);
    _poll?.cancel();
    _poll = Timer.periodic(pollInterval, (_) {
      final until = _pollUntil;
      if (until == null || _now().isAfter(until)) {
        _stopPolling();
        return;
      }
      unawaited(refresh());
    });
  }

  void _stopPolling() {
    _poll?.cancel();
    _poll = null;
  }

  static String _message(ApiException e) => switch (e.code) {
    'method_not_accepted' => 'Tu conductor no acepta ese medio de pago.',
    'bold_in_progress' => 'Tienes un pago con Bold en proceso. Espera su resultado.',
    'bold_unavailable' => 'El pago con Bold no está disponible ahora. Inténtalo más tarde o paga en efectivo.',
    'network' => 'Sin conexión. Revisa tu internet.',
    _ when e.statusCode == 409 => 'El pago cambió. Te mostramos el estado actual.',
    _ => 'No pudimos completar la acción. Inténtalo de nuevo.',
  };

  @override
  Future<void> close() async {
    _stopPolling();
    await _events?.cancel();
    return super.close();
  }
}
