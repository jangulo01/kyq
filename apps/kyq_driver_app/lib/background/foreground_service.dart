import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:kyq_radio/kyq_radio.dart';
import 'package:permission_handler/permission_handler.dart';

/// Servicio que mantiene viva la app mientras el conductor está ONLINE (T054).
abstract interface class OnlineService {
  Future<void> start();

  Future<void> stop();
}

/// Aviso fijo de Android con sus motivos: ONLINE (T054) y "Radio encendida" (011). Las pruebas
/// pasan uno falso.
abstract interface class ForegroundHost {
  Future<void> show({required bool online, required bool radio});

  Future<void> hide();

  /// Botones del aviso que se tocaron (`radio_off`).
  Stream<String> get buttons;
}

/// Un solo servicio en primer plano para los dos motivos: sigue vivo mientras haya alguno, y el
/// aviso dice cuáles (FR-026). "Apagar radio" en el aviso apaga solo la radio.
class KeepAlive implements RadioKeepAlive {
  KeepAlive(this._host);

  final ForegroundHost _host;
  bool _online = false;
  bool _radio = false;

  /// La vista que usa la presencia ONLINE.
  late final OnlineService online = _OnlineReason(this);

  Future<void> _sync() => !_online && !_radio ? _host.hide() : _host.show(online: _online, radio: _radio);

  @override
  Future<void> setRadioOn(bool on) {
    if (_radio == on) return Future.value();
    _radio = on;
    return _sync();
  }

  @override
  Stream<void> get turnOffRequests => _host.buttons.where((id) => id == radioOffButton);
}

class _OnlineReason implements OnlineService {
  _OnlineReason(this._keep);

  final KeepAlive _keep;

  @override
  Future<void> start() {
    _keep._online = true;
    return _keep._sync();
  }

  @override
  Future<void> stop() {
    _keep._online = false;
    return _keep._sync();
  }
}

/// Id del botón "Apagar radio" del aviso.
const radioOffButton = 'radio_off';

/// [ForegroundHost] con `flutter_foreground_task`.
///
/// El servicio solo mantiene el proceso en primer plano con su notificación: el envío de
/// ubicación, el tiempo real y las salas siguen en el isolate principal, que Android no congela
/// mientras el servicio está activo. Los tipos `microphone|mediaPlayback` mantienen viva la voz
/// con la pantalla apagada (T074, FR-018, FR-026); `location` solo mientras está ONLINE.
class PlatformForegroundHost implements ForegroundHost {
  PlatformForegroundHost() {
    FlutterForegroundTask.addTaskDataCallback(_onData);
  }

  final _buttons = StreamController<String>.broadcast();
  bool? _withLocation;

  void _onData(Object data) {
    if (data is String) _buttons.add(data);
  }

  /// Configura el canal de notificación. Se llama una vez desde `main`.
  static void configure() {
    FlutterForegroundTask.initCommunicationPort();
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'kyq_online',
        channelName: 'Conductor conectado y radio',
        channelDescription: 'Aviso fijo mientras estás ONLINE o con la Radio encendida.',
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(showNotification: false, playSound: false),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  static (String, String) _texts(bool online, bool radio) => switch ((online, radio)) {
    (true, true) => (
      'Kyq: estás ONLINE · Radio encendida',
      'Tus clientes pueden pedirte viajes y tus compañeros hablarte.',
    ),
    (true, false) => ('Kyq: estás ONLINE', 'Tus clientes pueden pedirte viajes.'),
    _ => ('Radio encendida', 'Oyes a tus compañeros aunque bloquees el teléfono.'),
  };

  @override
  Future<void> show({required bool online, required bool radio}) async {
    final (title, text) = _texts(online, radio);
    final buttons = [if (radio) const NotificationButton(id: radioOffButton, text: 'Apagar radio')];
    final ServiceRequestResult result;
    final running = await FlutterForegroundTask.isRunningService;
    if (running && _withLocation == online) {
      result = await FlutterForegroundTask.updateService(
        notificationTitle: title,
        notificationText: text,
        notificationButtons: buttons,
      );
    } else {
      // Los tipos del servicio no cambian en caliente: con o sin ubicación hay que reiniciarlo.
      if (running) await FlutterForegroundTask.stopService();
      // Android 14 exige el permiso de micrófono concedido para arrancar el tipo `microphone`.
      final mic = await Permission.microphone.isGranted;
      result = await FlutterForegroundTask.startService(
        serviceId: 256,
        serviceTypes: [
          if (online) ForegroundServiceTypes.location,
          ForegroundServiceTypes.mediaPlayback,
          if (mic) ForegroundServiceTypes.microphone,
        ],
        notificationTitle: title,
        notificationText: text,
        notificationButtons: buttons,
        notificationInitialRoute: online ? '/' : '/radio',
        callback: startOnlineTask,
      );
      _withLocation = online;
    }
    if (result is ServiceRequestFailure) debugPrint('Servicio en primer plano: ${result.error}');
  }

  @override
  Future<void> hide() async {
    _withLocation = null;
    if (await FlutterForegroundTask.isRunningService) await FlutterForegroundTask.stopService();
  }

  @override
  Stream<String> get buttons => _buttons.stream;
}

@pragma('vm:entry-point')
void startOnlineTask() {
  FlutterForegroundTask.setTaskHandler(_OnlineTaskHandler());
}

/// No hace trabajo propio: su presencia mantiene el proceso en primer plano. Los botones del aviso
/// se pasan al isolate principal.
class _OnlineTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}

  @override
  void onNotificationButtonPressed(String id) => FlutterForegroundTask.sendDataToMain(id);

  @override
  void onNotificationPressed() => FlutterForegroundTask.launchApp('/');
}
