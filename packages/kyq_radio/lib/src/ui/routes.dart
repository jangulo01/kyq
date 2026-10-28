import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'add_contact.dart';
import 'channels.dart';
import 'conversation_page.dart';
import 'radio_page.dart';
import 'settings_page.dart';

/// Rutas de Radio para el go_router de cada app, bajo `/radio` (deps.dart: [RadioRoutes]).
/// [extra] añade las de cada app (ajustes, canales, modo auto). [scope] envuelve cada pantalla:
/// la app pone ahí el [RadioCubit] y los [RadioDeps] cuando ya conoce al usuario.
GoRoute radioRoute({List<RouteBase> extra = const [], RadioScope scope = _bare}) => GoRoute(
  path: 'radio',
  builder: (context, state) => scope(context, const RadioPage()),
  routes: [
    GoRoute(
      path: 'c/:id',
      builder: (context, state) => scope(context, ConversationScreen(conversationId: state.pathParameters['id']!)),
    ),
    GoRoute(
      path: 'invite/:code',
      builder: (context, state) => scope(context, InviteAcceptPage(code: state.pathParameters['code']!)),
    ),
    GoRoute(path: 'channels/new', builder: (context, state) => scope(context, const NewChannelPage())),
    GoRoute(
      path: 'channels/:id',
      builder: (context, state) => scope(context, ChannelPage(conversationId: state.pathParameters['id']!)),
    ),
    GoRoute(path: 'settings', builder: (context, state) => scope(context, const RadioSettingsPage())),
    ...extra,
  ],
);

/// `kyq://radio/{code}` (intent-filter de las dos apps) → la pantalla de la invitación.
String? radioDeepLinkRedirect(Uri uri) {
  if (uri.scheme == 'kyq' && uri.host == 'radio' && uri.pathSegments.length == 1) {
    return '/radio/invite/${uri.pathSegments.first}';
  }
  final segments = uri.pathSegments;
  if (segments.length == 2 && segments.first == 'r') return '/radio/invite/${segments[1]}';
  return null;
}

/// Envuelve una pantalla de Radio con lo que necesita (ver [radioRoute]).
typedef RadioScope = Widget Function(BuildContext context, Widget page);

Widget _bare(BuildContext context, Widget page) => page;
