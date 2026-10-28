import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:kyq_radio/kyq_radio.dart';
import 'package:permission_handler/permission_handler.dart';

const _radioOffButton = 'radio_off';

/// "Radio encendida" del pasajero (011, FR-026): servicio en primer plano con su aviso fijo y el
/// botón "Apagar radio", para oír a su conductor con la pantalla bloqueada.
class PlatformRadioKeepAlive implements RadioKeepAlive {
  PlatformRadioKeepAlive() {
    if (_supported) FlutterForegroundTask.addTaskDataCallback(_onData);
  }

  final _off = StreamController<void>.broadcast();

  static bool get _supported => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  void _onData(Object data) {
    if (data == _radioOffButton) _off.add(null);
  }

  /// Configura el canal de notificación. Se llama una vez desde `main`.
  static void configure() {
    if (!_supported) return;
    FlutterForegroundTask.initCommunicationPort();
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'kyq_radio',
        channelName: 'Radio encendida',
        channelDescription: 'Aviso fijo mientras la Radio de Kyq está encendida.',
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

  @override
  Future<void> setRadioOn(bool on) async {
    if (!_supported) return;
    try {
      final running = await FlutterForegroundTask.isRunningService;
      if (!on) {
        if (running) await FlutterForegroundTask.stopService();
        return;
      }
      if (running) return;
      final mic = await Permission.microphone.isGranted;
      final result = await FlutterForegroundTask.startService(
        serviceId: 257,
        serviceTypes: [ForegroundServiceTypes.mediaPlayback, if (mic) ForegroundServiceTypes.microphone],
        notificationTitle: 'Radio encendida',
        notificationText: 'Oyes a tus conductores aunque bloquees el teléfono.',
        notificationButtons: const [NotificationButton(id: _radioOffButton, text: 'Apagar radio')],
        notificationInitialRoute: '/radio',
        callback: startRadioTask,
      );
      if (result is ServiceRequestFailure) debugPrint('Radio en primer plano: ${result.error}');
    } on Object catch (e) {
      debugPrint('Radio en primer plano: $e');
    }
  }

  @override
  Stream<void> get turnOffRequests => _off.stream;
}

@pragma('vm:entry-point')
void startRadioTask() {
  FlutterForegroundTask.setTaskHandler(_RadioTaskHandler());
}

/// Sin trabajo propio: mantiene el proceso en primer plano y pasa "Apagar radio" a la app.
class _RadioTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}

  @override
  void onNotificationButtonPressed(String id) => FlutterForegroundTask.sendDataToMain(id);

  @override
  void onNotificationPressed() => FlutterForegroundTask.launchApp('/radio');
}
