import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kyq_admin_web/support/support_admin_cubits.dart';
import 'package:kyq_admin_web/support/support_admin_pages.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:mocktail/mocktail.dart';

// 009 (US2): bandeja y caso de soporte en el panel, con notas internas y el pago de 004.

class _MockApi extends Mock implements KyqApiClient {}

SupportCase _case({SupportStatus status = SupportStatus.open, bool payment = false, PersonRef? assigned}) =>
    SupportCase(
      id: 'c1',
      topic: payment ? SupportTopic.payment : SupportTopic.lostItem,
      subject: payment ? 'Pago del viaje: efectivo no recibido' : 'Dejé mi sombrilla',
      status: status,
      user: PersonRef(id: payment ? 'd1' : 'p1', displayName: payment ? 'Carlos' : 'Ana'),
      userRole: payment ? 'driver' : 'passenger',
      counterpart: payment ? const PersonRef(id: 'p1', displayName: 'Ana') : null,
      tripPaymentId: payment ? 'pay1' : null,
      assignedTo: assigned,
      createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
      lastMessageAt: DateTime.now().subtract(const Duration(minutes: 30)),
      lastUserMessageAt: DateTime.now().subtract(const Duration(minutes: 30)),
      awaitingReply: true,
    );

SupportCaseDetail _detail(SupportCase c, {List<SupportMessage> extra = const []}) => SupportCaseDetail(
  supportCase: c,
  messages: [
    SupportMessage(
      id: 'm1',
      authorKind: SupportAuthor.user,
      authorName: c.user.displayName,
      body: 'Hola',
      createdAt: DateTime.utc(2026, 10, 28, 12),
    ),
    ...extra,
  ],
);

void main() {
  late _MockApi api;

  setUpAll(() => registerFallbackValue(SupportStatus.open));

  setUp(() => api = _MockApi());

  testWidgets('bandeja: sin respuesta por defecto y filtro de asignados a mí', (tester) async {
    when(
      () => api.adminSupportCases(
        status: any(named: 'status'),
        topic: any(named: 'topic'),
        assignedToMe: any(named: 'assignedToMe'),
        unanswered: any(named: 'unanswered'),
        includeClosed: any(named: 'includeClosed'),
      ),
    ).thenAnswer((_) async => [_case()]);
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (_) => SupportInboxCubit(api, refreshEvery: null)..load(),
          child: const SupportInboxPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Dejé mi sombrilla'), findsOneWidget);
    expect(find.textContaining('hace 30 min'), findsOneWidget);
    verify(() => api.adminSupportCases(unanswered: true)).called(1);

    await tester.tap(find.byKey(const Key('inbox.mine')));
    await tester.pumpAndSettle();
    verify(() => api.adminSupportCases(unanswered: true, assignedToMe: true)).called(1);
  });

  testWidgets('caso: nota interna, asignarse y resolver el pago como pagado (FR-006, FR-010)', (tester) async {
    tester.view.physicalSize = const Size(2400, 1600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final c = _case(payment: true);
    when(() => api.adminSupportCase('c1')).thenAnswer((_) async => _detail(c));
    when(() => api.adminReplySupportCase('c1', 'Revisar con Ana', internal: true)).thenAnswer(
      (_) async => _detail(
        c,
        extra: [
          SupportMessage(
            id: 'm2',
            authorKind: SupportAuthor.admin,
            authorName: 'Admin',
            body: 'Revisar con Ana',
            internal: true,
            createdAt: DateTime.utc(2026, 10, 28, 12, 1),
          ),
        ],
      ),
    );
    when(() => api.assignSupportCase('c1', adminId: 'a1')).thenAnswer(
      (_) async => _detail(
        _case(
          payment: true,
          assigned: const PersonRef(id: 'a1', displayName: 'Admin'),
        ),
      ),
    );
    when(
      () => api.resolveSupportPayment('c1', paid: true, note: 'Encontró el billete'),
    ).thenAnswer((_) async => _detail(_case(payment: true, status: SupportStatus.resolved)));

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (_) => SupportAdminCaseCubit(api, 'c1', refreshEvery: null)..load(),
          child: const SupportAdminCasePage(adminId: 'a1'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Carlos (conductor) y Ana'), findsOneWidget);

    await tester.tap(find.byKey(const Key('case.internal')));
    await tester.enterText(find.byKey(const Key('case.reply')), 'Revisar con Ana');
    await tester.tap(find.byKey(const Key('case.send')));
    await tester.pumpAndSettle();
    expect(find.text('Admin · nota interna'), findsOneWidget);

    await tester.tap(find.byKey(const Key('case.assignMe')));
    await tester.pumpAndSettle();
    expect(find.text('Asignado a Admin'), findsOneWidget);

    await tester.tap(find.byKey(const Key('case.paid')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('case.paymentNote')), 'Encontró el billete');
    await tester.tap(find.byKey(const Key('case.paymentConfirm')));
    await tester.pumpAndSettle();
    verify(() => api.resolveSupportPayment('c1', paid: true, note: 'Encontró el billete')).called(1);
    expect(find.byKey(const Key('case.paid')), findsNothing, reason: 'resuelto');
  });
}
