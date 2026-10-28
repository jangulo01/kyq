import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kyq_api/kyq_api.dart';

import 'photo_source.dart';

enum CapturePhase { editing, sending, done }

class DocumentCaptureState {
  const DocumentCaptureState({
    required this.docType,
    this.photos = const {},
    this.expiresAt,
    this.phase = CapturePhase.editing,
    this.progress,
    this.error,
  });

  final DocType docType;
  final Map<DocSide, Uint8List> photos;
  final DateTime? expiresAt;
  final CapturePhase phase;

  /// "Subiendo foto 1 de 2", mientras se envía.
  final String? progress;
  final String? error;

  bool get hasAllPhotos => docType.sides.every(photos.containsKey);

  DocumentCaptureState copyWith({
    Map<DocSide, Uint8List>? photos,
    DateTime? expiresAt,
    CapturePhase? phase,
    String? progress,
    String? error,
  }) => DocumentCaptureState(
    docType: docType,
    photos: photos ?? this.photos,
    expiresAt: expiresAt ?? this.expiresAt,
    phase: phase ?? this.phase,
    progress: progress,
    error: error,
  );
}

/// Captura y envío de un documento (T017): fotos comprimidas, número y vencimiento; luego
/// crea el envío, sube cada foto a su URL firmada y lo confirma. El documento no pasa a "en
/// revisión" hasta que todas sus fotos llegan; "Reintentar" sigue donde se quedó.
class DocumentCaptureCubit extends Cubit<DocumentCaptureState> {
  DocumentCaptureCubit({
    required this._api,
    required this._photos,
    required DocType docType,
    required this.onSubmitted,
    this.uploadBackoff = const Duration(seconds: 1),
  }) : super(DocumentCaptureState(docType: docType));

  final KyqApiClient _api;
  final PhotoSource _photos;

  /// Tras confirmar el envío (recarga el estado de alta).
  final Future<void> Function() onSubmitted;
  final Duration uploadBackoff;

  CreatedDocument? _created;
  final _uploaded = <DocSide>{};

  Future<void> pick(DocSide side, PhotoOrigin origin) async {
    try {
      final jpeg = await _photos.pick(origin);
      if (jpeg == null || isClosed) return;
      // Fotos nuevas: un envío a medio subir ya no sirve.
      _created = null;
      _uploaded.clear();
      emit(state.copyWith(photos: {...state.photos, side: jpeg}));
    } on PhotoTooLargeException {
      emit(state.copyWith(error: 'La foto es demasiado pesada. Tómala de nuevo con buena luz y sin zoom.'));
    } on Object {
      emit(state.copyWith(error: 'No pudimos abrir la cámara o la galería. Revisa los permisos de Kyq.'));
    }
  }

  void setExpiresAt(DateTime date) => emit(state.copyWith(expiresAt: date));

  Future<void> submit({required String number}) async {
    if (state.phase == CapturePhase.sending) return;
    final type = state.docType;
    if (!state.hasAllPhotos) {
      emit(state.copyWith(error: type.hasBack ? 'Falta la foto del frente o del reverso.' : 'Falta la foto.'));
      return;
    }
    if (number.trim().isEmpty) {
      emit(state.copyWith(error: 'Escribe el número del documento.'));
      return;
    }
    if (type.expires && state.expiresAt == null) {
      emit(state.copyWith(error: 'Indica la fecha de vencimiento.'));
      return;
    }
    emit(state.copyWith(phase: CapturePhase.sending, progress: 'Preparando el envío…'));
    try {
      final created = _created ??= await _api.createDocument(
        docType: type,
        number: number.trim(),
        expiresAt: type.expires ? state.expiresAt : null,
        sides: type.sides,
      );
      final pending = [
        for (final u in created.uploads)
          if (!_uploaded.contains(u.side)) u,
      ];
      for (final upload in pending) {
        final n = created.uploads.indexOf(upload) + 1;
        emit(state.copyWith(phase: CapturePhase.sending, progress: 'Subiendo foto $n de ${created.uploads.length}…'));
        await _api.uploadPhoto(upload.url, state.photos[upload.side]!, backoff: uploadBackoff);
        _uploaded.add(upload.side);
      }
      emit(state.copyWith(phase: CapturePhase.sending, progress: 'Enviando a revisión…'));
      await _api.submitDocument(created.document.id);
      await onSubmitted();
      if (!isClosed) emit(state.copyWith(phase: CapturePhase.done));
    } on ApiException catch (e) {
      // Una URL caducada o un envío que el backend ya no acepta: se empieza de nuevo al reintentar.
      if (e.code != 'network' && e.code != 'document_in_review') {
        _created = null;
        _uploaded.clear();
      }
      if (!isClosed) emit(state.copyWith(phase: CapturePhase.editing, error: _message(e)));
    }
  }

  static String _message(ApiException e) => switch (e.code) {
    'network' => 'Sin conexión. Tus fotos siguen aquí: toca Enviar para reintentar.',
    'upload_failed' => 'No pudimos subir las fotos. Toca Enviar para intentarlo de nuevo.',
    'photos_missing' => 'Alguna foto no llegó. Toca Enviar para subirlas de nuevo.',
    'photo_invalid' => 'Una foto no se pudo leer. Tómala otra vez y toca Enviar.',
    'vehicle_required' => 'Primero completa los datos de tu vehículo.',
    'document_in_review' => 'Ya enviaste este documento y está en revisión. Espera la respuesta.',
    'invalid_state' => 'Este envío ya no es válido. Toca Enviar para empezar de nuevo.',
    _ => e.message.isEmpty ? 'No pudimos enviar el documento. Inténtalo de nuevo.' : e.message,
  };
}
