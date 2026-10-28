import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Aviso sonoro de alerta SOS nueva en la consola (FR-007). Las pruebas usan un falso.
abstract interface class AlertSound {
  Future<void> play();
}

/// [AlertSound] con `audioplayers`: tres pitidos agudos sintetizados (sin assets de terceros).
///
/// El navegador solo deja sonar audio tras una interacción del usuario con la página; el
/// operador ya interactuó al iniciar sesión.
class BeepAlertSound implements AlertSound {
  AudioPlayer? _player;
  Uint8List? _wav;

  @override
  Future<void> play() async {
    try {
      final player = _player ??= AudioPlayer();
      await player.stop();
      await player.play(BytesSource(_wav ??= alarmWav(), mimeType: 'audio/wav'));
    } on Object catch (e) {
      debugPrint('Aviso sonoro: $e');
    }
  }
}

/// WAV PCM de 16 bits mono: tres pitidos de 1 kHz de 180 ms.
Uint8List alarmWav({int sampleRate = 16000}) {
  final samples = <int>[];
  for (var beep = 0; beep < 3; beep++) {
    final n = sampleRate * 180 ~/ 1000;
    for (var i = 0; i < n; i++) {
      final edge = math.min(i, n - 1 - i);
      final gain = math.min(1, edge / (sampleRate * 0.005));
      samples.add((math.sin(2 * math.pi * 1000 * i / sampleRate) * 0.5 * gain * 32767).round());
    }
    samples.addAll(List.filled(sampleRate * 120 ~/ 1000, 0));
  }
  final b = ByteData(44 + samples.length * 2);
  void ascii(int offset, String s) {
    for (var i = 0; i < s.length; i++) {
      b.setUint8(offset + i, s.codeUnitAt(i));
    }
  }

  ascii(0, 'RIFF');
  b.setUint32(4, 36 + samples.length * 2, Endian.little);
  ascii(8, 'WAVE');
  ascii(12, 'fmt ');
  b.setUint32(16, 16, Endian.little);
  b.setUint16(20, 1, Endian.little);
  b.setUint16(22, 1, Endian.little);
  b.setUint32(24, sampleRate, Endian.little);
  b.setUint32(28, sampleRate * 2, Endian.little);
  b.setUint16(32, 2, Endian.little);
  b.setUint16(34, 16, Endian.little);
  ascii(36, 'data');
  b.setUint32(40, samples.length * 2, Endian.little);
  for (var i = 0; i < samples.length; i++) {
    b.setInt16(44 + i * 2, samples[i], Endian.little);
  }
  return b.buffer.asUint8List();
}
