import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_ui/kyq_ui.dart';

import '../drivers/drivers_cubit.dart';
import '../drivers/drivers_page.dart';

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
    return BlocProvider.value(
      value: widget.auth,
      child: MaterialApp.router(title: 'Kyq Admin', theme: kyqTheme(), routerConfig: _router),
    );
  }
}
