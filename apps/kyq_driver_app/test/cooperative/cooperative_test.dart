import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_driver_app/cooperative/cooperative_channel_page.dart';
import 'package:kyq_driver_app/cooperative/cooperative_cubit.dart';
import 'package:kyq_driver_app/cooperative/cooperative_page.dart';
import 'package:kyq_driver_app/offers/offer_cubit.dart';
import 'package:kyq_driver_app/offers/offer_page.dart';
import 'package:kyq_ptt/kyq_ptt.dart';
import 'package:kyq_ptt/testing.dart';
import 'package:kyq_realtime/kyq_realtime.dart';
import 'package:mocktail/mocktail.dart';

import '../support/fakes.dart';

const _ref = CooperativeRef(id: 'c1', name: 'Cooperativa Andina');

const _andina = Cooperative(id: 'c1', name: 'Cooperativa Andina', cityCode: 'bogota', status: CooperativeStatus.active);

const _carlos = CooperativeMember(
  membershipId: 'm1',
  driverId: 'd1',
  displayName: 'Carlos',
  vehiclePlate: 'KYQ001',
  role: CooperativeRole.coordinator,
  presence: 'free',
);

const _beto = CooperativeMember(
  membershipId: 'm2',
  driverId: 'd2',
  displayName: 'Beto',
  vehiclePlate: 'KYQ002',
  role: CooperativeRole.member,
  presence: 'busy',
);

DriverCooperative _coordinator() => DriverCooperative(
  membership: const Membership(
    id: 'm1',
    cooperative: _ref,
    role: CooperativeRole.coordinator,
    status: MembershipStatus.active,
  ),
  members: const [_carlos, _beto],
  requests: [
    MembershipRequest(
      membershipId: 'm3',
      driverId: 'd3',
      displayName: 'Dani',
      vehiclePlate: 'KYQ003',
      requestedAt: DateTime.utc(2026, 10, 27),
    ),
  ],
);

