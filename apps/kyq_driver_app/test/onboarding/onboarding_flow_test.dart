import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_driver_app/app/app.dart';
import 'package:kyq_ui/kyq_ui.dart';
import 'package:mocktail/mocktail.dart';

import '../support/fakes.dart';

const _session = Tokens(accessToken: 'a', refreshToken: 'r', role: UserRole.driver);

DriverMe _me({bool canGoOnline = false, String? blockReason = 'kyc_expired'}) => DriverMe(
  driverId: 'd1',
  qrToken: 'q3T9xZk2LmN8pR4sV7wY1a',
  presence: DriverPresence.offline,
  subscriptionStatus: SubscriptionStatus.suspended,
  canGoOnline: canGoOnline,
  blockReason: blockReason,
);

const _vehicle = Vehicle(plate: 'ABC123', brand: 'Kia', model: 'Picanto', color: 'Gris', year: 2020);

KycDocument _doc(DocType type, DocumentStatus status, {String? reason, String id = 'old'}) => KycDocument(
  id: '$id-${type.name}',
  docType: type,
  status: status,
  rejectReason: reason,
  expiresAt: type.expires ? DateTime(2027, 6, 30) : null,
);

Onboarding _onboarding(OnboardingStatus status, {Map<DocType, OnboardingDocument> docs = const {}}) => Onboarding(
  status: status,
  vehicle: status == OnboardingStatus.profileIncomplete ? null : _vehicle,
  documents: [for (final t in DocType.values) docs[t] ?? OnboardingDocument(docType: t)],
);

class _Harness {
  final api = MockApi();
  final photos = FakePhotoSource();
  final onboardings = <Onboarding>[];

  Future<void> pump(WidgetTester tester, {DriverMe? me}) async {
    // Pantalla alta de teléfono: los formularios caben sin desplazarse.
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    when(() => api.currentSession()).thenAnswer((_) async => _session);
    when(() => api.driverMe()).thenAnswer((_) async => me ?? _me());
    when(() => api.driverNotices()).thenAnswer((_) async => []);
    // Cada carga devuelve el siguiente estado; el último se repite.
    when(
      () => api.driverOnboarding(),
    ).thenAnswer((_) async => onboardings.length > 1 ? onboardings.removeAt(0) : onboardings.single);
    final auth = AuthCubit(api, allowedRoles: {UserRole.driver}, wrongRoleMessage: '')..start();
    await tester.pumpWidget(
      KyqDriverApp(
        api: api,
        auth: auth,
        services: fakeServices(photos: photos),
      ),
    );
    await tester.pumpAndSettle();
  }
}

