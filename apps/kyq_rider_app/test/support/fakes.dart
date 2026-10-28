import 'dart:async';
import 'dart:convert';

import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_realtime/kyq_realtime.dart';
import 'package:kyq_rider_app/realtime/realtime_events.dart';
import 'package:kyq_rider_app/request/location_source.dart';
import 'package:mocktail/mocktail.dart';

class MockApi extends Mock implements KyqApiClient {
  // La pantalla de inicio siempre pregunta por un viaje en curso; por defecto no hay ninguno.
  @override
  Future<Trip?> activeTrip() async => null;

  // Pantalla del viaje: por defecto no hay alerta SOS abierta (003).
  @override
  Future<SosAlertSelf?> activeSos() async => null;
}

/// Tiempo real en memoria: las pruebas empujan eventos con [emit].
class FakeRealtime implements RealtimeEvents {
  final _channels = <String, StreamController<RealtimeEvent>>{};

  @override
  Stream<RealtimeEvent> subscribe(String channel) =>
      (_channels[channel] ??= StreamController<RealtimeEvent>.broadcast()).stream;

  bool isSubscribed(String channel) => _channels[channel]?.hasListener ?? false;

  void emit(String channel, RealtimeEvent event) => _channels[channel]?.add(event);
}

class FakeLocation implements LocationSource {
  FakeLocation({this.granted = true, this.position = const GeoPoint(lat: 4.65, lng: -74.05), this.failure});

  final bool granted;
  final GeoPoint position;
  final LocationUnavailable? failure;

  @override
  Future<bool> hasPermission() async => granted;

  @override
  Future<GeoPoint> current() async {
    if (failure != null) throw failure!;
    return position;
  }
}

/// JWT sin firma válida con `sub` = [userId]; basta para leer el claim.
String fakeAccessToken(String userId) {
  String part(String json) => base64Url.encode(json.codeUnits).replaceAll('=', '');
  return '${part('{"alg":"HS256"}')}.${part('{"sub":"$userId","role":"passenger"}')}.firma';
}
