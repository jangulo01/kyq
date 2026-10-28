import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show Offset;

import 'package:image/image.dart' as img;

/// Por debajo de esta nitidez la foto "parece borrosa" (010, R4).
const minSharpness = 60.0;

/// Ancho al que se reduce la foto para medir la nitidez: igual para todas las cámaras.
const _sharpnessWidth = 512;

/// Lado máximo del documento enderezado: de sobra para leerlo y luego se comprime.
const _maxRectifiedSide = 2000;

/// Nitidez de una foto: varianza del laplaciano sobre la imagen en gris a 512 px de ancho. Una
/// foto movida o desenfocada tiene bordes suaves y da un valor bajo. null si no se puede leer o
/// es demasiado pequeña para medirla.
double? sharpnessOf(Uint8List bytes) {
  var image = img.decodeImage(bytes);
  if (image == null) return null;
  if (image.width > _sharpnessWidth) {
    image = img.copyResize(image, width: _sharpnessWidth, interpolation: img.Interpolation.average);
  }
  final w = image.width, h = image.height;
  if (w < 3 || h < 3) return null;
  final gray = Float64List(w * h);
  for (final p in image) {
    gray[p.y * w + p.x] = img.getLuminanceRgb(p.rNormalized, p.gNormalized, p.bNormalized) * 255;
  }
  var sum = 0.0, sumSq = 0.0;
  for (var y = 1; y < h - 1; y++) {
    for (var x = 1; x < w - 1; x++) {
      final i = y * w + x;
      final lap = gray[i - 1] + gray[i + 1] + gray[i - w] + gray[i + w] - 4 * gray[i];
      sum += lap;
      sumSq += lap * lap;
    }
  }
  final n = (w - 2) * (h - 2);
  final mean = sum / n;
  return sumSq / n - mean * mean;
}

/// Las cuatro esquinas del documento, de 0 a 1 sobre el ancho y el alto de la foto, en el orden
/// arriba-izquierda, arriba-derecha, abajo-derecha, abajo-izquierda.
typedef Corners = List<Offset>;

/// Esquinas iniciales del recorte manual: un margen del 8 % por lado.
const Corners defaultCorners = [Offset(0.08, 0.08), Offset(0.92, 0.08), Offset(0.92, 0.92), Offset(0.08, 0.92)];

/// Endereza el cuadrilátero [corners] de la foto a un rectángulo (perspectiva aproximada) y lo
/// devuelve como JPEG. El tamaño sale de la media de los lados opuestos. null si no se puede leer.
Uint8List? rectifyJpeg(Uint8List bytes, Corners corners) {
  final src = img.decodeImage(bytes);
  if (src == null || corners.length != 4) return null;
  final pts = [
    for (final c in corners) img.Point(c.dx.clamp(0, 1) * (src.width - 1), c.dy.clamp(0, 1) * (src.height - 1)),
  ];
  double len(img.Point a, img.Point b) => math.sqrt(math.pow(a.x - b.x, 2) + math.pow(a.y - b.y, 2));
  var width = (len(pts[0], pts[1]) + len(pts[3], pts[2])) / 2;
  var height = (len(pts[0], pts[3]) + len(pts[1], pts[2])) / 2;
  final scale = math.min(1.0, _maxRectifiedSide / math.max(width, height));
  width = math.max(2, width * scale);
  height = math.max(2, height * scale);
  final out = img.copyRectify(
    src,
    topLeft: pts[0],
    topRight: pts[1],
    bottomRight: pts[2],
    bottomLeft: pts[3],
    interpolation: img.Interpolation.linear,
    toImage: img.Image(width: width.round(), height: height.round(), numChannels: src.numChannels),
  );
  return img.encodeJpg(out, quality: 90);
}
