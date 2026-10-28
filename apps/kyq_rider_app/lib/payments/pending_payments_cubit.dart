import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_realtime/kyq_realtime.dart';

import '../app/session_user.dart';
import '../realtime/realtime_events.dart';

/// Viajes del pasajero sin pagar (004, FR-016), recientes primero. Se recarga con el recordatorio
/// (`trip_payment.reminder`) y con cada cambio de un pago (`trip_payment.updated`).
class PendingPaymentsCubit extends Cubit<List<TripPayment>> {
  PendingPaymentsCubit(this._api, {this._realtime = const NoRealtimeEvents()}) : super(const []);

  final KyqApiClient _api;
  final RealtimeEvents _realtime;
  StreamSubscription<RealtimeEvent>? _events;

  Future<void> start() async {
    await load();
    final session = await _api.currentSession();
    final myId = session == null ? null : userIdFromAccessToken(session.accessToken);
    if (isClosed || myId == null) return;
    _events = _realtime.subscribe(Channels.user(myId)).listen((e) {
      if (e is TripPaymentReminder || e is TripPaymentUpdated) unawaited(load());
    }, onError: (Object _) {});
  }

  Future<void> load() async {
    try {
      final pending = await _api.pendingTripPayments();
      if (!isClosed) emit(pending);
    } on ApiException {
      // Es un aviso: si falla, se intenta en la próxima recarga.
    }
  }

  @override
  Future<void> close() async {
    await _events?.cancel();
    return super.close();
  }
}
