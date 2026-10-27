import 'dart:async';

import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_driver_app/app/driver_services.dart';
import 'package:kyq_driver_app/background/foreground_service.dart';
import 'package:kyq_driver_app/background/location_reporter.dart';
import 'package:kyq_driver_app/background/online_permissions.dart';
import 'package:kyq_driver_app/realtime/driver_events.dart';
import 'package:kyq_ptt/kyq_ptt.dart';
import 'package:kyq_ptt/testing.dart';
import 'package:kyq_realtime/kyq_realtime.dart';
import 'package:mocktail/mocktail.dart';

class MockApi extends Mock implements KyqApiClient {
  // La pantalla de inicio siempre pregunta por un viaje en curso; por defecto no hay ninguno.
  @override
  Future<Trip?> activeTrip() async => null;
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
}) => DriverServices(
  events: events ?? FakeEventSource(),
  permissions: permissions ?? FakePermissions(),
  onlineService: service ?? FakeOnlineService(),
  positions: FakePositions(),
  ptt: ptt ?? fakePttFactory([]),
);

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
