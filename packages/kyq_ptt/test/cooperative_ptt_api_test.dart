import 'package:flutter_test/flutter_test.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_ptt/kyq_ptt.dart';

/// Cliente con las rutas del canal de grupo simuladas.
class _GroupClient extends KyqApiClient {
  _GroupClient(this.status, {this.code = 'x'}) : super(baseUrl: 'http://api.test', tokenStore: InMemoryTokenStore());

  final int? status;

  /// Código de error del cuerpo; el backend responde `404 no_cooperative` al que ya no es miembro.
  final String code;

  Never _fail() => throw ApiException(status, code, 'x');

  @override
  Future<PttCredentials> cooperativePttToken() async {
    if (status != null) _fail();
    return const PttCredentials(url: 'ws://voz', token: 'tk', room: 'coop-c1');
  }

  @override
  Future<DateTime> requestCooperativeFloor() async {
    if (status != null) _fail();
    return DateTime.utc(2026, 10, 27, 12, 1);
  }

  @override
  Future<void> releaseCooperativeFloor() async {
    if (status != null) _fail();
  }
}

void main() {
  test('canal de grupo: credenciales y turno', () async {
    final api = KyqCooperativePttApi(_GroupClient(null));
    expect((await api.token()).room, 'coop-c1');
    expect(await api.requestFloor(), DateTime.utc(2026, 10, 27, 12, 1));
  });

  test('409 es turno ocupado; 404 (ya no es miembro) cierra el canal', () async {
    expect(KyqCooperativePttApi(_GroupClient(409)).requestFloor(), throwsA(isA<PttFloorBusy>()));
    expect(KyqCooperativePttApi(_GroupClient(404, code: 'no_cooperative')).token(), throwsA(isA<PttChannelClosed>()));
    expect(KyqCooperativePttApi(_GroupClient(410)).requestFloor(), throwsA(isA<PttChannelClosed>()));
    // Un 404 que no es `no_cooperative` (p. ej. de un proxy) no cierra el canal: se reintenta.
    expect(KyqCooperativePttApi(_GroupClient(404)).token(), throwsA(isA<ApiException>()));
    expect(KyqCooperativePttApi(_GroupClient(503)).releaseFloor(), throwsA(isA<ApiException>()));
  });
}
