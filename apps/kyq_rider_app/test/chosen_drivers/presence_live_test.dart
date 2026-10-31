import 'package:flutter_test/flutter_test.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_realtime/kyq_realtime.dart';
import 'package:kyq_rider_app/app/app.dart';
import 'package:kyq_ui/kyq_ui.dart';
import 'package:mocktail/mocktail.dart';

import '../support/fakes.dart';

const _ana = ChosenDriver(
  driverId: 'd2',
  displayName: 'Ana',
  vehicleDescription: 'Renault blanco',
  presence: DriverPresence.busy,
);

void main() {
  testWidgets('RN-KYQ-006: el chip de un conductor ocupado cambia en vivo con driver.presence', (tester) async {
    final api = MockApi();
    final realtime = FakeRealtime();
    when(
      () => api.currentSession(),
    ).thenAnswer((_) async => const Tokens(accessToken: 'a', refreshToken: 'r', role: UserRole.passenger));
    when(() => api.chosenDrivers()).thenAnswer((_) async => const [_ana]);
    final auth = AuthCubit(api, allowedRoles: {UserRole.passenger}, wrongRoleMessage: '')..start();

    await tester.pumpWidget(KyqRiderApp(api: api, auth: auth, realtime: realtime));
    await tester.pumpAndSettle();

    expect(find.text('Ocupado'), findsOneWidget);
    expect(find.text('Pedir viaje'), findsNothing);
    expect(realtime.isSubscribed(Channels.driverPresence('d2')), isTrue);

    realtime.emit(
      Channels.driverPresence('d2'),
      DriverPresenceChanged(DateTime.now(), driverId: 'd2', presence: 'free'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ocupado'), findsNothing);
    expect(find.text('Libre'), findsOneWidget);
    expect(find.text('Pedir viaje'), findsOneWidget);

    realtime.emit(
      Channels.driverPresence('d2'),
      DriverPresenceChanged(
        DateTime.now(),
        driverId: 'd2',
        presence: 'busy',
        busyUntilEstimate: DateTime.now().add(const Duration(minutes: 8, seconds: 30)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ocupado · 8 min'), findsOneWidget);
    expect(find.text('Pedir viaje'), findsNothing);
  });
}
