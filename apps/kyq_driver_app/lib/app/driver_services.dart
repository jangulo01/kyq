import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_ptt/kyq_ptt.dart';
import 'package:kyq_ui/kyq_ui.dart';

import '../background/foreground_service.dart';
import '../background/geolocator_source.dart';
import '../background/location_reporter.dart';
import '../background/online_permissions.dart';
import '../handsfree/platform_hands_free.dart';
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
    required this.preconsultPtt,
    required this.handsFree,
    required this.handsFreePrefs,
    required this.overlayPermission,
    this.cooperativePtt = PttController.cooperative,
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
    preconsultPtt: PttController.livePreconsult,
    handsFree: const MethodChannelHandsFree(),
    handsFreePrefs: const SharedPrefsHandsFreeStore(),
    overlayPermission: const PlatformOverlayPermission(),
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

  /// Walkie-talkie de cada pre-consulta de voz (005, RN-KYQ-010).
  final PttControllerFactory preconsultPtt;

  /// Botón físico y burbuja flotante (005, RN-KYQ-012).
  final HandsFreePlatform handsFree;
  final HandsFreePrefsStore handsFreePrefs;
  final OverlayPermission overlayPermission;

  /// Walkie-talkie de grupo de la cooperativa (006, COOP_GROUP).
  final PttController Function(KyqApiClient api) cooperativePtt;

  /// SOS, viaje compartido y 123 (003).
  final SafetyPlatform safety;
}
