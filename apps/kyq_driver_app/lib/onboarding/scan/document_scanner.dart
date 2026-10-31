import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart' as mlkit;

import 'image_tools.dart';

/// Escáner de documentos (010, US4): detecta los bordes, recorta y endereza. Las pruebas usan un
/// falso para no abrir la cámara.
abstract interface class DocumentScanner {
  /// JPEG del documento ya recortado; null si el conductor cancela. Lanza
  /// [ScannerUnavailableException] si el teléfono no puede escanear (sin Google Play Services):
  /// entonces se toma una foto normal y se recorta a mano.
  Future<Uint8List?> scan();

  /// Endereza las cuatro [corners] de [photo] (recorte manual).
  Future<Uint8List?> rectify(Uint8List photo, Corners corners);

  /// Nitidez de [photo] (ver [sharpnessOf]); null si no se puede medir.
  Future<double?> sharpness(Uint8List photo);
}

/// El escáner no está disponible en este teléfono.
class ScannerUnavailableException implements Exception {
  const ScannerUnavailableException();
}

/// [DocumentScanner] con ML Kit. Recortar y medir corren en otro isolate para no congelar la UI.
class MlKitDocumentScanner implements DocumentScanner {
  const MlKitDocumentScanner();

  @override
  Future<Uint8List?> scan() async {
    final scanner = mlkit.DocumentScanner(
      options: mlkit.DocumentScannerOptions(
        documentFormats: const {mlkit.DocumentFormat.jpeg},
        pageLimit: 1,
        mode: mlkit.ScannerMode.base,
      ),
    );
    try {
      final result = await scanner.scanDocument();
      final path = result.images?.firstOrNull;
      if (path == null) return null;
      final file = File(path);
      final bytes = await file.readAsBytes();
      await file.delete().catchError((_) => file);
      return bytes;
    } on PlatformException catch (e) {
      // El conductor cerró el escáner: no es un error.
      if (e.message?.toLowerCase().contains('cancel') ?? false) return null;
      throw const ScannerUnavailableException();
    } on MissingPluginException {
      throw const ScannerUnavailableException();
    } finally {
      await scanner.close().catchError((_) {});
    }
  }

  @override
  Future<Uint8List?> rectify(Uint8List photo, Corners corners) =>
      compute((args) => rectifyJpeg(args.$1, args.$2), (photo, corners));

  @override
  Future<double?> sharpness(Uint8List photo) => compute(sharpnessOf, photo);
}
