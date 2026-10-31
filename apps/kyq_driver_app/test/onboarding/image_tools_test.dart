import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:kyq_driver_app/onboarding/scan/image_tools.dart';

/// Tablero de ajedrez de casillas de [cell] px: bordes nítidos por todas partes.
img.Image _checkerboard(int w, int h, {int cell = 16}) {
  final image = img.Image(width: w, height: h);
  for (final p in image) {
    final v = ((p.x ~/ cell) + (p.y ~/ cell)).isEven ? 255 : 0;
    p.setRgb(v, v, v);
  }
  return image;
}

Uint8List _jpg(img.Image image) => img.encodeJpg(image, quality: 92);

void main() {
  group('nitidez (R4)', () {
    test('una foto nítida pasa el umbral y una desenfocada no', () {
      final sharp = _checkerboard(1024, 640);
      final blurry = img.gaussianBlur(_checkerboard(1024, 640), radius: 12);
      expect(sharpnessOf(_jpg(sharp)), greaterThan(minSharpness));
      expect(sharpnessOf(_jpg(blurry)), lessThan(minSharpness));
    });

    test('una imagen lisa no tiene bordes', () {
      final flat = img.Image(width: 200, height: 100)..clear(img.ColorRgb8(120, 120, 120));
      expect(sharpnessOf(_jpg(flat)), lessThan(1));
    });

    test('ilegible o diminuta: no se mide', () {
      expect(sharpnessOf(Uint8List.fromList([1, 2, 3])), isNull);
      expect(sharpnessOf(_jpg(img.Image(width: 2, height: 2))), isNull);
    });
  });

  group('recorte de cuatro esquinas (FR-013)', () {
    test('endereza el cuadrilátero al tamaño medio de sus lados', () {
      // Fondo blanco con un documento negro de 200 × 100 en (100, 50).
      final photo = img.Image(width: 400, height: 200)..clear(img.ColorRgb8(255, 255, 255));
      img.fillRect(photo, x1: 100, y1: 50, x2: 299, y2: 149, color: img.ColorRgb8(0, 0, 0));
      Offset at(double x, double y) => Offset(x / 399, y / 199);
      final out = rectifyJpeg(_jpg(photo), [at(104, 54), at(295, 54), at(295, 145), at(104, 145)]);
      expect(out, isNotNull);
      final doc = img.decodeJpg(out!)!;
      expect(doc.width, closeTo(191, 2));
      expect(doc.height, closeTo(91, 2));
      // Todo el recorte es el documento: sin fondo blanco.
      var bright = 0;
      for (final p in doc) {
        if (p.r > 128) bright++;
      }
      expect(bright / (doc.width * doc.height), lessThan(0.02));
    });

    test('esquinas fuera de la foto se ajustan al borde; foto ilegible da null', () {
      final photo = _jpg(_checkerboard(100, 80));
      final out = rectifyJpeg(photo, const [Offset(-1, -1), Offset(2, 0), Offset(1, 1), Offset(0, 1)]);
      expect(img.decodeJpg(out!)!.width, closeTo(100, 2));
      expect(rectifyJpeg(Uint8List.fromList([9]), defaultCorners), isNull);
    });
  });
}
