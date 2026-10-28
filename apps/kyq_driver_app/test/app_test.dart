import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_driver_app/app/app.dart';
import 'package:kyq_driver_app/app/driver_services.dart';
import 'package:kyq_driver_app/onboarding/my_qr_page.dart';
import 'package:kyq_ui/kyq_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'support/fakes.dart';

const _session = Tokens(accessToken: 'a', refreshToken: 'r', role: UserRole.driver);

DriverMe _me({bool canGoOnline = true, String? blockReason, DriverPresence presence = DriverPresence.offline}) =>
    DriverMe(
      driverId: 'd1',
      qrToken: 'q3T9xZk2LmN8pR4sV7wY1a',
      presence: presence,
      subscriptionStatus: canGoOnline ? SubscriptionStatus.active : SubscriptionStatus.suspended,
      canGoOnline: canGoOnline,
      blockReason: blockReason,
    );

Future<MockApi> _pumpSignedIn(
  WidgetTester tester, {
  DriverMe? me,
  List<DriverClient> clients = const [],
  DriverServices? services,
}) async {
  final api = MockApi();
  when(() => api.currentSession()).thenAnswer((_) async => _session);
  stubOnboardingDefaults(api);
  when(() => api.driverMe()).thenAnswer((_) async => me ?? _me());
  when(() => api.driverClients()).thenAnswer((_) async => clients);
  final auth = AuthCubit(api, allowedRoles: {UserRole.driver}, wrongRoleMessage: '')..start();
  await tester.pumpWidget(KyqDriverApp(api: api, auth: auth, services: services ?? fakeServices()));
  await tester.pumpAndSettle();
  return api;
}

void main() {
  testWidgets('sin sesión muestra el login', (tester) async {
    final deps = bootstrap(tokenStore: InMemoryTokenStore());
    await tester.pumpWidget(KyqDriverApp(api: deps.api, auth: deps.auth, services: fakeServices()));
    await tester.pumpAndSettle();
    expect(find.text('Kyq Conductor'), findsWidgets);
    expect(find.text('Enviarme un código'), findsOneWidget);
  });

  testWidgets('inicio muestra si puede trabajar', (tester) async {
    await _pumpSignedIn(tester);
    expect(find.text('Puedes trabajar'), findsOneWidget);
  });

  testWidgets('inicio muestra el bloqueo por suscripción', (tester) async {
    await _pumpSignedIn(tester, me: _me(canGoOnline: false, blockReason: 'subscription_suspended'));
    expect(find.text('Suscripción suspendida'), findsOneWidget);
  });

  testWidgets('Mi código QR muestra el QR y el PDF', (tester) async {
    await _pumpSignedIn(tester);
    await tester.tap(find.text('Mi código QR'));
    await tester.pumpAndSettle();
    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.text('Descargar PDF para imprimir'), findsOneWidget);
  });

  testWidgets('Mis clientes lista la cartera', (tester) async {
    await _pumpSignedIn(
      tester,
      clients: [DriverClient(passengerId: 'p1', displayName: 'Ana', affiliatedAt: DateTime.utc(2026, 10, 27))],
    );
    await tester.scrollUntilVisible(find.text('Mis clientes'), 200);
    await tester.tap(find.text('Mis clientes'));
    await tester.pumpAndSettle();
    expect(find.text('Ana'), findsOneWidget);
    expect(find.byType(ListTile), findsOneWidget);
  });

  test('el PDF imprimible es un PDF', () async {
    final bytes = await buildQrPdf('kyq://driver/q3T9xZk2LmN8pR4sV7wY1a');
    expect(ascii.decode(bytes.sublist(0, 5)), '%PDF-');
  });
}
