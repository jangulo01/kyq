import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_ptt/kyq_ptt.dart';
import 'package:kyq_ptt/testing.dart';

void main() {
  Future<FakePtt> pump(WidgetTester tester, {FakePtt? ptt}) async {
    final p = ptt ?? FakePtt();
    await p.controller.start();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: PttButton(controller: p.controller, remoteName: 'Carlos'),
          ),
        ),
      ),
    );
    addTearDown(p.controller.close);
    return p;
  }

  String label(WidgetTester tester) => tester.widget<Text>(find.byKey(const Key('ptt.label'))).data!;

  testWidgets('mantener pulsado habla y soltar termina', (tester) async {
    final ptt = await pump(tester);
    expect(label(tester), 'Mantén pulsado para hablar');

    final gesture = await tester.startGesture(tester.getCenter(find.byKey(const Key('ptt.button'))));
    await tester.pump();
    expect(label(tester), 'Hablando… suelta para terminar');
    expect(ptt.room.micEnabled, isTrue);

    await gesture.up();
    await tester.pump();
    expect(label(tester), 'Mantén pulsado para hablar');
    expect(ptt.room.micEnabled, isFalse);
    expect(ptt.api.floorReleases, 1);
  });

  testWidgets('muestra quién habla', (tester) async {
    final ptt = await pump(tester);
    ptt.room.emit(const VoiceDataReceived({'type': 'floor.taken', 'user_id': 'd1'}));
    await tester.pump();
    expect(label(tester), 'Habla Carlos');

    ptt.room.emit(const VoiceDataReceived({'type': 'floor.released'}));
    await tester.pump();
    expect(label(tester), 'Mantén pulsado para hablar');
  });

  testWidgets('turno ocupado avisa de esperar', (tester) async {
    final ptt = FakePtt()..api.onRequestFloor = () async => throw const PttFloorBusy();
    await pump(tester, ptt: ptt);

    final gesture = await tester.startGesture(tester.getCenter(find.byKey(const Key('ptt.button'))));
    await tester.pump();
    expect(label(tester), 'Carlos está hablando. Espera a que termine.');
    await gesture.up();
    await tester.pump(ptt.controller.busyFor);
    expect(label(tester), 'Mantén pulsado para hablar');
  });

  testWidgets('micrófono denegado para siempre ofrece abrir los ajustes', (tester) async {
    final ptt = FakePtt(mic: FakeMicPermission(granted: false, onRequest: MicAccess.permanentlyDenied));
    await pump(tester, ptt: ptt);

    await tester.tap(find.byKey(const Key('ptt.button')));
    await tester.pump();
    expect(label(tester), 'Activa el micrófono en los ajustes para hablar.');

    await tester.tap(find.byKey(const Key('ptt.settings')));
    expect(ptt.mic.settingsOpened, 1);
  });

  testWidgets('TripPttBar conecta al aceptar y se oculta al cerrar el canal', (tester) async {
    final ptt = FakePtt();
    addTearDown(ptt.controller.close);
    Widget bar(TripStatus status) => MaterialApp(
      home: Scaffold(
        bottomNavigationBar: TripPttBar(controller: ptt.controller, status: status, remoteName: 'Carlos'),
      ),
    );

    await tester.pumpWidget(bar(TripStatus.farePending));
    await tester.pump();
    expect(find.byType(PttButton), findsNothing);
    expect(ptt.api.tokenCalls, 0);

    await tester.pumpWidget(bar(TripStatus.accepted));
    await tester.pump();
    await tester.pump();
    expect(ptt.room.connects, 1);
    expect(find.text('Mantén pulsado para hablar'), findsOneWidget);

    await tester.pumpWidget(bar(TripStatus.completed));
    await tester.pump();
    expect(find.byType(PttButton), findsOneWidget);

    await ptt.controller.closeChannel();
    await tester.pump();
    expect(find.byType(PttButton), findsNothing);
  });

  testWidgets('TripPttBar cierra el canal si el viaje se cancela', (tester) async {
    final ptt = FakePtt();
    addTearDown(ptt.controller.close);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: TripPttBar(controller: ptt.controller, status: TripStatus.cancelled),
        ),
      ),
    );
    await tester.pump();
    expect(ptt.controller.state.status, PttStatus.closed);
    expect(find.byType(PttButton), findsNothing);
  });
}
