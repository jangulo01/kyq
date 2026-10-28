import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_realtime/kyq_realtime.dart';

/// Avisos de cambio de la torre (`tower.changed` en `admin:tower`, 007 research R3).
abstract interface class TowerEvents {
  /// Emite cada vez que algo cambió en la torre. Termina con error si el canal falla.
  Stream<void> changes();
}

/// [TowerEvents] sobre Centrifugo.
class RealtimeTowerEvents implements TowerEvents {
  RealtimeTowerEvents(this._realtime);

  final KyqRealtime _realtime;

  @override
  Stream<void> changes() async* {
    await _realtime.connect();
    yield* _realtime.subscribe(Channels.adminTower).where((e) => e is TowerChanged).map((_) {});
  }
}

/// Resoluciones H3 que ofrece la torre (de barrio a manzanas).
const towerResolutions = [6, 7, 8, 9];

class TowerState {
  const TowerState({
    this.snapshot,
    this.resolution = 8,
    this.loading = false,
    this.error,
    this.live = false,
    this.selected = const {},
  });

  final TowerSnapshot? snapshot;
  final int resolution;
  final bool loading;
  final String? error;

  /// Suscrito al canal en vivo; si no, solo se actualiza cada [TowerCubit.pollEvery].
  final bool live;

  /// 009: hexágonos elegidos para el megáfono.
  final Set<String> selected;

  TowerState copyWith({
    TowerSnapshot? snapshot,
    int? resolution,
    bool? loading,
    String? error,
    bool? live,
    Set<String>? selected,
  }) => TowerState(
    snapshot: snapshot ?? this.snapshot,
    resolution: resolution ?? this.resolution,
    loading: loading ?? this.loading,
    error: error,
    live: live ?? this.live,
    selected: selected ?? this.selected,
  );

  /// 009: hexágonos con conductores, que pueden recibir un comunicado.
  List<TowerCell> get driverCells => [
    for (final c in snapshot?.cells ?? const <TowerCell>[])
      if (c.freeDrivers + c.busyDrivers > 0) c,
  ];

  /// Hexágonos con demanda o sin oferta, ya ordenados por presión (el backend los ordena).
  List<TowerCell> get pressureCells => [
    for (final c in snapshot?.cells ?? const <TowerCell>[])
      if (c.level != PressureLevel.none) c,
  ];
}

String _message(ApiException e) => switch (e.code) {
  'network' => 'Sin conexión con el servidor.',
  _ => e.message.isEmpty ? 'Algo salió mal (${e.code}).' : e.message,
};

/// Torre de control (T017, FR-001–FR-006): carga la instantánea, la vuelve a pedir con cada
/// aviso en vivo sin solapar peticiones, y cada [pollEvery] para que avance la ventana de una hora
/// y como respaldo si el canal falla.
class TowerCubit extends Cubit<TowerState> {
  TowerCubit(this._api, {this.events, this.pollEvery = const Duration(seconds: 30)}) : super(const TowerState());

  final KyqApiClient _api;

  /// Avisos en vivo; sin ellos solo hay sondeo.
  final TowerEvents? events;
  final Duration pollEvery;

  StreamSubscription<void>? _sub;
  Timer? _timer;
  bool _inFlight = false;
  bool _again = false;

  /// Primera carga, suscripción al canal y sondeo de respaldo.
  Future<void> start() {
    _timer = Timer.periodic(pollEvery, (_) => load());
    final events = this.events;
    if (events != null) {
      _sub = events.changes().listen(
        (_) => load(),
        onError: (Object _) {
          if (!isClosed) emit(state.copyWith(live: false, error: state.error));
        },
        onDone: () {
          if (!isClosed) emit(state.copyWith(live: false, error: state.error));
        },
      );
      emit(state.copyWith(live: true));
    }
    return load();
  }

  Future<void> load() async {
    if (_inFlight) {
      _again = true;
      return;
    }
    _inFlight = true;
    try {
      do {
        _again = false;
        final resolution = state.resolution;
        emit(state.copyWith(loading: true, error: state.error));
        try {
          final snapshot = await _api.adminTower(resolution: resolution);
          if (isClosed) return;
          // Si la resolución cambió durante la petición, se descarta y se pide de nuevo.
          if (state.resolution != resolution) {
            _again = true;
            continue;
          }
          emit(state.copyWith(snapshot: snapshot, loading: false));
        } on ApiException catch (e) {
          if (isClosed) return;
          emit(state.copyWith(loading: false, error: _message(e)));
        }
      } while (_again && !isClosed);
    } finally {
      _inFlight = false;
    }
  }

  Future<void> setResolution(int resolution) {
    if (resolution == state.resolution) return Future.value();
    // Los hexágonos elegidos son de la resolución anterior.
    emit(state.copyWith(resolution: resolution, error: state.error, selected: const {}));
    return load();
  }

  /// 009: elige o quita un hexágono para el megáfono.
  void toggleCell(String cell) {
    final next = {...state.selected};
    if (!next.remove(cell)) next.add(cell);
    emit(state.copyWith(selected: next, error: state.error));
  }

  void clearSelection() => emit(state.copyWith(selected: const {}, error: state.error));

  @override
  Future<void> close() async {
    _timer?.cancel();
    await _sub?.cancel();
    return super.close();
  }
}
