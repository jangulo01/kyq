import 'package:url_launcher/url_launcher.dart';

/// Abre el checkout de Bold del pago del viaje. Las pruebas usan un falso que solo anota la URL.
abstract interface class CheckoutLauncher {
  /// false si no se pudo abrir.
  Future<bool> open(String url);
}

/// Custom Tab (Android): el pasajero paga sin salir de la app y vuelve con el botón atrás.
class CustomTabCheckout implements CheckoutLauncher {
  const CustomTabCheckout();

  @override
  Future<bool> open(String url) async {
    final uri = Uri.parse(url);
    try {
      return await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    } on Object {
      // Sin Custom Tabs, el navegador externo también sirve.
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
