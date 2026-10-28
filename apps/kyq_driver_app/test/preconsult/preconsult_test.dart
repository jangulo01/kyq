import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_driver_app/handsfree/hands_free_settings_cubit.dart';
import 'package:kyq_driver_app/preconsult/preconsult_cubit.dart';
import 'package:kyq_driver_app/preconsult/preconsult_page.dart';
import 'package:kyq_driver_app/preconsult/preconsult_settings_cubit.dart';
import 'package:kyq_driver_app/preconsult/preconsult_settings_page.dart';
import 'package:kyq_ptt/kyq_ptt.dart';
import 'package:kyq_ptt/testing.dart';
import 'package:kyq_realtime/kyq_realtime.dart';
import 'package:mocktail/mocktail.dart';

import '../support/fakes.dart';

final _now = DateTime.now().toUtc();

Preconsult _preconsult({String id = 'pc1', PreconsultStatus status = PreconsultStatus.open}) => Preconsult(
  id: id,
  passengerId: 'p1',
  passengerName: 'Ana',
  driverId: 'd1',
  driverName: 'Carlos',
  status: status,
  openedAt: _now,
  joinDeadline: _now.add(const Duration(seconds: 30)),
  closesAt: _now.add(const Duration(minutes: 2)),
);

PreconsultOpened _opened({String id = 'pc1'}) => PreconsultOpened(
  _now,
  preconsultId: id,
  passengerId: 'p1',
  passengerName: 'Ana',
  joinDeadline: _now.add(const Duration(seconds: 30)),
  closesAt: _now.add(const Duration(minutes: 2)),
);

