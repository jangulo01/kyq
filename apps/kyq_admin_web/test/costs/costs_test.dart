import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kyq_admin_web/costs/cost_rates_page.dart';
import 'package:kyq_admin_web/costs/costs_cubits.dart';
import 'package:kyq_admin_web/costs/costs_page.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:mocktail/mocktail.dart';

class _MockApi extends Mock implements KyqApiClient {}

CostBreakdown _row(String id, String name, {required int paid, required double total}) => CostBreakdown(
  driverId: id,
  displayName: name,
  month: '2026-10',
  currency: 'COP',
  paidMinor: paid,
  items: [
    CostItem(concept: CostConcepts.voiceMinute, usage: 120, costMinor: total - 1000000),
    const CostItem(concept: CostConcepts.fixedMonthly, usage: 1, costMinor: 1000000),
  ],
  totalCostMinor: total,
  marginMinor: paid - total,
);

void main() {
  late _MockApi api;

  setUpAll(
    () => registerFallbackValue(CostRate(concept: '', currency: '', unitCostMicro: 0, effectiveFrom: DateTime(2026))),
  );
  setUp(() => api = _MockApi());

  testWidgets('costos por conductor: peor margen arriba y margen negativo destacado', (tester) async {
    tester.view.physicalSize = const Size(3000, 2000);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    when(() => api.adminCosts(DateTime(2026, 10))).thenAnswer(
      (_) async => [_row('d1', 'Ana', paid: 5000000, total: 1300000), _row('d2', 'Beto', paid: 0, total: 1500000)],
    );
    when(() => api.adminCosts(DateTime(2026, 9))).thenAnswer((_) async => []);
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (_) => CostsCubit(api, now: DateTime(2026, 10, 27))..load(),
          child: const CostsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('octubre de 2026'), findsOneWidget);
    expect(find.text('1 con margen negativo'), findsOneWidget);
    final rows = tester.widget<DataTable>(find.byType(DataTable)).rows;
    expect(rows.first.key, const ValueKey('costs.row.d2'));
    expect(rows.first.color, isNotNull);
    expect(rows.last.color, isNull);
    final negative = tester.widget<Text>(find.byKey(const Key('costs.margin.d2')));
    expect(negative.data, '-\$ 15.000');
    expect(negative.style?.color, Theme.of(tester.element(find.byType(DataTable))).colorScheme.error);
    expect(tester.widget<Text>(find.byKey(const Key('costs.margin.d1'))).data, '\$ 37.000');

    await tester.tap(find.byKey(const Key('costs.previous')));
    await tester.pumpAndSettle();
    expect(find.text('septiembre de 2026'), findsOneWidget);
    expect(find.text('Sin datos de uso en este mes.'), findsOneWidget);
  });

  testWidgets('tarifas: vigente, anterior y alta de una nueva con decimales', (tester) async {
    var rates = [
      CostRate(
        concept: CostConcepts.voiceMinute,
        currency: 'COP',
        unitCostMicro: 2000000000,
        effectiveFrom: DateTime(2026, 9),
      ),
      CostRate(
        concept: CostConcepts.voiceMinute,
        currency: 'COP',
        unitCostMicro: 1500000000,
        effectiveFrom: DateTime(2026, 1),
      ),
    ];
    when(() => api.adminCostRates()).thenAnswer((_) async => rates);
    when(() => api.adminSetCostRate(any())).thenAnswer((inv) async {
      rates = [...rates, inv.positionalArguments.single as CostRate];
    });
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (_) => CostRatesCubit(api)..load(),
          child: CostRatesPage(today: DateTime(2026, 10, 27)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Voz del walkie-talkie: \$ 20 por minuto de voz'), findsOneWidget);
    expect(find.textContaining('Vigente desde el 01/09/2026'), findsOneWidget);
    expect(find.textContaining('Anterior desde el 01/01/2026'), findsOneWidget);

    await tester.tap(find.byKey(const Key('rates.add')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('rate.concept')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tiempo real').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('rate.cost')), '0,0004');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('rate.save')));
    await tester.pumpAndSettle();

    final saved = verify(() => api.adminSetCostRate(captureAny())).captured.single as CostRate;
    expect(saved.concept, CostConcepts.realtimeEvent);
    expect(saved.unitCostMicro, 40000);
    expect(find.text('Tiempo real: \$ 0,0004 por evento'), findsOneWidget);
  });

  test('conversión de costos unitarios', () {
    expect(parseUnitCost('20'), 2000000000);
    expect(parseUnitCost('0.5'), 50000000);
    expect(parseUnitCost('abc'), isNull);
    expect(formatUnitCost(2050000000), '\$ 20,5');
    expect(formatUnitCost(40000), '\$ 0,0004');
  });

  test('tarifa vigente: la más reciente que ya empezó', () {
    final old = CostRate(concept: 'voice_minute', currency: 'COP', unitCostMicro: 1, effectiveFrom: DateTime(2026, 1));
    final now = CostRate(concept: 'voice_minute', currency: 'COP', unitCostMicro: 2, effectiveFrom: DateTime(2026, 9));
    final future = CostRate(concept: 'voice_minute', currency: 'COP', unitCostMicro: 3, effectiveFrom: DateTime(2027));
    expect(currentRates([old, now, future], DateTime(2026, 10, 27)), {now});
  });
}
