import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kyq_admin_web/app/app.dart';
import 'package:kyq_admin_web/drivers/drivers_cubit.dart';
import 'package:kyq_admin_web/drivers/drivers_page.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_ui/kyq_ui.dart';
import 'package:mocktail/mocktail.dart';

class _MockApi extends Mock implements KyqApiClient {}

class _MockAuth extends Mock implements AuthCubit {}

AdminDriver _driver({bool canGoOnline = false}) => AdminDriver.fromJson({
  'driver_id': 'd1',
  'phone_e164': '+573001112233',
  'display_name': 'Carlos',
  'qr_token': 'qr',
  'vehicle_plate': 'ABC123',
  'vehicle_description': 'Kia gris',
  'presence': 'offline',
  'subscription_status': 'suspended',
  'can_go_online': canGoOnline,
  'block_reason': canGoOnline ? null : 'subscription_suspended',
  'documents': [],
});

void main() {
  testWidgets('sin sesión muestra el login de admin', (tester) async {
    final deps = bootstrap(tokenStore: InMemoryTokenStore());
    await tester.pumpWidget(KyqAdminApp(api: deps.api, auth: deps.auth));
    await tester.pumpAndSettle();
    expect(find.text('Kyq Admin'), findsWidgets);
    expect(find.text('Enviarme un código'), findsOneWidget);
  });

  testWidgets('lista conductores y crea uno nuevo', (tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    addTearDown(tester.view.reset);
    final api = _MockApi();
    var drivers = <AdminDriver>[];
    when(() => api.adminListDrivers()).thenAnswer((_) async => drivers);
    when(
      () => api.adminCreateDriver(
        phoneE164: any(named: 'phoneE164'),
        displayName: any(named: 'displayName'),
        vehiclePlate: any(named: 'vehiclePlate'),
        vehicleDescription: any(named: 'vehicleDescription'),
      ),
    ).thenAnswer((_) async {
      drivers = [_driver()];
      return 'd1';
    });

    await tester.pumpWidget(
      MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider<AuthCubit>.value(value: _MockAuth()),
            BlocProvider(create: (_) => DriversCubit(api)..load()),
          ],
          child: const DriversPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Aún no hay conductores. Crea el primero.'), findsOneWidget);

    await tester.tap(find.text('Nuevo conductor'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '+573001112233');
    await tester.enterText(fields.at(1), 'Carlos');
    await tester.enterText(fields.at(2), 'ABC123');
    await tester.enterText(fields.at(3), 'Kia gris');
    await tester.tap(find.text('Crear'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Carlos'), findsOneWidget);
    expect(find.text('Suscripción suspendida'), findsOneWidget);
  });
}
