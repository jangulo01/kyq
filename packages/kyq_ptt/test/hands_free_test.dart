import 'package:flutter_test/flutter_test.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_ptt/kyq_ptt.dart';
import 'package:kyq_ptt/testing.dart';

/// RN-KYQ-012: botón físico (Bluetooth, manos libres, volante) y burbuja flotante.
void main() {
  late FakeHandsFreePlatform platform;
  late HandsFreePtt handsFree;
  late FakePtt trip;
  late DateTime now;

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  setUp(() async {
    now = DateTime(2026, 10, 27, 12);
    platform = FakeHandsFreePlatform();
    handsFree = HandsFreePtt(platform, bubble: true, clock: () => now);
    trip = FakePtt();
    await trip.controller.start();
  });

  tearDown(() async {
    await handsFree.dispose();
    await trip.controller.close();
  });

  test('sin canal abierto no captura el botón ni muestra burbuja (FR-013)', () async {
    handsFree.setForeground(false);
    platform.emit(HandsFreeSignal.buttonDown);
    platform.emit(HandsFreeSignal.buttonUp);
    await settle();
    expect(platform.mediaActive, isFalse);
    expect(platform.bubble, isNull);
    expect(trip.api.floorRequests, 0);
  });

  test('un clic corto alterna: abre el turno y el siguiente clic lo suelta (FR-012)', () async {
    handsFree.attach(trip.controller);
    expect(platform.mediaActive, isTrue);

    platform.emit(HandsFreeSignal.buttonDown);
    now = now.add(const Duration(milliseconds: 80));
    platform.emit(HandsFreeSignal.buttonUp);
    await settle();
    expect(trip.controller.state.status, PttStatus.talking, reason: 'el clic deja el micrófono abierto');
    expect(trip.tones.played, [PttTone.start]);

    platform.emit(HandsFreeSignal.buttonDown);
    await settle();
    platform.emit(HandsFreeSignal.buttonUp);
    await settle();
    expect(trip.controller.state.status, PttStatus.idle);
    expect(trip.api.floorReleases, 1);
    expect(trip.tones.played, [PttTone.start, PttTone.end]);
  });

  test('mantener el botón habla mientras se mantiene (FR-012)', () async {
    handsFree.attach(trip.controller);
    platform.emit(HandsFreeSignal.buttonDown);
    await settle();
    expect(trip.controller.state.status, PttStatus.talking);
    now = now.add(const Duration(seconds: 2));
    platform.emit(HandsFreeSignal.buttonUp);
    await settle();
    expect(trip.controller.state.status, PttStatus.idle);

    // El siguiente clic vuelve a abrir: no quedó "enganchado".
    platform.emit(HandsFreeSignal.buttonDown);
    await settle();
    expect(trip.controller.state.status, PttStatus.talking);
  });

  test('si el turno caducó, el siguiente clic vuelve a pedirlo', () async {
    handsFree.attach(trip.controller);
    platform.emit(HandsFreeSignal.buttonDown);
    platform.emit(HandsFreeSignal.buttonUp);
    await settle();
    await trip.controller.release(); // p. ej. el turno se soltó solo al caducar
    platform.emit(HandsFreeSignal.buttonDown);
    await settle();
    expect(trip.controller.state.status, PttStatus.talking);
    expect(trip.api.floorRequests, 2);
  });

  test('botón desactivado en ajustes: no se captura (FR-015)', () async {
    handsFree
      ..configure(mediaButton: false)
      ..attach(trip.controller);
    expect(platform.mediaActive, isFalse);
    platform.emit(HandsFreeSignal.buttonDown);
    await settle();
    expect(trip.api.floorRequests, 0);
  });

  test('burbuja solo en segundo plano, con color por estado, y mantener para hablar (FR-014)', () async {
    handsFree.attach(trip.controller);
    expect(platform.bubble, isNull, reason: 'con Kyq delante basta el botón de la pantalla');
    handsFree.setForeground(false);
    expect(platform.bubble, BubbleLook.idle);

    platform.emit(HandsFreeSignal.bubbleDown);
    await settle();
    expect(platform.bubble, BubbleLook.talking);
    platform.emit(HandsFreeSignal.bubbleUp);
    await settle();
    expect(platform.bubble, BubbleLook.idle);
    expect(trip.api.floorReleases, 1);

    trip.room.emit(const VoiceDataReceived({'type': 'floor.taken', 'user_id': 'pasajero'}));
    await settle();
    expect(platform.bubble, BubbleLook.remoteTalking);

    handsFree.setForeground(true);
    expect(platform.bubble, isNull);
    handsFree
      ..setForeground(false)
      ..configure(bubble: false);
    expect(platform.bubble, isNull, reason: 'burbuja desactivada (FR-015)');
  });

  test('la consulta activa toma el botón y al cerrarse vuelve al viaje', () async {
    final consult = FakePtt(
      api: FakePttApi(
        credentials: const PttCredentials(url: 'wss://v', token: 't', room: 'pre-1'),
      ),
    );
    await consult.controller.start();
    handsFree
      ..attach(trip.controller)
      ..attach(consult.controller)
      ..setForeground(false);

    platform.emit(HandsFreeSignal.bubbleDown);
    await settle();
    expect(consult.api.floorRequests, 1);
    expect(trip.api.floorRequests, 0);
    platform.emit(HandsFreeSignal.bubbleUp);
    await settle();

    await consult.controller.closeChannel();
    await settle();
    expect(handsFree.target, trip.controller);
    platform.emit(HandsFreeSignal.bubbleDown);
    await settle();
    expect(trip.api.floorRequests, 1);
    platform.emit(HandsFreeSignal.bubbleUp);

    handsFree
      ..detach(trip.controller)
      ..detach(consult.controller);
    await settle();
    expect(platform.mediaActive, isFalse);
    expect(platform.bubble, isNull);
    await consult.controller.close();
  });
}
