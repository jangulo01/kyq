import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kyq_admin_web/tower/megaphone_cubit.dart';
import 'package:kyq_admin_web/tower/tower_cubit.dart';
import 'package:kyq_admin_web/tower/tower_map.dart';
import 'package:kyq_admin_web/tower/tower_page.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:mocktail/mocktail.dart';

class _MockApi extends Mock implements KyqApiClient {}

class _FakeEvents implements TowerEvents {
  final controller = StreamController<void>.broadcast();

  @override
  Stream<void> changes() => controller.stream;
}

TowerCell _cell(String id, PressureLevel level, {int requests = 0, int free = 0, int busy = 0}) => TowerCell(
  cell: id,
  center: const GeoPoint(lat: 4.7, lng: -74.03),
  boundary: const [
    GeoPoint(lat: 4.701, lng: -74.031),
    GeoPoint(lat: 4.702, lng: -74.03),
    GeoPoint(lat: 4.701, lng: -74.029),
  ],
  requests: requests,
  freeDrivers: free,
  busyDrivers: busy,
  level: level,
);

TowerSnapshot _snapshot({int online = 2, int resolution = 8}) => TowerSnapshot(
  generatedAt: DateTime.utc(2026, 10, 27, 12),
  resolution: resolution,
  totals: TowerTotals(online: online, free: 1, busy: 1, stale: 1, activeTrips: 1, requests: 3, unservedRequests: 1),
  cells: [_cell('c1', PressureLevel.noSupply, requests: 3, busy: 1), _cell('c2', PressureLevel.none, free: 1)],
  drivers: [
    TowerDriver(
      driverId: 'd1',
      displayName: 'Carlos',
      presence: DriverPresence.busy,
      lat: 4.7,
      lng: -74.03,
      locationAt: DateTime.utc(2026, 10, 27, 11, 55),
      stale: true,
      cell: 'c1',
    ),
  ],
);

void main() {
  late _MockApi api;

  setUp(() => api = _MockApi());

  group('cubit', () {
    test('un aviso en vivo recarga; los avisos durante una carga no la solapan', () async {
      final events = _FakeEvents();
      var calls = 0;
      final gate = Completer<void>();
      when(() => api.adminTower(resolution: any(named: 'resolution'))).thenAnswer((_) async {
        calls++;
        if (calls == 2) await gate.future;
        return _snapshot(online: calls);
      });
      final cubit = TowerCubit(api, events: events, pollEvery: const Duration(hours: 1));
      await cubit.start();
      expect(cubit.state.live, isTrue);
      expect(cubit.state.snapshot?.totals.online, 1);

      events.controller.add(null);
      await Future<void>.delayed(Duration.zero);
      events.controller.add(null);
      events.controller.add(null);
      await Future<void>.delayed(Duration.zero);
      expect(calls, 2, reason: 'una sola petición en vuelo');
      gate.complete();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(calls, 3, reason: 'los avisos acumulados se agrupan en una recarga');
      expect(cubit.state.snapshot?.totals.online, 3);

      events.controller.addError(Exception('canal caído'));
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.live, isFalse, reason: 'sin canal: actualización periódica');
      await cubit.close();
    });

    test('cambiar la resolución pide la nueva y el error no borra la instantánea', () async {
      when(() => api.adminTower(resolution: 8)).thenAnswer((_) async => _snapshot());
      when(() => api.adminTower(resolution: 6)).thenAnswer((_) async => _snapshot(resolution: 6));
      when(() => api.adminTower(resolution: 9)).thenThrow(const ApiException(null, 'network', ''));
      final cubit = TowerCubit(api, pollEvery: const Duration(hours: 1));
      await cubit.start();
      expect(cubit.state.live, isFalse);
      await cubit.setResolution(6);
      expect(cubit.state.snapshot?.resolution, 6);
      await cubit.setResolution(9);
      expect(cubit.state.error, 'Sin conexión con el servidor.');
      expect(cubit.state.snapshot?.resolution, 6);
      await cubit.close();
    });

    test('GeoJSON: anillo cerrado en [lng, lat] y propiedades para los colores', () {
      final hex = hexagonsGeoJson(_snapshot());
      final features = hex['features'] as List;
      expect(features, hasLength(2));
      final ring = ((features.first as Map)['geometry'] as Map)['coordinates'][0] as List;
      expect(ring.first, [-74.031, 4.701]);
      expect(ring.last, ring.first);
      expect(((features.first as Map)['properties'] as Map)['level'], 'no_supply');
      final drivers = driversGeoJson(_snapshot());
      final props = ((drivers['features'] as List).single as Map)['properties'] as Map;
      expect(props['presence'], 'busy');
      expect(props['stale'], isTrue);
    });
  });

  testWidgets('pantalla: totales, zonas con presión, conductores y resolución', (tester) async {
    tester.view.physicalSize = const Size(2800, 1600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    when(() => api.adminTower(resolution: any(named: 'resolution'))).thenAnswer((i) async {
      return _snapshot(resolution: i.namedArguments[#resolution] as int);
    });
    TowerSnapshot? drawn;
    await tester.pumpWidget(
      MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => TowerCubit(api, pollEvery: const Duration(hours: 1))..start()),
            BlocProvider(create: (_) => AdminMegaphoneCubit(api, room: () => throw UnimplementedError())),
          ],
          child: TowerPage(
            map: (s, _) {
              drawn = s;
              return const ColoredBox(
                color: Colors.black12,
                child: SizedBox.expand(key: Key('map')),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('map')), findsOneWidget);
    expect(drawn?.cells, hasLength(2));
    expect(tester.widget<Text>(find.byKey(const Key('tower.total.online'))).data, '2');
    expect(tester.widget<Text>(find.byKey(const Key('tower.total.unserved'))).data, '1');
    expect(find.text('1 con ubicación desactualizada'), findsOneWidget);
    expect(find.text('Actualización periódica'), findsOneWidget);
    expect(find.byKey(const ValueKey('tower.cell.c1')), findsOneWidget, reason: 'sin oferta se lista');
    expect(find.byKey(const ValueKey('tower.cell.c2')), findsNothing, reason: 'sin demanda no');
    expect(find.text('Sin oferta'), findsWidgets);
    expect(find.text('Carlos'), findsOneWidget);
    expect(find.textContaining('ubicación desactualizada ('), findsOneWidget);

    await tester.tap(find.text('Res. 6'));
    await tester.pumpAndSettle();
    verify(() => api.adminTower(resolution: 6)).called(1);
    expect(drawn?.resolution, 6);
  });
}
