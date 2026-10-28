import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kyq_admin_web/emergencies/alert_detail_page.dart';
import 'package:kyq_admin_web/emergencies/alert_sound.dart';
import 'package:kyq_admin_web/emergencies/emergencies_page.dart';
import 'package:kyq_admin_web/emergencies/emergency_cubits.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_ptt/kyq_ptt.dart';
import 'package:kyq_realtime/kyq_realtime.dart';
import 'package:mocktail/mocktail.dart';

class _MockApi extends Mock implements KyqApiClient {}

class _FakeRealtime implements OpsRealtime {
  final _channels = <String, StreamController<RealtimeEvent>>{};

  @override
  Stream<RealtimeEvent> subscribe(String channel) =>
      (_channels[channel] ??= StreamController<RealtimeEvent>.broadcast()).stream;

  void emit(String channel, RealtimeEvent e) => _channels[channel]?.add(e);
}

class _Sound implements AlertSound {
  int plays = 0;

  @override
  Future<void> play() async => plays++;
}

class _Voice implements VoiceRoom {
  bool connected = false;
  bool mic = false;

  @override
  Stream<VoiceRoomEvent> get events => const Stream.empty();

  @override
  String? get localIdentity => 'op1';

  @override
  Future<void> connect(String url, String token) async => connected = true;

  @override
  Future<void> setMicrophoneEnabled(bool enabled) async => mic = enabled;

  @override
  Future<void> sendData(Map<String, Object?> message) async {}

  @override
  Future<void> disconnect() async => connected = false;
}

final _created = DateTime.now().toUtc().subtract(const Duration(seconds: 42));

SosAlertSummary _summary({
  String id = 'al1',
  SosStatus status = SosStatus.open,
  String? claimedBy,
  bool noPin = false,
}) => SosAlertSummary(
  id: id,
  tripId: 't1',
  raisedRole: SosRole.passenger,
  raisedByName: 'Ana',
  status: status,
  cancelWithoutPin: noPin,
  claimedBy: claimedBy,
  claimedByName: claimedBy == null ? null : (claimedBy == 'op1' ? 'Lucía' : 'Juan'),
  createdAt: _created,
  lastLocation: const SosLocation(lat: 4.61, lng: -74.07),
);

SosAlertDetail _detail({SosStatus status = SosStatus.open, String? claimedBy, List<SosNote> notes = const []}) =>
    SosAlertDetail(
      id: 'al1',
      tripId: 't1',
      raisedRole: SosRole.passenger,
      raisedByName: 'Ana',
      status: status,
      claimedBy: claimedBy,
      claimedByName: claimedBy == null ? null : 'Lucía',
      createdAt: _created,
      lastLocation: SosLocation(lat: 4.611234, lng: -74.071234, accuracyM: 8, at: DateTime.now().toUtc()),
      raisedByPhone: '+573200000002',
      emergencyContacts: const [EmergencyContact(name: 'Mamá', phoneE164: '+573001110001')],
      trip: const SosTrip(
        status: 'IN_PROGRESS',
        pickup: GeoPoint(lat: 4.6, lng: -74.08),
        dropoff: GeoPoint(lat: 4.65, lng: -74.05),
      ),
      passenger: const SosPerson(userId: 'p1', name: 'Ana'),
      driver: const SosDriver(userId: 'd1', name: 'Carlos', vehiclePlate: 'KYQ001', vehicleDescription: 'Kia gris'),
      track: const [SosLocation(lat: 4.61, lng: -74.07)],
      notes: notes,
    );

Widget _fakeMap(SosAlertDetail alert) =>
    ColoredBox(key: const Key('fake.map'), color: Colors.blueGrey, child: Text('${alert.track.length} puntos'));

