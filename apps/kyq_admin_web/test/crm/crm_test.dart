import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kyq_admin_web/crm/crm_page.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:mocktail/mocktail.dart';

class _MockApi extends Mock implements KyqApiClient {}

CrmReport _report({double? rate = 0.8, bool? met = true}) => CrmReport(
  from: DateTime(2026, 8, 5),
  to: DateTime(2026, 10, 27),
  affiliations: CrmAffiliations(
    activeNow: 6,
    activeAtStart: 1,
    created: 6,
    removed: 1,
    net: 5,
    churnRate: 0.1429,
    weekly: [
      CrmWeek(weekStart: DateTime(2026, 10, 19), created: 1, activeEnd: 5),
      CrmWeek(weekStart: DateTime(2026, 10, 26), created: 1, activeEnd: 6),
    ],
  ),
  repeat: const CrmRepeat(pairs: 2, repeatPairs: 1, repeatRate: 0.5, completedTrips: 4, avgTripsPerPair: 2),
  sc008: Sc008(matured: 5, withRequest30d: 4, rate: rate, met: met, pending: 1),
  churnedDrivers: const [ChurnedDriver(driverId: 'd2', displayName: 'Diana', removed: 1)],
  inactiveChosenDrivers: const [InactiveChosenDriver(driverId: 'd1', displayName: 'Carlos', activeAffiliations: 6)],
);

void main() {
  testWidgets('fidelización: SC-008 frente a la meta, indicadores y listas', (tester) async {
    tester.view.physicalSize = const Size(2400, 3200);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final api = _MockApi();
    when(() => api.adminCrm(from: DateTime(2026, 8, 5), to: DateTime(2026, 10, 27))).thenAnswer((_) async => _report());
    when(
      () => api.adminCrm(from: DateTime(2026, 9, 30), to: DateTime(2026, 10, 27)),
    ).thenAnswer((_) async => _report(rate: 0.5, met: false));

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (_) => CrmCubit(api, now: DateTime(2026, 10, 27, 15))..load(),
          child: const CrmPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Del 05/08/2026 al 27/10/2026'), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(const Key('crm.sc008.rate'))).data, '80,0 %');
    expect(tester.widget<Text>(find.byKey(const Key('crm.sc008.verdict'))).data, 'Cumple la meta del 80,0 %');
    expect(find.text('4 de 5 afiliaciones con 30 días cumplidos · 1 en curso'), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(const Key('crm.kpi.churn'))).data, '14,3 %');
    expect(tester.widget<Text>(find.byKey(const Key('crm.kpi.repeatRate'))).data, '50,0 %');
    expect(tester.widget<Text>(find.byKey(const Key('crm.kpi.avgTrips'))).data, '2,0');
    expect(find.byKey(const ValueKey('crm.week.26/10/2026')), findsOneWidget);
    expect(find.byKey(const ValueKey('crm.churned.d2')), findsOneWidget);
    expect(find.text('6 afiliados · nunca completó un viaje'), findsOneWidget);

    await tester.tap(find.text('4 semanas'));
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(find.byKey(const Key('crm.sc008.verdict'))).data, 'Por debajo de la meta del 80,0 %');
  });
}
