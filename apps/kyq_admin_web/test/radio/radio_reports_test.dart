import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kyq_admin_web/radio/reports_page.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:mocktail/mocktail.dart';

// 011 (US11, FR-036/037): cola de reportes de Radio con el mensaje, su audio y la decisión.

class _MockApi extends Mock implements KyqApiClient {}

class _Player implements ReportPlayer {
  final played = <String>[];

  @override
  Future<void> play(String url) async => played.add(url);

  @override
  Future<void> stop() async {}
}

final _report = RadioReport(
  id: 'r1',
  messageKind: 'voice',
  conversationTitle: 'Taxistas Norte',
  reason: 'grito',
  createdAt: DateTime.utc(2026, 10, 28, 12),
);

void main() {
  testWidgets('cola, abrir con audio y resolver suspendiendo al autor', (tester) async {
    tester.view.physicalSize = const Size(2000, 1600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final api = _MockApi();
    var queue = [_report];
    when(() => api.radioReports()).thenAnswer((_) async => queue);
    when(() => api.radioReport('r1')).thenAnswer(
      (_) async => RadioReportDetail(
        report: _report,
        message: RadioMessage(
          id: 'm1',
          conversationId: 'c1',
          authorName: 'Jonathan',
          kind: RadioMessageKind.voice,
          durationMs: 2300,
          hasMedia: true,
          createdAt: DateTime.utc(2026, 10, 28, 11),
        ),
        mediaUrl: 'https://objects.test/m1.ogg',
        authorName: 'Jonathan',
      ),
    );
    when(() => api.resolveRadioReport('r1', any(), note: any(named: 'note'))).thenAnswer((_) async {
      queue = [];
    });
    final player = _Player();
    final router = GoRouter(
      initialLocation: '/radio/reports',
      routes: [
        GoRoute(
          path: '/radio/reports',
          builder: (_, _) =>
              BlocProvider(create: (_) => RadioReportsCubit(api)..load(), child: const RadioReportsPage()),
          routes: [
            GoRoute(
              path: ':id',
              builder: (_, state) => BlocProvider(
                create: (_) => RadioReportCubit(api, state.pathParameters['id']!)..load(),
                child: RadioReportPage(player: player),
              ),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    expect(find.text('Mensaje de voz · Taxistas Norte'), findsOneWidget);
    expect(find.textContaining('"grito"'), findsOneWidget);

    await tester.tap(find.byKey(const Key('radio.report.r1')));
    await tester.pumpAndSettle();
    verify(() => api.radioReport('r1')).called(1);
    expect(find.text('De Jonathan · 28/10/2026'), findsOneWidget);
    await tester.tap(find.byKey(const Key('radio.report.play')));
    await tester.pump();
    expect(player.played, ['https://objects.test/m1.ogg']);

    await tester.enterText(find.byKey(const Key('radio.report.note')), 'tercera vez');
    await tester.tap(find.byKey(const Key('radio.report.decide.user_suspended')));
    await tester.pumpAndSettle();
    verify(() => api.resolveRadioReport('r1', 'user_suspended', note: 'tercera vez')).called(1);
    expect(find.text('No hay reportes pendientes.'), findsOneWidget, reason: 'vuelve a la cola, ya vacía');
  });
}
