import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kyq_admin_web/finance/finance_page.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:mocktail/mocktail.dart';

class _MockApi extends Mock implements KyqApiClient {}

FinanceMonth _month(String m, {required int revenue, required double cost, bool ratesMissing = false}) => FinanceMonth(
  month: m,
  revenueMinor: revenue,
  infraCostMinor: cost,
  marginMinor: revenue - cost,
  marginPct: revenue == 0 ? null : (revenue - cost) / revenue * 100,
  drivers: 3,
  activeDrivers: 2,
  payingDrivers: revenue > 0 ? 1 : 0,
  negativeMarginDrivers: 2,
  costPerActiveDriverMinor: cost / 2,
  revenuePerPayingDriverMinor: revenue > 0 ? revenue.toDouble() : null,
  costByConcept: [FinanceConceptCost(concept: CostConcepts.fixedMonthly, costMinor: cost)],
  ratesMissing: ratesMissing,
);

void main() {
  testWidgets('finanzas: tarjetas del último mes, mes con margen negativo destacado y rango', (tester) async {
    tester.view.physicalSize = const Size(3200, 2000);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final api = _MockApi();
    when(() => api.adminFinance(to: DateTime(2026, 10), months: 6)).thenAnswer(
      (_) async => FinanceReport(
        months: [
          _month('2026-09', revenue: 0, cost: 1600000, ratesMissing: false),
          _month('2026-10', revenue: 5000000, cost: 1806400),
        ],
        totals: const FinanceTotals(
          revenueMinor: 5000000,
          infraCostMinor: 3406400,
          marginMinor: 1593600,
          marginPct: 31.87,
        ),
      ),
    );
    when(
      () => api.adminFinance(to: DateTime(2026, 10), months: 3),
    ).thenAnswer((_) async => FinanceReport(months: [_month('2026-10', revenue: 0, cost: 0, ratesMissing: true)]));

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (_) => FinanceCubit(api, now: DateTime(2026, 10, 27))..load(),
          child: const FinancePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('octubre de 2026'), findsWidgets);
    expect(tester.widget<Text>(find.byKey(const Key('finance.card.revenue'))).data, r'$ 50.000');
    expect(tester.widget<Text>(find.byKey(const Key('finance.card.cost'))).data, r'$ 18.064');
    expect(tester.widget<Text>(find.byKey(const Key('finance.card.margin'))).data, r'$ 31.936 (63,9 %)');
    expect(tester.widget<Text>(find.byKey(const Key('finance.card.costPerDriver'))).data, r'$ 9.032');
    expect(find.byKey(const Key('finance.negativeDrivers')), findsOneWidget);
    expect(find.byKey(const Key('finance.ratesMissing')), findsNothing);

    final rows = tester.widget<DataTable>(find.byType(DataTable)).rows;
    expect(rows.first.key, const ValueKey('finance.row.2026-10'), reason: 'el más reciente arriba');
    expect(rows.last.color, isNotNull, reason: 'septiembre con margen negativo');
    expect(rows.first.color, isNull);
    expect(tester.widget<Text>(find.byKey(const Key('finance.margin.2026-09'))).data, r'-$ 16.000');
    expect(find.textContaining('(31,9 %)'), findsOneWidget);

    await tester.tap(find.text('3 meses'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('finance.ratesMissing')), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(const Key('finance.card.margin'))).data, r'$ 0 (—)');
  });
}
