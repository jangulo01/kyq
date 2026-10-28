import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_realtime/kyq_realtime.dart';
import 'package:kyq_rider_app/request/location_source.dart';
import 'package:kyq_rider_app/request/request_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../support/fakes.dart';

const _here = GeoPoint(lat: 4.65, lng: -74.05);
const _there = GeoPoint(lat: 4.70, lng: -74.04);
const _quote = FareQuote(distanceM: 6200, durationS: 900, suggestedFareMinor: 1470000, currency: 'COP');

Trip _trip(String id) => Trip(
  id: id,
  status: TripStatus.requested,
  passengerId: 'p1',
  driverId: 'd1',
  pickup: _here,
  dropoff: _there,
  distanceM: 6200,
  durationS: 900,
  currency: 'COP',
  suggestedFareMinor: 1470000,
);

void main() {
  late MockApi api;
  late FakeRealtime realtime;

  setUpAll(() => registerFallbackValue(_here));

  setUp(() {
    api = MockApi();
    realtime = FakeRealtime();
    when(() => api.quote(any(), any(), driverId: any(named: 'driverId'))).thenAnswer((_) async => _quote);
  });

  RequestCubit build({LocationSource? location}) => RequestCubit(
    api: api,
    location: location ?? FakeLocation(position: _here),
    realtime: realtime,
    driverId: 'd1',
    driverName: 'Carlos',
  );

  blocTest<RequestCubit, RequestState>(
    'origen por ubicación, destino por toque, cotiza y pide el viaje',
    setUp: () => when(
      () => api.requestTrip(driverId: 'd1', pickup: _here, dropoff: _there),
    ).thenAnswer((_) async => _trip('t1')),
    build: build,
    act: (c) async {
      await c.start();
      await c.setPoint(_there);
      await c.request();
    },
    verify: (c) {
      expect(c.state.pickup, _here);
      expect(c.state.dropoff, _there);
      expect(c.state.quote, _quote);
      expect(c.state.tripId, 't1');
      verify(() => api.quote(_here, _there, driverId: 'd1')).called(1);
    },
  );

  blocTest<RequestCubit, RequestState>(
    'sin permiso de ubicación pide explicación antes de solicitarlo',
    build: () => build(location: FakeLocation(granted: false)),
    act: (c) => c.start(),
    verify: (c) {
      expect(c.state.needsLocationPermission, isTrue);
      expect(c.state.pickup, isNull);
    },
  );

  blocTest<RequestCubit, RequestState>(
    'ubicación no disponible pasa a marcar el origen en el mapa',
    build: () => build(location: FakeLocation(failure: const LocationUnavailable('Sin GPS'))),
    act: (c) async {
      await c.locate();
      await c.setPoint(_here);
    },
    verify: (c) {
      expect(c.state.pickup, _here);
      expect(c.state.editing, RequestPoint.dropoff);
    },
  );

  blocTest<RequestCubit, RequestState>(
    'driver_not_free muestra el aviso y bloquea el botón',
    setUp: () => when(
      () => api.requestTrip(
        driverId: any(named: 'driverId'),
        pickup: any(named: 'pickup'),
        dropoff: any(named: 'dropoff'),
      ),
    ).thenThrow(const ApiException(409, 'driver_not_free', 'busy')),
    build: build,
    act: (c) async {
      await c.start();
      await c.setPoint(_there);
      await c.request();
    },
    verify: (c) {
      expect(c.state.tripId, isNull);
      expect(c.state.driverFree, isFalse);
      expect(c.state.canRequest, isFalse);
      expect(c.state.error, contains('Carlos ya no está libre'));
    },
  );

  blocTest<RequestCubit, RequestState>(
    'account_suspended (007, FR-016) explica que la cuenta está suspendida',
    setUp: () => when(
      () => api.requestTrip(
        driverId: any(named: 'driverId'),
        pickup: any(named: 'pickup'),
        dropoff: any(named: 'dropoff'),
      ),
    ).thenThrow(const ApiException(403, 'account_suspended', 'x')),
    build: build,
    act: (c) async {
      await c.start();
      await c.setPoint(_there);
      await c.request();
    },
    verify: (c) {
      expect(c.state.tripId, isNull);
      expect(c.state.error, contains('Tu cuenta está suspendida'));
    },
  );

  blocTest<RequestCubit, RequestState>(
    'no_route muestra un mensaje en español y no hay tarifa',
    setUp: () => when(
      () => api.quote(any(), any(), driverId: any(named: 'driverId')),
    ).thenThrow(const ApiException(422, 'no_route', 'x')),
    build: build,
    act: (c) async {
      await c.start();
      await c.setPoint(_there);
    },
    verify: (c) {
      expect(c.state.quote, isNull);
      expect(c.state.error, contains('No encontramos una ruta'));
    },
  );

  blocTest<RequestCubit, RequestState>(
    'si el conductor se ocupa mientras se arma la solicitud, no se envía',
    build: build,
    act: (c) async {
      await c.start();
      await c.setPoint(_there);
      realtime.emit(
        Channels.driverPresence('d1'),
        DriverPresenceChanged(DateTime(2026), driverId: 'd1', presence: 'busy'),
      );
      await Future<void>.delayed(Duration.zero);
      await c.request();
    },
    verify: (c) {
      expect(c.state.driverFree, isFalse);
      verifyNever(
        () => api.requestTrip(
          driverId: any(named: 'driverId'),
          pickup: any(named: 'pickup'),
          dropoff: any(named: 'dropoff'),
        ),
      );
    },
  );
}
