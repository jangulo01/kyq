import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_ptt/kyq_ptt.dart';

@immutable
class AdminMegaphoneState {
  const AdminMegaphoneState({this.onAir, this.starting = false, this.message, this.log = const []});

  /// Comunicado en el aire.
  final MegaphoneOnAir? onAir;
  final bool starting;

  /// Resultado o error del último intento, para la pantalla.
  final String? message;
  final List<MegaphoneBroadcast> log;
}

/// Megáfono del panel (009, US3): mantener pulsado habla a los conductores de los hexágonos
/// elegidos; soltar o llegar a 60 s termina el comunicado.
class AdminMegaphoneCubit extends Cubit<AdminMegaphoneState> {
  AdminMegaphoneCubit(this._api, {required this.room}) : super(const AdminMegaphoneState());

  final KyqApiClient _api;
  final VoiceRoom Function() room;
  VoiceRoom? _voice;
  Timer? _cut;
  bool _released = false;

  Future<void> press(Set<String> cells) async {
    if (cells.isEmpty || state.starting || state.onAir != null) return;
    _released = false;
    emit(AdminMegaphoneState(starting: true, log: state.log));
    try {
      final onAir = await _api.startMegaphone(cells.toList());
      final voice = room();
      _voice = voice;
      await voice.connect(onAir.url, onAir.token);
      await voice.setMicrophoneEnabled(true);
      if (isClosed) return;
      emit(AdminMegaphoneState(onAir: onAir, log: state.log));
      _cut = Timer(onAir.endsAt.difference(DateTime.now()), release);
      // Si se soltó mientras se abría la sala, se termina enseguida.
      if (_released) await release();
    } on ApiException catch (e) {
      await _hangUp();
      if (!isClosed) emit(AdminMegaphoneState(message: _message(e), log: state.log));
    } on Object catch (e) {
      debugPrint('Megáfono: $e');
      await _hangUp();
      if (!isClosed) emit(AdminMegaphoneState(message: 'No se pudo abrir el micrófono.', log: state.log));
    }
  }

  Future<void> release() async {
    _released = true;
    final onAir = state.onAir;
    if (onAir == null) return;
    _cut?.cancel();
    await _hangUp();
    try {
      await _api.endMegaphone(onAir.broadcastId);
    } on ApiException {
      // Ya terminó por tiempo en el servidor.
    }
    if (isClosed) return;
    emit(
      AdminMegaphoneState(
        message: 'Comunicado enviado a ${onAir.recipients} conductor${onAir.recipients == 1 ? '' : 'es'}.',
        log: state.log,
      ),
    );
    await loadLog();
  }

  Future<void> loadLog() async {
    try {
      final log = await _api.megaphoneLog(limit: 20);
      if (!isClosed) emit(AdminMegaphoneState(onAir: state.onAir, message: state.message, log: log));
    } on ApiException {
      // El registro es secundario.
    }
  }

  Future<void> _hangUp() async {
    final voice = _voice;
    _voice = null;
    if (voice == null) return;
    try {
      await voice.setMicrophoneEnabled(false);
      await voice.disconnect();
    } on Object {
      // La sala se cierra en el servidor.
    }
  }

  static String _message(ApiException e) => switch (e.code) {
    'no_recipients' => 'No hay conductores conectados en esas zonas.',
    'on_air' => 'Ya tienes un comunicado en curso.',
    'invalid_cells' => 'Elige de 1 a 50 hexágonos de la misma resolución.',
    'network' => 'Sin conexión con el servidor.',
    _ => 'No se pudo emitir el comunicado.',
  };

  @override
  Future<void> close() async {
    _cut?.cancel();
    if (state.onAir != null) await release();
    return super.close();
  }
}
