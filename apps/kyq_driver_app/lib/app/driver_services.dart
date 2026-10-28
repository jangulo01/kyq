import 'package:kyq_ptt/kyq_ptt.dart';
import 'package:kyq_ui/kyq_ui.dart';

import '../background/foreground_service.dart';
import '../background/geolocator_source.dart';
import '../background/location_reporter.dart';
import '../background/online_permissions.dart';
import '../onboarding/photo_source.dart';
import '../realtime/driver_events.dart';
import '../safety/platform_safety.dart';
import '../subscription/checkout_launcher.dart';

/// Servicios de plataforma de la app. Las pruebas pasan falsos para no abrir sockets ni tocar
/// el GPS, la cámara o el navegador.
class DriverServices {
  const DriverServices({
    required this.events,
    required this.permissions,
    required this.onlineService,
    required this.positions,
    required this.ptt,
    required this.photos,
    required this.checkout,
    required this.safety,
  });

  factory DriverServices.platform(DriverEventSource events) => DriverServices(
    events: events,
    permissions: PlatformOnlinePermissions(),
    onlineService: ForegroundOnlineService(),
    positions: GeolocatorPositionSource(),
    ptt: PttController.live,
    photos: PlatformPhotoSource(),
    checkout: const CustomTabCheckout(),
    safety: platformSafety(),
  );

  final DriverEventSource events;
  final OnlinePermissions permissions;
  final OnlineService onlineService;
  final PositionSource positions;

  /// Walkie-talkie de cada viaje (T074). La sala sigue viva en segundo plano gracias al servicio
  /// ONLINE, que declara los tipos `microphone|mediaPlayback`.
  final PttControllerFactory ptt;

  /// Fotos de los documentos (T017).
  final PhotoSource photos;

  /// Checkout de Bold (T032).
  final CheckoutLauncher checkout;

  /// SOS, viaje compartido y 123 (003).
  final SafetyPlatform safety;
}
