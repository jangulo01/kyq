import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kyq_api/kyq_api.dart';

String _message(ApiException e) => switch (e.code) {
  'network' => 'Sin conexión con el servidor.',
  'not_approved' => 'Solo se pueden anular pagos aprobados.',
  'price_not_set' => 'Define primero el precio mensual de la ciudad.',
  _ => e.message.isEmpty ? 'Algo salió mal (${e.code}).' : e.message,
};

class SubscriptionsState {
  const SubscriptionsState({this.items = const [], this.filter, this.loading = false, this.error});

  final List<AdminSubscription> items;

  /// null: todas.
  final BillingStatus? filter;
  final bool loading;
  final String? error;
}

/// Suscripciones por estado con vencimiento y último pago (T040, FR-022).
class SubscriptionsCubit extends Cubit<SubscriptionsState> {
  SubscriptionsCubit(this._api) : super(const SubscriptionsState());

  final KyqApiClient _api;

  Future<void> load() async {
    final filter = state.filter;
    emit(SubscriptionsState(items: state.items, filter: filter, loading: true));
    try {
      final items = await _api.adminSubscriptions(status: filter);
      emit(SubscriptionsState(items: items, filter: filter));
    } on ApiException catch (e) {
      emit(SubscriptionsState(items: state.items, filter: filter, error: _message(e)));
    }
  }

  Future<void> setFilter(BillingStatus? filter) {
    emit(SubscriptionsState(items: const [], filter: filter));
    return load();
  }

  /// Nuevo precio mensual de una ciudad (FR-013). Devuelve false si falla.
  Future<bool> setPrice(String cityCode, {required int amountMinor, DateTime? effectiveFrom}) async {
    try {
      await _api.adminSetSubscriptionPrice(
        cityCode,
        currency: 'COP',
        amountMinor: amountMinor,
        effectiveFrom: effectiveFrom,
      );
      return true;
    } on ApiException catch (e) {
      emit(SubscriptionsState(items: state.items, filter: state.filter, error: _message(e)));
      return false;
    }
  }
}

class DriverPaymentsState {
  const DriverPaymentsState({this.payments = const [], this.loading = false, this.error});

  final List<Payment> payments;
  final bool loading;
  final String? error;
}

/// Historial de pagos de un conductor, pago manual y anulación con motivo (T040, FR-021).
class DriverPaymentsCubit extends Cubit<DriverPaymentsState> {
  DriverPaymentsCubit(this._api, this.driverId) : super(const DriverPaymentsState());

  final KyqApiClient _api;
  final String driverId;

  Future<void> load() => _run(() async {});

  Future<bool> manual({required String methodDetail, required String reference}) =>
      _run(() => _api.adminManualPayment(driverId, methodDetail: methodDetail, reference: reference));

  Future<bool> voidPayment(String paymentId, String reason) => _run(() => _api.adminVoidPayment(paymentId, reason));

  Future<bool> _run(Future<void> Function() action) async {
    emit(DriverPaymentsState(payments: state.payments, loading: true));
    try {
      await action();
      emit(DriverPaymentsState(payments: await _api.adminDriverPayments(driverId)));
      return true;
    } on ApiException catch (e) {
      emit(DriverPaymentsState(payments: state.payments, error: _message(e)));
      return false;
    }
  }
}
