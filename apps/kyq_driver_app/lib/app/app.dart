import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_ptt/kyq_ptt.dart';
import 'package:kyq_realtime/kyq_realtime.dart';
import 'package:kyq_ui/kyq_ui.dart';

import '../background/location_reporter.dart';
import '../offers/offer_cubit.dart';
import '../offers/offer_page.dart';
import '../onboarding/clients_page.dart';
import '../onboarding/my_qr_page.dart';
import '../presence/presence_cubit.dart';
import '../realtime/driver_events.dart';
import '../trip/trip_cubit.dart';
import '../trip/trip_page.dart';
import 'driver_services.dart';
import 'home_page.dart';

/// URL del backend. En el emulador de Android, 10.0.2.2 es el localhost del PC.
const apiBaseUrl = String.fromEnvironment('KYQ_API_URL', defaultValue: 'http://10.0.2.2:8080');

/// WebSocket de Centrifugo.
const realtimeUrl = String.fromEnvironment(
  'KYQ_REALTIME_URL',
  defaultValue: 'ws://192.168.1.66:8000/connection/websocket',
);

/// Crea el cliente, la sesión con almacenamiento seguro y los servicios de plataforma.
({KyqApiClient api, AuthCubit auth, DriverServices services}) bootstrap({TokenStore? tokenStore}) {
  late final AuthCubit auth;
  final api = KyqApiClient(
    baseUrl: apiBaseUrl,
    tokenStore: tokenStore ?? SecureTokenStore(),
    onSessionExpired: () => auth.sessionExpired(),
  );
  auth = AuthCubit(
    api,
    allowedRoles: {UserRole.driver},
    wrongRoleMessage: 'Esta app es para conductores. Usa Kyq Pasajero.',
  )..start();
  final realtime = KyqRealtime(
    url: realtimeUrl,
    connectionToken: api.realtimeToken,
    subscriptionToken: api.subscriptionToken,
  );
  return (api: api, auth: auth, services: DriverServices.platform(KyqRealtimeEventSource(realtime)));
}

class KyqDriverApp extends StatefulWidget {
  const KyqDriverApp({super.key, required this.api, required this.auth, required this.services});

  final KyqApiClient api;
  final AuthCubit auth;
  final DriverServices services;

  @override
  State<KyqDriverApp> createState() => _KyqDriverAppState();
}

class _KyqDriverAppState extends State<KyqDriverApp> {
  final _messenger = GlobalKey<ScaffoldMessengerState>();
  late final DriverEvents _events = DriverEvents(widget.services.events);
  late final OfferCubit _offers = OfferCubit(widget.api, _events.stream);
  late final PresenceCubit _presence = PresenceCubit(
    api: widget.api,
    events: _events,
    permissions: widget.services.permissions,
    service: widget.services.onlineService,
    reporter: LocationReporter(
      source: widget.services.positions,
      sink: (fix) => widget.api.sendLocation(
        GeoPoint(lat: fix.lat, lng: fix.lng),
        heading: fix.heading,
        speedMps: fix.speedMps,
        recordedAt: fix.recordedAt,
      ),
      onError: (e) => debugPrint('Ubicación: $e'),
    ),
  );
  late final StreamSubscription<AuthState> _authSub;

  late final GoRouter _router = buildAuthRouter(
    auth: widget.auth,
    title: 'Kyq Conductor',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomePage(),
        routes: [
          GoRoute(path: 'qr', builder: (context, state) => const MyQrPage()),
          GoRoute(path: 'clients', builder: (context, state) => const ClientsPage()),
          GoRoute(path: 'offer', builder: (context, state) => const OfferPage()),
          GoRoute(
            path: 'trip/:id',
            builder: (context, state) {
              final tripId = state.pathParameters['id']!;
              return MultiBlocProvider(
                providers: [
                  BlocProvider(
                    create: (_) {
                      final initial = state.extra is Trip ? state.extra! as Trip : null;
                      final cubit = TripCubit(widget.api, _events.stream, tripId, initial: initial);
                      unawaited(cubit.refresh());
                      return cubit;
                    },
                  ),
                  BlocProvider(
                    create: (_) => widget.services.ptt(
                      widget.api,
                      tripId,
                      _events.stream.where((e) => e is PttClosed && e.tripId == tripId),
                    ),
                  ),
                ],
                child: Builder(builder: (context) => TripPage(ptt: context.read<PttController>())),
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

  void _onAuth(AuthState state) {
    switch (state) {
      case AuthSignedIn():
        if (_presence.state.me == null && !_presence.state.loading) unawaited(_presence.load());
      case AuthSignedOut():
        if (_presence.state.me != null) unawaited(_presence.reset());
      default:
        break;
    }
  }

  void _onOffer(BuildContext context, OfferState state) {
    switch (state) {
      case OfferShown():
        _router.go('/offer');
      case OfferTaken(:final trip):
        _router.go('/trip/${trip.id}', extra: trip);
      case OfferIdle(:final notice):
        if (_router.routerDelegate.currentConfiguration.uri.path == '/offer') _router.go('/');
        if (notice != null) _messenger.currentState?.showSnackBar(SnackBar(content: Text(notice)));
    }
  }

  @override
  void dispose() {
    _authSub.cancel();
    _router.dispose();
    _offers.close();
    _presence.close();
    _events.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: widget.api),
        RepositoryProvider.value(value: _events),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: widget.auth),
          BlocProvider.value(value: _presence),
          BlocProvider.value(value: _offers),
        ],
        child: MaterialApp.router(
          title: 'Kyq Conductor',
          theme: kyqTheme(),
          routerConfig: _router,
          scaffoldMessengerKey: _messenger,
          builder: (context, child) => BlocListener<OfferCubit, OfferState>(
            bloc: _offers,
            listenWhen: (a, b) => a.runtimeType != b.runtimeType,
            listener: _onOffer,
            child: child!,
          ),
        ),
      ),
    );
  }
}
