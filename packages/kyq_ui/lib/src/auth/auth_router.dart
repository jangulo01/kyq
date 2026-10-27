import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'auth_cubit.dart';
import 'login_page.dart';

/// Router con guardia de sesión: sin sesión todo lleva a `/login`; con sesión, `/login` lleva
/// a `/`. [routes] son las rutas de la app bajo `/`.
GoRouter buildAuthRouter({
  required AuthCubit auth,
  required String title,
  required List<RouteBase> routes,
  String countryCode = '+57',
}) {
  return GoRouter(
    refreshListenable: _CubitListenable(auth),
    redirect: (context, state) {
      final atLogin = state.matchedLocation == '/login';
      return switch (auth.state) {
        AuthUnknown() => null,
        AuthSignedIn() => atLogin ? '/' : null,
        _ => atLogin ? null : '/login',
      };
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => LoginPage(title: title, countryCode: countryCode),
      ),
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
