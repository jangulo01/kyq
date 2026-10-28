import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_ptt/kyq_ptt.dart';
import 'package:kyq_radio/kyq_radio.dart';
import 'package:kyq_realtime/kyq_realtime.dart';
import 'package:kyq_ui/kyq_ui.dart';

import '../chosen_drivers/affiliate_link_page.dart';
import '../chosen_drivers/chosen_drivers_cubit.dart';
import '../chosen_drivers/chosen_drivers_page.dart';
import '../chosen_drivers/scan_cubit.dart';
import '../chosen_drivers/scan_page.dart';
import '../map/trip_map.dart';
import '../payments/pending_payments_cubit.dart';
import '../places/saved_places.dart';
import '../preconsult/preconsult_cubit.dart';
import '../preconsult/preconsult_page.dart';
import '../realtime/realtime_events.dart';
import '../request/location_source.dart';
import '../request/request_cubit.dart';
import '../request/request_page.dart';
import '../reservations/booking_cubit.dart';
import '../reservations/booking_page.dart';
import '../reservations/reservations_cubit.dart';
import '../reservations/reservations_page.dart';
import '../safety/platform_safety.dart';
import '../trip/checkout_launcher.dart';
import '../trip/trip_cubit.dart';
import '../trip/trip_page.dart';
import '../trip/trip_payment_cubit.dart';
import 'session_user.dart';

/// URL del backend. En el emulador de Android, 10.0.2.2 es el localhost del PC.
const apiBaseUrl = String.fromEnvironment('KYQ_API_URL', defaultValue: 'http://10.0.2.2:8080');

/// WebSocket de Centrifugo.
const realtimeUrl = String.fromEnvironment(
  'KYQ_REALTIME_URL',
  defaultValue: 'ws://192.168.1.66:8000/connection/websocket',
);

/// Crea el cliente, la sesión con almacenamiento seguro y el tiempo real (conecta al primer uso).
/// Con [domains] (009) usa los dominios espejo: la API rota sola y el tiempo real toma el
/// dominio en uso al abrir la app.
({KyqApiClient api, AuthCubit auth, RealtimeEvents realtime}) bootstrap({
  TokenStore? tokenStore,
  DomainRotator? domains,
}) {
  late final AuthCubit auth;
  final api = KyqApiClient(
    baseUrl: apiBaseUrl,
    tokenStore: tokenStore ?? SecureTokenStore(),
    onSessionExpired: () => auth.sessionExpired(),
    onSupportOnly: () => auth.supportOnly(),
  );
  if (domains != null) useDomains(api, domains);
  final realtimeAt = domains?.current.realtimeUrl ?? realtimeUrl;
  auth = AuthCubit(
    api,
    allowedRoles: {UserRole.passenger},
    wrongRoleMessage: 'Esta app es para pasajeros. Usa Kyq Conductor.',
  )..start();
  final realtime = CentrifugoRealtimeEvents(
    () => KyqRealtime(url: realtimeAt, connectionToken: api.realtimeToken, subscriptionToken: api.subscriptionToken),
  );
  return (api: api, auth: auth, realtime: realtime);
}

class KyqRiderApp extends StatefulWidget {
  const KyqRiderApp({
    super.key,
    required this.api,
    required this.auth,
    this.realtime = const NoRealtimeEvents(),
    this.location = const GeolocatorLocationSource(),
    this.ptt = PttController.live,
    this.preconsultPtt = PttController.livePreconsult,
    this.safety,
    this.checkout = const CustomTabCheckout(),
    this.places = const SharedPrefsSavedPlaces(),
    this.map = maplibreTripMap,
    this.pickDateTime = materialDateTimePicker,
    this.radio = liveRadioCubit,
    this.radioPlayer = JustAudioMessagePlayer.new,
    this.radioApi,
    this.radioReferrer = const PlayRadioReferrer(),
  });

  final KyqApiClient api;
  final AuthCubit auth;
  final RealtimeEvents realtime;
  final LocationSource location;

  /// Walkie-talkie de cada viaje; las pruebas pasan falsos.
  final PttControllerFactory ptt;

  /// Walkie-talkie de cada consulta de voz (005, RN-KYQ-010); las pruebas pasan falsos.
  final PttControllerFactory preconsultPtt;

  /// SOS, viaje compartido y 123 (003); null usa los de la plataforma.
  final SafetyPlatform? safety;

  /// Checkout de Bold para pagar el viaje (004); las pruebas pasan un falso.
  final CheckoutLauncher checkout;

