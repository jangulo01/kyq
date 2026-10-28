import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_ptt/kyq_ptt.dart';
import 'package:kyq_realtime/kyq_realtime.dart';
import 'package:kyq_ui/kyq_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../domains/domains_page.dart';
import '../emergencies/session_user.dart';
import '../radio/bulk_uploads_page.dart';
import '../radio/radio_settings_page.dart';
import '../radio/reports_page.dart';
import '../support/support_admin_cubits.dart';
import '../support/support_admin_pages.dart';
import '../billing/billing_cubits.dart';
import '../billing/driver_payments_page.dart';
import '../billing/subscriptions_page.dart';
import '../cooperatives/cooperative_detail_page.dart';
import '../cooperatives/cooperatives_cubits.dart';
import '../cooperatives/cooperatives_page.dart';
import '../costs/cost_rates_page.dart';
import '../costs/costs_cubits.dart';
import '../costs/costs_page.dart';
import '../crm/crm_page.dart';
import '../drivers/drivers_cubit.dart';
import '../drivers/drivers_page.dart';
import '../emergencies/alert_detail_page.dart';
import '../emergencies/alert_sound.dart';
import '../emergencies/emergencies_page.dart';
import '../emergencies/emergency_cubits.dart';
import '../emergencies/sos_map.dart';
import '../fares/fare_table_page.dart';
import '../finance/finance_page.dart';
import '../health/health_page.dart';
import '../kyc/kyc_cubits.dart';
import '../kyc/kyc_driver_page.dart';
import '../kyc/kyc_queue_page.dart';
import '../tower/megaphone_cubit.dart';
import '../tower/tower_cubit.dart';
import '../tower/tower_page.dart';
import '../trip_payments/driver_ledger_page.dart';
import '../trip_payments/settlements_page.dart';
import '../trip_payments/trip_payments_cubits.dart';
import '../trip_payments/trip_payments_page.dart';
import '../users/users_page.dart';

const apiBaseUrl = String.fromEnvironment('KYQ_API_URL', defaultValue: 'http://localhost:8080');

/// WebSocket de Centrifugo: torre en vivo (007) y consola de emergencias (003).
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

/// Crea el cliente, la sesión con almacenamiento seguro y los avisos en vivo de la torre.
/// Con [domains] (009) usa los dominios espejo: la API rota sola y el tiempo real toma el
/// dominio en uso al abrir el panel.
({KyqApiClient api, AuthCubit auth, TowerEvents towerEvents}) bootstrap({
  TokenStore? tokenStore,
  DomainRotator? domains,
}) {
  late final AuthCubit auth;
  final api = KyqApiClient(
    baseUrl: apiBaseUrl,
    tokenStore: tokenStore ?? SecureTokenStore(),
    onSessionExpired: () => auth.sessionExpired(),
  );
  if (domains != null) useDomains(api, domains);
  auth = AuthCubit(api, allowedRoles: {UserRole.admin}, wrongRoleMessage: 'Solo los administradores pueden entrar.')
    ..start();
  final realtime = KyqRealtime(
    url: domains?.current.realtimeUrl ?? realtimeUrl,
    connectionToken: api.realtimeToken,
    subscriptionToken: api.subscriptionToken,
  );
  return (api: api, auth: auth, towerEvents: RealtimeTowerEvents(realtime));
}

class KyqAdminApp extends StatefulWidget {
  const KyqAdminApp({
    super.key,
    required this.api,
    required this.auth,
    this.towerEvents,
    this.ops,
    this.pickCsv = pickCsvFile,
    this.reportPlayer,
  });

  final KyqApiClient api;
  final AuthCubit auth;

  /// Avisos en vivo de la torre; sin ellos la torre se actualiza cada 30 s.
  final TowerEvents? towerEvents;

  /// Consola de emergencias; null usa Centrifugo, LiveKit y el aviso sonoro reales.
  final OpsServices? ops;

  /// CSV de las cargas masivas de Radio (011); las pruebas pasan uno en memoria.
  final CsvPicker pickCsv;

  /// Audio de los mensajes reportados; null usa audioplayers.
  final ReportPlayer? reportPlayer;

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

  /// Administrador de la sesión (claim `sub`), para asignarse casos de soporte.
  String? _adminId;

