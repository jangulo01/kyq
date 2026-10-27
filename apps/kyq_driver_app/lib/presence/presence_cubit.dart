import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kyq_api/kyq_api.dart';

import '../background/foreground_service.dart';
import '../background/location_reporter.dart';
import '../background/online_permissions.dart';
import '../realtime/driver_events.dart';

/// Cuenta del conductor y su interruptor ONLINE/OFFLINE (T056).
class PresenceState {
  const PresenceState({
    this.me,
    this.presence = DriverPresence.offline,
    this.loading = false,
    this.loadFailed = false,
    this.busy = false,
    this.needsPermissions = false,
    this.error,
  });

  final DriverMe? me;
  final DriverPresence presence;
  final bool loading;
  final bool loadFailed;

  /// Hay un cambio de presencia en curso.
  final bool busy;

  /// La UI debe explicar los permisos y luego llamar a [PresenceCubit.grantPermissionsAndGoOnline].
  final bool needsPermissions;
  final String? error;

  bool get online => presence != DriverPresence.offline;

  PresenceState copyWith({
    DriverMe? me,
    DriverPresence? presence,
    bool? loading,
    bool? loadFailed,
    bool? busy,
    bool? needsPermissions,
    String? error,
  }) => PresenceState(
    me: me ?? this.me,
    presence: presence ?? this.presence,
    loading: loading ?? this.loading,
    loadFailed: loadFailed ?? this.loadFailed,
    busy: busy ?? this.busy,
    needsPermissions: needsPermissions ?? false,
    error: error,
  );
}

/// Mensaje en español para los bloqueos de `POST /v1/driver/presence`.
String presenceErrorMessage(ApiException e) => switch (e.code) {
  'subscription_suspended' => 'Tu suscripción está suspendida. Paga tu mensualidad para volver a recibir viajes.',
  'kyc_expired' => 'Algún documento obligatorio falta o venció. Contacta a Kyq para actualizarlo.',
  'trip_in_progress' => 'Termina tu viaje en curso antes de desconectarte.',
  'network' => 'Sin conexión con el servidor. Inténtalo de nuevo.',
  _ => 'No pudimos cambiar tu estado. Inténtalo de nuevo.',
};

class PresenceCubit extends Cubit<PresenceState> {
  PresenceCubit({
    required this._api,
    required this._events,
    required this._permissions,
    required this._service,
    required this._reporter,
  }) : super(const PresenceState());

  final KyqApiClient _api;
  final DriverEvents _events;
  final OnlinePermissions _permissions;
  final OnlineService _service;
  final LocationReporter _reporter;
  bool _permissionsAsked = false;

  /// Carga la cuenta y empieza a escuchar sus eventos. Si ya estaba ONLINE, reanuda el servicio.
  Future<void> load() async {
    emit(state.copyWith(loading: true, loadFailed: false));
    try {
      final me = await _api.driverMe();
      _events.listenTo(me.driverId);
      emit(state.copyWith(me: me, presence: me.presence, loading: false));
      if (me.presence != DriverPresence.offline) await _startTracking();
    } on ApiException {
      emit(state.copyWith(loading: false, loadFailed: true));
    }
  }

  Future<void> setOnline(bool online) => online ? goOnline() : goOffline();

  Future<void> goOnline() async {
    if (state.busy) return;
    if (!await _permissions.allGranted() && (!_permissionsAsked || !await _permissions.requiredGranted())) {
      emit(state.copyWith(needsPermissions: true));
      return;
    }
    await _change(true);
  }

  /// Tras explicar los permisos: los pide y, si hay ubicación, pasa a ONLINE.
  Future<void> grantPermissionsAndGoOnline() async {
    _permissionsAsked = true;
    if (!await _permissions.request()) {
      emit(state.copyWith(error: 'Sin permiso de ubicación no podemos enviarte viajes. Actívalo en Ajustes.'));
      return;
    }
    await _change(true);
  }

  void dismissPermissions() => emit(state.copyWith());

  Future<void> openSettings() => _permissions.openSettings();

  Future<void> goOffline() async {
    if (state.busy) return;
    await _change(false);
  }

  Future<void> _change(bool online) async {
    emit(state.copyWith(busy: true));
    try {
      final presence = await _api.setOnline(online);
      emit(state.copyWith(presence: presence, busy: false));
      if (presence == DriverPresence.offline) {
        await _stopTracking();
      } else {
        await _startTracking();
      }
    } on ApiException catch (e) {
      emit(state.copyWith(busy: false, error: presenceErrorMessage(e)));
    }
  }

  Future<void> _startTracking() async {
    try {
      await _service.start();
    } on Object {
      // Sin servicio la app sigue funcionando en primer plano; el GPS se envía igual.
    }
    _reporter.start();
  }

  Future<void> _stopTracking() async {
    await _reporter.stop();
    try {
      await _service.stop();
    } on Object {
      // Nada que hacer: el servicio ya no está.
    }
  }

  /// Al cerrar sesión: para el servicio y el tiempo real.
  Future<void> reset() async {
    await _stopTracking();
    await _events.stop();
    _permissionsAsked = false;
    emit(const PresenceState());
  }

  @override
  Future<void> close() async {
    await _stopTracking();
    return super.close();
  }
}
