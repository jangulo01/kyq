// Regresiones encontradas probando en un Redmi Note 13 Pro+ contra el backend real.
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_realtime/kyq_realtime.dart';
import 'package:kyq_rider_app/request/request_cubit.dart';
import 'package:kyq_rider_app/trip/trip_cubit.dart';
import 'package:mocktail/mocktail.dart';

import 'support/fakes.dart';

const _here = GeoPoint(lat: 4.65, lng: -74.05);
const _there = GeoPoint(lat: 4.70, lng: -74.04);

Trip _trip(TripStatus status) => Trip(
  id: 't1',
  status: status,
  passengerId: 'p1',
  driverId: 'd1',
  pickup: _here,
  dropoff: _there,
  distanceM: 400,
  durationS: 60,
  currency: 'COP',
  suggestedFareMinor: 700000,
  agreedFareMinor: status == TripStatus.requested ? null : 700000,
);

void main() {
  late MockApi api;
  late FakeRealtime realtime;

  setUpAll(() => registerFallbackValue(_here));

  setUp(() {
    api = MockApi();
    realtime = FakeRealtime();
  });

  test('nuestra propia solicitud no dispara el aviso "dejó de estar libre"', () async {
    when(() => api.quote(any(), any())).thenAnswer(
      (_) async => const FareQuote(distanceM: 400, durationS: 60, suggestedFareMinor: 700000, currency: 'COP'),
    );
    when(
      () => api.requestTrip(
        driverId: 'd1',
        pickup: any(named: 'pickup'),
        dropoff: any(named: 'dropoff'),
      ),
    ).thenAnswer((_) async {
      // El backend marca al conductor ocupado antes de responder a la solicitud.
      realtime.emit(
        Channels.driverPresence('d1'),
        DriverPresenceChanged(DateTime.now(), driverId: 'd1', presence: 'busy'),
      );
      return _trip(TripStatus.requested);
    });
    final cubit = RequestCubit(
      api: api,
      location: FakeLocation(position: _here),
      realtime: realtime,
      driverId: 'd1',
      driverName: 'Carlos',
    );
    await cubit.start();
    await cubit.setPoint(_there);
    await cubit.request();
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.tripId, 't1');
    expect(cubit.state.error, isNull);
    await cubit.close();
  });

  test('con el viaje cargado, un refresco fallido reintenta en silencio', () {
    fakeAsync((async) {
      var calls = 0;
      when(() => api.getTrip('t1')).thenAnswer((_) async {
        calls++;
        if (calls == 2) throw const ApiException(null, 'network', 'sin conexión');
        return _trip(calls == 1 ? TripStatus.inProgress : TripStatus.completed);
      });
      final cubit = TripCubit(api: api, realtime: realtime, tripId: 't1');
      cubit.refresh();
      async.flushMicrotasks();
      expect(cubit.state.trip?.status, TripStatus.inProgress);

      cubit.refresh(); // falla: red cortada en segundo plano
      async.flushMicrotasks();
      expect(cubit.state.error, isNull, reason: 'no se muestra error con el viaje en pantalla');

      async.elapse(TripCubit.retryAfter);
      async.flushMicrotasks();
      expect(cubit.state.trip?.status, TripStatus.completed);
      expect(cubit.state.error, isNull);
      cubit.close();
    });
  });

  test('sin viaje cargado, el fallo sí se muestra', () async {
    when(() => api.getTrip('t1')).thenThrow(const ApiException(null, 'network', 'sin conexión'));
    final cubit = TripCubit(api: api, realtime: realtime, tripId: 't1');
    await cubit.refresh();
    expect(cubit.state.error, 'No pudimos actualizar el viaje.');
    await cubit.close();
  });
}
