import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_radio/kyq_radio.dart';
import 'package:kyq_radio/testing.dart';

import 'support/harness.dart';

RadioConversation _client(String id, String name, {bool muted = false, bool blocked = false}) =>
    fakeContact(id, title: name).copyWith(kind: RadioConversationKind.client, peerMuted: muted, peerBlocked: blocked);

void main() {
  testWidgets('modo del botón: mantener o tocar (FR-007)', (tester) async {
    final api = FakeRadioApi();
    final h = RadioHarness(api);
    await h.pump(tester, initial: '/radio/settings');
    await tester.tap(find.text('Tocar'));
    await tester.pumpAndSettle();
    expect(api.calls.last, endsWith('toggle'));
    expect(find.textContaining('Toca una vez'), findsOneWidget);
    await h.done(tester);
  });

  testWidgets('Radio con mis clientes: activar, silenciar y bloquear (FR-003)', (tester) async {
    final api = FakeRadioApi(conversations: [_client('c3', 'Ana'), _client('c4', 'Luis', blocked: true)]);
    final h = RadioHarness(api);
    await h.pump(tester, initial: '/radio/settings');
    expect(find.byKey(const Key('radio.client.c3')), findsNothing, reason: 'apagada por defecto');
    await tester.tap(find.byKey(const Key('radio.settings.clients')));
    await tester.pumpAndSettle();
    expect(api.calls, contains('clients true'));
    expect(find.text('Bloqueado: no puede enviarte mensajes'), findsOneWidget);

    await tester.tap(find.byKey(const Key('radio.client.mute.c3')));
    await tester.pumpAndSettle();
    expect(api.calls, contains('client peer-c3 muted=true blocked=null'));
    await tester.tap(find.byKey(const Key('radio.client.block.c4')));
    await tester.pumpAndSettle();
    expect(api.calls, contains('client peer-c4 muted=null blocked=false'));
    await h.done(tester);
  });

  testWidgets('pasajero: sin ajustes de clientes y "Pedir viaje" en la conversación (US3-6)', (tester) async {
    final api = FakeRadioApi(me: fakeMe(), conversations: [_client('c3', 'Carlos')]);
    RadioConversation? asked;
    final h = RadioHarness(api, isDriver: false, onRequestTrip: (_, c) => asked = c);
    await h.pump(tester, initial: '/radio/settings');
    expect(find.byKey(const Key('radio.settings.clients')), findsNothing);
    await h.done(tester);

    final h2 = RadioHarness(api, isDriver: false, onRequestTrip: (_, c) => asked = c);
    await h2.pump(tester, initial: '/radio/c/c3');
    await tester.tap(find.byKey(const Key('radio.requestTrip')));
    await tester.pumpAndSettle();
    expect(asked?.peerId, 'peer-c3');
    await h2.done(tester);
  });

  testWidgets('horarios de silencio: agregar, apagar y quitar (FR-021, US5)', (tester) async {
    final api = FakeRadioApi();
    final h = RadioHarness(api);
    await h.pump(tester, initial: '/radio/settings');
    await tester.scrollUntilVisible(find.byKey(const Key('radio.quiet.add')), 200);
    await tester.tap(find.byKey(const Key('radio.quiet.add')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('radio.quiet.overnight')), findsOneWidget, reason: 'de 22:00 a 06:00 cruza la noche');
    await tester.tap(find.byKey(const Key('radio.quiet.day.6')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('radio.quiet.save')));
    await tester.pumpAndSettle();
    expect(api.calls, contains('quiet 1'));
    expect(api.quiet.single.weekdays, [1, 2, 3, 4, 5, 6]);
    expect(find.text('22:00 a 06:00'), findsOneWidget);
    expect(find.text('Lunes, martes, miércoles, jueves, viernes y sábado'), findsOneWidget);

    await tester.tap(find.byKey(const Key('radio.quiet.enabled.0')));
    await tester.pumpAndSettle();
    expect(api.quiet.single.enabled, isFalse);
    await tester.tap(find.byKey(const Key('radio.quiet.delete.0')));
    await tester.pumpAndSettle();
    expect(api.quiet, isEmpty);
    await h.done(tester);
  });

  test('días de los horarios en palabras', () {
    expect(quietDaysText([1, 2, 3, 4, 5]), 'Lunes a viernes');
    expect(quietDaysText([7, 6]), 'Sábado y domingo');
    expect(quietDaysText([1, 2, 3, 4, 5, 6, 7]), 'Todos los días');
    expect(quietDaysText([3]), 'Miércoles');
  });
}
