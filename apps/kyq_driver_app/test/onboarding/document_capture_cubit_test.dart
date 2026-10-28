import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_driver_app/onboarding/document_capture_cubit.dart';
import 'package:kyq_driver_app/onboarding/photo_source.dart';
import 'package:mocktail/mocktail.dart';

import '../support/fakes.dart';

KycDocument _doc(DocType type, {DocumentStatus status = DocumentStatus.uploading}) =>
    KycDocument(id: 'doc1', docType: type, status: status);

CreatedDocument _created(DocType type) => CreatedDocument(
  document: _doc(type),
  uploads: [for (final s in type.sides) DocumentUpload(side: s, url: 'https://s3.test/${s.name}?X-Amz-Signature=1')],
);

void main() {
  late MockApi api;
  late FakePhotoSource photos;
  late int submitted;

  setUpAll(() {
    registerFallbackValue(DocType.license);
    registerFallbackValue(Uint8List(0));
    registerFallbackValue(Duration.zero);
  });

  setUp(() {
    api = MockApi();
    photos = FakePhotoSource();
    submitted = 0;
    when(() => api.submitDocument(any())).thenAnswer((_) async {});
    when(() => api.uploadPhoto(any(), any(), backoff: any(named: 'backoff'))).thenAnswer((_) async {});
  });

  DocumentCaptureCubit cubit(DocType type) => DocumentCaptureCubit(
    api: api,
    photos: photos,
    docType: type,
    onSubmitted: () async => submitted++,
    uploadBackoff: Duration.zero,
  );

  void stubCreate(DocType type) => when(
    () => api.createDocument(
      docType: type,
      number: any(named: 'number'),
      expiresAt: any(named: 'expiresAt'),
      sides: any(named: 'sides'),
    ),
  ).thenAnswer((_) async => _created(type));

  test('licencia: frente, reverso, número y vencimiento; sube cada foto y confirma', () async {
    stubCreate(DocType.license);
    final c = cubit(DocType.license);
    final front = Uint8List.fromList([1]);
    final back = Uint8List.fromList([2]);
    photos.next = front;
    await c.pick(DocSide.front, PhotoOrigin.camera);
    photos.next = back;
    await c.pick(DocSide.back, PhotoOrigin.gallery);
    c.setExpiresAt(DateTime(2030, 1, 31));
    await c.submit(number: ' 1023 ');

    expect(photos.origins, [PhotoOrigin.camera, PhotoOrigin.gallery]);
    verify(
      () => api.createDocument(
        docType: DocType.license,
        number: '1023',
        expiresAt: DateTime(2030, 1, 31),
        sides: [DocSide.front, DocSide.back],
      ),
    ).called(1);
    verify(() => api.uploadPhoto('https://s3.test/front?X-Amz-Signature=1', front, backoff: Duration.zero)).called(1);
    verify(() => api.uploadPhoto('https://s3.test/back?X-Amz-Signature=1', back, backoff: Duration.zero)).called(1);
    verify(() => api.submitDocument('doc1')).called(1);
    expect(submitted, 1);
    expect(c.state.phase, CapturePhase.done);
  });

  test('cédula: no pide vencimiento y no lo envía', () async {
    stubCreate(DocType.nationalId);
    final c = cubit(DocType.nationalId);
    await c.pick(DocSide.front, PhotoOrigin.camera);
    await c.pick(DocSide.back, PhotoOrigin.camera);
    await c.submit(number: '1023456789');

    verify(
      () => api.createDocument(
        docType: DocType.nationalId,
        number: '1023456789',
        expiresAt: null,
        sides: [DocSide.front, DocSide.back],
      ),
    ).called(1);
    expect(c.state.phase, CapturePhase.done);
  });

  test('valida fotos, número y vencimiento antes de crear nada', () async {
    final c = cubit(DocType.license);
    await c.submit(number: '1');
    expect(c.state.error, 'Falta la foto del frente o del reverso.');

    await c.pick(DocSide.front, PhotoOrigin.camera);
    await c.pick(DocSide.back, PhotoOrigin.camera);
    await c.submit(number: '  ');
    expect(c.state.error, 'Escribe el número del documento.');

    await c.submit(number: '123');
    expect(c.state.error, 'Indica la fecha de vencimiento.');
    verifyNever(
      () => api.createDocument(
        docType: any(named: 'docType'),
        number: any(named: 'number'),
        expiresAt: any(named: 'expiresAt'),
        sides: any(named: 'sides'),
      ),
    );
  });

  test('sin red a mitad: reintentar sube solo la foto que faltó y no crea otro envío', () async {
    stubCreate(DocType.license);
    final c = cubit(DocType.license);
    await c.pick(DocSide.front, PhotoOrigin.camera);
    await c.pick(DocSide.back, PhotoOrigin.camera);
    c.setExpiresAt(DateTime(2030));
    var backFails = true;
    when(
      () => api.uploadPhoto('https://s3.test/back?X-Amz-Signature=1', any(), backoff: any(named: 'backoff')),
    ).thenAnswer((_) async {
      if (backFails) throw const ApiException(null, 'network', 'sin red');
    });

    await c.submit(number: '123');
    expect(c.state.phase, CapturePhase.editing);
    expect(c.state.error, contains('Sin conexión'));
    verifyNever(() => api.submitDocument(any()));

    backFails = false;
    await c.submit(number: '123');
    expect(c.state.phase, CapturePhase.done);
    verify(
      () => api.createDocument(
        docType: DocType.license,
        number: any(named: 'number'),
        expiresAt: any(named: 'expiresAt'),
        sides: any(named: 'sides'),
      ),
    ).called(1);
    verify(
      () => api.uploadPhoto('https://s3.test/front?X-Amz-Signature=1', any(), backoff: any(named: 'backoff')),
    ).called(1);
    verify(
      () => api.uploadPhoto('https://s3.test/back?X-Amz-Signature=1', any(), backoff: any(named: 'backoff')),
    ).called(2);
  });

  test('URL caducada (4xx): reintentar empieza un envío nuevo', () async {
    stubCreate(DocType.mandatoryInsurance);
    final c = cubit(DocType.mandatoryInsurance);
    await c.pick(DocSide.front, PhotoOrigin.camera);
    c.setExpiresAt(DateTime(2030));
    var fail = true;
    when(() => api.uploadPhoto(any(), any(), backoff: any(named: 'backoff'))).thenAnswer((_) async {
      if (fail) throw const ApiException(403, 'upload_failed', 'caducada');
    });

    await c.submit(number: 'AT-1');
    expect(c.state.error, contains('No pudimos subir las fotos'));
    fail = false;
    await c.submit(number: 'AT-1');

    expect(c.state.phase, CapturePhase.done);
    verify(
      () => api.createDocument(
        docType: DocType.mandatoryInsurance,
        number: any(named: 'number'),
        expiresAt: any(named: 'expiresAt'),
        sides: [DocSide.front],
      ),
    ).called(2);
  });

  test('foto demasiado pesada o cámara sin permiso: mensaje claro', () async {
    final c = cubit(DocType.mandatoryInsurance);
    photos.error = const PhotoTooLargeException();
    await c.pick(DocSide.front, PhotoOrigin.camera);
    expect(c.state.error, contains('demasiado pesada'));

    photos.error = Exception('sin permiso');
    await c.pick(DocSide.front, PhotoOrigin.camera);
    expect(c.state.error, contains('permisos'));
    expect(c.state.photos, isEmpty);
  });

  group('compressToLimit', () {
    test('baja calidad y tamaño hasta caber en el límite', () async {
      final calls = <(int, int)>[];
      Future<Uint8List> fake(Uint8List input, {required int quality, required int side}) async {
        calls.add((side, quality));
        return Uint8List(side == 1280 && quality == 75 ? 900 : 2000);
      }

      final out = await compressToLimit(Uint8List(5000), fake, limit: 1000);
      expect(out, hasLength(900));
      expect(calls, [(1600, 85), (1600, 75), (1280, 75)]);
    });

    test('null si ni la menor calidad cabe', () async {
      Future<Uint8List> fake(Uint8List input, {required int quality, required int side}) async => Uint8List(2000);
      expect(await compressToLimit(Uint8List(5000), fake, limit: 1000), isNull);
    });
  });
}
