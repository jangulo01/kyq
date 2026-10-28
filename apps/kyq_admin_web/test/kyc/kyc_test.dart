import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kyq_admin_web/kyc/kyc_cubits.dart';
import 'package:kyq_admin_web/kyc/kyc_driver_page.dart';
import 'package:kyq_admin_web/kyc/kyc_queue_page.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:mocktail/mocktail.dart';

class _MockApi extends Mock implements KyqApiClient {}

KycDocument _doc(
  String id,
  DocType type,
  DocumentStatus status, {
  String number = '123',
  DateTime? expiresAt,
  String? reason,
  List<DocumentPhoto> photos = const [],
}) => KycDocument(
  id: id,
  docType: type,
  number: number,
  expiresAt: expiresAt,
  status: status,
  rejectReason: reason,
  submittedAt: DateTime.utc(2026, 10, 26),
  photos: photos,
);

KycDriverFile _file(List<KycDocument> docs) => KycDriverFile(
  driverId: 'd1',
  displayName: 'Carlos',
  phoneE164: '+573001112233',
  vehicle: const Vehicle(plate: 'ABC123', brand: 'Kia', model: 'Picanto', color: 'Gris', year: 2020),
  // Como el backend: por tipo, el aprobado (`current`) y el envío más reciente (`latest`).
  documents: [
    for (final t in DocType.values)
      if (docs.any((d) => d.docType == t))
        OnboardingDocument(
          docType: t,
          current: docs.where((d) => d.docType == t && d.status == DocumentStatus.approved).firstOrNull,
          latest: docs.where((d) => d.docType == t && d.status != DocumentStatus.approved).firstOrNull,
        ),
  ],
);