void main() {
  setUpAll(() => registerFallbackValue(SosOutcome.resolved));

  late _MockApi api;
  late _FakeRealtime realtime;

  setUp(() {
    api = _MockApi();
    realtime = _FakeRealtime();
  });

  group('cola', () {
    testWidgets('alerta nueva: aparece arriba con aviso sonoro y tiempo de espera (US2-1)', (tester) async {
      final sound = _Sound();
      var alerts = [_summary(noPin: true)];
      when(() => api.opsOpenAlerts()).thenAnswer((_) async => alerts);
      when(() => api.opsOnDuty()).thenAnswer((_) async => true);
      when(() => api.opsSetOnDuty(false)).thenAnswer((_) async => false);
      final queue = SosQueueCubit(api, realtime, sound, poll: const Duration(hours: 1));
      addTearDown(queue.close);

      await tester.pumpWidget(
        MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider.value(value: queue..load()),
              BlocProvider(create: (_) => SosHistoryCubit(api)),
            ],
            child: const EmergenciesPage(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.text('Pasajero: Ana'), findsOneWidget);
      expect(find.text('Sin tomar'), findsOneWidget);
      expect(find.byKey(const Key('ops.alert.noPin')), findsOneWidget, reason: 'posible coacción');
      expect(find.textContaining('00:4'), findsOneWidget, reason: 'tiempo de espera');
      expect(sound.plays, 0, reason: 'la carga inicial no suena');

      alerts = [_summary(), _summary(id: 'al2')];
      realtime.emit(
        Channels.opsSos,
        SosCreated(DateTime.now(), alertId: 'al2', tripId: 't2', raisedRole: 'driver', raisedByName: 'Carlos'),
      );
      await tester.pump();
      await tester.pump();
      expect(find.byKey(const Key('ops.alert.al2')), findsOneWidget);
      expect(sound.plays, 1, reason: 'aviso sonoro con la alerta nueva');

      await tester.tap(find.byKey(const Key('ops.duty')));
      await tester.pump();
      verify(() => api.opsSetOnDuty(false)).called(1);
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(queue.close);
    });

    testWidgets('sin permiso de operador lo explica', (tester) async {
      when(() => api.opsOpenAlerts()).thenThrow(const ApiException(403, 'not_emergency_operator', 'sin permiso'));
      final queue = SosQueueCubit(api, realtime, _Sound(), poll: const Duration(hours: 1));
      addTearDown(queue.close);
      await tester.pumpWidget(
        MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider.value(value: queue..load()),
              BlocProvider(create: (_) => SosHistoryCubit(api)),
            ],
            child: const EmergenciesPage(),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Tu cuenta no tiene el permiso de operador de emergencias.'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(queue.close);
    });
  });

  group('detalle', () {
    late _Voice voice;
    late List<String> opened;

    setUp(() {
      voice = _Voice();
      opened = [];
    });

    Future<SosDetailCubit> pump(WidgetTester tester, {required String operatorId}) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final cubit = SosDetailCubit(api, 'al1', operatorId: operatorId, realtime: realtime, voice: () => voice);
      addTearDown(cubit.close);
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: cubit..load(),
            child: AlertDetailPage(map: _fakeMap, openUrl: (url) async => opened.add(url)),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      return cubit;
    }

    testWidgets('tomar, hablar, notas y cerrar con desenlace (US2 independiente)', (tester) async {
      var detail = _detail();
      when(() => api.opsAlert('al1')).thenAnswer((_) async => detail);
      when(
        () => api.opsVoiceToken('al1'),
      ).thenAnswer((_) async => const SosVoice(url: 'ws://lk', token: 'op', room: 'sos-al1'));
      when(() => api.opsClaim('al1')).thenAnswer((_) async {
        detail = _detail(status: SosStatus.claimed, claimedBy: 'op1');
        return _summary(status: SosStatus.claimed, claimedBy: 'op1');
      });
      when(() => api.opsAddNote('al1', any())).thenAnswer((inv) async {
        final note = SosNote(
          id: 'n1',
          operatorId: 'op1',
          operatorName: 'Lucía',
          body: inv.positionalArguments[1] as String,
          createdAt: DateTime.utc(2026, 10, 27, 22, 1),
        );
        detail = detail.copyWith(notes: [...detail.notes, note]);
        return note;
      });
      when(() => api.opsClose('al1', any())).thenAnswer((_) async {
        detail = detail.copyWith(status: SosStatus.closed, outcome: SosOutcome.falseAlarm);
      });

      await pump(tester, operatorId: 'op1');
      expect(find.byKey(const Key('fake.map')), findsOneWidget);
      expect(find.textContaining('Placa KYQ001'), findsOneWidget, reason: 'datos del viaje y del vehículo (FR-009)');
      expect(find.textContaining('+573001110001'), findsOneWidget);

      await tester.tap(find.byKey(const Key('ops.listen')));
      await tester.pump();
      expect(voice.connected, isTrue, reason: 'todos los operadores pueden escuchar');
      expect(voice.mic, isFalse);

      await tester.tap(find.byKey(const Key('ops.claim')));
      await tester.pump();
      await tester.pump();
      expect(voice.mic, isTrue, reason: 'quien toma la alerta habla');
      expect(find.byKey(const Key('ops.release')), findsOneWidget);

      Object? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') copied = call.arguments;
        return null;
      });
      await tester.ensureVisible(find.byKey(const Key('ops.copyLocation')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('ops.copyLocation')));
      await tester.pump();
      await tester.pump();
      expect((copied! as Map)['text'], contains('4.611234, -74.071234'), reason: 'ubicación para la policía');

      for (final note in ['Llamé a la policía', 'Contacté a la familia']) {
        await tester.enterText(find.byKey(const Key('ops.note')), note);
        await tester.ensureVisible(find.byKey(const Key('ops.note.save')));
        await tester.pump();
        await tester.tap(find.byKey(const Key('ops.note.save')));
        await tester.pump();
        await tester.pump();
      }
      expect(find.text('Llamé a la policía'), findsOneWidget);
      expect(find.text('Contacté a la familia'), findsOneWidget);

      await tester.ensureVisible(find.byKey(const Key('ops.close')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('ops.close')));
      await tester.pumpAndSettle();
      expect(
        tester.widget<FilledButton>(find.byKey(const Key('ops.close.confirm'))).onPressed,
        isNull,
        reason: 'desenlace obligatorio',
      );
      await tester.tap(find.byKey(const Key('ops.outcome.falseAlarm')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('ops.close.confirm')));
      await tester.pumpAndSettle();
      verify(() => api.opsClose('al1', SosOutcome.falseAlarm)).called(1);
      expect(find.text('Desenlace: Falsa alarma'), findsOneWidget);
      expect(voice.connected, isFalse, reason: 'al cerrar se cuelga');
    });

    testWidgets('otro operador la tiene: escucha pero no habla ni cierra (US2-2)', (tester) async {
      when(() => api.opsAlert('al1')).thenAnswer((_) async => _detail(status: SosStatus.claimed, claimedBy: 'op1'));
      await pump(tester, operatorId: 'op2');
      expect(find.text('Tomada por Lucía'), findsOneWidget);
      expect(find.byKey(const Key('ops.listen')), findsOneWidget);
      expect(find.byKey(const Key('ops.claim')), findsNothing);
      expect(find.byKey(const Key('ops.close')), findsNothing);
      expect(find.text('Puedes escuchar; solo quien tomó la alerta habla.'), findsOneWidget);
    });

    testWidgets('la ubicación llega en vivo por sos:{id} y se suma al recorrido', (tester) async {
      when(() => api.opsAlert('al1')).thenAnswer((_) async => _detail());
      await pump(tester, operatorId: 'op1');
      expect(find.text('1 puntos'), findsOneWidget);
      realtime.emit(
        Channels.sos('al1'),
        SosLocationUpdate(DateTime.now(), alertId: 'al1', lat: 4.62, lng: -74.06, at: DateTime.now().toUtc()),
      );
      await tester.pump();
      await tester.pump();
      expect(find.text('2 puntos'), findsOneWidget);
      expect(find.text('4.620000, -74.060000'), findsOneWidget);
    });

    testWidgets('alerta cerrada: grabación reproducible', (tester) async {
      when(() => api.opsAlert('al1')).thenAnswer(
        (_) async => _detail(
          status: SosStatus.closed,
          claimedBy: 'op1',
        ).copyWith(outcome: SosOutcome.resolved, recordingUrl: 'https://s3.test/sos/al1.ogg?X-Amz-Signature=1'),
      );
      await pump(tester, operatorId: 'op1');
      expect(find.byKey(const Key('ops.listen')), findsNothing);
      await tester.ensureVisible(find.byKey(const Key('ops.recording')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('ops.recording')));
      expect(opened.single, contains('sos/al1.ogg'));
    });
  });

  test('texto para la policía con coordenadas y enlace de mapa', () {
    expect(
      locationForAuthorities(const SosLocation(lat: 4.6112345, lng: -74.071234)),
      'Ubicación: 4.611235, -74.071234 — https://www.openstreetmap.org/?mlat=4.611235&mlon=-74.071234#map=18/4.611235/-74.071234',
    );
    expect(formatElapsed(const Duration(seconds: 75)), '01:15');
    expect(formatElapsed(const Duration(hours: 1, seconds: 5)), '1:00:05');
  });

  test('historial filtra por desenlace y fechas (FR-007)', () async {
    when(
      () => api.opsAlertHistory(
        from: any(named: 'from'),
        to: any(named: 'to'),
        outcome: any(named: 'outcome'),
      ),
    ).thenAnswer((_) async => [_summary(status: SosStatus.closed)]);
    final history = SosHistoryCubit(api);
    await history.load(outcome: SosOutcome.falseAlarm, from: DateTime(2026, 10, 1), to: DateTime(2026, 10, 27));
    expect(history.state.alerts, hasLength(1));
    verify(
      () =>
          api.opsAlertHistory(from: DateTime(2026, 10, 1), to: DateTime(2026, 10, 27), outcome: SosOutcome.falseAlarm),
    ).called(1);
    await history.close();
  });

  test('alarma WAV válida', () {
    final wav = alarmWav();
    expect(String.fromCharCodes(wav.sublist(0, 4)), 'RIFF');
    expect(wav.length, greaterThan(44));
    expect(Clipboard.kTextPlain, 'text/plain');
  });
}
