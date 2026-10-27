import '../background/foreground_service.dart';
import '../background/geolocator_source.dart';
import '../background/location_reporter.dart';
import '../background/online_permissions.dart';
import '../realtime/driver_events.dart';

/// Servicios de plataforma de la app. Las pruebas pasan falsos para no abrir sockets ni tocar
/// el GPS.
class DriverServices {
  const DriverServices({
    required this.events,
    required this.permissions,
    required this.onlineService,
    required this.positions,
  });

  factory DriverServices.platform(DriverEventSource events) => DriverServices(
    events: events,
    permissions: PlatformOnlinePermissions(),
    onlineService: ForegroundOnlineService(),
    positions: GeolocatorPositionSource(),
  );

  final DriverEventSource events;
  final OnlinePermissions permissions;
  final OnlineService onlineService;
  final PositionSource positions;
}
