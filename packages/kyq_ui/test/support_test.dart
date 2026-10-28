import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_ui/kyq_ui.dart';
import 'package:mocktail/mocktail.dart';

// 009: centro de soporte en las apps y sesión de solo soporte de una cuenta suspendida.

class _MockApi extends Mock implements KyqApiClient {}

const _support = Tokens(accessToken: 'a', refreshToken: 'r', role: UserRole.passenger, scope: 'support');

SupportCase _case({SupportStatus status = SupportStatus.waitingUser}) => SupportCase(
  id: 'c1',
  topic: SupportTopic.lostItem,
  subject: 'Dejé mi sombrilla',
  status: status,
  user: const PersonRef(id: 'p1', displayName: 'Ana'),
  userRole: 'passenger',
  createdAt: DateTime.utc(2026, 10, 28, 12),
  lastMessageAt: DateTime.utc(2026, 10, 28, 12, 5),
);

SupportCaseDetail _detail({SupportStatus status = SupportStatus.waitingUser}) => SupportCaseDetail(
  supportCase: _case(status: status),
  messages: [
    SupportMessage(
      id: 'm1',
      authorKind: SupportAuthor.user,
      mine: true,
      body: 'Dejé mi sombrilla roja',
      createdAt: DateTime.utc(2026, 10, 28, 12),
    ),
    SupportMessage(
      id: 'm2',
      authorKind: SupportAuthor.admin,
      authorName: 'Admin',
      body: 'La tiene tu conductor',
      createdAt: DateTime.utc(2026, 10, 28, 12, 5),
    ),
  ],
);

void main() {
  late _MockApi api;

  setUpAll(() => registerFallbackValue(SupportTopic.other));

  setUp(() {
    api = _MockApi();
    when(() => api.logout()).thenAnswer((_) async {});
  });

  group('cuenta suspendida (FR-011)', () {
    test('la sesión guardada de solo soporte abre el modo suspendido', () async {
      when(() => api.currentSession()).thenAnswer((_) async => _support);
      final cubit = AuthCubit(api, allowedRoles: {UserRole.passenger}, wrongRoleMessage: 'x');
      await cubit.start();
      expect(cubit.state, isA<AuthSupportOnly>());
    });

    test('suspendida con la sesión abierta pasa a solo soporte', () async {
      when(() => api.currentSession()).thenAnswer((_) async => _support);
      final cubit = AuthCubit(api, allowedRoles: {UserRole.passenger}, wrongRoleMessage: 'x');
      await cubit.supportOnly();
      expect(cubit.state, isA<AuthSupportOnly>());
    });

    testWidgets('el router solo deja ver Ayuda', (tester) async {
      when(() => api.currentSession()).thenAnswer((_) async => _support);
      when(() => api.supportCases()).thenAnswer((_) async => [_case()]);
      final auth = AuthCubit(api, allowedRoles: {UserRole.passenger}, wrongRoleMessage: 'x');
      await auth.start();
      final router = buildAuthRouter(
        auth: auth,
        title: 'Kyq Pasajero',
        withSupport: true,
        routes: [GoRoute(path: '/', builder: (_, _) => const Text('Inicio'))],
      );
      await tester.pumpWidget(
        RepositoryProvider<KyqApiClient>.value(
          value: api,
          child: BlocProvider.value(
            value: auth,
            child: MaterialApp.router(routerConfig: router),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Inicio'), findsNothing);
      expect(find.byKey(const Key('support.suspended')), findsOneWidget);
      expect(find.text('Dejé mi sombrilla'), findsOneWidget);
      router.go('/');
      await tester.pumpAndSettle();
      expect(find.text('Inicio'), findsNothing, reason: 'vuelve a Ayuda');
    });
  });

  blocTest<NewCaseCubit, NewCaseState>(
    'nuevo caso con tema, viaje y descripción (FR-005)',
    setUp: () {
      when(() => api.supportTrips()).thenAnswer(
        (_) async => [
          SupportTripRef(id: 't1', status: 'COMPLETED', createdAt: DateTime.utc(2026, 10, 27), otherParty: 'Carlos'),
        ],
      );
      when(
        () => api.openSupportCase(SupportTopic.lostItem, 'Dejé mi sombrilla roja', tripId: 't1'),
      ).thenAnswer((_) async => _detail());
    },
    build: () => NewCaseCubit(api),
    act: (c) async {
      await c.loadTrips();
      c
        ..setTopic(SupportTopic.lostItem)
        ..setTrip('t1');
      await c.submit('corto');
      expect(c.state.error, isNotNull, reason: 'al menos 10 caracteres');
      await c.submit('  Dejé mi sombrilla roja ');
    },
    verify: (c) => expect(c.state.createdId, 'c1'),
  );

  blocTest<SupportCaseCubit, SupportCaseState>(
    'un caso cerrado no admite respuesta y se recarga',
    setUp: () {
      when(() => api.supportCase('c1')).thenAnswer((_) async => _detail(status: SupportStatus.closed));
      when(() => api.replySupportCase('c1', any())).thenThrow(const ApiException(409, 'case_closed', ''));
    },
    build: () => SupportCaseCubit(api, 'c1'),
    act: (c) async => expect(await c.reply('Hola'), isFalse),
    verify: (c) {
      expect(c.state.closed, isTrue);
      expect(c.state.error, contains('cerrado'));
    },
  );

  testWidgets('conversación: responder y ver la respuesta del soporte', (tester) async {
    when(() => api.supportCase('c1')).thenAnswer((_) async => _detail());
    when(() => api.replySupportCase('c1', 'Gracias')).thenAnswer((_) async => _detail(status: SupportStatus.open));
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(create: (_) => SupportCaseCubit(api, 'c1')..load(), child: const SupportCasePage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Soporte Kyq'), findsOneWidget);
    expect(find.text('Esperando tu respuesta'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('support.reply')), 'Gracias');
    await tester.tap(find.byKey(const Key('support.send')));
    await tester.pumpAndSettle();
    expect(find.text('Abierto'), findsOneWidget);
    verify(() => api.replySupportCase('c1', 'Gracias')).called(1);
  });
}
