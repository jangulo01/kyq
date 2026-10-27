import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';

/// Foco de audio para la voz entrante (FR-019, RN-KYQ-011).
abstract interface class AudioFocus {
  /// Configura la sesión una vez antes de conectar.
  Future<void> prepare();

  /// Pide foco transitorio con atenuación: la navegación baja el volumen mientras suena la voz.
  Future<void> duck();

  /// Devuelve el foco; la navegación recupera su volumen.
  Future<void> release();
}

/// [AudioFocus] con `audio_session`.
///
/// Solo actúa en Android. En iOS la sesión la gestiona LiveKit (`playAndRecord` con altavoz) y
/// configurarla aquí también la pisaría. La salida por altavoz la fija [LiveKitVoiceRoom].
class AudioSessionFocus implements AudioFocus {
  AudioSession? _session;

  bool get _android => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  Future<void> prepare() async {
    if (!_android) return;
    final session = _session ??= await AudioSession.instance;
    await session.configure(
      const AudioSessionConfiguration(
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.speech,
          usage: AndroidAudioUsage.voiceCommunication,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gainTransientMayDuck,
        androidWillPauseWhenDucked: false,
      ),
    );
  }

  @override
  Future<void> duck() async {
    if (!_android) return;
    final session = _session ??= await AudioSession.instance;
    await session.setActive(true, androidAudioFocusGainType: AndroidAudioFocusGainType.gainTransientMayDuck);
  }

  @override
  Future<void> release() async {
    if (!_android) return;
    await _session?.setActive(false);
  }
}
