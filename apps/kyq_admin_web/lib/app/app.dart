import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_ui/kyq_ui.dart';

import '../billing/billing_cubits.dart';
import '../billing/driver_payments_page.dart';
import '../billing/subscriptions_page.dart';
import '../costs/cost_rates_page.dart';
import '../costs/costs_cubits.dart';
import '../costs/costs_page.dart';
import '../drivers/drivers_cubit.dart';
import '../drivers/drivers_page.dart';
import '../fares/fare_table_page.dart';
import '../kyc/kyc_cubits.dart';
import '../kyc/kyc_driver_page.dart';
import '../kyc/kyc_queue_page.dart';
import '../trip_payments/driver_ledger_page.dart';
import '../trip_payments/settlements_page.dart';
import '../trip_payments/trip_payments_cubits.dart';
import '../trip_payments/trip_payments_page.dart';

const apiBaseUrl = String.fromEnvironment('KYQ_API_URL', defaultValue: 'http://localhost:8080');

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
  const KyqAdminApp({super.key, required this.api, required this.auth});

  final KyqApiClient api;
  final AuthCubit auth;

  @override
  State<KyqAdminApp> createState() => _KyqAdminAppState();
}

class _KyqAdminAppState extends State<KyqAdminApp> {
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
