import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_ui/kyq_ui.dart';

import 'home_page.dart';

/// URL del backend. En el emulador de Android, 10.0.2.2 es el localhost del PC.
const apiBaseUrl = String.fromEnvironment('KYQ_API_URL', defaultValue: 'http://10.0.2.2:8080');

/// Crea el cliente y la sesión con almacenamiento seguro.
({KyqApiClient api, AuthCubit auth}) bootstrap({TokenStore? tokenStore}) {
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
  return (api: api, auth: auth);
}

class KyqRiderApp extends StatefulWidget {
  const KyqRiderApp({super.key, required this.api, required this.auth});

  final KyqApiClient api;
  final AuthCubit auth;

  @override
  State<KyqRiderApp> createState() => _KyqRiderAppState();
}

class _KyqRiderAppState extends State<KyqRiderApp> {
  late final GoRouter _router = buildAuthRouter(
    auth: widget.auth,
    title: 'Kyq Pasajero',
    routes: [GoRoute(path: '/', builder: (context, state) => const HomePage())],
  );

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [RepositoryProvider.value(value: widget.api)],
      child: BlocProvider.value(
        value: widget.auth,
        child: MaterialApp.router(title: 'Kyq Pasajero', theme: kyqTheme(), routerConfig: _router),
      ),
    );
  }
}
