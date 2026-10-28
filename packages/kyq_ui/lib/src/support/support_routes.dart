import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kyq_api/kyq_api.dart';

import '../auth/auth_cubit.dart';
import 'support_cubits.dart';
import 'support_pages.dart';

/// Ruta del centro de soporte en las apps (009).
const supportLocation = '/support';

/// Cada cuánto se vuelve a pedir una conversación abierta (SC-003: < 10 s).
const supportRefresh = Duration(seconds: 8);

/// `/support`, `/support/new` y `/support/{caseId}`. Lee [KyqApiClient] y [AuthCubit] del árbol.
GoRoute supportRoute({Duration? refreshEvery = supportRefresh}) => GoRoute(
  path: supportLocation,
  builder: (context, state) {
    final auth = context.read<AuthCubit>();
    final suspended = auth.state is AuthSupportOnly;
    return BlocProvider(
      create: (context) => SupportListCubit(context.read<KyqApiClient>(), refreshEvery: refreshEvery)..load(),
      child: SupportListPage(suspended: suspended, onSignOut: suspended ? auth.signOut : null),
    );
  },
  routes: [
    GoRoute(
      path: 'new',
      builder: (context, state) => BlocProvider(
        create: (context) => NewCaseCubit(context.read<KyqApiClient>())..loadTrips(),
        child: const NewSupportCasePage(),
      ),
    ),
    GoRoute(
      path: ':caseId',
      builder: (context, state) => BlocProvider(
        create: (context) =>
            SupportCaseCubit(context.read<KyqApiClient>(), state.pathParameters['caseId']!, refreshEvery: refreshEvery)
              ..load(),
        child: const SupportCasePage(),
      ),
    ),
  ],
);
