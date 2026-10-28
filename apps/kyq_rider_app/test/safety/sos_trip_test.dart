import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_ptt/kyq_ptt.dart';
import 'package:kyq_rider_app/map/trip_map.dart';
import 'package:kyq_rider_app/trip/trip_cubit.dart';
import 'package:kyq_rider_app/trip/trip_page.dart';
import 'package:kyq_ui/kyq_ui.dart';
import 'package:mocktail/mocktail.dart';

import '../support/fakes.dart';

Trip _trip(TripStatus status) => Trip(
  id: 't1',
  status: status,
  passengerId: 'p1',
  driverId: 'd1',
  pickup: const GeoPoint(lat: 4.65, lng: -74.05),
  dropoff: const GeoPoint(lat: 4.70, lng: -74.04),
  distanceM: 6200,
  durationS: 900,
  currency: 'COP',
  suggestedFareMinor: 1470000,
  agreedFareMinor: 1470000,
  offerExpiresAt: DateTime.now().add(const Duration(seconds: 25)),
);

Widget _fakeMap(TripMapMarkers markers, ValueChanged<GeoPoint>? onTap) => const ColoredBox(color: Colors.blueGrey);

final _alert = SosAlertSelf(id: 'al1', tripId: 't1', status: SosStatus.open, createdAt: DateTime.utc(2026, 10, 27));

class _Gps implements SosLocationSource {
  @override
  Future<SosPoint?> current() async => SosPoint(lat: 4.66, lng: -74.05, recordedAt: DateTime.now().toUtc());

  @override
  Future<void> stop() async {}
}

class _Voice implements VoiceRoom {
  bool mic = false;

  @override
  Stream<VoiceRoomEvent> get events => const Stream.empty();

  @override
  String? get localIdentity => 'p1';

  @override
  Future<void> connect(String url, String token) async {}

  @override
  Future<void> setMicrophoneEnabled(bool enabled) async => mic = enabled;

  @override
  Future<void> sendData(Map<String, Object?> message) async {}

  @override
  Future<void> disconnect() async {}
}

class _Mic implements MicPermission {
  @override
  Future<bool> isGranted() async => true;

  @override
  Future<MicAccess> request() async => MicAccess.granted;

  @override
  Future<void> openSettings() async {}
}

void main() {
  late MockApi api;
  late _Voice voice;
  late List<String> shared;
  late List<String> calls;

  setUp(() {
    api = MockApi();
    voice = _Voice();
    shared = [];
    calls = [];
    when(() => api.currentSession()).thenAnswer((_) async => null);
    when(() => api.raiseSos('t1', location: any(named: 'location'))).thenAnswer(
      (_) async => SosRaise(
        alert: _alert,
        voice: const SosVoice(url: 'ws://lk', token: 'tok', room: 'sos-al1', canPublish: true),
        needsPin: true,
      ),
    );
    when(() => api.sendSosLocations('al1', any())).thenAnswer((_) async => _alert);
    when(
      () => api.shareTrip('t1'),
    ).thenAnswer((_) async => const ShareLink(token: 'abc', url: 'https://kyq.test/s/abc'));
  });

  Future<SosCubit> pump(WidgetTester tester, Trip trip) async {
    when(() => api.getTrip('t1')).thenAnswer((_) async => trip);
    final platform = SafetyPlatform(
      location: _Gps.new,
      share: (text) async => shared.add(text),
      callEmergency: () async => calls.add('123'),
      voice: () => voice,
      mic: _Mic(),
    );
    final sos = SosCubit(
      api: api,
      tripId: 't1',
      location: _Gps(),
      voice: () => voice,
      mic: _Mic(),
      interval: const Duration(hours: 1),
    );
    addTearDown(sos.close);
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (_) => TripCubit(api: api, tripId: 't1')..start(),
          child: TripPage(
            driverName: 'Carlos',
            map: _fakeMap,
            safety: TripSafety(api: api, tripId: 't1', sos: sos, platform: platform),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    return sos;
  }

  testWidgets('en viaje: SOS de 2 s abre la alerta con aviso de no cerrar la app', (tester) async {
    final sos = await pump(tester, _trip(TripStatus.inProgress));
    expect(find.byKey(const Key('sos.button')), findsOneWidget);

    final gesture = await tester.startGesture(tester.getCenter(find.byKey(const Key('sos.button'))));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 2100));
    await gesture.up();
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
    await tester.pump();

    verify(() => api.raiseSos('t1', location: any(named: 'location'))).called(1);
    expect(find.text('Alerta enviada'), findsOneWidget);
    expect(find.byKey(const Key('sos.keepOpen')), findsOneWidget);
    expect(voice.mic, isTrue, reason: 'el micrófono se abre sin pasos extra (FR-004)');
    await tester.tap(find.byKey(const Key('sos.call123')));
    expect(calls, ['123']);
    await tester.runAsync(sos.close);
  });

  testWidgets('pulsación corta no envía nada y explica cómo usarlo', (tester) async {
    await pump(tester, _trip(TripStatus.accepted));
    final gesture = await tester.startGesture(tester.getCenter(find.byKey(const Key('sos.button'))));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await gesture.up();
    await tester.pump();
    verifyNever(() => api.raiseSos(any(), location: any(named: 'location')));
    expect(find.text('Mantén pulsado para pedir ayuda'), findsOneWidget);
  });

  testWidgets('compartir viaje abre el menú con el enlace', (tester) async {
    await pump(tester, _trip(TripStatus.accepted));
    await tester.tap(find.byKey(const Key('trip.share')));
    await tester.pump();
    expect(shared.single, contains('https://kyq.test/s/abc'));
  });

  testWidgets('antes de ACCEPTED no hay SOS ni compartir', (tester) async {
    await pump(tester, _trip(TripStatus.requested));
    expect(find.byKey(const Key('sos.button')), findsNothing);
    expect(find.byKey(const Key('trip.share')), findsNothing);
  });
}