void main() {
  setUpAll(() {
    registerFallbackValue(DocType.license);
    registerFallbackValue(Uint8List(0));
    registerFallbackValue(Duration.zero);
  });

  testWidgets('sin vehículo lleva al formulario; al guardarlo pasa a los documentos', (tester) async {
    final h = _Harness()
      ..onboardings.addAll([
        _onboarding(OnboardingStatus.profileIncomplete),
        _onboarding(OnboardingStatus.documentsPending),
      ]);
    when(
      () => h.api.setVehicle(
        plate: any(named: 'plate'),
        brand: any(named: 'brand'),
        model: any(named: 'model'),
        color: any(named: 'color'),
        year: any(named: 'year'),
      ),
    ).thenAnswer((_) async {});
    await h.pump(tester);
    expect(find.text('Tu vehículo'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('vehicle.plate')), 'abc12');
    await tester.tap(find.byKey(const Key('vehicle.save')));
    await tester.pumpAndSettle();
    expect(find.text('Escribe la placa así: ABC123'), findsOneWidget);
    expect(find.text('Obligatorio'), findsNWidgets(3));

    await tester.enterText(find.byKey(const Key('vehicle.plate')), 'abc123');
    await tester.enterText(find.byKey(const Key('vehicle.brand')), 'Kia');
    await tester.enterText(find.byKey(const Key('vehicle.model')), 'Picanto');
    await tester.enterText(find.byKey(const Key('vehicle.color')), 'Gris');
    await tester.enterText(find.byKey(const Key('vehicle.year')), '2020');
    await tester.ensureVisible(find.byKey(const Key('vehicle.save')));
    await tester.tap(find.byKey(const Key('vehicle.save')));
    await tester.pumpAndSettle();

    verify(
      () => h.api.setVehicle(plate: 'ABC123', brand: 'Kia', model: 'Picanto', color: 'Gris', year: 2020),
    ).called(1);
    expect(find.text('Mis documentos'), findsOneWidget);
    expect(find.text('Envía tus documentos para poder conectarte.'), findsOneWidget);
    for (final label in ['Cédula', 'Licencia de conducción', 'SOAT', 'Revisión técnico-mecánica']) {
      expect(find.text(label), findsOneWidget);
    }
    await tester.scrollUntilVisible(find.text('Tarjeta de propiedad'), 100);
    expect(find.text('Tarjeta de propiedad'), findsOneWidget);
  });

  testWidgets('documento rechazado: ve el motivo y reenvía solo ese, con frente y reverso', (tester) async {
    final rejected = {
      DocType.license: OnboardingDocument(
        docType: DocType.license,
        latest: _doc(DocType.license, DocumentStatus.rejected, reason: 'Foto borrosa'),
      ),
      DocType.mandatoryInsurance: OnboardingDocument(
        docType: DocType.mandatoryInsurance,
        current: _doc(DocType.mandatoryInsurance, DocumentStatus.approved),
        latest: _doc(DocType.mandatoryInsurance, DocumentStatus.approved),
      ),
    };
    final h = _Harness()
      ..onboardings.addAll([
        _onboarding(OnboardingStatus.documentsPending, docs: rejected),
        _onboarding(
          OnboardingStatus.inReview,
          docs: {
            ...rejected,
            DocType.license: OnboardingDocument(
              docType: DocType.license,
              latest: _doc(DocType.license, DocumentStatus.submitted, id: 'new'),
            ),
          },
        ),
      ]);
    when(
      () => h.api.createDocument(
        docType: DocType.license,
        number: '1023456789',
        expiresAt: any(named: 'expiresAt'),
        sides: [DocSide.front, DocSide.back],
      ),
    ).thenAnswer(
      (_) async => const CreatedDocument(
        document: KycDocument(id: 'new-license', docType: DocType.license, status: DocumentStatus.uploading),
        uploads: [
          DocumentUpload(side: DocSide.front, url: 'https://s3.test/f'),
          DocumentUpload(side: DocSide.back, url: 'https://s3.test/b'),
        ],
      ),
    );
    when(() => h.api.uploadPhoto(any(), any(), backoff: any(named: 'backoff'))).thenAnswer((_) async {});
    when(() => h.api.submitDocument('new-license')).thenAnswer((_) async {});
    await h.pump(tester);

    expect(find.text('Mis documentos'), findsOneWidget);
    expect(find.textContaining('Motivo: Foto borrosa'), findsOneWidget);
    expect(find.textContaining('Vence el 30/06/2027'), findsOneWidget);

    // El SOAT aprobado y vigente no se puede reenviar todavía.
    await tester.tap(find.text('SOAT'));
    await tester.pumpAndSettle();
    expect(find.text('Mis documentos'), findsOneWidget);

    await tester.tap(find.text('Licencia de conducción'));
    await tester.pumpAndSettle();
    expect(find.text('Lo rechazamos la vez anterior'), findsOneWidget);
    expect(find.text('Frente'), findsOneWidget);
    expect(find.text('Reverso'), findsOneWidget);

    await tester.tap(find.byKey(const Key('capture.camera.front')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('capture.gallery.back')));
    await tester.tap(find.byKey(const Key('capture.gallery.back')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('capture.number')), '1023456789');
    await tester.ensureVisible(find.byKey(const Key('capture.expiry')));
    await tester.tap(find.byKey(const Key('capture.expiry')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('capture.submit')));
    await tester.tap(find.byKey(const Key('capture.submit')));
    await tester.pumpAndSettle();

    verify(() => h.api.uploadPhoto('https://s3.test/f', any(), backoff: any(named: 'backoff'))).called(1);
    verify(() => h.api.uploadPhoto('https://s3.test/b', any(), backoff: any(named: 'backoff'))).called(1);
    verify(() => h.api.submitDocument('new-license')).called(1);
    expect(find.text('Licencia de conducción enviado. Queda en revisión.'), findsOneWidget);
    expect(find.text('Mis documentos'), findsOneWidget);
    expect(find.text('En revisión: te avisaremos cuando un administrador apruebe tus documentos.'), findsOneWidget);
  });

  testWidgets('en revisión: el inicio lo explica y no deja ponerse ONLINE', (tester) async {
    final h = _Harness()..onboardings.add(_onboarding(OnboardingStatus.inReview));
    await h.pump(tester);

    expect(find.text('Documentos en revisión'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Text &&
            w.key == const Key('home.blocked') &&
            w.data == 'En revisión: te avisaremos cuando un administrador apruebe tus documentos.',
      ),
      findsOneWidget,
    );
    final toggle = tester.widget<SwitchListTile>(find.byKey(const Key('home.online')));
    expect(toggle.onChanged, isNull);
  });

  testWidgets('documento vencido: el interruptor nombra el documento (blocked_documents)', (tester) async {
    final h = _Harness()..onboardings.add(_onboarding(OnboardingStatus.documentsOk));
    await h.pump(
      tester,
      me: _me().copyWith(
        blockedDocuments: const [
          BlockedDocument(docType: DocType.mandatoryInsurance, problem: BlockedDocumentProblem.expired),
        ],
      ),
    );

    expect(find.text('SOAT vencido: envía el nuevo en "Mis documentos".'), findsWidgets);
  });

  testWidgets('documentos de 001 (legacy): siguen valiendo pero pide subirlos', (tester) async {
    final legacy = KycDocument(
      id: 'l',
      docType: DocType.license,
      status: DocumentStatus.approved,
      legacy: true,
      expiresAt: DateTime(2027, 6, 30),
    );
    final placeholder = KycDocument(
      id: 't',
      docType: DocType.technicalInspection,
      status: DocumentStatus.approved,
      legacy: true,
      exemptUntil: DateTime(2026, 12, 26),
    );
    final h = _Harness()
      ..onboardings.add(
        _onboarding(
          OnboardingStatus.documentsOk,
          docs: {
            DocType.license: OnboardingDocument(docType: DocType.license, current: legacy),
            DocType.technicalInspection: OnboardingDocument(
              docType: DocType.technicalInspection,
              current: placeholder,
              rejectedCount: 3,
              suggestSupport: true,
            ),
          },
        ),
      );
    await h.pump(tester, me: _me(canGoOnline: true, blockReason: null));
    await tester.tap(find.byKey(const Key('home.documents')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Sube tu documento'), findsNWidgets(2));
    expect(find.textContaining('súbelo para no perderlo'), findsNWidgets(2));
    expect(find.textContaining('No se exige hasta el 26/12/2026'), findsOneWidget);
    expect(find.textContaining('escríbenos a soporte'), findsOneWidget);

    // Se puede subir el real aunque el de 001 siga vigente.
    await tester.tap(find.text('Licencia de conducción'));
    await tester.pumpAndSettle();
    expect(find.text('Frente'), findsOneWidget);
  });

  testWidgets('suscripción sin pagar: lleva a Mi suscripción', (tester) async {
    final h = _Harness()..onboardings.add(_onboarding(OnboardingStatus.documentsOk));
    await h.pump(tester, me: _me(blockReason: 'subscription_suspended'));

    expect(find.text('Suscripción suspendida'), findsOneWidget);
    expect(find.textContaining('Paga tu mensualidad en "Mi suscripción"'), findsOneWidget);
  });
}
