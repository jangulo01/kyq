import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kyq_api/kyq_api.dart';

import 'checkout_launcher.dart';

/// Resultado del pago que se está siguiendo.
enum PaymentOutcome { processing, approved, rejected, review }

class SubscriptionState {
  const SubscriptionState({
    this.view,
    this.loading = false,
    this.loadFailed = false,
    this.paying = false,
    this.payment,
    this.outcome,
    this.message,
  });

  final SubscriptionView? view;
  final bool loading;
  final bool loadFailed;

  /// Creando el pago o abriendo el checkout.
  final bool paying;

  /// Pago que se sigue hasta que Bold lo confirme o lo rechace.
  final Payment? payment;
  final PaymentOutcome? outcome;
  final String? message;

  SubscriptionState copyWith({
    SubscriptionView? view,
    bool? loading,
    bool? loadFailed,
    bool? paying,
    Payment? payment,
    PaymentOutcome? outcome,
    String? message,
  }) => SubscriptionState(
    view: view ?? this.view,
    loading: loading ?? this.loading,
    loadFailed: loadFailed ?? this.loadFailed,
    paying: paying ?? this.paying,
    payment: payment ?? this.payment,
    outcome: outcome ?? this.outcome,
    message: message,
  );
}

/// "Mi suscripción" (T032): estado, precio, pago con Bold e historial.
///
/// Bold confirma al backend; la app solo pregunta: al volver de la Custom Tab y cada
/// [pollInterval] mientras el pago esté en curso, durante [pollTimeout] como mucho.
class SubscriptionCubit extends Cubit<SubscriptionState> {
  SubscriptionCubit(
    this._api,
    this._checkout, {
    this.pollInterval = const Duration(seconds: 4),
    this.pollTimeout = const Duration(minutes: 2),
    this.onApproved,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now,
       super(const SubscriptionState());

  final KyqApiClient _api;
  final CheckoutLauncher _checkout;
  final Duration pollInterval;
  final Duration pollTimeout;

  /// Tras un pago aprobado (la cuenta puede pasar a poder trabajar).
  final void Function()? onApproved;
  final DateTime Function() _now;

  Timer? _poll;
  DateTime? _pollUntil;
  bool _refreshing = false;

  Future<void> load() async {
    emit(state.copyWith(loading: true, loadFailed: false, message: state.message));
    try {
      final view = await _api.driverSubscription();
      if (isClosed) return;
      emit(state.copyWith(view: view, loading: false, message: state.message));
      // Al reabrir la pantalla con un pago a medias (p. ej. PSE pendiente) se sigue esperándolo.
      final inProgress = view.payments.where((p) => p.status.inProgress).firstOrNull;
      if (state.payment == null && inProgress != null) _follow(inProgress);
    } on ApiException {
      if (!isClosed) emit(state.copyWith(loading: false, loadFailed: true));
    }
  }

  /// Crea el pago y abre el checkout de Bold.
  Future<void> pay() async {
    if (state.paying) return;
    emit(state.copyWith(paying: true));
    try {
      final payment = await _api.createPayment();
      _follow(payment);
      await _open(payment);
    } on ApiException catch (e) {
      if (e.code == 'payment_in_progress') {
        await _resumeInProgress();
      } else {
        if (!isClosed) emit(state.copyWith(paying: false, message: _payMessage(e)));
      }
    }
  }

  /// Vuelve a abrir el checkout del pago en curso (si el conductor cerró la pestaña).
  Future<void> continuePayment() async {
    final payment = state.payment;
    if (payment == null || state.paying) return;
    emit(state.copyWith(paying: true));
    await _open(payment);
  }

  /// La app volvió a primer plano (normalmente, al cerrar la Custom Tab).
  Future<void> onResumed() async {
    if (state.payment?.status.inProgress ?? false) {
      _pollUntil = _now().add(pollTimeout);
      _startPolling();
      await _refreshPayment();
    }
  }

  Future<void> _open(Payment payment) async {
    final url = payment.checkoutUrl;
    final opened = url != null && await _checkout.open(url);
    if (isClosed) return;
    emit(state.copyWith(paying: false, message: opened ? null : 'No pudimos abrir la página de pago. Reintenta.'));
  }

  Future<void> _resumeInProgress() async {
    try {
      final view = await _api.driverSubscription();
      final inProgress = view.payments.where((p) => p.status.inProgress).firstOrNull;
      if (isClosed) return;
      emit(state.copyWith(view: view));
      if (inProgress == null) {
        emit(state.copyWith(paying: false, message: 'Ya tienes un pago en proceso. Espera un momento.'));
        return;
      }
      _follow(inProgress);
      await _open(inProgress);
    } on ApiException catch (e) {
      if (!isClosed) emit(state.copyWith(paying: false, message: _payMessage(e)));
    }
  }

  void _follow(Payment payment) {
    emit(state.copyWith(payment: payment, outcome: PaymentOutcome.processing, paying: state.paying));
    _pollUntil = _now().add(pollTimeout);
    _startPolling();
  }

  void _startPolling() {
    _poll?.cancel();
    _poll = Timer.periodic(pollInterval, (_) {
      final until = _pollUntil;
      if (until == null || _now().isAfter(until)) {
        _stopPolling();
        if (!isClosed && state.outcome == PaymentOutcome.processing) {
          emit(state.copyWith(message: 'Bold aún no confirma tu pago. Te avisaremos apenas llegue la confirmación.'));
        }
        return;
      }
      unawaited(_refreshPayment());
    });
  }

  void _stopPolling() {
    _poll?.cancel();
    _poll = null;
  }

  Future<void> _refreshPayment() async {
    final payment = state.payment;
    if (payment == null || _refreshing || isClosed) return;
    _refreshing = true;
    try {
      final updated = await _api.refreshPayment(payment.id);
      if (isClosed) return;
      final outcome = switch (updated.status) {
        PaymentStatus.created || PaymentStatus.processing => PaymentOutcome.processing,
        PaymentStatus.approved => PaymentOutcome.approved,
        PaymentStatus.needsReview => PaymentOutcome.review,
        PaymentStatus.rejected || PaymentStatus.expired || PaymentStatus.voided => PaymentOutcome.rejected,
      };
      emit(state.copyWith(payment: updated, outcome: outcome, paying: state.paying));
      if (outcome != PaymentOutcome.processing) {
        _stopPolling();
        await load();
        if (outcome == PaymentOutcome.approved) onApproved?.call();
      }
    } on ApiException {
      // Sin red se reintenta en el siguiente sondeo.
    } finally {
      _refreshing = false;
    }
  }

  static String _payMessage(ApiException e) => switch (e.code) {
    'documents_not_ok' => 'Podrás pagar cuando un administrador apruebe tus documentos.',
    'price_not_set' => 'El precio de la suscripción aún no está definido. Inténtalo más tarde.',
    'bold_unavailable' => 'El servicio de pagos no responde. Inténtalo en unos minutos.',
    'network' => 'Sin conexión. Revisa tu internet.',
    _ => 'No pudimos iniciar el pago. Inténtalo de nuevo.',
  };

  @override
  Future<void> close() {
    _stopPolling();
    return super.close();
  }
}
