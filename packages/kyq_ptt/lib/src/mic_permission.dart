import 'package:permission_handler/permission_handler.dart';

enum MicAccess { granted, denied, permanentlyDenied }

/// Permiso de micrófono. Las pruebas usan un falso para no tocar canales de plataforma.
abstract interface class MicPermission {
  Future<bool> isGranted();

  Future<MicAccess> request();

  Future<void> openSettings();
}

/// [MicPermission] con `permission_handler`.
class PlatformMicPermission implements MicPermission {
  const PlatformMicPermission();

  @override
  Future<bool> isGranted() => Permission.microphone.isGranted;

  @override
  Future<MicAccess> request() async {
    final status = await Permission.microphone.request();
    if (status.isGranted) return MicAccess.granted;
    return status.isPermanentlyDenied ? MicAccess.permanentlyDenied : MicAccess.denied;
  }

  @override
  Future<void> openSettings() => openAppSettings();
}
