import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_driver_app/app/app.dart';
import 'package:kyq_driver_app/notices/notices_cubit.dart';
import 'package:kyq_realtime/kyq_realtime.dart';
import 'package:kyq_ui/kyq_ui.dart';
import 'package:mocktail/mocktail.dart';

import '../support/fakes.dart';

const _session = Tokens(accessToken: 'a', refreshToken: 'r', role: UserRole.driver);

const _me = DriverMe(
  driverId: 'd1',
  qrToken: 'q3T9xZk2LmN8pR4sV7wY1a',
  presence: DriverPresence.offline,
  subscriptionStatus: SubscriptionStatus.active,
  canGoOnline: true,
);

final _at = DateTime.utc(2026, 10, 27, 12);

Notice _notice(String id, {String kind = 'doc_rejected', DateTime? readAt}) =>
    Notice(id: id, kind: kind, title: 'Aviso $id', body: 'Detalle $id', createdAt: _at, readAt: readAt);

NoticeCreated _event(String id, {String kind = 'doc_approved'}) =>
    NoticeCreated(_at, noticeId: id, kind: kind, title: 'Documento aprobado', body: 'Tu SOAT fue aprobado');

void main() {
  group('NoticesCubit', () {
    late MockApi api;
    late FakeEventSource events;

    setUp(() {
      api = MockApi();
      events = FakeEventSource();
      when(() => api.markNoticeRead(any())).thenAnswer((_) async {});
    });

    test('carga, cuenta los no leídos y marca leído', () async {
      when(() => api.driverNotices()).thenAnswer((_) async => [_notice('n1'), _notice('n2', readAt: _at)]);
      final cubit = NoticesCubit(api, events.controller.stream, now: () => _at);
      await cubit.load();
      expect(cubit.state.unread, 1);

      await cubit.markRead('n1');
      expect(cubit.state.unread, 0);
      verify(() => api.markNoticeRead('n1')).called(1);

      // Ya leído: no vuelve a llamar.
      await cubit.markRead('n1');
      verifyNever(() => api.markNoticeRead('n2'));
      await cubit.close();
    });

    test('notice.created llega en vivo, sin duplicar, y avisa a la app', () async {
      when(() => api.driverNotices()).thenAnswer((_) async => [_notice('n1')]);
      final received = <Notice>[];
      final cubit = NoticesCubit(api, events.controller.stream, onNotice: received.add);
      await cubit.load();

      events.push(_event('n2'));
      events.push(_event('n2'));
      events.push(DriverPresenceChanged(_at, driverId: 'd1', presence: 'free'));
      await pumpEventQueue();

      expect(cubit.state.notices.map((n) => n.id), ['n2', 'n1']);
      expect(cubit.state.unread, 2);
      expect(cubit.state.latest?.title, 'Documento aprobado');
      expect(received.single.kind, 'doc_approved');
      await cubit.close();
    });
  });

  testWidgets('insignia en el inicio, aviso en vivo y lista de avisos', (tester) async {
    final api = MockApi();
    final events = FakeEventSource();
    when(() => api.currentSession()).thenAnswer((_) async => _session);
    when(() => api.driverMe()).thenAnswer((_) async => _me);
    stubOnboardingDefaults(api, notices: [_notice('n1', kind: 'doc_rejected')]);
    when(() => api.markNoticeRead(any())).thenAnswer((_) async {});
    final auth = AuthCubit(api, allowedRoles: {UserRole.driver}, wrongRoleMessage: '')..start();
    await tester.pumpWidget(
      KyqDriverApp(
        api: api,
        auth: auth,
        services: fakeServices(events: events),
      ),
    );
    await tester.pumpAndSettle();

    Text badge() => tester.widget<Text>(find.byKey(const Key('home.notices.badge')));
    expect(badge().data, '1');

    events.push(_event('n2', kind: 'payment_approved'));
    await tester.pumpAndSettle();
    expect(badge().data, '2');
    // Se muestra al momento y la cuenta se recarga (un pago o documento cambia si puede trabajar).
    expect(find.text('Documento aprobado'), findsOneWidget);
    verify(() => api.driverMe()).called(greaterThanOrEqualTo(2));

    await tester.tap(find.byKey(const Key('home.notices')));
    await tester.pumpAndSettle();
    expect(find.text('Avisos'), findsOneWidget);
    expect(find.text('Aviso n1'), findsOneWidget);

    await tester.tap(find.text('Marcar leídos'));
    await tester.pumpAndSettle();
    verify(() => api.markNoticeRead('n1')).called(1);
    verify(() => api.markNoticeRead('n2')).called(1);
    expect(find.text('Marcar leídos'), findsNothing);
  });
}
