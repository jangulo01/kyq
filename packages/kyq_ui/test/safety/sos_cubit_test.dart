import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_ptt/kyq_ptt.dart';
import 'package:kyq_ui/kyq_ui.dart';

import 'fakes.dart';

void main() {
  late FakeSafetyApi api;
  late FakeVoiceRoom room;
  late FakeSosLocation gps;
  late SosCubit cubit;

  SosCubit build({FakeMic? mic}) =>
      SosCubit(api: api, tripId: 't1', location: gps, voice: () => room, mic: mic ?? FakeMic());

  setUp(() {
    api = FakeSafetyApi();
    room = FakeVoiceRoom();
    gps = FakeSosLocation();
  });

  test('RN-KYQ-015: alerta, ubicación cada segundo y micrófono abierto sin pasos extra', () {
    fakeAsync((async) {
      cubit = build();
      cubit.raise();
      async.flushMicrotasks();
      expect(cubit.state.phase, SosPhase.active);
      expect(cubit.state.needsPin, isTrue);
      expect(api.raised.single?.lat, 4.61, reason: 'la alerta lleva la última ubicación');
      expect(room.connected, isTrue);
      expect(room.mic, isTrue, reason: 'en emergencia no hay turno: micrófono abierto');
      expect(cubit.state.voice, SosVoiceStatus.connected);

      async.elapse(const Duration(seconds: 3));
      expect(api.batches, hasLength(3), reason: '1 Hz');
      expect(api.batches.every((b) => b.length == 1), isTrue);

      api.onLocations = (_) async => alert(status: SosStatus.claimed, operator: true);
      async.elapse(const Duration(seconds: 1));
      expect(cubit.state.operatorConnected, isTrue);
      cubit.close();
    });
  });

  test('sin red guarda hasta 5 puntos y los envía en un lote al volver', () {
    fakeAsync((async) {
      cubit = build();
      cubit.raise();
      async.flushMicrotasks();
      api.onLocations = (_) async => throw const ApiException(null, 'network', 'sin conexión');
      async.elapse(const Duration(seconds: 8));
      expect(cubit.state.offline, isTrue);
      api.onLocations = (_) async => alert();
      async.elapse(const Duration(seconds: 1));
      expect(api.batches.last, hasLength(SosCubit.maxBatch));
      expect(cubit.state.offline, isFalse);
      cubit.close();
    });
  });

  test('el cierre del operador (410) detiene la ubicación y la voz', () {
    fakeAsync((async) {
      cubit = build();
      cubit.raise();
      async.flushMicrotasks();
      api.onLocations = (_) async => throw const ApiException(410, 'sos_closed', 'cerrada');
      async.elapse(const Duration(seconds: 1));
      expect(cubit.state.phase, SosPhase.closed);
      expect(cubit.state.cancelledByUser, isFalse);
      expect(room.connected, isFalse);
      expect(gps.stopped, isTrue);
      final sent = api.batches.length;
      async.elapse(const Duration(seconds: 5));
      expect(api.batches.length, sent, reason: 'deja de enviar (US2-4)');
      cubit.close();
    });
  });

  test('cancelar exige el PIN: incorrecto deja la alerta activa', () {
    fakeAsync((async) {
      cubit = build();
      cubit.raise();
      async.flushMicrotasks();
      api.onCancel = (pin) async {
        if (pin != '2468') throw const ApiException(403, 'invalid_pin', 'PIN incorrecto');
      };
      cubit.cancel('0000');
      async.flushMicrotasks();
      expect(cubit.state.phase, SosPhase.active);
      expect(cubit.state.message, 'PIN incorrecto. La alerta sigue activa.');

      cubit.cancel('2468');
      async.flushMicrotasks();
      expect(cubit.state.phase, SosPhase.closed);
      expect(cubit.state.cancelledByUser, isTrue);
      expect(room.connected, isFalse);
      cubit.close();
    });
  });

  test('fuera del viaje no hay alerta y se ofrece el 123', () async {
    api.onRaise = (_) async => throw const ApiException(409, 'sos_unavailable', 'fuera');
    cubit = build();
    await cubit.raise();
    expect(cubit.state.phase, SosPhase.idle);
    expect(cubit.state.message, contains('123'));
    await cubit.close();
  });

  test('sin datos móviles reintenta enviar la alerta cada pocos segundos', () {
    fakeAsync((async) {
      var fail = true;
      api.onRaise = (_) async {
        if (fail) throw const ApiException(null, 'network', 'sin conexión');
        return SosRaise(alert: alert(), voice: voice);
      };
      cubit = build();
      cubit.raise();
      async.flushMicrotasks();
      expect(cubit.state.phase, SosPhase.sending);
      expect(cubit.state.offline, isTrue);
      fail = false;
      async.elapse(const Duration(seconds: 5));
      expect(cubit.state.phase, SosPhase.active);
      expect(api.raised, hasLength(2));
      cubit.close();
    });
  });

  test('sin GPS la alerta se envía igual', () async {
    gps.available = false;
    cubit = build();
    await cubit.raise();
    expect(api.raised.single, isNull);
    expect(cubit.state.phase, SosPhase.active);
    await cubit.close();
  });

  test('si LiveKit falla, la alerta sigue y la voz se reintenta', () {
    fakeAsync((async) {
      room.failConnect = true;
      cubit = build();
      cubit.raise();
      async.flushMicrotasks();
      expect(cubit.state.phase, SosPhase.active);
      expect(cubit.state.voice, SosVoiceStatus.unavailable);
      room.failConnect = false;
      async.elapse(const Duration(seconds: 5));
      expect(cubit.state.voice, SosVoiceStatus.connected);
      room.emit(const VoiceConnectionChanged(VoiceConnection.reconnecting));
      async.flushMicrotasks();
      expect(cubit.state.voice, SosVoiceStatus.connecting);
      cubit.close();
    });
  });

  test('retoma la alerta abierta del viaje al reabrir la pantalla', () async {
    api.active = alert(status: SosStatus.claimed, operator: true);
    cubit = build();
    await cubit.resume();
    expect(cubit.state.phase, SosPhase.active);
    expect(cubit.state.operatorConnected, isTrue);
    await cubit.close();
  });

  test('011: Emergencia de Radio sin viaje: misma voz, ubicación cada segundo y cancelar con PIN', () {
    fakeAsync((async) {
      final noTrip = SosAlertSelf(id: 'al9', status: SosStatus.open, createdAt: DateTime.utc(2026, 10, 28));
      final points = <SosPoint?>[];
      cubit = SosCubit(
        api: api,
        tripId: '',
        location: gps,
        voice: () => room,
        mic: FakeMic(),
        raiser: (fix) async {
          points.add(fix);
          return noTrip;
        },
      );
      cubit.raise();
      async.flushMicrotasks();
      expect(points.single?.lat, 4.61, reason: 'lleva la ubicación');
      expect(api.raised, isEmpty, reason: 'no usa el SOS de viaje');
      expect(cubit.state.phase, SosPhase.active);
      expect(cubit.state.alert?.tripId, isNull);
      expect(room.connected, isTrue);
      async.elapse(const Duration(seconds: 2));
      expect(api.batches, hasLength(2));
      cubit.close();
    });
  });

  test('011: Radio retoma una alerta abierta sin viaje', () async {
    api.active = SosAlertSelf(id: 'al9', status: SosStatus.open, createdAt: DateTime.utc(2026, 10, 28));
    cubit = SosCubit(
      api: api,
      tripId: '',
      location: gps,
      voice: () => room,
      mic: FakeMic(),
      raiser: (_) async => throw StateError('no debe levantar otra'),
    );
    await cubit.resume();
    expect(cubit.state.phase, SosPhase.active);
    expect(cubit.state.alert?.id, 'al9');
    await cubit.close();

    // El SOS de un viaje no retoma la alerta sin viaje.
    final trip = build();
    await trip.resume();
    expect(trip.state.phase, isNot(SosPhase.active));
    await trip.close();
  });
}
