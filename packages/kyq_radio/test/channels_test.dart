import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_radio/testing.dart';

import 'support/harness.dart';

RadioConversationDetail _detail(RadioRole myRole, {String kind = 'channel'}) => RadioConversationDetail(
  conversation: fakeChannel(
    'c2',
    role: myRole,
  ).copyWith(kind: kind == 'cooperative' ? RadioConversationKind.cooperative : RadioConversationKind.channel),
  description: 'Norte de Bogotá',
  joinMode: 'approval',
  members: [
    fakeMember('me', 'Yo', role: myRole),
    fakeMember('u1', 'Carlos', role: myRole == RadioRole.owner ? RadioRole.moderator : RadioRole.owner),
    fakeMember('u2', 'Jonathan', presence: RadioPresence.busy),
    fakeMember('u3', 'Pedro', status: RadioMemberStatus.pending),
    fakeMember('u4', 'Ana', role: RadioRole.listener, passenger: true),
  ],
);

void main() {
  testWidgets('crear canal: nombre, cómo se entra y pasajeros (US4-1)', (tester) async {
    final api = FakeRadioApi();
    final h = RadioHarness(api);
    await h.pump(tester, initial: '/radio/channels/new');
    await tester.enterText(find.byKey(const Key('radio.channel.name')), 'ab');
    await tester.tap(find.byKey(const Key('radio.channel.create')));
    await tester.pumpAndSettle();
    expect(find.text('El nombre debe tener entre 3 y 40 letras.'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('radio.channel.name')), 'Taxistas Norte');
    await tester.tap(find.byKey(const Key('radio.channel.openLink')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('radio.channel.create')));
    await tester.pumpAndSettle();
    expect(api.calls, contains('channel Taxistas Norte open_link'));
    expect(find.byKey(const Key('radio.channel.title')), findsOneWidget, reason: 'abre el detalle del canal nuevo');
    await h.done(tester);
  });

  testWidgets('el dueño ve solicitudes, miembros con estado y modera (US4-2, FR-016)', (tester) async {
    final api = FakeRadioApi(conversations: [fakeChannel('c2', role: RadioRole.owner)]);
    api.details['c2'] = _detail(RadioRole.owner);
    final h = RadioHarness(api);
    await h.pump(tester, initial: '/radio/channels/c2');
    expect(find.text('Solicitudes (1)'), findsOneWidget);
    expect(find.text('Miembros (4)'), findsOneWidget);
    expect(find.textContaining('Ocupado'), findsOneWidget);
    expect(find.textContaining('Pasajero'), findsOneWidget);

    await tester.tap(find.byKey(const Key('radio.request.approve.u3')));
    await tester.pumpAndSettle();
    expect(api.calls, contains('moderate u3 approve'));

    await tester.tap(find.byKey(const Key('radio.member.menu.u2')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('radio.act.moderator')), findsOneWidget);
    expect(find.byKey(const Key('radio.act.owner')), findsOneWidget);
    await tester.tap(find.byKey(const Key('radio.act.block')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('radio.channel.confirm')));
    await tester.pumpAndSettle();
    expect(api.calls, contains('moderate u2 block'));

    // Un pasajero no se hace moderador ni dueño.
    await tester.tap(find.byKey(const Key('radio.member.menu.u4')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('radio.act.moderator')), findsNothing);
    expect(find.byKey(const Key('radio.act.owner')), findsNothing);
    await tester.tapAt(Offset.zero);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byKey(const Key('radio.channel.delete')), 200);
    expect(find.byKey(const Key('radio.channel.delete')), findsOneWidget);
    await h.done(tester);
  });

  testWidgets('un moderador no toca al dueño y no nombra moderadores', (tester) async {
    final api = FakeRadioApi(conversations: [fakeChannel('c2', role: RadioRole.moderator)]);
    api.details['c2'] = _detail(RadioRole.moderator);
    final h = RadioHarness(api);
    await h.pump(tester, initial: '/radio/channels/c2');
    expect(find.byKey(const Key('radio.member.menu.u1')), findsNothing);
    await tester.tap(find.byKey(const Key('radio.member.menu.u2')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('radio.act.moderator')), findsNothing);
    await tester.tap(find.byKey(const Key('radio.act.mute')));
    await tester.pumpAndSettle();
    expect(api.calls, contains('moderate u2 mute'));
    expect(find.byKey(const Key('radio.channel.delete')), findsNothing);
    await h.done(tester);
  });

  testWidgets('miembro: sale del canal; la cooperativa no se administra desde Radio (FR-018)', (tester) async {
    final api = FakeRadioApi(conversations: [fakeChannel('c2')]);
    api.details['c2'] = _detail(RadioRole.member);
    final h = RadioHarness(api);
    await h.pump(tester, initial: '/radio/channels/c2');
    expect(find.text('Solicitudes (1)'), findsNothing);
    expect(find.byKey(const Key('radio.member.menu.u2')), findsNothing);
    await tester.tap(find.byKey(const Key('radio.channel.leave')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('radio.channel.confirm')));
    await tester.pumpAndSettle();
    expect(api.calls, contains('leave c2'));
    expect(find.text('Radio'), findsOneWidget, reason: 'vuelve a la lista');
    await h.done(tester);

    final coop = FakeRadioApi(conversations: [fakeChannel('c2', role: RadioRole.moderator)]);
    coop.details['c2'] = _detail(RadioRole.moderator, kind: 'cooperative');
    final h2 = RadioHarness(coop);
    await h2.pump(tester, initial: '/radio/channels/c2');
    expect(find.textContaining('los maneja la cooperativa'), findsOneWidget);
    expect(find.byKey(const Key('radio.channel.leave')), findsNothing);
    expect(find.byKey(const Key('radio.channel.invite')), findsNothing);
    expect(find.byKey(const Key('radio.member.menu.u2')), findsNothing);
    await h2.done(tester);
  });
}