void main() {
  late MockApi api;
  late StreamController<RealtimeEvent> events;
  late FakeHandsFreePlatform platform;
  late HandsFreePtt handsFree;
  late List<FakePtt> created;
  late PreconsultCubit cubit;

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  setUp(() {
    api = MockApi();
    when(() => api.driverPreconsults()).thenAnswer((_) async => []);
    events = StreamController<RealtimeEvent>.broadcast(sync: true);
    platform = FakeHandsFreePlatform();
    handsFree = HandsFreePtt(platform);
    created = [];
    cubit = PreconsultCubit(api: api, events: events.stream, ptt: fakePttFactory(created), handsFree: handsFree);
  });

  tearDown(() async {
    await cubit.close();
    await handsFree.dispose();
    await events.close();
  });

  group('RN-KYQ-010 en el conductor', () {
    test('preconsult.opened se une sola con tono y la ofrece al botón físico', () async {
      events.add(_opened());
      await settle();

      expect(cubit.state.active?.passengerName, 'Ana');
      expect(created, hasLength(1));
      final ptt = created.single;
      expect(ptt.room.connects, 1, reason: 'se une sin tocar nada (FR-005)');
      expect(ptt.tones.played, [PttTone.incoming]);
      expect(platform.mediaActive, isTrue, reason: 'el botón del volante responde a la consulta');

      events.add(PreconsultClosed(_now, preconsultId: 'pc1', reason: 'ended_by_passenger'));
      await settle();
      expect(cubit.state.active, isNull);
      expect(cubit.state.notice, 'Ana terminó la consulta.');
      expect(ptt.controller.isClosed, isTrue);
      expect(platform.mediaActive, isFalse, reason: 'sin canal no se captura el botón (FR-013)');
    });

    test('al cargar retoma una consulta abierta sin volver a sonar', () async {
      when(
        () => api.driverPreconsults(),
      ).thenAnswer((_) async => [_preconsult(), _preconsult(id: 'pc0', status: PreconsultStatus.missed)]);
      await cubit.load();
      await settle();
      expect(cubit.state.inbox, hasLength(2));
      expect(cubit.state.active?.id, 'pc1');
      expect(created.single.tones.played, isEmpty);
    });

    test('terminar avisa al backend y cierra el canal', () async {
      when(() => api.endPreconsult('pc1')).thenAnswer((_) async => _preconsult(status: PreconsultStatus.answered));
      events.add(_opened());
      await settle();
      await cubit.end();
      verify(() => api.endPreconsult('pc1')).called(1);
      expect(cubit.state.active, isNull);
      expect(created.single.controller.isClosed, isTrue);
    });

    test('si el canal cierra solo (2 min) la consulta desaparece', () async {
      events.add(_opened());
      await settle();
      await created.single.controller.closeChannel();
      await settle();
      expect(cubit.state.active, isNull);
    });
  });

  testWidgets('la tarjeta de la consulta muestra quién consulta, el botón y terminar', (tester) async {
    events.add(_opened());
    await tester.pump();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlocProvider.value(value: cubit, child: const ActivePreconsultCard()),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Consulta de voz de Ana'), findsOneWidget);
    expect(find.byKey(const Key('ptt.button')), findsOneWidget);
    expect(find.byKey(const Key('preconsult.end')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  group('ajustes', () {
    late FakeOverlayPermission overlay;
    late HandsFreeSettingsCubit handsFreeSettings;
    late PreconsultSettingsCubit settings;

    setUp(() {
      overlay = FakeOverlayPermission();
      handsFreeSettings = HandsFreeSettingsCubit(store: FakeHandsFreePrefs(), overlay: overlay, handsFree: handsFree);
      when(
        () => api.preconsultSettings(),
      ).thenAnswer((_) async => const PreconsultSettings(acceptsPreconsults: false, blockedPassengerIds: ['p2']));
      when(() => api.driverClients()).thenAnswer(
        (_) async => [
          DriverClient(passengerId: 'p1', displayName: 'Ana', affiliatedAt: DateTime.utc(2026)),
          DriverClient(passengerId: 'p2', displayName: 'Pedro', affiliatedAt: DateTime.utc(2026)),
        ],
      );
      when(
        () => api.setAcceptsPreconsults(true),
      ).thenAnswer((_) async => const PreconsultSettings(acceptsPreconsults: true, blockedPassengerIds: ['p2']));
      when(() => api.setClientPreconsultsBlocked('p1', blocked: true)).thenAnswer((_) async {});
      settings = PreconsultSettingsCubit(api);
    });

    tearDown(() async {
      await settings.close();
      await handsFreeSettings.close();
    });

    testWidgets('activar consultas, silenciar a un cliente y pedir el permiso de la burbuja', (tester) async {
      await tester.runAsync(() async {
        await settings.load();
        await handsFreeSettings.load();
      });
      await tester.pumpWidget(
        MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider.value(value: settings),
              BlocProvider.value(value: handsFreeSettings),
            ],
            child: const PreconsultSettingsPage(),
          ),
        ),
      );
      expect(tester.widget<SwitchListTile>(find.byKey(const Key('preconsult.accepts'))).value, isFalse);
      expect(find.text('Ana'), findsNothing, reason: 'los clientes se ven con las consultas activadas');

      await tester.tap(find.byKey(const Key('preconsult.accepts')));
      await tester.pumpAndSettle();
      verify(() => api.setAcceptsPreconsults(true)).called(1);
      expect(tester.widget<SwitchListTile>(find.byKey(const Key('preconsult.client.p2'))).value, isFalse);

      await tester.tap(find.byKey(const Key('preconsult.client.p1')));
      await tester.pumpAndSettle();
      verify(() => api.setClientPreconsultsBlocked('p1', blocked: true)).called(1);

      // La burbuja está activada en las preferencias pero falta el permiso: no se muestra.
      expect(tester.widget<SwitchListTile>(find.byKey(const Key('handsfree.bubble'))).value, isFalse);
      await tester.ensureVisible(find.byKey(const Key('handsfree.bubble')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('handsfree.bubble')));
      await tester.pumpAndSettle();
      expect(overlay.requests, 1);
      expect(handsFreeSettings.state.bubbleActive, isTrue);
      expect(handsFree.bubbleEnabled, isTrue);

      await tester.ensureVisible(find.byKey(const Key('handsfree.button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('handsfree.button')));
      await tester.pumpAndSettle();
      expect(handsFree.mediaButtonEnabled, isFalse, reason: 'botón físico desactivado (FR-015)');
    });
  });
}
