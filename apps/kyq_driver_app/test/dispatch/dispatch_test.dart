import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_driver_app/dispatch/dispatch_settings_cubit.dart';
import 'package:kyq_driver_app/dispatch/dispatch_settings_page.dart';
import 'package:kyq_driver_app/offers/offer.dart';
import 'package:kyq_driver_app/offers/offer_cubit.dart';
import 'package:kyq_driver_app/offers/offer_page.dart';
import 'package:kyq_driver_app/onboarding/clients_page.dart';
import 'package:kyq_realtime/kyq_realtime.dart';
import 'package:mocktail/mocktail.dart';

import '../support/fakes.dart';

// 008: preferencias de despacho, etiquetas de la oferta y origen de los clientes.

const _settings = DispatchSettings(affiliateLink: 'https://kyq.test/a/qr-token-0000001');
final _now = DateTime.utc(2026, 10, 28, 12);

TripOffered _offer({
  OfferOrigin origin = OfferOrigin.chosenDriver,
  bool loyal = false,
  int together = 0,
  int? distance,
  int discount = 0,
}) => TripOffered(
  _now,
  tripId: 't1',
  passengerName: 'Ana',
  pickup: (lat: 4.6, lng: -74.05),
  dropoff: (lat: 4.7, lng: -74.1),
  distanceM: 4200,
  durationS: 720,
  suggestedFareMinor: 1320000,
  currency: 'COP',
  expiresAt: _now.add(const Duration(seconds: 25)),
  origin: origin,
  loyalClient: loyal,
  tripsTogether: together,
  pickupDistanceM: distance,
  preferentialDiscountPct: discount,
);

void main() {
  late MockApi api;

  setUp(() => api = MockApi());

  blocTest<DispatchSettingsCubit, DispatchSettingsState>(
    'carga, edita y guarda la bolsa zonal y el descuento',
    setUp: () {
      when(() => api.dispatchSettings()).thenAnswer((_) async => _settings);
      when(
        () => api.setDispatchSettings(acceptsZonePool: true, preferentialDiscountPct: 30),
      ).thenAnswer((_) async => _settings.copyWith(acceptsZonePool: true, preferentialDiscountPct: 30));
    },
    build: () => DispatchSettingsCubit(api),
    act: (c) async {
      await c.load();
      expect(c.state.dirty, isFalse);
      c
        ..setAcceptsZonePool(true)
        ..setDiscount(45);
      expect(c.state.discountPct, 30, reason: 'RN-KYQ-013: tope del 30 %');
      expect(c.state.dirty, isTrue);
      await c.save();
    },
    verify: (c) {
      expect(c.state.saved.acceptsZonePool, isTrue);
      expect(c.state.saved.preferentialDiscountPct, 30);
      expect(c.state.dirty, isFalse);
    },
  );

  blocTest<DispatchSettingsCubit, DispatchSettingsState>(
    'un error al guardar conserva el borrador y avisa',
    setUp: () {
      when(() => api.dispatchSettings()).thenAnswer((_) async => _settings);
      when(
        () => api.setDispatchSettings(
          acceptsZonePool: any(named: 'acceptsZonePool'),
          preferentialDiscountPct: any(named: 'preferentialDiscountPct'),
        ),
      ).thenThrow(const ApiException(400, 'invalid_settings', ''));
    },
    build: () => DispatchSettingsCubit(api),
    act: (c) async {
      await c.load();
      c.setDiscount(10);
      await c.save();
    },
    verify: (c) {
      expect(c.state.discountPct, 10);
      expect(c.state.error, 'No pudimos guardar tus preferencias.');
    },
  );

  testWidgets('la página activa la bolsa y comparte el enlace', (tester) async {
    when(() => api.dispatchSettings()).thenAnswer((_) async => _settings);
    String? shared;
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (_) => DispatchSettingsCubit(api)..load(),
          child: DispatchSettingsPage(share: (t) async => shared = t),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(find.byKey(const Key('dispatch.save'))).onPressed, isNull);
    await tester.tap(find.byKey(const Key('dispatch.zonePool')));
    await tester.pump();
    expect(tester.widget<FilledButton>(find.byKey(const Key('dispatch.save'))).onPressed, isNotNull);

    await tester.tap(find.byKey(const Key('dispatch.shareLink')));
    expect(shared, contains('https://kyq.test/a/qr-token-0000001'));
  });

  group('etiqueta de la oferta (FR-005–FR-007)', () {
    test('cliente de la cartera con viajes juntos', () {
      expect(Offer.fromEvent(_offer(loyal: true, together: 3)).label, '⭐ Cliente de tu cartera · 3 viajes juntos');
      expect(Offer.fromEvent(_offer(loyal: true, together: 1)).label, '⭐ Cliente de tu cartera · 1 viaje juntos');
      expect(Offer.fromEvent(_offer(loyal: true)).label, '⭐ Cliente de tu cartera');
    });

    test('bolsa zonal con distancia y cooperativa', () {
      expect(
        Offer.fromEvent(_offer(origin: OfferOrigin.zonePool, distance: 3200)).label,
        'Bolsa zonal · a 3,2 km de la recogida',
      );
      expect(Offer.fromEvent(_offer(origin: OfferOrigin.zonePool)).label, 'Bolsa zonal');
      expect(Offer.fromEvent(_offer(origin: OfferOrigin.cooperative)).label, 'De tu cooperativa');
      expect(Offer.fromEvent(_offer()).label, isNull);
    });

    testWidgets('la tarjeta muestra la etiqueta y la tarifa preferencial', (tester) async {
      final events = StreamController<RealtimeEvent>.broadcast();
      final cubit = OfferCubit(api, events.stream, now: () => _now);
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(value: cubit, child: const OfferPage()),
        ),
      );
      events.add(_offer(loyal: true, together: 2, discount: 10));
      await tester.pump();
      await tester.pump();
      expect(find.text('⭐ Cliente de tu cartera · 2 viajes juntos'), findsOneWidget);
      expect(find.text('Tarifa preferencial (−10 %)'), findsOneWidget);
      unawaited(cubit.close());
      unawaited(events.close());
    });
  });

  test('origen de los clientes en "Mis clientes"', () {
    expect(sourceLabel(AffiliationSource.qrScan), 'con tu QR');
    expect(sourceLabel(AffiliationSource.postTrip), 'después de un viaje');
    expect(sourceLabel(AffiliationSource.link), 'con tu enlace');
  });
}
