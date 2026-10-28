import 'package:dio/dio.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:test/test.dart';

const _session = {'access_token': 'a1', 'refresh_token': 'r1', 'role': 'passenger'};

Map<String, dynamic> preconsultJson({String status = 'open', String? reason}) => {
  'id': 'pc1',
  'passenger_id': 'p1',
  'passenger_name': 'Ana',
  'driver_id': 'd1',
  'driver_name': 'Carlos',
  'status': status,
  'opened_at': '2026-10-27T12:00:00Z',
  'join_deadline': '2026-10-27T12:00:30Z',
  'closes_at': '2026-10-27T12:02:00Z',
  'joined_at': null,
  'answered_at': null,
  'closed_at': reason == null ? null : '2026-10-27T12:01:00Z',
  'close_reason': reason,
};

void main() {
  late DioAdapter adapter;
  late KyqApiClient client;

  setUp(() async {
    final dio = Dio();
    adapter = DioAdapter(dio: dio, matcher: const UrlRequestMatcher());
    final store = InMemoryTokenStore();
    await store.write(Tokens.fromJson(_session));
    client = KyqApiClient(baseUrl: 'http://api.test', tokenStore: store, dio: dio);
  });

  test('abre una consulta y lee su estado', () async {
    adapter.onPost('/v1/preconsults', (s) => s.reply(201, preconsultJson()), data: {'driver_id': 'd1'});
    final pre = await client.openPreconsult('d1');
    expect(pre.isOpen, isTrue);
    expect(pre.driverName, 'Carlos');
    expect(pre.closesAt, DateTime.utc(2026, 10, 27, 12, 2));
  });

  test('motivos de cierre conocidos y desconocidos', () async {
    adapter.onGet('/v1/preconsults/pc1', (s) => s.reply(200, preconsultJson(status: 'missed', reason: 'missed')));
    final pre = await client.getPreconsult('pc1');
    expect(pre.status, PreconsultStatus.missed);
    expect(pre.closeReason, PreconsultCloseReason.missed);
    expect(preconsultCloseReasonFromApi('driver_unavailable'), PreconsultCloseReason.driverUnavailable);
    expect(preconsultCloseReasonFromApi('nuevo'), PreconsultCloseReason.unknown);
    expect(Preconsult.fromJson(preconsultJson(status: 'otro')).status, PreconsultStatus.unknown);
  });

  test('errores del contrato como ApiException', () async {
    adapter.onPost(
      '/v1/preconsults',
      (s) => s.reply(429, {'code': 'rate_limited', 'message': 'espera'}),
      data: Matchers.any,
    );
    await expectLater(
      client.openPreconsult('d1'),
      throwsA(isA<ApiException>().having((e) => e.code, 'code', 'rate_limited')),
    );
  });

  // UrlRequestMatcher solo mira la URL: cada respuesta se registra justo antes de su llamada.
  test('turno, token y fin de la consulta', () async {
    adapter.onPost(
      '/v1/preconsults/pc1/ptt/token',
      (s) => s.reply(200, {'url': 'wss://v', 'token': 't', 'room': 'pre-pc1'}),
    );
    expect((await client.preconsultToken('pc1')).room, 'pre-pc1');
    adapter.onPost('/v1/preconsults/pc1/ptt/floor', (s) => s.reply(200, {'expires_at': '2026-10-27T12:00:15Z'}));
    expect(await client.requestPreconsultFloor('pc1'), DateTime.utc(2026, 10, 27, 12, 0, 15));
    adapter.onDelete('/v1/preconsults/pc1/ptt/floor', (s) => s.reply(204, null));
    await client.releasePreconsultFloor('pc1');
    adapter.onPost('/v1/preconsults/pc1/end', (s) => s.reply(200, preconsultJson(reason: 'ended_by_passenger')));
    expect((await client.endPreconsult('pc1')).closeReason, PreconsultCloseReason.endedByPassenger);
  });

  test('ajustes, silencio, bandeja y conductores que aceptan', () async {
    adapter.onGet(
      '/v1/driver/preconsults/settings',
      (s) => s.reply(200, {
        'accepts_preconsults': false,
        'blocked_passenger_ids': ['p2'],
      }),
    );
    expect((await client.preconsultSettings()).blockedPassengerIds, ['p2']);
    adapter.onPut(
      '/v1/driver/preconsults/settings',
      (s) => s.reply(200, {'accepts_preconsults': true, 'blocked_passenger_ids': <String>[]}),
      data: {'accepts_preconsults': true},
    );
    expect((await client.setAcceptsPreconsults(true)).acceptsPreconsults, isTrue);
    adapter.onPut('/v1/driver/clients/p2/preconsults', (s) => s.reply(204, null), data: {'blocked': false});
    await client.setClientPreconsultsBlocked('p2', blocked: false);
    adapter.onGet('/v1/driver/preconsults', (s) => s.reply(200, [preconsultJson()]));
    expect(await client.driverPreconsults(), hasLength(1));
    adapter.onGet(
      '/v1/preconsults/drivers',
      (s) => s.reply(200, {
        'driver_ids': ['d1', 'd2'],
      }),
    );
    expect(await client.preconsultDrivers(), {'d1', 'd2'});
  });
}