void main() {
  late MockApi api;
  late StreamController<RealtimeEvent> events;

  setUp(() {
    api = MockApi();
    events = StreamController<RealtimeEvent>.broadcast();
  });

  tearDown(() => events.close());

  Widget page(CooperativeCubit cubit) => MaterialApp(
    home: BlocProvider.value(value: cubit, child: const CooperativePage()),
  );

  group('CooperativeCubit', () {
    blocTest<CooperativeCubit, CooperativeState>(
      'sin cooperativa carga las disponibles; pedir entrar recarga como pendiente',
      setUp: () {
        var joined = false;
        when(() => api.myCooperative()).thenAnswer(
          (_) async => joined
              ? const DriverCooperative(
                  membership: Membership(
                    id: 'm9',
                    cooperative: _ref,
                    role: CooperativeRole.member,
                    status: MembershipStatus.pending,
                  ),
                )
              : const DriverCooperative(),
        );
        when(() => api.cooperatives()).thenAnswer((_) async => [_andina]);
        when(() => api.requestToJoinCooperative('c1')).thenAnswer((_) async {
          joined = true;
          return const Membership(
            id: 'm9',
            cooperative: _ref,
            role: CooperativeRole.member,
            status: MembershipStatus.pending,
          );
        });
      },
      build: () => CooperativeCubit(api, events.stream),
      act: (cubit) async {
        await cubit.load();
        await cubit.join('c1');
      },
      verify: (cubit) {
        expect(cubit.state.mine!.isPending, isTrue);
        expect(cubit.state.available, isEmpty, reason: 'con solicitud en curso no se ofrece otra');
        verify(() => api.cooperatives()).called(1);
      },
    );

    blocTest<CooperativeCubit, CooperativeState>(
      'una sola cooperativa: el error del backend se explica',
      setUp: () {
        when(() => api.myCooperative()).thenAnswer((_) async => const DriverCooperative());
        when(() => api.cooperatives()).thenAnswer((_) async => [_andina]);
        when(
          () => api.requestToJoinCooperative('c1'),
        ).thenThrow(const ApiException(409, 'already_in_cooperative', 'ya'));
      },
      build: () => CooperativeCubit(api, events.stream),
      act: (cubit) => cubit.join('c1'),
      verify: (cubit) => expect(cubit.state.error, contains('Ya perteneces')),
    );

    blocTest<CooperativeCubit, CooperativeState>(
      'cooperative.membership recarga (p. ej. aprobado por el coordinador)',
      setUp: () {
        when(() => api.myCooperative()).thenAnswer((_) async => _coordinator());
      },
      build: () => CooperativeCubit(api, events.stream),
      act: (_) async {
        events.add(
          CooperativeMembershipChanged(
            DateTime.utc(2026),
            membershipId: 'm1',
            cooperativeId: 'c1',
            status: 'active',
            role: 'member',
          ),
        );
        await Future<void>.delayed(Duration.zero);
      },
      verify: (_) => verify(() => api.myCooperative()).called(1),
    );
  });

  testWidgets('coordinador: ve compañeros, aprueba y rechaza con motivo', (tester) async {
    when(() => api.myCooperative()).thenAnswer((_) async => _coordinator());
    when(() => api.decideCooperativeRequest('m3', approve: true)).thenAnswer((_) async {});
    when(() => api.decideCooperativeRequest('m3', approve: false, reason: 'Sin referencias')).thenAnswer((_) async {});
    final cubit = CooperativeCubit(api, events.stream);
    await cubit.load();
    await tester.pumpWidget(page(cubit));

    expect(find.byKey(const Key('coop.name')), findsOneWidget);
    expect(find.textContaining('Coordinador ·'), findsOneWidget);
    expect(find.text('Dani'), findsOneWidget);
    expect(find.textContaining('Ocupado'), findsOneWidget);
    expect(find.byTooltip('Retirar de la cooperativa'), findsOneWidget, reason: 'solo miembros, no coordinadores');

    await tester.tap(find.byKey(const Key('coop.approve.m3')));
    await tester.pumpAndSettle();
    verify(() => api.decideCooperativeRequest('m3', approve: true)).called(1);

    await tester.tap(find.byTooltip('Rechazar'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('coop.reason')), 'Sin referencias');
    await tester.tap(find.byKey(const Key('coop.reason.ok')));
    await tester.pumpAndSettle();
    verify(() => api.decideCooperativeRequest('m3', approve: false, reason: 'Sin referencias')).called(1);
    // En testWidgets no se espera el cierre: el cubit cancela sus timers al momento.
    unawaited(cubit.close());
  });

  testWidgets('rechazado: ve el motivo y las cooperativas para pedir entrar', (tester) async {
    when(() => api.myCooperative()).thenAnswer(
      (_) async => const DriverCooperative(
        membership: Membership(
          id: 'm1',
          cooperative: _ref,
          role: CooperativeRole.member,
          status: MembershipStatus.rejected,
          rejectReason: 'Placa no coincide',
        ),
      ),
    );
    when(() => api.cooperatives()).thenAnswer((_) async => [_andina]);
    final cubit = CooperativeCubit(api, events.stream);
    await cubit.load();
    await tester.pumpWidget(page(cubit));

    expect(find.textContaining('Placa no coincide'), findsOneWidget);
    expect(find.byKey(const Key('coop.available.c1')), findsOneWidget);
    // En testWidgets no se espera el cierre: el cubit cancela sus timers al momento.
    unawaited(cubit.close());
  });

  testWidgets('canal de grupo: conecta al abrir y nombra a quien habla', (tester) async {
    final ptt = FakePtt();
    await tester.pumpWidget(
      MaterialApp(
        home: CooperativeChannelPage(controller: ptt.controller, members: const [_carlos, _beto]),
      ),
    );
    await tester.pumpAndSettle();
    expect(ptt.room.connects, 1);
    expect(find.text('Mantén pulsado para hablar'), findsOneWidget);

    ptt.room.emit(const VoiceDataReceived({'type': 'floor.taken', 'user_id': 'd2'}));
    await tester.pump();
    await tester.pump();
    expect(find.text('Habla Beto'), findsOneWidget);
    unawaited(ptt.controller.close());
  });

  testWidgets('oferta derivada: muestra el origen y el botón de pasar a la cooperativa', (tester) async {
    when(() => api.delegateTrip('t1')).thenAnswer((_) async => trip(status: TripStatus.requested));
    final cubit = OfferCubit(api, events.stream, now: () => tripNow);
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(value: cubit, child: const OfferPage()),
      ),
    );
    events.add(
      TripOffered(
        tripNow,
        tripId: 't1',
        passengerName: 'Ana',
        pickup: (lat: 4.6, lng: -74.05),
        dropoff: (lat: 4.7, lng: -74.1),
        distanceM: 4200,
        durationS: 720,
        suggestedFareMinor: 1470000,
        currency: 'COP',
        expiresAt: tripNow.add(const Duration(seconds: 25)),
        delegated: true,
        canDelegate: true,
        cooperativeName: 'Cooperativa Andina',
        requestedDriverName: 'Carlos',
      ),
    );
    await tester.pump();
    expect(find.text('Solicitud de tu cooperativa: cliente de Carlos'), findsOneWidget);
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('offer.delegate')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('offer.delegate')));
    await tester.pump();
    verify(() => api.delegateTrip('t1')).called(1);
    expect(cubit.state, isA<OfferIdle>().having((s) => s.notice, 'aviso', 'Pasaste la solicitud a tu cooperativa.'));
    // En testWidgets no se espera el cierre: el cubit cancela sus timers al momento.
    unawaited(cubit.close());
  });

  testWidgets('sin consentimiento no hay botón de pasar', (tester) async {
    final cubit = OfferCubit(api, events.stream, now: () => tripNow);
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(value: cubit, child: const OfferPage()),
      ),
    );
    events.add(offerEvent());
    await tester.pump();
    expect(find.byKey(const Key('offer.delegate')), findsNothing);
    expect(find.byKey(const Key('offer.delegated')), findsNothing);
    // En testWidgets no se espera el cierre: el cubit cancela sus timers al momento.
    unawaited(cubit.close());
  });
}