  @override
  void initState() {
    super.initState();
    widget.api.currentSession().then((t) {
      if (t != null) _adminId = userIdFromAccessToken(t.accessToken);
    });
  }

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
            path: 'tower',
            builder: (context, state) => MultiBlocProvider(
              providers: [
                BlocProvider(create: (_) => TowerCubit(widget.api, events: widget.towerEvents)..start()),
                // 009: megáfono por hexágonos.
                BlocProvider(
                  create: (_) => AdminMegaphoneCubit(widget.api, room: widget.ops?.voice ?? LiveKitVoiceRoom.new),
                ),
              ],
              child: const TowerPage(),
            ),
          ),
          GoRoute(
            path: 'finance',
            builder: (context, state) =>
                BlocProvider(create: (_) => FinanceCubit(widget.api)..load(), child: const FinancePage()),
          ),
          GoRoute(
            path: 'crm',
            builder: (context, state) =>
                BlocProvider(create: (_) => CrmCubit(widget.api)..load(), child: const CrmPage()),
          ),
          GoRoute(
            path: 'users',
            builder: (context, state) =>
                BlocProvider(create: (_) => UsersCubit(widget.api)..search(), child: const UsersPage()),
          ),
          GoRoute(
            path: 'health',
            builder: (context, state) =>
                BlocProvider(create: (_) => HealthCubit(widget.api)..start(), child: const HealthPage()),
          ),
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
            path: 'cooperatives',
            builder: (context, state) =>
                BlocProvider(create: (_) => CooperativesCubit(widget.api)..load(), child: const CooperativesPage()),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) => BlocProvider(
                  create: (_) => CooperativeDetailCubit(widget.api, state.pathParameters['id']!)..load(),
                  child: const CooperativeDetailPage(),
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
          // 004: pagos de viajes, incidencias y liquidaciones a conductores.
          GoRoute(
            path: 'trip-payments',
            builder: (context, state) =>
                BlocProvider(create: (_) => TripPaymentsCubit(widget.api)..load(), child: const TripPaymentsPage()),
            routes: [
              GoRoute(
                path: 'settlements',
                builder: (context, state) =>
                    BlocProvider(create: (_) => SettlementsCubit(widget.api)..load(), child: const SettlementsPage()),
                routes: [
                  GoRoute(
                    path: 'drivers/:id',
                    builder: (context, state) => BlocProvider(
                      create: (_) => DriverLedgerCubit(widget.api, state.pathParameters['id']!)..load(),
                      child: DriverLedgerPage(driverName: state.extra is String ? state.extra! as String : null),
                    ),
                  ),
                ],
              ),
            ],
          ),
          // 009: centro de soporte y disputas.
          GoRoute(
            path: 'support',
            builder: (context, state) =>
                BlocProvider(create: (_) => SupportInboxCubit(widget.api)..load(), child: const SupportInboxPage()),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) => BlocProvider(
                  create: (_) => SupportAdminCaseCubit(widget.api, state.pathParameters['id']!)..load(),
                  child: SupportAdminCasePage(adminId: _adminId),
                ),
              ),
            ],
          ),
          // 009: dominios espejo.
          GoRoute(
            path: 'domains',
            builder: (context, state) =>
                BlocProvider(create: (_) => DomainsCubit(widget.api)..load(), child: const DomainsPage()),
          ),
          // 011: configuración de Radio y cargas masivas de invitaciones.
          GoRoute(
            path: 'radio',
            builder: (context, state) =>
                BlocProvider(create: (_) => RadioSettingsCubit(widget.api)..load(), child: const RadioSettingsPage()),
            routes: [
              GoRoute(
                path: 'reports',
                builder: (context, state) =>
                    BlocProvider(create: (_) => RadioReportsCubit(widget.api)..load(), child: const RadioReportsPage()),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) => BlocProvider(
                      create: (_) => RadioReportCubit(widget.api, state.pathParameters['id']!)..load(),
                      child: RadioReportPage(player: widget.reportPlayer ?? AudioplayersReportPlayer()),
                    ),
                  ),
                ],
              ),
              GoRoute(
                path: 'bulk',
                builder: (context, state) => BlocProvider(
                  create: (_) => BulkUploadsCubit(widget.api)..load(),
                  child: BulkUploadsPage(pick: widget.pickCsv),
                ),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) => BlocProvider(
                      create: (_) => BulkDetailCubit(widget.api, state.pathParameters['id']!)..load(),
                      child: const BulkDetailPage(),
                    ),
                  ),
                ],
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