  /// Casa, Trabajo y destinos recientes (010); las pruebas pasan uno en memoria.
  final SavedPlacesStore places;

  /// Mapa del inicio (pines dorados, 010); las pruebas lo sustituyen.
  final TripMapBuilder map;

  /// Fecha y hora de una reserva; las pruebas no abren los diálogos.
  final DateTimePicker pickDateTime;

  /// Radio Kyq (011): salas, tonos y audio reales; las pruebas pasan un cubit con falsos.
  final RadioCubitFactory radio;
  final MessagePlayer Function() radioPlayer;

  /// API de Radio; null usa [api]. Las pruebas pasan una en memoria.
  final RadioApi? radioApi;

  /// Invitación con la que se instaló la app (Play Install Referrer, R9).
  final RadioReferrer radioReferrer;

  @override
  State<KyqRiderApp> createState() => _KyqRiderAppState();
}

class _KyqRiderAppState extends State<KyqRiderApp> {
  late final SafetyPlatform _safety = widget.safety ?? platformSafety();

  // 011: Radio con los conductores que activaron "Radio con mis clientes"; vive con la sesión.
  late final RadioMount _radio = RadioMount(
    api: widget.radioApi ?? widget.api,
    events: (userId) => widget.realtime.subscribe('user:$userId'),
    factory: widget.radio,
    newPlayer: widget.radioPlayer,
    isDriver: false,
    location: _RiderRadioLocation(widget.location),
    onRequestTrip: (context, c) =>
        context.push(Uri(path: '/request/${c.peerId}', queryParameters: {'name': c.title}).toString()),
  );
  late final StreamSubscription<AuthState> _authSub;

