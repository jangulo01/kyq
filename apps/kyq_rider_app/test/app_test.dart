import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_rider_app/app/app.dart';
import 'package:kyq_rider_app/chosen_drivers/chosen_drivers_page.dart';
import 'package:kyq_ui/kyq_ui.dart';
import 'package:mocktail/mocktail.dart';

class _MockApi extends Mock implements KyqApiClient {
  // La pantalla de inicio siempre pregunta por un viaje en curso; por defecto no hay ninguno.
  @override
  Future<Trip?> activeTrip() async => null;

  // Ni viajes sin pagar (004).
  @override
  Future<List<TripPayment>> pendingTripPayments() async => const [];

  // Ni reservas (010).
  @override
  Future<List<Reservation>> reservations() async => const [];
}

const _session = Tokens(accessToken: 'a', refreshToken: 'r', role: UserRole.passenger);

const _carlos = ChosenDriver(
  driverId: 'd1',
  displayName: 'Carlos',
  vehicleDescription: 'Kia gris',
  presence: DriverPresence.free,
);

Future<_MockApi> _pumpSignedIn(WidgetTester tester, List<ChosenDriver> drivers) async {
  final api = _MockApi();
  when(() => api.currentSession()).thenAnswer((_) async => _session);
  when(() => api.chosenDrivers()).thenAnswer((_) async => drivers);
  when(() => api.removeChosenDriver(any())).thenAnswer((_) async {});
  final auth = AuthCubit(api, allowedRoles: {UserRole.passenger}, wrongRoleMessage: '')..start();
  await tester.pumpWidget(KyqRiderApp(api: api, auth: auth));
  await tester.pumpAndSettle();
  return api;
}

void main() {
  testWidgets('sin sesión muestra el login', (tester) async {
    final deps = bootstrap(tokenStore: InMemoryTokenStore());
    await tester.pumpWidget(KyqRiderApp(api: deps.api, auth: deps.auth));
    await tester.pumpAndSettle();
    expect(find.text('Kyq Pasajero'), findsWidgets);
    expect(find.text('Enviarme un código'), findsOneWidget);
  });

  testWidgets('sin conductores invita a escanear', (tester) async {
    await _pumpSignedIn(tester, const []);
    expect(find.textContaining('Escanea el código QR'), findsOneWidget);
    expect(find.text('Escanear QR'), findsOneWidget);
  });

  testWidgets('lista los conductores elegidos y permite quitarlos', (tester) async {
    final api = await _pumpSignedIn(tester, const [_carlos]);
    expect(find.text('Carlos'), findsOneWidget);
    expect(find.text('Libre'), findsOneWidget);

    await tester.tap(find.byTooltip('Quitar de mi lista'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Quitar'));
    await tester.pumpAndSettle();

    verify(() => api.removeChosenDriver('d1')).called(1);
    expect(find.text('Carlos'), findsNothing);
  });

  testWidgets('presencia ocupado muestra minutos para liberarse', (tester) async {
    final now = DateTime(2026, 10, 27, 12);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PresenceChip(presence: DriverPresence.busy, busyUntil: now.add(const Duration(minutes: 12)), now: now),
        ),
      ),
    );
    expect(find.text('Ocupado · 12 min'), findsOneWidget);
  });
}
