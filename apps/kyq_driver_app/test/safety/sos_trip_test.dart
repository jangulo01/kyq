import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_driver_app/trip/trip_cubit.dart';
import 'package:kyq_driver_app/trip/trip_page.dart';
import 'package:kyq_ui/kyq_ui.dart';
import 'package:mocktail/mocktail.dart';

import '../support/fakes.dart';

final _alert = SosAlertSelf(id: 'al1', tripId: 't1', status: SosStatus.open, createdAt: DateTime.utc(2026, 10, 27));

void main() {
  late MockApi api;
  late List<String> shared;

  setUp(() {
    api = MockApi();
    shared = [];
    when(() => api.raiseSos('t1', location: any(named: 'location'))).thenAnswer(
      (_) async => SosRaise(
        alert: _alert,
        voice: const SosVoice(url: 'ws://lk', token: 'tok', room: 'sos-al1', canPublish: true),
      ),
    );
    when(() => api.sendSosLocations('al1', any())).thenAnswer((_) async => _alert);
    when(
      () => api.shareTrip('t1'),
    ).thenAnswer((_) async => const ShareLink(token: 'abc', url: 'https://kyq.test/s/abc'));
  });

  Future<SosCubit> pump(WidgetTester tester, Trip t) async {
    final platform = fakeSafety(shared: shared);
    final sos = SosCubit(
      api: api,
      tripId: 't1',
      location: FakeSosLocation(),
      voice: FakeVoice.new,
      mic: GrantedMic(),
      interval: const Duration(hours: 1),
    );
    addTearDown(sos.close);
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (_) => TripCubit(api, const Stream.empty(), 't1', initial: t),
          child: TripPage(
            safety: TripSafety(api: api, tripId: 't1', sos: sos, platform: platform),
          ),
        ),
      ),
    );
    await tester.pump();
    return sos;
  }

  testWidgets('el conductor en viaje activa el SOS con 2 s pulsado (US1-5)', (tester) async {
    final sos = await pump(tester, trip(status: TripStatus.inProgress));
    expect(find.byKey(const Key('sos.button')), findsOneWidget);
    final gesture = await tester.startGesture(tester.getCenter(find.byKey(const Key('sos.button'))));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 2100));
    await gesture.up();
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
    await tester.pump();
    verify(() => api.raiseSos('t1', location: any(named: 'location'))).called(1);
    expect(find.text('Alerta enviada'), findsOneWidget);
    expect(find.byKey(const Key('sos.keepOpen')), findsNothing, reason: 'el servicio en primer plano la mantiene viva');
    await tester.runAsync(sos.close);
  });

  testWidgets('compartir el viaje desde la barra superior', (tester) async {
    await pump(tester, trip(status: TripStatus.accepted));
    await tester.tap(find.byKey(const Key('trip.share')));
    await tester.pump();
    expect(shared.single, 'Sigue mi viaje en Kyq en vivo: https://kyq.test/s/abc');
  });

  testWidgets('en la oferta no hay SOS', (tester) async {
    await pump(tester, trip(status: TripStatus.requested, agreedFareMinor: null));
    expect(find.byKey(const Key('sos.button')), findsNothing);
    expect(find.byKey(const Key('trip.share')), findsNothing);
  });
}
