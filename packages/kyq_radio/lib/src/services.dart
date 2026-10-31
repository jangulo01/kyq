import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:kyq_ptt/kyq_ptt.dart';

/// Velocidades de reproducción del historial (FR-011); la voz no cambia de tono.
const radioSpeeds = [1.0, 1.5, 2.0];

/// Reproduce un mensaje del registro. Las pruebas usan un falso.
abstract interface class MessagePlayer {
  /// Suena [url] a [speed] y termina cuando acaba o se detiene.
  Future<void> play(String url, {double speed});

  Future<void> setSpeed(double speed);

  Future<void> stop();

  Future<void> dispose();
}

/// [MessagePlayer] con just_audio: ExoPlayer conserva el tono al acelerar (research R4).
class JustAudioMessagePlayer implements MessagePlayer {
  AudioPlayer? _player;

  @override
  Future<void> play(String url, {double speed = 1.0}) async {
    final player = _player ??= AudioPlayer();
    await player.stop();
    await player.setUrl(url);
    await player.setSpeed(speed);
    final done = player.processingStateStream.firstWhere((s) => s == ProcessingState.completed);
    unawaited(player.play());
    // stop() deja el reproductor en idle: también termina la espera.
    await Future.any([
      done,
      player.playerStateStream.firstWhere((s) => s.processingState == ProcessingState.idle).then((_) {}),
    ]);
  }

  @override
  Future<void> setSpeed(double speed) async => _player?.setSpeed(speed);

  @override
  Future<void> stop() async => _player?.stop();

  @override
  Future<void> dispose() async => _player?.dispose();
}

/// Un punto en el mapa.
typedef RadioPoint = ({double lat, double lng});

/// Ubicación actual para "Enviar ubicación" y Emergencia; la app pone la suya (GPS).
abstract interface class RadioLocation {
  /// null si no hay permiso o no se pudo obtener.
  Future<RadioPoint?> current();
}

/// Foto de cámara o galería, ya comprimida (≤ 1280 px, JPEG 75, sin metadatos de ubicación, R6).
abstract interface class RadioPhotoPicker {
  Future<Uint8List?> pick({required bool camera});
}

/// [RadioPhotoPicker] con image_picker y flutter_image_compress.
class PlatformRadioPhotoPicker implements RadioPhotoPicker {
  const PlatformRadioPhotoPicker();

  @override
  Future<Uint8List?> pick({required bool camera}) async {
    final file = await ImagePicker().pickImage(source: camera ? ImageSource.camera : ImageSource.gallery);
    if (file == null) return null;
    // Recomprimir sin EXIF quita la ubicación de la foto (FR-023).
    return FlutterImageCompress.compressWithList(
      await file.readAsBytes(),
      minWidth: 1280,
      minHeight: 1280,
      quality: 75,
      keepExif: false,
    );
  }
}

/// Hace sonar y vibrar una alerta de llamada o una emergencia hasta 60 s o hasta [stop] (FR-022).
class AlertRinger {
  AlertRinger(this._tones, {this.every = const Duration(seconds: 2), this.maxRing = const Duration(seconds: 60)});

  final TonePlayer _tones;
  final Duration every;
  final Duration maxRing;
  Timer? _timer;
  Timer? _limit;

  bool get ringing => _timer != null;

  void start({bool emergency = false}) {
    stop();
    void ring() {
      unawaited(_tones.play(emergency ? PttTone.emergency : PttTone.alert));
      unawaited(HapticFeedback.vibrate());
    }

    ring();
    _timer = Timer.periodic(every, (_) => ring());
    _limit = Timer(maxRing, stop);
  }

  void stop() {
    _timer?.cancel();
    _limit?.cancel();
    _timer = null;
    _limit = null;
  }
}

/// Salida de audio de la radio: altavoz o auricular (FR-009).
abstract interface class AudioOutput {
  Future<void> setSpeaker(bool on);
}

/// [AudioOutput] de las salas LiveKit.
class LiveKitAudioOutput implements AudioOutput {
  const LiveKitAudioOutput();

  @override
  Future<void> setSpeaker(bool on) => setLiveKitSpeakerOutput(on);
}
