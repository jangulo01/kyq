import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';

/// Tamaño máximo de una foto de documento tras comprimirla (la URL firmada admite 2 MB).
const maxPhotoBytes = 1024 * 1024;

enum PhotoOrigin { camera, gallery }

/// Toma o elige una foto y la devuelve como JPEG de [maxPhotoBytes] o menos. Las pruebas usan un
/// falso para no tocar la cámara.
abstract interface class PhotoSource {
  /// null si el conductor cancela.
  Future<Uint8List?> pick(PhotoOrigin origin);
}

/// Comprime a JPEG con [quality] de 0 a 100, reduciendo la foto hasta que su lado menor ronde
/// [side] píxeles (nunca la amplía).
typedef JpegCompressor = Future<Uint8List> Function(Uint8List input, {required int quality, required int side});

/// Baja calidad y luego resolución hasta que la foto quepa en [limit]. Un documento sigue siendo
/// legible a 1000 px y calidad 60; por debajo se prefiere avisar a mandar una foto inservible.
Future<Uint8List?> compressToLimit(Uint8List input, JpegCompressor compress, {int limit = maxPhotoBytes}) async {
  const steps = [(1600, 85), (1600, 75), (1280, 75), (1280, 65), (1000, 60)];
  for (final (side, quality) in steps) {
    final out = await compress(input, quality: quality, side: side);
    if (out.isNotEmpty && out.length <= limit) return out;
  }
  return null;
}

/// [PhotoSource] con image_picker y flutter_image_compress.
class PlatformPhotoSource implements PhotoSource {
  PlatformPhotoSource([ImagePicker? picker]) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<Uint8List?> pick(PhotoOrigin origin) async {
    final file = await _picker.pickImage(
      source: origin == PhotoOrigin.camera ? ImageSource.camera : ImageSource.gallery,
      // El recorte grueso lo hace el sistema; la compresión fina, abajo.
      maxWidth: 3000,
      maxHeight: 3000,
    );
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    final out = await compressToLimit(bytes, _compress);
    if (out == null) throw const PhotoTooLargeException();
    return out;
  }

  static Future<Uint8List> _compress(Uint8List input, {required int quality, required int side}) =>
      FlutterImageCompress.compressWithList(
        input,
        minWidth: side,
        minHeight: side,
        quality: quality,
        format: CompressFormat.jpeg,
        // Respeta la orientación de la cámara y quita los metadatos (ubicación incluida).
        autoCorrectionAngle: true,
        keepExif: false,
      );
}

/// La foto no bajó de [maxPhotoBytes] ni a la menor calidad aceptable.
class PhotoTooLargeException implements Exception {
  const PhotoTooLargeException();
}
