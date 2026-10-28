import 'dart:async';

import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_ptt/kyq_ptt.dart';
import 'package:kyq_ui/kyq_ui.dart';

SosAlertSelf alert({SosStatus status = SosStatus.open, bool operator = false, bool escalated = false}) => SosAlertSelf(
  id: 'al1',
  tripId: 't1',
  status: status,
  operatorConnected: operator,
  escalated: escalated,
  createdAt: DateTime.utc(2026, 10, 27, 22),
);

const voice = SosVoice(url: 'ws://lk', token: 'tok', room: 'sos-al1', canPublish: true);

/// API de seguridad en memoria: cada método usa su respuesta configurable.
class FakeSafetyApi implements SafetyApi {
  Future<SosRaise> Function(SosPoint? location) onRaise = (_) async =>
      SosRaise(alert: alert(), voice: voice, needsPin: true);
  Future<SosAlertSelf> Function(List<SosPoint> points) onLocations = (_) async => alert();
  Future<void> Function(String pin) onCancel = (_) async {};
  SosAlertSelf? active;
  final raised = <SosPoint?>[];
  final batches = <List<SosPoint>>[];
  final cancels = <String>[];

  List<EmergencyContact> contacts = [];
  bool hasPin = false;
  final pins = <(String, String?)>[];
  ApiException? failContacts;
  int shares = 0;

  @override
  Future<SosRaise> raiseSos(String tripId, {SosPoint? location}) {
    raised.add(location);
    return onRaise(location);
  }

  @override
  Future<SosAlertSelf?> activeSos() async => active;

  @override
  Future<SosAlertSelf> sendSosLocations(String alertId, List<SosPoint> points) {
    batches.add(points);
    return onLocations(points);
  }

  @override
  Future<void> cancelSos(String alertId, String pin) {
    cancels.add(pin);
    return onCancel(pin);
  }

  @override
  Future<SosVoice> sosToken(String alertId) async => voice;

  @override
  Future<ShareLink> shareTrip(String tripId) async {
    shares++;
    return const ShareLink(token: 'abc', url: 'https://kyq.test/s/abc');
  }

  @override
  Future<List<EmergencyContact>> emergencyContacts() async => contacts;

  @override
  Future<List<EmergencyContact>> setEmergencyContacts(List<EmergencyContact> contacts) async {
    if (failContacts != null) throw failContacts!;
    return this.contacts = contacts;
  }

  @override
  Future<bool> hasSafetyPin() async => hasPin;

  @override
  Future<void> setSafetyPin(String pin, {String? currentPin}) async {
    if (hasPin && currentPin != '2468') throw const ApiException(403, 'wrong_current_pin', 'no coincide');
    pins.add((pin, currentPin));
    hasPin = true;
  }
}

class FakeVoiceRoom implements VoiceRoom {
  final _events = StreamController<VoiceRoomEvent>.broadcast();
  bool connected = false;
  bool mic = false;
  bool failConnect = false;

  @override
  Stream<VoiceRoomEvent> get events => _events.stream;

  @override
  String? get localIdentity => 'me';

  @override
  Future<void> connect(String url, String token) async {
    if (failConnect) throw Exception('livekit caído');
    connected = true;
  }

  @override
  Future<void> setMicrophoneEnabled(bool enabled) async => mic = enabled;

  @override
  Future<void> sendData(Map<String, Object?> message) async {}

  @override
  Future<void> disconnect() async {
    connected = false;
    mic = false;
  }

  void emit(VoiceRoomEvent e) => _events.add(e);
}

class FakeMic implements MicPermission {
  FakeMic({this.granted = true});

  bool granted;

  @override
  Future<bool> isGranted() async => granted;

  @override
  Future<MicAccess> request() async => granted ? MicAccess.granted : MicAccess.denied;

  @override
  Future<void> openSettings() async {}
}

/// GPS falso: cada lectura avanza un segundo.
class FakeSosLocation implements SosLocationSource {
  FakeSosLocation({this.available = true});

  bool available;
  bool stopped = false;
  var _t = DateTime.utc(2026, 10, 27, 22);

  @override
  Future<SosPoint?> current() async {
    if (!available) return null;
    _t = _t.add(const Duration(seconds: 1));
    return SosPoint(lat: 4.61, lng: -74.07, accuracyM: 5, recordedAt: _t);
  }

  @override
  Future<void> stop() async => stopped = true;
}
