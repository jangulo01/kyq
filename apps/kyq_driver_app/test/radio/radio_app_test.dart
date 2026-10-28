import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_driver_app/app/app.dart';
import 'package:kyq_radio/testing.dart';
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

Future<FakeRadioApi> _pump(WidgetTester tester, {FakeRadioApi? radio}) async {
  final api = MockApi();
  when(() => api.currentSession()).thenAnswer((_) async => _session);
  stubOnboardingDefaults(api);
  when(() => api.driverMe()).thenAnswer((_) async => _me);
  final radioApi = radio ?? FakeRadioApi(conversations: [fakeContact('c1'), fakeChannel('c2')]);
  final auth = AuthCubit(api, allowedRoles: {UserRole.driver}, wrongRoleMessage: '')..start();
  await tester.pumpWidget(
    KyqDriverApp(
      api: api,
      auth: auth,
      services: fakeServices(radioApi: radioApi),
    ),
  );
  await tester.pumpAndSettle();
  return radioApi;
}

void main() {
  testWidgets('Radio desde el inicio: lista única con contactos y canales (T016)', (tester) async {
    await _pump(tester);
    await tester.scrollUntilVisible(find.byKey(const Key('home.radio')), 200);
    await tester.tap(find.byKey(const Key('home.radio')));
    await tester.pumpAndSettle();
    expect(find.text('Jonathan'), findsOneWidget);
    expect(find.text('Taxistas Norte'), findsOneWidget);

    await tester.tap(find.byKey(const Key('radio.conversation.c1')));
    await tester.pumpAndSettle();
    expect(find.text('Mantén pulsado para hablar'), findsOneWidget);
  });

  testWidgets('la radio arranca con la sesión, sin abrir la pantalla (permanente)', (tester) async {
    final radio = await _pump(tester);
    expect(radio.calls, isNot(contains('consent')));
    expect(find.byKey(const Key('home.radio')), findsOneWidget);
  });

  testWidgets('kyq://radio/{code} abre la invitación (FR-032)', (tester) async {
    await _pump(tester);
    await tester.binding.handlePushRoute('kyq://radio/ABCDEFGHIJ');
    await tester.pumpAndSettle();
    expect(find.text('Carlos quiere agregarte a su Radio'), findsOneWidget);
  });
}
