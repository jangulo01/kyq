import 'package:kyq_api/kyq_api.dart';
import 'package:url_launcher/url_launcher.dart';

enum NavigationApp { waze, googleMaps }

/// Enlaces a probar en orden: la app pedida y, si no está, cualquier app de mapas (`geo:`).
List<Uri> navigationUris(NavigationApp app, GeoPoint p) {
  final ll = '${p.lat},${p.lng}';
  return [
    switch (app) {
      NavigationApp.waze => Uri.parse('waze://?ll=$ll&navigate=yes'),
      NavigationApp.googleMaps => Uri.parse('google.navigation:q=$ll'),
    },
    Uri.parse('geo:$ll?q=$ll'),
  ];
}

/// Abre la ruta hacia [p] en una app externa (FR-014). Devuelve false si no hay ninguna.
Future<bool> openNavigation(NavigationApp app, GeoPoint p, {Future<bool> Function(Uri uri)? launcher}) async {
  final launch = launcher ?? (uri) => launchUrl(uri, mode: LaunchMode.externalApplication);
  for (final uri in navigationUris(app, p)) {
    try {
      if (await launch(uri)) return true;
    } on Object {
      // Sin app para este esquema: probamos el siguiente.
    }
  }
  return false;
}