Future<void> _pumpFile(WidgetTester tester, _MockApi api) async {
  tester.view.physicalSize = const Size(2400, 3000);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider(create: (_) => KycDriverCubit(api, 'd1')..load(), child: const KycDriverPage()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  late _MockApi api;

  setUp(() => api = _MockApi());

  testWidgets('la cola va del envío más antiguo al más reciente con lo pendiente de cada uno', (tester) async {
    when(() => api.adminKycQueue()).thenAnswer(
      (_) async => [
        KycQueueEntry(
          driverId: 'd2',
          displayName: 'Beto',
          pendingCount: 1,
          oldestSubmittedAt: DateTime.utc(2026, 10, 26, 15),
        ),
        KycQueueEntry(
          driverId: 'd1',
          displayName: 'Ana',
          vehiclePlate: 'ABC123',
          pendingCount: 5,
          oldestSubmittedAt: DateTime.utc(2026, 10, 20, 15),
        ),
        KycQueueEntry(
          driverId: 'd3',
          displayName: 'Ceci',
          pendingCount: 2,
          oldestSubmittedAt: DateTime.utc(2026, 10, 27, 15),
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(create: (_) => KycQueueCubit(api)..load(), child: const KycQueuePage()),
      ),
    );
    await tester.pumpAndSettle();

    final names = tester.widgetList<ListTile>(find.byType(ListTile)).map((t) => (t.title! as Text).data).toList();
    expect(names, ['Ana · ABC123', 'Beto', 'Ceci']);
    expect(find.textContaining('5 documentos por revisar · enviado el 20/10/2026'), findsOneWidget);
    expect(find.textContaining('1 documento por revisar'), findsOneWidget);
  });

  testWidgets('expediente: fotos ampliables y aprobar con correcciones', (tester) async {
    final soat = _doc(
      's1',
      DocType.mandatoryInsurance,
      DocumentStatus.submitted,
      number: 'AT-1',
      expiresAt: DateTime(2027, 6, 30),
      photos: const [DocumentPhoto(side: DocSide.front, url: 'https://s3.test/soat.jpg?X-Amz-Signature=1')],
    );
    when(() => api.adminKycDriver('d1')).thenAnswer(
      (_) async => _file([
        soat,
        _doc('s0', DocType.mandatoryInsurance, DocumentStatus.approved, expiresAt: DateTime(2026, 11, 10)),
      ]),
    );
    when(
      () => api.adminReviewDocument(
        any(),
        approve: any(named: 'approve'),
        reason: any(named: 'reason'),
        number: any(named: 'number'),
        expiresAt: any(named: 'expiresAt'),
        exemptUntil: any(named: 'exemptUntil'),
      ),
    ).thenAnswer((_) async {});
    await _pumpFile(tester, api);

    expect(find.text('Expediente de Carlos'), findsOneWidget);
    expect(find.text('ABC123 · Kia · Picanto · Gris · 2020'), findsOneWidget);
    expect(find.text('En revisión'), findsOneWidget);
    expect(find.text('Aprobado'), findsOneWidget);
    expect(find.textContaining('Número: AT-1'), findsOneWidget);
    expect(find.text('No ha enviado este documento.'), findsNWidgets(4));

    // La foto (URL firmada) se abre en grande con zoom; sin red se ve el aviso, no un error.
    await tester.tap(find.byKey(const Key('kyc.photo.front')));
    await tester.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(find.text('SOAT · Frente'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('kyc.approve.s1')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('approve.number')), 'AT-2');
    await tester.tap(find.byKey(const Key('approve.confirm')));
    await tester.pumpAndSettle();

    verify(
      () => api.adminReviewDocument('s1', approve: true, number: 'AT-2', expiresAt: null, exemptUntil: null),
    ).called(1);
    verify(() => api.adminKycDriver('d1')).called(2);
  });

  testWidgets('documentos de 001 sin fotos, bloqueos y sugerencia de soporte', (tester) async {
    when(() => api.adminKycDriver('d1')).thenAnswer(
      (_) async => KycDriverFile(
        driverId: 'd1',
        displayName: 'Carlos',
        documents: [
          OnboardingDocument(
            docType: DocType.license,
            label: 'Licencia de conducción',
            current: KycDocument(
              id: 'l0',
              docType: DocType.license,
              status: DocumentStatus.approved,
              legacy: true,
              expiresAt: DateTime(2027),
            ),
            rejectedCount: 3,
            suggestSupport: true,
          ),
        ],
        blockedDocuments: const [BlockedDocument(docType: DocType.nationalId, problem: BlockedDocumentProblem.missing)],
      ),
    );
    await _pumpFile(tester, api);

    expect(find.text('Aprobado · de 001, sin fotos'), findsOneWidget);
    expect(find.text('Rechazado 3 veces: conviene llamar al conductor.'), findsOneWidget);
    expect(find.text('No puede trabajar: Cédula sin aprobar.'), findsOneWidget);
  });

  testWidgets('rechazar exige un motivo: predefinido o escrito', (tester) async {
    when(() => api.adminKycDriver('d1')).thenAnswer(
      (_) async => _file([_doc('l1', DocType.license, DocumentStatus.submitted, expiresAt: DateTime(2030))]),
    );
    when(() => api.adminReviewDocument(any(), approve: false, reason: any(named: 'reason'))).thenAnswer((_) async {});
    await _pumpFile(tester, api);

    await tester.tap(find.byKey(const Key('kyc.reject.l1')));
    await tester.pumpAndSettle();
    final confirm = find.byKey(const Key('reject.confirm'));
    expect(tester.widget<FilledButton>(confirm).onPressed, isNull);

    await tester.tap(find.text('Foto borrosa o ilegible'));
    await tester.pumpAndSettle();
    await tester.tap(confirm);
    await tester.pumpAndSettle();
    verify(() => api.adminReviewDocument('l1', approve: false, reason: 'Foto borrosa o ilegible')).called(1);

    await tester.tap(find.byKey(const Key('kyc.reject.l1')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('reject.other')), 'La placa no coincide');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('reject.confirm')));
    await tester.pumpAndSettle();
    verify(() => api.adminReviewDocument('l1', approve: false, reason: 'La placa no coincide')).called(1);
  });

  testWidgets('revisión técnico-mecánica de vehículo nuevo: "no aplica hasta"', (tester) async {
    when(
      () => api.adminKycDriver('d1'),
    ).thenAnswer((_) async => _file([_doc('t1', DocType.technicalInspection, DocumentStatus.submitted)]));
    when(
      () => api.adminReviewDocument(
        any(),
        approve: true,
        number: any(named: 'number'),
        expiresAt: any(named: 'expiresAt'),
        exemptUntil: any(named: 'exemptUntil'),
      ),
    ).thenAnswer((_) async {});
    await _pumpFile(tester, api);

    await tester.tap(find.byKey(const Key('kyc.approve.t1')));
    await tester.pumpAndSettle();
    // Sin vencimiento ni exención no se puede aprobar.
    expect(tester.widget<FilledButton>(find.byKey(const Key('approve.confirm'))).onPressed, isNull);
    await tester.tap(find.byKey(const Key('approve.exempt')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('approve.confirm')));
    await tester.pumpAndSettle();

    final captured = verify(
      () => api.adminReviewDocument(
        't1',
        approve: true,
        number: null,
        expiresAt: null,
        exemptUntil: captureAny(named: 'exemptUntil'),
      ),
    ).captured;
    expect(captured.single, isA<DateTime>());
  });

  test('aprobar solo envía lo que cambia', () async {
    when(() => api.adminKycDriver('d1')).thenAnswer((_) async => _file(const []));
    when(
      () => api.adminReviewDocument(
        any(),
        approve: true,
        number: any(named: 'number'),
        expiresAt: any(named: 'expiresAt'),
        exemptUntil: any(named: 'exemptUntil'),
      ),
    ).thenAnswer((_) async {});
    final cubit = KycDriverCubit(api, 'd1');
    final doc = _doc('x', DocType.license, DocumentStatus.submitted, number: '9', expiresAt: DateTime(2030, 5, 1));

    await cubit.approve(doc, number: '9', expiresAt: DateTime(2030, 5, 1, 12));
    verify(
      () => api.adminReviewDocument('x', approve: true, number: null, expiresAt: null, exemptUntil: null),
    ).called(1);

    await cubit.approve(doc, number: '10', expiresAt: DateTime(2031));
    verify(
      () => api.adminReviewDocument('x', approve: true, number: '10', expiresAt: DateTime(2031), exemptUntil: null),
    ).called(1);
  });
}
