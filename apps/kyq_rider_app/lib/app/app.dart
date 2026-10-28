import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_ptt/kyq_ptt.dart';
import 'package:kyq_realtime/kyq_realtime.dart';
import 'package:kyq_ui/kyq_ui.dart';

import '../chosen_drivers/chosen_drivers_cubit.dart';
import '../chosen_drivers/chosen_drivers_page.dart';
import '../chosen_drivers/scan_page.dart';
import '../realtime/realtime_events.dart';
import '../request/location_source.dart';
import '../request/request_cubit.dart';
import '../request/request_page.dart';
import '../safety/platform_safety.dart';
import '../trip/trip_cubit.dart';
import '../trip/trip_page.dart';

/// URL del backend. En el emulador de Android, 10.0.2.2 es el localhost del PC.
const apiBaseUrl = String.fromEnvironment('KYQ_API_URL', defaultValue: 'http://10.0.2.2:8080');

/// WebSocket de Centrifugo.
const realtimeUrl = String.fromEnvironment(
  'KYQ_REALTIME_URL',
  defaultValue: 'ws://192.168.1.66:8000/connection/websocket',
);

/// Crea el cliente, la sesión con almacenamiento seguro y el tiempo real (conecta al primer uso).
({KyqApiClient api, AuthCubit auth, RealtimeEvents realtime}) bootstrap({TokenStore? tokenStore}) {
  late final AuthCubit auth;
  final api = KyqApiClient(
    baseUrl: apiBaseUrl,
    tokenStore: tokenStore ?? SecureTokenStore(),
    onSessionExpired: () => auth.sessionExpired(),
  );
  auth = AuthCubit(
    api,
    allowedRoles: {UserRole.passenger},
    wrongRoleMessage: 'Esta app es para pasajeros. Usa Kyq Conductor.',
  )..start();
  final realtime = CentrifugoRealtimeEvents(
    () => KyqRealtime(url: realtimeUrl, connectionToken: api.realtimeToken, subscriptionToken: api.subscriptionToken),
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
    this.safety,
  });

  final KyqApiClient api;
  final AuthCubit auth;
  final RealtimeEvents realtime;
  final LocationSource location;

  /// Walkie-talkie de cada viaje; las pruebas pasan falsos.
  final PttControllerFactory ptt;

  /// SOS, viaje compartido y 123 (003); null usa los de la plataforma.
  final SafetyPlatform? safety;

  @override
  State<KyqRiderApp> createState() => _KyqRiderAppState();
}

class _KyqRiderAppState extends State<KyqRiderApp> {
  late final SafetyPlatform _safety = widget.safety ?? platformSafety();

  late final GoRouter _router = buildAuthRouter(
    auth: widget.auth,
    title: 'Kyq Pasajero',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => BlocProvider(
          create: (context) =>
              ChosenDriversCubit(context.read<KyqApiClient>(), realtime: context.read<RealtimeEvents>())..load(),
          child: const ChosenDriversPage(),
        ),
        routes: [
          GoRoute(path: 'scan', builder: (context, state) => const ScanPage()),
          GoRoute(
            path: 'safety',
            builder: (context, state) => BlocProvider(
              create: (context) => SafetyCubit(context.read<KyqApiClient>())..load(),
              child: const SafetyPage(),
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
                ],
                child: Builder(
                  builder: (context) => TripPage(
                    driverName: state.uri.queryParameters['name'] ?? 'tu conductor',
                    ptt: context.read<PttController>(),
                    safety: TripSafety(
                      api: context.read<KyqApiClient>(),
                      tripId: tripId,
                      sos: context.read<SosCubit>(),
                      platform: _safety,
                      onSetupPin: () => context.push('/safety'),
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
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: widget.api),
        RepositoryProvider<RealtimeEvents>.value(value: widget.realtime),
      ],
      child: BlocProvider.value(
        value: widget.auth,
        child: MaterialApp.router(title: 'Kyq Pasajero', theme: kyqTheme(), routerConfig: _router),
      ),
    );
  }
}
