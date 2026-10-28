import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kyq_admin_web/health/health_page.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:mocktail/mocktail.dart';

class _MockApi extends Mock implements KyqApiClient {}

void main() {
  testWidgets('salud: estado global, dependencias con latencia y backend caído', (tester) async {
    tester.view.physicalSize = const Size(2800, 1600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final api = _MockApi();
    var calls = 0;
    when(() => api.adminHealth()).thenAnswer((_) async {
      calls++;
      if (calls > 1) throw const ApiException(null, 'network', '');
      return HealthReport(
        status: HealthStatus.degraded,
        checkedAt: DateTime.utc(2026, 10, 27, 12),
        checks: const [
          HealthCheck(name: 'database', status: HealthStatus.ok, latencyMs: 3, detail: 'disponible'),
          HealthCheck(name: 'osrm', status: HealthStatus.down, latencyMs: 3000, detail: 'sin respuesta en 3 s'),
          HealthCheck(name: 'bold', status: HealthStatus.disabled, detail: 'pagos con Bold desactivados'),
        ],
      );
    });

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (_) => HealthCubit(api, refreshEvery: const Duration(hours: 1))..start(),
          child: const HealthPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.widget<Text>(find.byKey(const Key('health.overall'))).data, 'Degradado');
    expect(find.text('Rutas (OSRM)'), findsOneWidget);
    expect(find.text('Caído · sin respuesta en 3 s'), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(const Key('health.latency.database'))).data, '3 ms');
    expect(tester.widget<Text>(find.byKey(const Key('health.latency.bold'))).data, '—');
    expect(find.text('Desactivado · pagos con Bold desactivados'), findsOneWidget);

    await tester.tap(find.byTooltip('Comprobar ahora'));
    await tester.pumpAndSettle();
    expect(find.text('Sin conexión con el servidor: el backend no responde.'), findsOneWidget);
    expect(find.byKey(const Key('health.overall')), findsOneWidget, reason: 'se conserva la última comprobación');
  });
}
