import 'dart:async';
import 'dart:typed_data';

import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_driver_app/app/driver_services.dart';
import 'package:kyq_driver_app/background/foreground_service.dart';
import 'package:kyq_driver_app/background/location_reporter.dart';
import 'package:kyq_driver_app/background/online_permissions.dart';
import 'package:kyq_driver_app/handsfree/platform_hands_free.dart';
import 'package:kyq_driver_app/onboarding/photo_source.dart';
import 'package:kyq_driver_app/realtime/driver_events.dart';
import 'package:kyq_driver_app/subscription/checkout_launcher.dart';
import 'package:kyq_ptt/kyq_ptt.dart';
import 'package:kyq_ptt/testing.dart';
import 'package:kyq_realtime/kyq_realtime.dart';
import 'package:mocktail/mocktail.dart';

class MockApi extends Mock implements KyqApiClient {
  // La pantalla de inicio siempre pregunta por un viaje en curso; por defecto no hay ninguno.
  @override
  Future<Trip?> activeTrip() async => null;
}

/// Conductor con el alta terminada: el router no lo desvía a vehículo ni documentos.
const onboardingOk = Onboarding(status: OnboardingStatus.documentsOk);

/// Respuestas por defecto de las rutas de 002 que la app consulta al iniciar sesión.
void stubOnboardingDefaults(MockApi api, {Onboarding onboarding = onboardingOk, List<Notice> notices = const []}) {
  when(() => api.driverOnboarding()).thenAnswer((_) async => onboarding);
  when(() => api.driverNotices()).thenAnswer((_) async => notices);
  when(() => api.driverPreconsults()).thenAnswer((_) async => []);
}

/// PNG de 1×1 válido, para que las vistas previas se dibujen sin errores.
final tinyImage = Uint8List.fromList([
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, //
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
  0x42, 0x60, 0x82,
]);

/// Cámara y galería falsas: devuelven [next] (o una imagen mínima) y anotan de dónde.
class FakePhotoSource implements PhotoSource {
  final origins = <PhotoOrigin>[];
  Uint8List? next;
  Object? error;

  @override
  Future<Uint8List?> pick(PhotoOrigin origin) async {
    origins.add(origin);
    final e = error;
    if (e != null) throw e;
    return next ?? tinyImage;
  }
}

/// Custom Tab falsa: solo anota las URLs abiertas.
class FakeCheckout implements CheckoutLauncher {
  final opened = <String>[];
  bool succeed = true;

  @override
  Future<bool> open(String url) async {
    opened.add(url);
    return succeed;
  }
}

/// Eventos de tiempo real empujados a mano, sin sockets.
class FakeEventSource implements DriverEventSource {
  final controller = StreamController<RealtimeEvent>.broadcast();
  final subscribedUsers = <String>[];

  void push(RealtimeEvent e) => controller.add(e);

  @override
  Stream<RealtimeEvent> userEvents(String userId) {
    subscribedUsers.add(userId);
    return controller.stream;
  }

  @override
  Future<void> close() async {}
}

class FakePermissions implements OnlinePermissions {
  FakePermissions({this.granted = true});

  bool granted;
  int requests = 0;

  @override
  Future<bool> allGranted() async => granted;

  @override
  Future<bool> requiredGranted() async => granted;

  @override
  Future<bool> request() async {
    requests++;
    granted = true;
    return true;
  }

  @override
  Future<void> openSettings() async {}
}

class FakeOnlineService implements OnlineService {
  bool running = false;

  @override
  Future<void> start() async => running = true;

  @override
  Future<void> stop() async => running = false;
}

class FakePositions implements PositionSource {
  final fixes = <LocationFix?>[];
  int stops = 0;

  @override
  Future<LocationFix?> current() async => fixes.isEmpty ? null : fixes.removeAt(0);

  @override
  Future<void> stop() async => stops++;
}

DriverServices fakeServices({
  FakeEventSource? events,
  FakePermissions? permissions,
  FakeOnlineService? service,
  PttControllerFactory? ptt,
  FakePhotoSource? photos,
  FakeCheckout? checkout,
  PttControllerFactory? preconsultPtt,
  FakeHandsFreePlatform? handsFree,
  FakeHandsFreePrefs? handsFreePrefs,
  FakeOverlayPermission? overlay,
}) => DriverServices(
  events: events ?? FakeEventSource(),
  permissions: permissions ?? FakePermissions(),
  onlineService: service ?? FakeOnlineService(),
  positions: FakePositions(),
  ptt: ptt ?? fakePttFactory([]),
  photos: photos ?? FakePhotoSource(),
  checkout: checkout ?? FakeCheckout(),
  preconsultPtt: preconsultPtt ?? fakePttFactory([]),
  handsFree: handsFree ?? FakeHandsFreePlatform(),
  handsFreePrefs: handsFreePrefs ?? FakeHandsFreePrefs(),
  overlayPermission: overlay ?? FakeOverlayPermission(),
);

/// Preferencias del manos libres en memoria.
class FakeHandsFreePrefs implements HandsFreePrefsStore {
  HandsFreePrefs prefs = (mediaButton: true, bubble: true);

  @override
  Future<HandsFreePrefs> load() async => prefs;

  @override
  Future<void> save(HandsFreePrefs value) async => prefs = value;
}

/// Permiso de superposición: [onRequest] es lo que "concede" el conductor en los ajustes.
class FakeOverlayPermission implements OverlayPermission {
  FakeOverlayPermission({this.granted = false, this.onRequest = true});

  bool granted;
  bool onRequest;
  int requests = 0;

  @override
  Future<bool> isGranted() async => granted;

  @override
  Future<bool> request() async {
    requests++;
    return granted = onRequest;
  }
}

final tripNow = DateTime.utc(2026, 10, 27, 12);

TripOffered offerEvent({String tripId = 't1', DateTime? expiresAt}) => TripOffered(
  tripNow,
  tripId: tripId,
  passengerName: 'Ana',
  pickup: (lat: 4.6, lng: -74.05),
  dropoff: (lat: 4.7, lng: -74.1),
  distanceM: 4200,
  durationS: 720,
  suggestedFareMinor: 1470000,
  currency: 'COP',
  expiresAt: expiresAt ?? tripNow.add(const Duration(seconds: 25)),
);

Trip trip({
  String id = 't1',
  TripStatus status = TripStatus.accepted,
  int? agreedFareMinor = 1470000,
  FareProposal? openProposal,
  String? cancelReason,
  DateTime? negotiationExpiresAt,
}) => Trip(
  id: id,
  status: status,
  passengerId: 'p1',
  driverId: 'd1',
  pickup: const GeoPoint(lat: 4.6, lng: -74.05),
  dropoff: const GeoPoint(lat: 4.7, lng: -74.1),
  distanceM: 4200,
  durationS: 720,
  currency: 'COP',
  suggestedFareMinor: 1470000,
  agreedFareMinor: agreedFareMinor,
  driverPayoutMinor: status == TripStatus.completed ? agreedFareMinor : null,
  openProposal: openProposal,
  cancelReason: cancelReason,
  negotiationExpiresAt: negotiationExpiresAt,
);
