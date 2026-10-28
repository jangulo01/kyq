import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kyq_admin_web/users/users_page.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:mocktail/mocktail.dart';

class _MockApi extends Mock implements KyqApiClient {}

ModeratedUser _user(String id, String name, UserRole role, {String? reason}) => ModeratedUser(
  userId: id,
  displayName: name,
  phoneE164: '+57310000000$id',
  role: role,
  createdAt: DateTime(2026, 10, 1),
  suspendedAt: reason == null ? null : DateTime(2026, 10, 27),
  suspensionReason: reason,
);

void main() {
  testWidgets('moderación: buscar, suspender con motivo obligatorio, reactivar e historial', (tester) async {
    tester.view.physicalSize = const Size(2800, 1600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final api = _MockApi();
    when(
      () => api.adminUsers(
        query: any(named: 'query'),
        role: any(named: 'role'),
        suspended: any(named: 'suspended'),
      ),
    ).thenAnswer(
      (_) async => [
        _user('1', 'Carlos', UserRole.driver),
        _user('2', 'Ana', UserRole.passenger, reason: 'acoso'),
        _user('3', 'Admin', UserRole.admin),
      ],
    );
    when(
      () => api.adminSuspendUser('1', 'documentos falsos'),
    ).thenAnswer((_) async => _user('1', 'Carlos', UserRole.driver, reason: 'documentos falsos'));
    when(() => api.adminReactivateUser('2', 'aclarado')).thenAnswer((_) async => _user('2', 'Ana', UserRole.passenger));
    when(() => api.adminModerationHistory('2')).thenAnswer(
      (_) async => [
        ModerationAction(
          id: 'm1',
          action: ModerationKind.suspend,
          reason: 'acoso',
          actorId: 'a1',
          actorName: 'Admin',
          createdAt: DateTime(2026, 10, 27),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(create: (_) => UsersCubit(api)..search(), child: const UsersPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('users.row.1')), findsOneWidget);
    expect(find.textContaining('suspendido el 27/10/2026: acoso'), findsOneWidget);
    expect(find.byKey(const Key('users.suspend.3')), findsNothing, reason: 'a un admin no se le modera');

    await tester.enterText(find.byKey(const Key('users.query')), 'car');
    await tester.tap(find.byKey(const Key('users.search')));
    await tester.pumpAndSettle();
    verify(() => api.adminUsers(query: 'car', role: null, suspended: null)).called(1);

    await tester.tap(find.byKey(const Key('users.suspend.1')));
    await tester.pumpAndSettle();
    expect(find.textContaining('quedará OFFLINE'), findsOneWidget);
    final confirm = find.byKey(const Key('users.confirm'));
    await tester.enterText(find.byKey(const Key('users.reason')), 'no');
    await tester.pump();
    expect(tester.widget<FilledButton>(confirm).onPressed, isNull, reason: 'motivo de al menos 3 caracteres');
    await tester.enterText(find.byKey(const Key('users.reason')), '  documentos falsos ');
    await tester.pump();
    await tester.tap(confirm);
    await tester.pumpAndSettle();
    verify(() => api.adminSuspendUser('1', 'documentos falsos')).called(1);
    expect(find.text('Carlos quedó suspendido.'), findsOneWidget);
    expect(find.byKey(const Key('users.reactivate.1')), findsOneWidget);

    await tester.tap(find.byKey(const Key('users.reactivate.2')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('users.reason')), 'aclarado');
    await tester.pump();
    await tester.tap(find.byKey(const Key('users.confirm')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('users.suspend.2')), findsOneWidget);

    await tester.tap(find.byKey(const Key('users.history.2')));
    await tester.pumpAndSettle();
    expect(find.text('Historial de Ana'), findsOneWidget);
    expect(find.text('27/10/2026 · Admin: acoso'), findsOneWidget);
  });
}
