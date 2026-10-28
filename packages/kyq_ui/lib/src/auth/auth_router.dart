import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../support/support_routes.dart';
import 'auth_cubit.dart';
import 'login_page.dart';

/// Router con guardia de sesión: sin sesión todo lleva a `/login`; con sesión, `/login` lleva
/// a `/`. [routes] son las rutas de la app bajo `/`.
///
/// [guard] decide redirecciones propias de la app con sesión iniciada (p. ej. completar el alta);
/// se evalúa en cada navegación.
///
/// Con [withSupport] (apps de pasajero y conductor) monta el centro de soporte en `/support`,
/// que es lo único que ve una cuenta suspendida (009).
GoRouter buildAuthRouter({
  required AuthCubit auth,
  required String title,
  required List<RouteBase> routes,
  String countryCode = '+57',
  String? subtitle,
  String? newAccountHint,
  GoRouterRedirect? guard,
  bool withSupport = false,
}) {
  return GoRouter(
    refreshListenable: _CubitListenable(auth),
    redirect: (context, state) {
      final atLogin = state.matchedLocation == '/login';
      return switch (auth.state) {
        AuthUnknown() => null,
        AuthSignedIn() => atLogin ? '/' : guard?.call(context, state),
        // 009: una cuenta suspendida solo ve el centro de soporte.
        AuthSupportOnly() => state.matchedLocation.startsWith(supportLocation) ? null : supportLocation,
        _ => atLogin ? null : '/login',
      };
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) =>
            LoginPage(title: title, countryCode: countryCode, subtitle: subtitle, newAccountHint: newAccountHint),
      ),
      if (withSupport) supportRoute(),
      ...routes,
    ],
  );
}

class _CubitListenable extends ChangeNotifier {
  _CubitListenable(AuthCubit cubit) {
    _sub = cubit.stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<AuthState> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
