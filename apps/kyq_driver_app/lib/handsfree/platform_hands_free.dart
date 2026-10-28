import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:kyq_ptt/kyq_ptt.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// [HandsFreePlatform] sobre la capa Kotlin de `android/.../HandsFreeBridge.kt` (RN-KYQ-012):
/// sesión multimedia para el botón físico y burbuja flotante. Fuera de Android no hace nada.
class MethodChannelHandsFree implements HandsFreePlatform {
  const MethodChannelHandsFree();

  static const _methods = MethodChannel('kyq/hands_free');
  static const _events = EventChannel('kyq/hands_free/events');

  static bool get _android => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  Stream<HandsFreeSignal> get signals {
    if (!_android) return const Stream.empty();
    return _events.receiveBroadcastStream().map(_signal).where((s) => s != null).cast<HandsFreeSignal>();
  }

  static HandsFreeSignal? _signal(Object? raw) => switch (raw) {
    'button_down' => HandsFreeSignal.buttonDown,
    'button_up' => HandsFreeSignal.buttonUp,
    'bubble_down' => HandsFreeSignal.bubbleDown,
    'bubble_up' => HandsFreeSignal.bubbleUp,
    _ => null,
  };

  @override
  Future<void> setMediaButtonActive(bool active) async {
    if (_android) await _methods.invokeMethod<void>('setMediaButtonActive', {'active': active});
  }

  @override
  Future<void> showBubble(BubbleLook look) async {
    if (_android) await _methods.invokeMethod<bool>('showBubble', {'look': look.name});
  }

  @override
  Future<void> hideBubble() async {
    if (_android) await _methods.invokeMethod<void>('hideBubble');
  }
}

/// Preferencias del manos libres guardadas en el teléfono (FR-015).
typedef HandsFreePrefs = ({bool mediaButton, bool bubble});

abstract interface class HandsFreePrefsStore {
  Future<HandsFreePrefs> load();

  Future<void> save(HandsFreePrefs prefs);
}

/// [HandsFreePrefsStore] con `shared_preferences`. Por defecto ambos activados.
class SharedPrefsHandsFreeStore implements HandsFreePrefsStore {
  const SharedPrefsHandsFreeStore();

  static const _mediaButton = 'handsfree.media_button';
  static const _bubble = 'handsfree.bubble';

  @override
  Future<HandsFreePrefs> load() async {
    final prefs = SharedPreferencesAsync();
    return (mediaButton: await prefs.getBool(_mediaButton) ?? true, bubble: await prefs.getBool(_bubble) ?? true);
  }

  @override
  Future<void> save(HandsFreePrefs value) async {
    final prefs = SharedPreferencesAsync();
    await prefs.setBool(_mediaButton, value.mediaButton);
    await prefs.setBool(_bubble, value.bubble);
  }
}

/// Permiso de Android para dibujar sobre otras apps (burbuja, FR-014).
abstract interface class OverlayPermission {
  Future<bool> isGranted();

  /// Abre la pantalla del sistema; devuelve si quedó concedido.
  Future<bool> request();
}

/// [OverlayPermission] con `permission_handler`.
class PlatformOverlayPermission implements OverlayPermission {
  const PlatformOverlayPermission();

  @override
  Future<bool> isGranted() => Permission.systemAlertWindow.isGranted;

  @override
  Future<bool> request() async => (await Permission.systemAlertWindow.request()).isGranted;
}
