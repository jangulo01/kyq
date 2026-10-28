import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kyq_admin_web/radio/bulk_uploads_page.dart';
import 'package:kyq_admin_web/radio/radio_settings_page.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:mocktail/mocktail.dart';

// 011 (US10, FR-033, FR-034, FR-040): configuración de Radio y cargas masivas en el panel.

class _MockApi extends Mock implements KyqApiClient {}

RadioSettings _settings({int retention = 30, String policy = 'trial'}) => RadioSettings(
  trialPolicy: policy,
  trialDays: 14,
  passengersInChannels: 'none',
  retentionDays: retention,
  updatedAt: DateTime.utc(2026, 10, 1, 15),
  updatedByName: 'Laura',
  estimatedMonthlyCostMinor: const {'7': 1400, '30': 6000, '90': 18000},
);

final _upload = RadioBulkUpload(
  id: 'b1',
  fileName: 'flota.csv',
  status: 'validated',
  rowsTotal: 3,
  counts: const {'pending': 2, 'failed': 1},
  createdAt: DateTime.utc(2026, 10, 28),
);

RadioBulkUploadDetail _detail(RadioBulkUpload u, {String second = 'pending'}) => RadioBulkUploadDetail(
  upload: u,
  rows: [
    const RadioBulkRow(
      line: 2,
      name: 'Carlos',
      phoneMasked: '+57 310 *** **01',
      channel: 'Taxistas Norte',
      role: RadioRole.owner,
      status: 'pending',
    ),
    RadioBulkRow(line: 3, name: 'Luis', phoneMasked: '+57 300 *** **02', channel: 'Taxistas Norte', status: second),
    const RadioBulkRow(
      line: 4,
      name: 'X',
      phoneMasked: '***',
      channel: 'Taxistas Norte',
      status: 'failed',
      error: 'teléfono inválido',
    ),
  ],
);

void main() {
  late _MockApi api;

  setUp(() => api = _MockApi());

  void wide(WidgetTester tester) {
    tester.view.physicalSize = const Size(2400, 1800);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
  }

  testWidgets('configuración: políticas, costo por retención y nuevo aviso (FR-040)', (tester) async {
    wide(tester);
    when(() => api.radioSettings()).thenAnswer((_) async => _settings());
    when(
      () => api.updateRadioSettings(
        trialPolicy: any(named: 'trialPolicy'),
        trialDays: any(named: 'trialDays'),
        passengersInChannels: any(named: 'passengersInChannels'),
        retentionDays: any(named: 'retentionDays'),
      ),
    ).thenAnswer((_) async => _settings(retention: 90, policy: 'listen_only'));

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(create: (_) => RadioSettingsCubit(api)..load(), child: const RadioSettingsPage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Prueba gratis'), findsOneWidget);
    expect(find.text('7 días · \$1.400 al mes'), findsOneWidget);
    expect(find.text('90 días · \$18.000 al mes'), findsOneWidget);
    expect(find.textContaining('por Laura'), findsOneWidget);

    await tester.tap(find.byKey(const Key('radio.policy.listen_only')));
    await tester.tap(find.byKey(const Key('radio.retention.90')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('radio.trialDays')), findsNothing, reason: 'los días solo aplican a la prueba');
    await tester.tap(find.byKey(const Key('radio.settings.save')));
    await tester.pumpAndSettle();
    expect(find.textContaining('verán de nuevo el aviso de registro'), findsOneWidget);
    await tester.tap(find.byKey(const Key('radio.settings.confirm')));
    await tester.pumpAndSettle();
    verify(
      () => api.updateRadioSettings(
        trialPolicy: 'listen_only',
        trialDays: 14,
        passengersInChannels: 'none',
        retentionDays: 90,
      ),
    ).called(1);
    expect(find.text('Configuración guardada.'), findsOneWidget);
  });

  testWidgets('carga masiva: subir, ver errores, confirmar y reenviar fallidas (FR-033, FR-034)', (tester) async {
    wide(tester);
    var uploads = <RadioBulkUpload>[];
    when(() => api.radioBulkUploads()).thenAnswer((_) async => uploads);
    when(() => api.uploadRadioBulk('flota.csv', any())).thenAnswer((_) async {
      uploads = [_upload];
      return _detail(_upload);
    });
    var detail = _detail(_upload);
    when(() => api.radioBulkUpload('b1')).thenAnswer((_) async => detail);
    when(() => api.sendRadioBulk('b1', onlyFailed: any(named: 'onlyFailed'))).thenAnswer((_) async {
      final done = _upload.copyWith(status: 'done', counts: const {'sent': 1, 'already_member': 1, 'failed': 1});
      detail = _detail(done, second: 'sent');
    });

    final router = GoRouter(
      initialLocation: '/radio/bulk',
      routes: [
        GoRoute(
          path: '/radio/bulk',
          builder: (_, _) => BlocProvider(
            create: (_) => BulkUploadsCubit(api)..load(),
            child: BulkUploadsPage(pick: () async => (name: 'flota.csv', text: 'nombre,telefono\n')),
          ),
          routes: [
            GoRoute(
              path: ':id',
              builder: (_, state) => BlocProvider(
                create: (_) => BulkDetailCubit(api, state.pathParameters['id']!)..load(),
                child: const BulkDetailPage(),
              ),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    expect(find.text('Aún no hay cargas.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('radio.bulk.upload')));
    await tester.pumpAndSettle();
    expect(find.text('flota.csv'), findsOneWidget);
    expect(find.byKey(const Key('radio.bulk.errors')), findsOneWidget);
    expect(find.text('Fallida: teléfono inválido'), findsOneWidget);
    expect(find.text('+57 300 *** **02'), findsOneWidget, reason: 'sin el teléfono completo');
    verifyNever(() => api.sendRadioBulk(any(), onlyFailed: any(named: 'onlyFailed')));

    await tester.tap(find.byKey(const Key('radio.bulk.send')));
    await tester.pumpAndSettle();
    verify(() => api.sendRadioBulk('b1', onlyFailed: false)).called(1);
    expect(find.text('Enviada'), findsOneWidget);
    expect(find.byKey(const Key('radio.bulk.send')), findsNothing);

    await tester.tap(find.byKey(const Key('radio.bulk.resend')));
    await tester.pumpAndSettle();
    verify(() => api.sendRadioBulk('b1', onlyFailed: true)).called(1);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.textContaining('3 filas'), findsOneWidget);
  });
}