  late final GoRouter _router = buildAuthRouter(
    auth: widget.auth,
    title: 'Kyq Pasajero',
    // 009: Ayuda, y lo único que ve una cuenta suspendida.
    withSupport: true,
    // 008: el enlace del conductor abre la app con `kyq://affiliate/{token}`; 011: kyq://radio/{code}.
    guard: (context, state) => affiliateLinkRedirect(state.uri) ?? radioDeepLinkRedirect(state.uri),
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (context) =>
                  ChosenDriversCubit(context.read<KyqApiClient>(), realtime: context.read<RealtimeEvents>())..load(),
            ),
            BlocProvider(
              create: (context) =>
                  PendingPaymentsCubit(context.read<KyqApiClient>(), realtime: context.read<RealtimeEvents>())..start(),
            ),
            BlocProvider(
              create: (context) =>
                  ReservationsCubit(context.read<KyqApiClient>(), realtime: context.read<RealtimeEvents>())..start(),
            ),
          ],
          child: ChosenDriversPage(map: widget.map),
        ),
        routes: [
          // 010: reservar con un Conductor Elegido y "Mis reservas" (US1).
          GoRoute(
            path: 'book/:driverId',
            builder: (context, state) => BlocProvider(
              create: (context) => BookingCubit(
                api: context.read<KyqApiClient>(),
                location: widget.location,
                driverId: state.pathParameters['driverId']!,
                driverName: state.uri.queryParameters['name'] ?? 'tu conductor',
              )..start(),
              child: BookingPage(pickDateTime: widget.pickDateTime),
            ),
          ),
          GoRoute(
            path: 'reservations',
            builder: (context, state) => BlocProvider(
              create: (context) =>
                  ReservationsCubit(context.read<KyqApiClient>(), realtime: context.read<RealtimeEvents>())..start(),
              child: const ReservationsPage(),
            ),
          ),
          GoRoute(path: 'scan', builder: (context, state) => const ScanPage()),
          radioRoute(scope: _radio.wrap),
          GoRoute(
            path: 'affiliate/:token',
            builder: (context, state) => BlocProvider(
              create: (context) => ScanCubit(context.read<KyqApiClient>())..fromLink(state.pathParameters['token']!),
              child: const AffiliateLinkPage(),
            ),
          ),
          GoRoute(
            path: 'preconsult/:driverId',
            builder: (context, state) => BlocProvider(
              create: (context) => PreconsultCubit(
                api: context.read<KyqApiClient>(),
                realtime: context.read<RealtimeEvents>(),
                ptt: widget.preconsultPtt,
                driverId: state.pathParameters['driverId']!,
                driverName: state.uri.queryParameters['name'] ?? 'tu conductor',
                refreshEvery: const Duration(seconds: 3),
              )..start(),
              child: const PreconsultPage(),
            ),
          ),
          GoRoute(
            path: 'safety',
            builder: (context, state) => BlocProvider(
              create: (context) => SafetyCubit(context.read<KyqApiClient>())..load(),
              child: const SafetyPage(),
            ),
          ),
          // 008: bolsa zonal desde el inicio, sin Conductor Elegido (FR-001).
          GoRoute(
            path: 'nearby',
            builder: (context, state) => BlocProvider(
              create: (context) => RequestCubit(api: context.read<KyqApiClient>(), location: widget.location)..start(),
              child: const RequestPage(),
            ),
          ),
          GoRoute(
            path: 'request/:driverId',
            builder: (context, state) => BlocProvider(
              create: (context) => RequestCubit(
                api: context.read<KyqApiClient>(),
                location: widget.location,
                realtime: context.read<RealtimeEvents>(),
                driverId: state.pathParameters['driverId']!,
                driverName: state.uri.queryParameters['name'] ?? 'tu conductor',
                cooperative: switch ((state.uri.queryParameters['coopId'], state.uri.queryParameters['coop'])) {
                  (final String id, final String name) => CooperativeRef(id: id, name: name),
                  _ => null,
                },
              )..start(),
              child: const RequestPage(),
            ),
          ),
          GoRoute(
            path: 'trip/:tripId',
            builder: (context, state) {
              final tripId = state.pathParameters['tripId']!;
              return MultiBlocProvider(
                providers: [
                  BlocProvider(
                    create: (context) => TripCubit(
                      api: context.read<KyqApiClient>(),
                      realtime: context.read<RealtimeEvents>(),
                      tripId: tripId,
                      refreshEvery: const Duration(seconds: 15),
                    )..start(),
                  ),
                  BlocProvider(
                    create: (context) =>
                        widget.ptt(context.read<KyqApiClient>(), tripId, context.read<TripCubit>().pttClosed),
                  ),
                  // SOS del pasajero (003): el conductor no ve nada de la alerta (FR-006).
                  BlocProvider(create: (context) => _safety.sosFor(context.read<KyqApiClient>(), tripId)),
                  // Pago del viaje (004): se carga al completarse y se sigue en vivo.
                  BlocProvider(
                    create: (context) => TripPaymentCubit(
                      api: context.read<KyqApiClient>(),
                      tripId: tripId,
                      checkout: widget.checkout,
                      realtime: context.read<RealtimeEvents>(),
                    ),
                  ),
                ],
                child: Builder(
                  builder: (context) => BlocListener<TripCubit, TripState>(
                    listenWhen: (a, b) =>
                        a.trip?.status != TripStatus.completed && b.trip?.status == TripStatus.completed,
                    listener: (context, _) => context.read<TripPaymentCubit>().load(),
                    child: TripPage(
                      driverName: state.uri.queryParameters['name'] ?? 'tu conductor',
                      ptt: context.read<PttController>(),
                      payments: true,
                      safety: TripSafety(
                        api: context.read<KyqApiClient>(),
                        tripId: tripId,
                        sos: context.read<SosCubit>(),
                        platform: _safety,
                        onSetupPin: () => context.push('/safety'),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    ],
  );

  @override
  void initState() {
    super.initState();
    _authSub = widget.auth.stream.listen(_onAuth);
    _onAuth(widget.auth.state);
  }

  Future<void> _onAuth(AuthState state) async {
    switch (state) {
      case AuthSignedIn(:final radioInvitesApplied):
        final session = await widget.api.currentSession();
        final id = session == null ? null : userIdFromAccessToken(session.accessToken);
        if (id != null && mounted) _radio.start(id, applied: radioInvitesApplied);
      case AuthSignedOut():
        await _radio.stop();
      default:
        break;
    }
  }

  @override
  void dispose() {
    _authSub.cancel();
    unawaited(_radio.dispose());
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: widget.api),
        RepositoryProvider<RealtimeEvents>.value(value: widget.realtime),
        RepositoryProvider<SavedPlacesStore>.value(value: widget.places),
      ],
      child: BlocProvider.value(
        value: widget.auth,
        child: MaterialApp.router(title: 'Kyq Pasajero', theme: kyqTheme(), routerConfig: _router),
      ),
    );
  }
}

/// Ubicación de la radio con el GPS del pasajero; sin permiso no hay punto.
class _RiderRadioLocation implements RadioLocation {
  const _RiderRadioLocation(this.source);

  final LocationSource source;

  @override
  Future<RadioPoint?> current() async {
    try {
      final p = await source.current();
      return (lat: p.lat, lng: p.lng);
    } on LocationUnavailable {
      return null;
    }
  }
}
