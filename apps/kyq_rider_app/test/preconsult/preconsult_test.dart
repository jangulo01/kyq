import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_ptt/kyq_ptt.dart';
import 'package:kyq_ptt/testing.dart';
import 'package:kyq_realtime/kyq_realtime.dart';
import 'package:kyq_rider_app/app/app.dart';
import 'package:kyq_rider_app/preconsult/preconsult_cubit.dart';
import 'package:kyq_ui/kyq_ui.dart';
import 'package:mocktail/mocktail.dart';

import '../support/fakes.dart';

final _now = DateTime.now().toUtc();

Preconsult _preconsult({DateTime? joinedAt, PreconsultStatus status = PreconsultStatus.open}) => Preconsult(
  id: 'pc1',
  passengerId: 'p1',
  passengerName: 'Ana',
  driverId: 'd1',
  driverName: 'Carlos',
  status: status,
  openedAt: _now,
  joinDeadline: _now.add(const Duration(seconds: 30)),
  closesAt: _now.add(const Duration(minutes: 2)),
  joinedAt: joinedAt,
  closedAt: status == PreconsultStatus.open ? null : _now,
  closeReason: status == PreconsultStatus.missed ? PreconsultCloseReason.missed : null,
);

const _carlos = ChosenDriver(
  driverId: 'd1',
  displayName: 'Carlos',
  vehicleDescription: 'Kia gris',
  presence: DriverPresence.free,
);

void main() {
  late MockApi api;
  late FakeRealtime realtime;
  late List<FakePtt> created;

  setUp(() {
    api = MockApi();
    realtime = FakeRealtime();
    created = [];
    when(
      () => api.currentSession(),
    ).thenAnswer((_) async => Tokens(accessToken: fakeAccessToken('p1'), refreshToken: 'r', role: UserRole.passenger));
  });

  PreconsultCubit cubit() =>
      PreconsultCubit(api: api, realtime: realtime, ptt: fakePttFactory(created), driverId: 'd1', driverName: 'Carlos');

  group('RN-KYQ-010 en el pasajero', () {
    test('espera al conductor, habla cuando se une y se cierra con el motivo', () async {
      when(() => api.openPreconsult('d1')).thenAnswer((_) async => _preconsult());
      final c = cubit();
      await c.start();
      await Future<void>.delayed(Duration.zero);
      expect(c.state.phase, PreconsultPhase.waiting);
      expect(created.single.room.connects, 1);

      realtime.emit(Channels.user('p1'), PreconsultJoined(_now, preconsultId: 'pc1'));
      await Future<void>.delayed(Duration.zero);
      expect(c.state.phase, PreconsultPhase.ready);

      realtime.emit(Channels.user('p1'), PreconsultClosed(_now, preconsultId: 'pc1', reason: 'ended_by_driver'));
      await Future<void>.delayed(Duration.zero);
      expect(c.state.phase, PreconsultPhase.closed);
      expect(c.state.message, 'Carlos terminó la consulta.');
      expect(created.single.controller.state.status, PttStatus.closed);
      await c.close();
    });

    test('un conductor que no acepta consultas se explica sin abrir nada', () async {
      when(
        () => api.openPreconsult('d1'),
      ).thenThrow(const ApiException(403, 'preconsults_disabled', 'no recibe consultas'));
      final c = cubit();
      await c.start();
      expect(c.state.phase, PreconsultPhase.failed);
      expect(c.state.message, 'Carlos no recibe consultas de voz ahora.');
      expect(created, isEmpty);
      await c.close();
    });

    test('una consulta perdida muestra que el conductor no respondió', () async {
      when(() => api.openPreconsult('d1')).thenAnswer((_) async => _preconsult());
      when(() => api.getPreconsult('pc1')).thenAnswer((_) async => _preconsult(status: PreconsultStatus.missed));
      final c = PreconsultCubit(
        api: api,
        realtime: realtime,
        ptt: fakePttFactory(created),
        driverId: 'd1',
        driverName: 'Carlos',
        refreshEvery: const Duration(milliseconds: 10),
      );
      await c.start();
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(c.state.phase, PreconsultPhase.closed);
      expect(c.state.message, 'Carlos no respondió. Puedes pedir el viaje igualmente.');
      await c.close();
    });

    test('terminar avisa al backend', () async {
      when(() => api.openPreconsult('d1')).thenAnswer((_) async => _preconsult(joinedAt: _now));
      when(() => api.endPreconsult('pc1')).thenAnswer((_) async => _preconsult());
      final c = cubit();
      await c.start();
      expect(c.state.phase, PreconsultPhase.ready);
      await c.end();
      verify(() => api.endPreconsult('pc1')).called(1);
      expect(c.state.phase, PreconsultPhase.closed);
      await c.close();
    });
  });

  testWidgets('"Preguntar por voz" solo junto a conductores libres que aceptan consultas', (tester) async {
    when(() => api.chosenDrivers()).thenAnswer(
      (_) async => [
        _carlos,
        const ChosenDriver(
          driverId: 'd2',
          displayName: 'Luis',
          vehicleDescription: 'Renault',
          presence: DriverPresence.free,
        ),
      ],
    );
    when(() => api.preconsultDrivers()).thenAnswer((_) async => {'d1'});
    when(() => api.openPreconsult('d1')).thenAnswer((_) async => _preconsult(joinedAt: _now));
    when(() => api.endPreconsult('pc1')).thenAnswer((_) async => _preconsult());
    final auth = AuthCubit(api, allowedRoles: {UserRole.passenger}, wrongRoleMessage: '')..start();

    await tester.pumpWidget(
      KyqRiderApp(api: api, auth: auth, realtime: realtime, preconsultPtt: fakePttFactory(created)),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chosen.voice.d1')), findsOneWidget);
    expect(find.byKey(const Key('chosen.voice.d2')), findsNothing, reason: 'Luis no acepta consultas');

    await tester.tap(find.byKey(const Key('chosen.voice.d1')));
    await tester.pump();
    await tester.pump();
    expect(find.text('Carlos te escucha'), findsOneWidget);
    expect(find.byKey(const Key('ptt.button')), findsOneWidget);
    expect(find.byKey(const Key('preconsult.request')), findsOneWidget);

    // Volver atrás termina la consulta.
    await tester.pageBack();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    verify(() => api.endPreconsult('pc1')).called(1);
  });
}
