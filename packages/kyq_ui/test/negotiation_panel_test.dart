import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kyq_ui/kyq_ui.dart';

void main() {
  final now = DateTime(2026, 10, 27, 12);

  Future<List<Object>> pump(WidgetTester tester, NegotiationOffer? offer) async {
    final calls = <Object>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NegotiationPanel(
            currency: 'COP',
            suggestedMinor: 1470000,
            offer: offer,
            negotiationEndsAt: now.add(const Duration(minutes: 3)),
            onAccept: () => calls.add('accept'),
            onPropose: calls.add,
            onAbandon: () => calls.add('abandon'),
            now: () => now,
          ),
        ),
      ),
    );
    return calls;
  }

  test('formatMoney', () {
    expect(formatMoney(1470000, 'COP'), r'$ 14.700');
    expect(formatMoney(123456789, 'COP'), r'$ 1.234.567');
  });

  testWidgets('propuesta de la otra parte: muestra monto, plazo y aceptar', (tester) async {
    final calls = await pump(
      tester,
      NegotiationOffer(amountMinor: 1600000, fromMe: false, expiresAt: now.add(const Duration(seconds: 30))),
    );
    expect(find.text(r'$ 16.000'), findsOneWidget);
    expect(find.text('Responde en 30 s'), findsOneWidget);
    expect(find.text('3:00'), findsOneWidget);

    await tester.tap(find.byKey(const Key('negotiation.accept')));
    expect(calls, ['accept']);
  });

  testWidgets('propuesta propia: no se puede aceptar a uno mismo', (tester) async {
    await pump(
      tester,
      NegotiationOffer(amountMinor: 1600000, fromMe: true, expiresAt: now.add(const Duration(seconds: 12))),
    );
    expect(find.byKey(const Key('negotiation.accept')), findsNothing);
    expect(find.text('Esperando respuesta · 12 s'), findsOneWidget);
  });

  testWidgets('contraproponer envía unidades mínimas', (tester) async {
    final calls = await pump(tester, null);
    expect(find.text('Proponer'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('negotiation.input')), '15000');
    await tester.tap(find.byKey(const Key('negotiation.propose')));
    expect(calls, [1500000]);
  });

  testWidgets('abandonar', (tester) async {
    final calls = await pump(tester, null);
    await tester.tap(find.byKey(const Key('negotiation.abandon')));
    expect(calls, ['abandon']);
  });
}
