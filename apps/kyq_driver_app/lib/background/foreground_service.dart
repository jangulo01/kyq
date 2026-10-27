import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:permission_handler/permission_handler.dart';

/// Servicio que mantiene viva la app mientras el conductor está ONLINE (T054).
abstract interface class OnlineService {
  Future<void> start();

  Future<void> stop();
}

/// [OnlineService] con `flutter_foreground_task`.
///
/// El servicio solo mantiene el proceso en primer plano con su notificación: el envío de
/// ubicación y el tiempo real siguen en el isolate principal, que Android no congela mientras el
/// servicio está activo. Los tipos `microphone|mediaPlayback` mantienen viva la sala de voz del PTT
/// con la pantalla apagada (T074, FR-018).
class ForegroundOnlineService implements OnlineService {
  /// Configura el canal de notificación. Se llama una vez desde `main`.
  static void configure() {
    FlutterForegroundTask.initCommunicationPort();
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'kyq_online',
        channelName: 'Conductor conectado',
        channelDescription: 'Aviso fijo mientras estás ONLINE y recibiendo viajes.',
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
  Future<void> start() async {
    // Android 14 exige el permiso de micrófono concedido para arrancar el tipo `microphone`.
    final mic = await Permission.microphone.isGranted;
    final types = [
      ForegroundServiceTypes.location,
      ForegroundServiceTypes.mediaPlayback,
      if (mic) ForegroundServiceTypes.microphone,
    ];
    final ServiceRequestResult result;
    if (await FlutterForegroundTask.isRunningService) {
      result = await FlutterForegroundTask.restartService();
    } else {
      result = await FlutterForegroundTask.startService(
        serviceId: 256,
        serviceTypes: types,
        notificationTitle: 'Kyq: estás ONLINE',
        notificationText: 'Tus clientes pueden pedirte viajes.',
        notificationInitialRoute: '/',
        callback: startOnlineTask,
      );
    }
    if (result is ServiceRequestFailure) debugPrint('Servicio en primer plano: ${result.error}');
  }

  @override
  Future<void> stop() async {
    if (await FlutterForegroundTask.isRunningService) await FlutterForegroundTask.stopService();
  }
}

@pragma('vm:entry-point')
void startOnlineTask() {
  FlutterForegroundTask.setTaskHandler(_OnlineTaskHandler());
}

/// No hace trabajo propio: su presencia mantiene el proceso en primer plano.
class _OnlineTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}

  @override
  void onNotificationPressed() => FlutterForegroundTask.launchApp('/');
}
