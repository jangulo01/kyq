import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kyq_admin_web/tower/megaphone_cubit.dart';
import 'package:kyq_admin_web/tower/tower_cubit.dart';
import 'package:kyq_admin_web/tower/tower_page.dart';
import 'package:kyq_admin_web/tower/trip_inspection_cubit.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_ptt/kyq_ptt.dart';
import 'package:mocktail/mocktail.dart';

// 009: inspección del viaje en un clic y megáfono por hexágonos desde la torre.

class _MockApi extends Mock implements KyqApiClient {}

class _Room implements VoiceRoom {
  final log = <String>[];

  @override
  Stream<VoiceRoomEvent> get events => const Stream.empty();

  @override
  String? get localIdentity => 'admin';

  @override
  Future<void> connect(String url, String token) async => log.add('connect $token');

  @override
  Future<void> setMicrophoneEnabled(bool enabled) async => log.add('mic $enabled');

  @override
  Future<void> sendData(Map<String, Object?> message) async {}

  @override
  Future<void> disconnect() async => log.add('disconnect');
}

final _snapshot = TowerSnapshot(
  generatedAt: DateTime.utc(2026, 10, 28, 12),
  resolution: 8,
  totals: const TowerTotals(online: 2, free: 1, busy: 1, activeTrips: 1),
  cells: const [
    TowerCell(cell: '88aaa', center: GeoPoint(lat: 4.6, lng: -74.08), busyDrivers: 1, activeTrips: 1, tripIds: ['t1']),
    TowerCell(cell: '88bbb', center: GeoPoint(lat: 4.65, lng: -74.05), freeDrivers: 1),
  ],
  drivers: [
    TowerDriver(
      driverId: 'd1',
      displayName: 'Carlos',
      presence: DriverPresence.busy,
      lat: 4.6,
      lng: -74.08,
      locationAt: DateTime.utc(2026, 10, 28, 11, 59),
      cell: '88aaa',
      activeTripId: 't1',
    ),
    TowerDriver(
      driverId: 'd2',
      displayName: 'Beto',
      presence: DriverPresence.free,
      lat: 4.65,
      lng: -74.05,
      locationAt: DateTime.utc(2026, 10, 28, 11, 59),
      cell: '88bbb',
    ),
  ],
);

TripInspection _inspection({bool active = true}) => TripInspection(
  tripId: 't1',
  status: active ? 'IN_PROGRESS' : 'COMPLETED',
  active: active,
  dispatch: 'zone_pool',
  passenger: const PersonRef(id: 'p1', displayName: 'Ana'),
  driver: const PersonRef(id: 'd1', displayName: 'Carlos'),
  vehiclePlate: 'KYQ001',
  vehicleDescription: 'Kia Picanto',
  pickup: const GeoPoint(lat: 4.6, lng: -74.08),
  dropoff: const GeoPoint(lat: 4.65, lng: -74.05),
  distanceM: 5200,
  durationS: 900,
  currency: 'COP',
  listFareMinor: 1470000,
  suggestedFareMinor: 1470000,
  steps: [TripStep(status: 'REQUESTED', at: DateTime.utc(2026, 10, 28, 11, 50))],
  driverPosition: InspectionPosition(lat: 4.61, lng: -74.07, locationAt: DateTime.utc(2026, 10, 28, 11, 59, 30)),
  openSos: active ? const InspectionSos(id: 's1', status: 'open') : null,
  generatedAt: DateTime.utc(2026, 10, 28, 12),
);

void main() {
  late _MockApi api;
  late _Room room;

  setUp(() {
    api = _MockApi();
    room = _Room();
    when(() => api.adminTower(resolution: any(named: 'resolution'))).thenAnswer((_) async => _snapshot);
    when(() => api.inspectTrip('t1')).thenAnswer((_) async => _inspection());
    when(() => api.megaphoneLog(limit: any(named: 'limit'))).thenAnswer((_) async => []);
  });

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(2800, 1800);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      RepositoryProvider<KyqApiClient>.value(
        value: api,
        child: MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider(create: (_) => TowerCubit(api, pollEvery: const Duration(hours: 1))..start()),
              BlocProvider(create: (_) => AdminMegaphoneCubit(api, room: () => room)),
            ],
            child: TowerPage(map: (s, taps) => const SizedBox.expand(key: Key('map'))),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('un clic en el conductor ocupado abre su viaje sin teléfonos y con el SOS (FR-001, FR-002)', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.byKey(const ValueKey('tower.driver.d1')));
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const Key('inspection.passenger')), findsOneWidget);
    expect(find.text('KYQ001 · Kia Picanto'), findsOneWidget);
    expect(find.byKey(const Key('inspection.sos')), findsOneWidget);
    expect(find.text('En curso'), findsOneWidget);
    verify(() => api.inspectTrip('t1')).called(1);
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
  });

  testWidgets('el hexágono lista sus viajes y se elige para el megáfono', (tester) async {
    await pump(tester);
    final state = tester.element(find.byType(TowerPage)).read<TowerCubit>().state;
    showCellSheet(tester.element(find.byType(TowerPage)), '88aaa');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('tower.sheet.trip.t1')), findsOneWidget);
    await tester.tap(find.byKey(const Key('tower.sheet.select')));
    await tester.pumpAndSettle();
    expect(tester.element(find.byType(TowerPage)).read<TowerCubit>().state.selected, {'88aaa'});
    expect(state.selected, isEmpty);
  });

  testWidgets('megáfono: mantener pulsado habla a los hexágonos elegidos y soltar termina (FR-013)', (tester) async {
    when(() => api.startMegaphone(['88bbb'])).thenAnswer(
      (_) async => MegaphoneOnAir(
        broadcastId: 'b1',
        url: 'wss://lk',
        token: 'tk',
        endsAt: DateTime.now().add(const Duration(seconds: 60)),
        recipients: 1,
      ),
    );
    when(() => api.endMegaphone('b1')).thenAnswer((_) async {});
    await pump(tester);
    expect(tester.widget<FilledButton>(find.byKey(const Key('megaphone.talk'))).onPressed, isNull);
    await tester.tap(find.byKey(const ValueKey('megaphone.cell.88bbb')));
    await tester.pump();

    final gesture = await tester.startGesture(tester.getCenter(find.byKey(const Key('megaphone.talk'))));
    await tester.pump();
    await tester.pump();
    expect(find.text('Hablando a 1 conductor…'), findsOneWidget);
    expect(room.log, ['connect tk', 'mic true']);
    await gesture.up();
    await tester.pump();
    await tester.pump();
    verify(() => api.endMegaphone('b1')).called(1);
    expect(room.log, ['connect tk', 'mic true', 'mic false', 'disconnect']);
    expect(find.text('Comunicado enviado a 1 conductor.'), findsOneWidget);
  });

  test('sin conductores en la zona se explica', () async {
    when(() => api.startMegaphone(any())).thenThrow(const ApiException(409, 'no_recipients', ''));
    final c = AdminMegaphoneCubit(api, room: () => room);
    await c.press({'88ccc'});
    expect(c.state.message, 'No hay conductores conectados en esas zonas.');
    expect(room.log, isEmpty);
    await c.close();
  });

  test('un viaje terminado deja de refrescarse', () async {
    when(() => api.inspectTrip('t1')).thenAnswer((_) async => _inspection(active: false));
    final c = TripInspectionCubit(api, 't1', refreshEvery: const Duration(milliseconds: 10));
    await c.load();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    verify(() => api.inspectTrip('t1')).called(1);
    await c.close();
  });
}
