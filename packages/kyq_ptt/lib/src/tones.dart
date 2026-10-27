import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';

/// Tonos del walkie-talkie: empiezo a hablar, termino y turno ocupado.
enum PttTone { start, end, busy }

/// Tramo de un tono: frecuencia en Hz (0 = silencio) y duración en ms.
typedef _Segment = (double hz, int ms);

const _segments = <PttTone, List<_Segment>>{
  // Subida corta: puedes hablar.
  PttTone.start: [(880, 60), (0, 25), (1320, 80)],
  // Bajada: cambio.
  PttTone.end: [(1320, 60), (0, 25), (880, 80)],
  // Tres pitidos graves, como la señal de ocupado.
  PttTone.busy: [(480, 140), (0, 90), (480, 140), (0, 90), (480, 140)],
};

/// WAV PCM de 16 bits mono sintetizado en el momento, sin assets de terceros (T072).
Uint8List toneWav(PttTone tone, {int sampleRate = 16000, double volume = 0.35}) {
  final samples = <int>[];
  for (final (hz, ms) in _segments[tone]!) {
    final n = sampleRate * ms ~/ 1000;
    // Rampa de 5 ms en cada borde para que no haga clic.
    final fade = math.min(sampleRate * 5 ~/ 1000, n ~/ 2);
    for (var i = 0; i < n; i++) {
      if (hz == 0) {
        samples.add(0);
        continue;
      }
      final edge = math.min(i, n - 1 - i);
      final gain = fade == 0 || edge >= fade ? 1.0 : edge / fade;
      samples.add((math.sin(2 * math.pi * hz * i / sampleRate) * volume * gain * 32767).round());
    }
  }
  return _wav(samples, sampleRate);
}

Uint8List _wav(List<int> samples, int sampleRate) {
  final dataBytes = samples.length * 2;
  final b = ByteData(44 + dataBytes);
  void ascii(int offset, String s) {
    for (var i = 0; i < s.length; i++) {
      b.setUint8(offset + i, s.codeUnitAt(i));
    }
  }

  ascii(0, 'RIFF');
  b.setUint32(4, 36 + dataBytes, Endian.little);
  ascii(8, 'WAVE');
  ascii(12, 'fmt ');
  b.setUint32(16, 16, Endian.little); // tamaño del bloque fmt
  b.setUint16(20, 1, Endian.little); // PCM
  b.setUint16(22, 1, Endian.little); // mono
  b.setUint32(24, sampleRate, Endian.little);
  b.setUint32(28, sampleRate * 2, Endian.little); // bytes por segundo
  b.setUint16(32, 2, Endian.little); // bytes por muestra
  b.setUint16(34, 16, Endian.little); // bits por muestra
  ascii(36, 'data');
  b.setUint32(40, dataBytes, Endian.little);
  for (var i = 0; i < samples.length; i++) {
    b.setInt16(44 + i * 2, samples[i], Endian.little);
  }
  return b.buffer.asUint8List();
}

/// Reproduce los tonos. Las pruebas usan un falso.
abstract interface class TonePlayer {
  Future<void> play(PttTone tone);

  Future<void> dispose();
}

/// [TonePlayer] con `audioplayers`.
class AudioplayersTonePlayer implements TonePlayer {
  AudioPlayer? _player;
  final _cache = <PttTone, Uint8List>{};

  @override
  Future<void> play(PttTone tone) async {
    final player = _player ??= await _create();
    await player.stop();
    await player.play(BytesSource(_cache[tone] ??= toneWav(tone), mimeType: 'audio/wav'));
  }

  Future<AudioPlayer> _create() async {
    final player = AudioPlayer();
    await player.setReleaseMode(ReleaseMode.stop);
    // audioplayers fija el modo y el altavoz de Android de forma global: se ponen los mismos
    // valores que usa la sala de voz y sin pedir foco, para no quitárselo a la navegación.
    await player.setAudioContext(
      AudioContext(
        android: const AudioContextAndroid(
          isSpeakerphoneOn: true,
          audioMode: AndroidAudioMode.inCommunication,
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.voiceCommunicationSignalling,
          audioFocus: AndroidAudioFocus.none,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playAndRecord,
          options: const {AVAudioSessionOptions.defaultToSpeaker, AVAudioSessionOptions.mixWithOthers},
        ),
      ),
    );
    return player;
  }

  @override
  Future<void> dispose() async => _player?.dispose();
}
