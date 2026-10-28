import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_realtime/kyq_realtime.dart';

import '../realtime/realtime_events.dart';

class ChosenDriversState {
  const ChosenDriversState({this.drivers = const [], this.loading = false, this.error, this.voiceDrivers = const {}});

  final List<ChosenDriver> drivers;

  /// Conductores que aceptan consultas de voz de este pasajero (005, RN-KYQ-010).
  final Set<String> voiceDrivers;

  /// Se puede preguntar por voz: acepta consultas y está libre ahora.
  bool canAskByVoice(ChosenDriver d) => d.presence == DriverPresence.free && voiceDrivers.contains(d.driverId);
  final bool loading;
  final String? error;
}

/// Lista "Mis Conductores Elegidos" (FR-006, FR-008) con presencia en vivo por
/// `driver_presence:{driverId}` (RN-KYQ-006, SC-002).
class ChosenDriversCubit extends Cubit<ChosenDriversState> {
  ChosenDriversCubit(this._api, {this._realtime = const NoRealtimeEvents()})
    : super(const ChosenDriversState(loading: true));

  final KyqApiClient _api;
  final RealtimeEvents _realtime;
  final _presence = <String, StreamSubscription<RealtimeEvent>>{};

  Future<void> load() async {
    emit(ChosenDriversState(drivers: state.drivers, loading: true, voiceDrivers: state.voiceDrivers));
    try {
      final (drivers, voice) = await (_api.chosenDrivers(), _voiceDrivers()).wait;
      if (isClosed) return;
      emit(ChosenDriversState(drivers: drivers, voiceDrivers: voice));
      _syncPresence();
    } on ApiException {
      if (isClosed) return;
      emit(
        ChosenDriversState(
          drivers: state.drivers,
          error: 'No pudimos cargar tus conductores.',
          voiceDrivers: state.voiceDrivers,
        ),
      );
    }
  }

  Future<void> remove(String driverId) async {
    final before = state.drivers;
    emit(
      ChosenDriversState(
        drivers: before.where((d) => d.driverId != driverId).toList(),
        voiceDrivers: state.voiceDrivers,
      ),
    );
    _syncPresence();
    try {
      await _api.removeChosenDriver(driverId);
    } on ApiException catch (e) {
      // 404: ya no estaba en la lista; la vista ya es correcta.
      if (e.statusCode != 404 && !isClosed) {
        emit(
          ChosenDriversState(
            drivers: before,
            error: 'No pudimos eliminar al conductor.',
            voiceDrivers: state.voiceDrivers,
          ),
        );
        _syncPresence();
      }
    }
  }

  /// Una suscripción por conductor de la lista; quita las de conductores que ya no están.
  void _syncPresence() {
    final ids = state.drivers.map((d) => d.driverId).toSet();
    for (final gone in _presence.keys.where((id) => !ids.contains(id)).toList()) {
      _presence.remove(gone)?.cancel();
    }
    for (final id in ids.where((id) => !_presence.containsKey(id))) {
      _presence[id] = _realtime.subscribe(Channels.driverPresence(id)).listen(_onEvent, onError: (Object _) {});
    }
  }

  void _onEvent(RealtimeEvent e) {
    if (e is! DriverPresenceChanged || isClosed) return;
    final presence = DriverPresence.values.asNameMap()[e.presence];
    if (presence == null) return;
    emit(
      ChosenDriversState(
        drivers: [
          for (final d in state.drivers)
            d.driverId == e.driverId
                ? d.copyWith(
                    presence: presence,
                    busyUntilEstimate: presence == DriverPresence.busy ? e.busyUntilEstimate : null,
                  )
                : d,
        ],
        loading: state.loading,
        voiceDrivers: state.voiceDrivers,
      ),
    );
  }

  /// Si falla, sin consultas de voz: no debe impedir ver la lista.
  Future<Set<String>> _voiceDrivers() async {
    try {
      return await _api.preconsultDrivers();
    } on Object {
      return const {};
    }
  }

  @override
  Future<void> close() async {
    for (final sub in _presence.values) {
      await sub.cancel();
    }
    return super.close();
  }
}
