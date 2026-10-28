import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kyq_api/kyq_api.dart';

@immutable
class PreconsultSettingsState {
  const PreconsultSettingsState({
    this.accepts = false,
    this.blocked = const {},
    this.clients = const [],
    this.loading = true,
    this.error,
  });

  /// Recibe consultas de voz de sus clientes (FR-001).
  final bool accepts;

  /// Clientes silenciados (FR-002).
  final Set<String> blocked;
  final List<DriverClient> clients;
  final bool loading;
  final String? error;

  PreconsultSettingsState copyWith({
    bool? accepts,
    Set<String>? blocked,
    List<DriverClient>? clients,
    bool? loading,
    String? error,
  }) => PreconsultSettingsState(
    accepts: accepts ?? this.accepts,
    blocked: blocked ?? this.blocked,
    clients: clients ?? this.clients,
    loading: loading ?? this.loading,
    error: error,
  );
}

/// Ajustes de consultas de voz del conductor: interruptor global y silencio por cliente.
class PreconsultSettingsCubit extends Cubit<PreconsultSettingsState> {
  PreconsultSettingsCubit(this._api) : super(const PreconsultSettingsState());

  final KyqApiClient _api;

  Future<void> load() async {
    emit(state.copyWith(loading: true));
    try {
      final (settings, clients) = await (_api.preconsultSettings(), _api.driverClients()).wait;
      if (isClosed) return;
      emit(
        state.copyWith(
          accepts: settings.acceptsPreconsults,
          blocked: settings.blockedPassengerIds.toSet(),
          clients: clients,
          loading: false,
        ),
      );
    } on Object catch (e) {
      debugPrint('Ajustes de consultas: $e');
      if (!isClosed) emit(state.copyWith(loading: false, error: 'No pudimos cargar tus ajustes.'));
    }
  }

  Future<void> setAccepts(bool on) async {
    final before = state.accepts;
    emit(state.copyWith(accepts: on));
    try {
      final settings = await _api.setAcceptsPreconsults(on);
      if (!isClosed) emit(state.copyWith(accepts: settings.acceptsPreconsults));
    } on ApiException {
      if (!isClosed) emit(state.copyWith(accepts: before, error: 'No pudimos guardar el cambio.'));
    }
  }

  /// [allowed] false silencia al cliente.
  Future<void> setClientAllowed(String passengerId, bool allowed) async {
    final before = state.blocked;
    emit(state.copyWith(blocked: allowed ? (before.toSet()..remove(passengerId)) : {...before, passengerId}));
    try {
      await _api.setClientPreconsultsBlocked(passengerId, blocked: !allowed);
    } on ApiException {
      if (!isClosed) emit(state.copyWith(blocked: before, error: 'No pudimos guardar el cambio.'));
    }
  }
}
