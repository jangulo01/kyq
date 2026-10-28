import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kyq_ptt/kyq_ptt.dart';
import 'package:kyq_radio/kyq_radio.dart';
import 'package:kyq_radio/testing.dart';

import 'support/harness.dart';

void main() {
  testWidgets('modo auto: botones grandes, flechas entre conversaciones y sin teclado (FR-029)', (tester) async {
    tester.view.physicalSize = const Size(1080, 2160);
    tester.view.devicePixelRatio = 2.7;
    addTearDown(tester.view.reset);
    final h = RadioHarness(FakeRadioApi(conversations: [fakeContact('c1'), fakeChannel('c2')]));
    await h.pump(tester, initial: '/radio/auto');
    expect(find.text('Jonathan'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    final width = tester.getSize(find.byType(Scaffold).first).width;
    expect(tester.getSize(find.byKey(const Key('radio.auto.next'))).width, greaterThanOrEqualTo(width / 3 - 1));
    expect(tester.getSize(find.byKey(const Key('radio.talk'))).width, greaterThan(width / 2));

    await tester.tap(find.byKey(const Key('radio.auto.next')));
    await tester.pumpAndSettle();
    expect(find.text('Taxistas Norte'), findsOneWidget);
    await tester.tap(find.byKey(const Key('radio.auto.prev')));
    await tester.pumpAndSettle();
    expect(find.text('Jonathan'), findsOneWidget);

    final gesture = await tester.startGesture(tester.getCenter(find.byKey(const Key('radio.talk'))));
    await tester.pumpAndSettle();
    expect(h.api.calls, contains('floor c1'));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(h.api.calls, contains('release c1'));
    await h.done(tester);
  });

  testWidgets('modo auto con el teléfono horizontal: todo cabe', (tester) async {
    final h = RadioHarness(FakeRadioApi(conversations: [fakeContact('c1')]));
    await h.pump(tester, initial: '/radio/auto');
    expect(tester.takeException(), isNull);
    await h.done(tester);
  });

  testWidgets('el botón físico habla por la conversación seleccionada (FR-028)', (tester) async {
    final h = RadioHarness(FakeRadioApi(conversations: [fakeContact('c1')]));
    await h.pump(tester, initial: '/radio/c/c1');
    final hands = RadioHandsFree(h.cubit);
    expect(hands.ready, isTrue);
    expect(hands.look, BubbleLook.idle);
    await hands.press();
    await tester.pumpAndSettle();
    expect(hands.speaking, isTrue);
    expect(hands.look, BubbleLook.talking);
    await hands.release();
    await tester.pumpAndSettle();
    expect(hands.speaking, isFalse);
    expect(h.api.calls, containsAllInOrder(['floor c1', 'release c1']));
    await h.done(tester);
  });
}
