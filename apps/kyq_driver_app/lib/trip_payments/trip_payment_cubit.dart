import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_realtime/kyq_realtime.dart';

/// Acción del conductor sobre el pago de un viaje (004, FR-005, FR-006).
enum DriverPaymentAction { confirmCash, disputeCash, markUnpaid }

/// Llama a la ruta de [action] para el viaje [tripId].
Future<TripPayment> runDriverPaymentAction(KyqApiClient api, String tripId, DriverPaymentAction action) =>
    switch (action) {
      DriverPaymentAction.confirmCash => api.confirmCashReceived(tripId),
      DriverPaymentAction.disputeCash => api.disputeCash(tripId),
      DriverPaymentAction.markUnpaid => api.markTripUnpaid(tripId),
    };

/// Mensaje para el conductor de un error al actuar sobre un pago.
String driverPaymentError(ApiException e) => switch (e.code) {
  'bold_in_progress' => 'El pasajero está pagando con Bold. Espera el resultado.',
  'network' => 'Sin conexión. Revisa tu internet.',
  _ when e.statusCode == 409 => 'El pago cambió. Te mostramos el estado actual.',
  _ => 'No pudimos completar la acción. Inténtalo de nuevo.',
};

class TripPaymentState {
  const TripPaymentState({this.payment, this.loading = false, this.busy = false, this.message});

  /// null: el viaje aún no tiene pago (no completado o anterior a 004).
  final TripPayment? payment;
  final bool loading;
  final bool busy;
  final String? message;
}

/// Pago del viaje en el resumen del conductor: confirmar efectivo, disputarlo o marcar no pagado.
/// Los reportes del pasajero y Bold llegan por `trip_payment.updated` (FR-007).
class TripPaymentCubit extends Cubit<TripPaymentState> {
  TripPaymentCubit(this._api, Stream<RealtimeEvent> events, this.tripId)
    : super(const TripPaymentState(loading: true)) {
    _sub = events.listen((e) {
      if (e is TripPaymentUpdated && e.tripId == tripId) unawaited(load());
    });
  }

  final KyqApiClient _api;
  final String tripId;
  late final StreamSubscription<RealtimeEvent> _sub;

  Future<void> load() async {
    try {
      final payment = await _api.tripPayment(tripId);
      if (!isClosed) emit(TripPaymentState(payment: payment, message: state.message));
    } on ApiException {
      if (!isClosed) emit(TripPaymentState(payment: state.payment, message: 'No pudimos cargar el pago del viaje.'));
    }
  }

  Future<void> act(DriverPaymentAction action) async {
    if (state.busy) return;
    emit(TripPaymentState(payment: state.payment, busy: true));
    try {
      final payment = await runDriverPaymentAction(_api, tripId, action);
      if (!isClosed) emit(TripPaymentState(payment: payment));
    } on ApiException catch (e) {
      if (isClosed) return;
      emit(TripPaymentState(payment: state.payment, message: driverPaymentError(e)));
      if (e.code != 'network') await load();
    }
  }

  @override
  Future<void> close() async {
    await _sub.cancel();
    return super.close();
  }
}
