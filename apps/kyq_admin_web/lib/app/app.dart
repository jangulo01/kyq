import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_ptt/kyq_ptt.dart';
import 'package:kyq_realtime/kyq_realtime.dart';
import 'package:kyq_ui/kyq_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../billing/billing_cubits.dart';
import '../billing/driver_payments_page.dart';
import '../billing/subscriptions_page.dart';
import '../costs/cost_rates_page.dart';
import '../costs/costs_cubits.dart';
import '../costs/costs_page.dart';
import '../drivers/drivers_cubit.dart';
import '../drivers/drivers_page.dart';
import '../emergencies/alert_detail_page.dart';
import '../emergencies/alert_sound.dart';
import '../emergencies/emergencies_page.dart';
import '../emergencies/emergency_cubits.dart';
import '../emergencies/sos_map.dart';
import '../fares/fare_table_page.dart';
import '../kyc/kyc_cubits.dart';
import '../kyc/kyc_driver_page.dart';
import '../kyc/kyc_queue_page.dart';

const apiBaseUrl = String.fromEnvironment('KYQ_API_URL', defaultValue: 'http://localhost:8080');

/// WebSocket de Centrifugo para la consola de emergencias (003).
const realtimeUrl = String.fromEnvironment(
  'KYQ_REALTIME_URL',
  defaultValue: 'ws://localhost:8000/connection/websocket',
);

/// Servicios de la consola de emergencias; las pruebas pasan falsos.
class OpsServices {
  const OpsServices({
    required this.realtime,
    required this.sound,
    this.voice,
    this.map = maplibreSosMap,
    this.openUrl = _openInNewTab,
  });

  final OpsRealtime realtime;
  final AlertSound sound;

  /// Sala de voz; null usa LiveKit.
  final VoiceRoom Function()? voice;
  final SosMapBuilder map;
  final Future<void> Function(String url) openUrl;
}

Future<void> _openInNewTab(String url) async {
  await launchUrl(Uri.parse(url), webOnlyWindowName: '_blank');
}

/// Crea el cliente y la sesión con almacenamiento seguro.
({KyqApiClient api, AuthCubit auth}) bootstrap({TokenStore? tokenStore}) {
  late final AuthCubit auth;
  final api = KyqApiClient(
    baseUrl: apiBaseUrl,
    tokenStore: tokenStore ?? SecureTokenStore(),
    onSessionExpired: () => auth.sessionExpired(),
  );
  auth = AuthCubit(api, allowedRoles: {UserRole.admin}, wrongRoleMessage: 'Solo los administradores pueden entrar.')
    ..start();
  return (api: api, auth: auth);
}

class KyqAdminApp extends StatefulWidget {
  const KyqAdminApp({super.key, required this.api, required this.auth, this.ops});

  final KyqApiClient api;
  final AuthCubit auth;

  /// Consola de emergencias; null usa Centrifugo, LiveKit y el aviso sonoro reales.
  final OpsServices? ops;

  @override
  State<KyqAdminApp> createState() => _KyqAdminAppState();
}

class _KyqAdminAppState extends State<KyqAdminApp> {
  late final OpsServices _ops =
      widget.ops ??
      OpsServices(
        realtime: CentrifugoOpsRealtime(
          () => KyqRealtime(
            url: realtimeUrl,
            connectionToken: widget.api.realtimeToken,
            subscriptionToken: widget.api.subscriptionToken,
          ),
        ),
        sound: BeepAlertSound(),
      );

  late final GoRouter _router = buildAuthRouter(
    auth: widget.auth,
    title: 'Kyq Admin',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) =>
            BlocProvider(create: (_) => DriversCubit(widget.api)..load(), child: const DriversPage()),
        routes: [
          GoRoute(path: 'fares', builder: (context, state) => const FareTablePage()),
          GoRoute(
            path: 'emergencies',
            builder: (context, state) => MultiBlocProvider(
              providers: [
                BlocProvider(create: (_) => SosQueueCubit(widget.api, _ops.realtime, _ops.sound)..load()),
                BlocProvider(create: (_) => SosHistoryCubit(widget.api)..load()),
              ],
              child: const EmergenciesPage(),
            ),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) => BlocProvider(
                  create: (_) => SosDetailCubit(
                    widget.api,
                    state.pathParameters['id']!,
                    realtime: _ops.realtime,
                    voice: _ops.voice,
                  )..load(),
                  child: AlertDetailPage(map: _ops.map, openUrl: _ops.openUrl),
                ),
              ),
            ],
          ),
          GoRoute(
            path: 'kyc',
            builder: (context, state) =>
                BlocProvider(create: (_) => KycQueueCubit(widget.api)..load(), child: const KycQueuePage()),
            routes: [
              GoRoute(
                path: 'drivers/:id',
                builder: (context, state) => BlocProvider(
                  create: (_) => KycDriverCubit(widget.api, state.pathParameters['id']!)..load(),
                  child: const KycDriverPage(),
                ),
              ),
            ],
          ),
          GoRoute(
            path: 'billing',
            builder: (context, state) =>
                BlocProvider(create: (_) => SubscriptionsCubit(widget.api)..load(), child: const SubscriptionsPage()),
            routes: [
              GoRoute(
                path: 'drivers/:id',
                builder: (context, state) => BlocProvider(
                  create: (_) => DriverPaymentsCubit(widget.api, state.pathParameters['id']!)..load(),
                  child: DriverPaymentsPage(driverName: state.extra is String ? state.extra! as String : null),
                ),
              ),
            ],
          ),
          GoRoute(
            path: 'costs',
            builder: (context, state) =>
                BlocProvider(create: (_) => CostsCubit(widget.api)..load(), child: const CostsPage()),
            routes: [
              GoRoute(
                path: 'rates',
                builder: (context, state) =>
                    BlocProvider(create: (_) => CostRatesCubit(widget.api)..load(), child: const CostRatesPage()),
              ),
            ],
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
    return RepositoryProvider.value(
      value: widget.api,
      child: BlocProvider.value(
        value: widget.auth,
        child: MaterialApp.router(title: 'Kyq Admin', theme: kyqTheme(), routerConfig: _router),
      ),
    );
  }
}
