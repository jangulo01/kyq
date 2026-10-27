import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:permission_handler/permission_handler.dart';

/// Permisos que necesita el conductor para estar ONLINE (T056).
abstract interface class OnlinePermissions {
  /// Imprescindible: ubicación mientras se usa la app.
  Future<bool> requiredGranted();

  /// Todos: ubicación en segundo plano, notificaciones y micrófono.
  Future<bool> allGranted();

  /// Pide todos los permisos en orden. Devuelve [requiredGranted].
  Future<bool> request();

  Future<void> openSettings();
}

/// [OnlinePermissions] con `permission_handler`.
class PlatformOnlinePermissions implements OnlinePermissions {
  @override
  Future<bool> requiredGranted() => Permission.locationWhenInUse.isGranted;

  @override
  Future<bool> allGranted() async =>
      await Permission.locationWhenInUse.isGranted &&
      await Permission.locationAlways.isGranted &&
      await Permission.notification.isGranted &&
      await Permission.microphone.isGranted;

  @override
  Future<bool> request() async {
    // Android pide primero "mientras se usa" y después "todo el tiempo", por separado.
    final location = await Permission.locationWhenInUse.request();
    if (location.isGranted) await Permission.locationAlways.request();
    await Permission.notification.request();
    await Permission.microphone.request();
    if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
      await FlutterForegroundTask.requestIgnoreBatteryOptimization();
    }
    return requiredGranted();
  }

  @override
  Future<void> openSettings() => openAppSettings();
}
