import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_ui/kyq_ui.dart';

import 'fakes.dart';

void main() {
  group('SosButton', () {
    testWidgets('solo envía tras 2 s pulsado (FR-002)', (tester) async {
      var triggered = 0;
      var hints = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SosButton(onTriggered: () => triggered++, onShortPress: () => hints++),
            ),
          ),
        ),
      );
      final center = tester.getCenter(find.byKey(const Key('sos.button')));

      final short = await tester.startGesture(center);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1500));
      await short.up();
      await tester.pump();
      expect(triggered, 0, reason: 'pulsación corta no envía nada');
      expect(hints, 1);

      final long = await tester.startGesture(center);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1900));
      expect(triggered, 0);
      await tester.pump(const Duration(milliseconds: 200));
      expect(triggered, 1);
      await long.up();
      await tester.pump();
      expect(hints, 1, reason: 'soltar tras enviar no muestra la ayuda');
    });
  });

  group('SosActiveView', () {
    late FakeSafetyApi api;
    late SosCubit cubit;

    Future<void> pump(WidgetTester tester, {bool keepOpen = false, VoidCallback? onCall}) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider.value(
              value: cubit,
              child: SosActiveView(onCallEmergency: onCall ?? () {}, keepOpenWarning: keepOpen, onSetupPin: () {}),
            ),
          ),
        ),
      );
    }

    setUp(() {
      api = FakeSafetyApi();
      cubit = SosCubit(
        api: api,
        tripId: 't1',
        location: FakeSosLocation(),
        voice: FakeVoiceRoom.new,
        mic: FakeMic(),
        interval: const Duration(hours: 1),
      );
    });

    tearDown(() => cubit.close());

    testWidgets('alerta enviada y luego "Ayuda en camino" al tomarla un operador', (tester) async {
      await tester.runAsync(cubit.raise);
      await pump(tester, keepOpen: true);
      expect(find.text('Alerta enviada'), findsOneWidget);
      expect(find.byKey(const Key('sos.keepOpen')), findsOneWidget, reason: 'aviso de no cerrar la app (pasajero)');
      expect(find.byKey(const Key('sos.voice')), findsOneWidget);

      api.onLocations = (_) async => alert(status: SosStatus.claimed, operator: true);
      await tester.runAsync(() async {
        await cubit.sendLocation();
        await Future<void>.delayed(Duration.zero);
      });
      await tester.pump();
      expect(find.text('Ayuda en camino: un operador te escucha'), findsOneWidget);
    });

    testWidgets('a los 60 s sin operador lo dice y ofrece el 123', (tester) async {
      var calls = 0;
      await tester.runAsync(cubit.raise);
      api.onLocations = (_) async => alert(escalated: true);
      await tester.runAsync(cubit.sendLocation);
      await pump(tester, onCall: () => calls++);
      expect(find.text('Seguimos intentando conectar con un operador'), findsOneWidget);
      await tester.tap(find.byKey(const Key('sos.call123')));
      expect(calls, 1);
    });

    testWidgets('"Estoy bien" pide el PIN; uno incorrecto deja la alerta abierta', (tester) async {
      api.onCancel = (pin) async => throw const ApiException(403, 'invalid_pin', 'PIN incorrecto');
      await tester.runAsync(cubit.raise);
      await pump(tester);
      await tester.tap(find.byKey(const Key('sos.imOk')));
      await tester.pumpAndSettle();
      expect(find.text('Cancelar alerta'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('sos.pin')), '0000');
      await tester.pump();
      await tester.tap(find.byKey(const Key('sos.pin.confirm')));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();
      expect(api.cancels, ['0000']);
      expect(find.text('PIN incorrecto. La alerta sigue activa.'), findsOneWidget);
      expect(find.byKey(const Key('sos.imOk')), findsOneWidget);
    });

    testWidgets('al cerrar sin PIN pide configurarlo', (tester) async {
      api.onLocations = (_) async => throw const ApiException(410, 'sos_closed', 'cerrada');
      await tester.runAsync(cubit.raise);
      await tester.runAsync(cubit.sendLocation);
      await pump(tester);
      expect(find.text('Alerta cerrada'), findsOneWidget);
      expect(find.byKey(const Key('sos.setupPin')), findsOneWidget);
      await tester.tap(find.byKey(const Key('sos.dismiss')));
      await tester.pump();
      expect(cubit.state.phase, SosPhase.idle);
    });
  });

  testWidgets('ShareTripButton abre el menú de compartir con el enlace', (tester) async {
    final api = FakeSafetyApi();
    String? shared;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ShareTripButton(api: api, tripId: 't1', share: (text) async => shared = text),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('trip.share')));
    await tester.pump();
    expect(shared, 'Sigue mi viaje en Kyq en vivo: https://kyq.test/s/abc');
  });
}
