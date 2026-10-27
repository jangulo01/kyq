import 'package:flutter_test/flutter_test.dart';
import 'package:kyq_ui/kyq_ui.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

const _jwt = 'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMjMifQ.c2lnbmF0dXJl';
const _uuid = '2b0c9a5e-4f3d-4d8e-9c1a-0f6b7e8d9a10';

void main() {
  group('scrubText', () {
    test('tapa teléfonos E.164 y móviles colombianos de 10 dígitos', () {
      expect(scrubText('llamar a +573001234567 ya'), 'llamar a [phone] ya');
      expect(scrubText('tel +57 300 123 4567'), 'tel [phone]');
      expect(scrubText('móvil 3001234567.'), 'móvil [phone].');
      expect(scrubText('móvil 300-123-4567'), 'móvil [phone]');
    });

    test('no toca números que no son teléfonos', () {
      expect(scrubText('timestamp 1730000000000'), 'timestamp 1730000000000');
      expect(scrubText('status 404, tarifa 12500'), 'status 404, tarifa 12500');
      expect(scrubText('id $_uuid'), 'id $_uuid');
    });

    test('tapa JWT y cabeceras Authorization', () {
      expect(scrubText('token=$_jwt'), 'token=[jwt]');
      expect(scrubText('Authorization: Bearer abc.def-123'), 'Authorization: [redacted]');
      expect(scrubText('enviando Bearer s3cr3t'), 'enviando Bearer [redacted]');
    });

    test('tapa el OTP en cuerpos de /v1/auth/otp/*', () {
      expect(
        scrubText('POST /v1/auth/otp/verify {"phone":"+573001234567","code":"123456"}'),
        'POST /v1/auth/otp/verify {"phone":"[phone]","code":"[otp]"}',
      );
      expect(scrubText('POST /v1/auth/otp/verify falló con 482913'), 'POST /v1/auth/otp/verify falló con [otp]');
      expect(scrubText('otp=4821'), 'otp=[otp]');
    });

    test('scrubUrl quita consulta y fragmento', () {
      expect(scrubUrl('https://api.kyq.co/v1/trips?phone=+573001234567#x'), 'https://api.kyq.co/v1/trips');
    });
  });

  group('scrubValue', () {
    test('limpia mapas y listas anidados y tapa claves sensibles', () {
      final out = scrubValue({
        'trip': {
          'passenger': {'display_name': 'Ana Gómez', 'phone_e164': '+573001234567', 'id': _uuid},
          'notes': ['llamar al 3001234567', _jwt],
        },
        'headers': {'Authorization': 'Bearer x', 'X-Request-Id': 'r1'},
        'code': 'subscription_suspended',
        'otp_code': 123456,
      });
      expect(out, {
        'trip': {
          'passenger': {'display_name': redacted, 'phone_e164': redacted, 'id': _uuid},
          'notes': ['llamar al [phone]', '[jwt]'],
        },
        'headers': {'Authorization': redacted, 'X-Request-Id': 'r1'},
        'code': 'subscription_suspended',
        'otp_code': redacted,
      });
    });

    test('code con aspecto de OTP se tapa', () {
      expect(scrubValue({'code': '123456'}), {'code': redacted});
      expect(scrubValue({'code': 4821}), {'code': redacted});
    });

    test('descarta el cuerpo de una petición a /v1/auth/otp/*', () {
      final out = scrubValue({
        'path': '/v1/auth/otp/request',
        'body': {'phone': '+573001234567', 'channel': 'sms'},
      });
      expect(out, {'path': '/v1/auth/otp/request', 'body': redacted});
    });
  });

  group('scrubBreadcrumb', () {
    test('http: solo URL sin consulta, método, estado y tiempos', () {
      final crumb = Breadcrumb.http(
        url: Uri.parse('https://api.kyq.co/v1/auth/otp/verify?phone=%2B573001234567'),
        method: 'POST',
        statusCode: 200,
        requestDuration: const Duration(milliseconds: 120),
        httpQuery: 'phone=%2B573001234567',
      );
      crumb.data!['body'] = '{"code":"123456"}';
      crumb.data!['request_headers'] = {'Authorization': 'Bearer $_jwt'};

      final out = scrubBreadcrumb(crumb)!;
      expect(out.data!['url'], 'https://api.kyq.co/v1/auth/otp/verify');
      expect(out.data!['method'], 'POST');
      expect(out.data!['status_code'], 200);
      expect(out.data!.keys, isNot(contains('http.query')));
      expect(out.data!.keys, isNot(contains('body')));
      expect(out.data!.keys, isNot(contains('request_headers')));
      expect(out.data!.keys, contains('duration'));
    });

    test('mensaje y datos anidados se limpian; etiquetas de toques se descartan', () {
      final out = scrubBreadcrumb(
        Breadcrumb(
          message: 'oferta de +573001234567',
          category: 'ui.click',
          data: {
            'label': 'Ana Gómez',
            'view.id': 'accept',
            'extra': {
              'list': [
                {'phone': '3001234567'},
              ],
            },
          },
        ),
      )!;
      expect(out.message, 'oferta de [phone]');
      expect(out.data, {
        'view.id': 'accept',
        'extra': {
          'list': [
            {'phone': redacted},
          ],
        },
      });
    });

    test('null se mantiene null', () => expect(scrubBreadcrumb(null), isNull));
  });

  group('scrubEvent', () {
    test('usuario: solo el id si es UUID', () {
      final event = scrubEvent(
        SentryEvent(
          user: SentryUser(id: _uuid, name: 'Ana', username: 'ana', email: 'a@b.co', ipAddress: '181.1.2.3'),
        ),
      );
      expect(event.user!.id, _uuid);
      expect(event.user!.name, isNull);
      expect(event.user!.username, isNull);
      expect(event.user!.email, isNull);
      expect(event.user!.ipAddress, isNull);

      expect(scrubEvent(SentryEvent(user: SentryUser(id: '+573001234567'))).user, isNull);
      expect(scrubEvent(SentryEvent(user: SentryUser(ipAddress: '1.2.3.4'))).user, isNull);
    });

    test('limpia mensaje, excepciones, tags, extras, contextos, petición y breadcrumbs', () {
      final event = SentryEvent(
        message: SentryMessage('fallo para +573001234567', template: 'fallo para %s', params: ['3001234567']),
        exceptions: [SentryException(type: 'ApiException', value: 'Authorization: Bearer $_jwt')],
        tags: {'phone': '+573001234567', 'screen': 'trip'},
        // ignore: deprecated_member_use
        extra: {
          'payload': {
            'riders': [
              {'display_name': 'Ana', 'phone_e164': '+573001234567'},
            ],
          },
        },
        request: SentryRequest(
          url: 'https://api.kyq.co/v1/auth/otp/verify?x=1',
          method: 'POST',
          queryString: 'x=1',
          cookies: 'sid=1',
          data: {'code': '123456'},
          headers: {'Authorization': 'Bearer $_jwt', 'Accept': 'application/json'},
        ),
        breadcrumbs: [Breadcrumb(message: 'llamada a 3001234567')],
        contexts: Contexts(
          device: SentryDevice(name: 'Teléfono de Ana', model: 'P30'),
        ),
      );
      event.contexts['kyq'] = {
        'session': {'access_token': _jwt, 'trip_id': 't1'},
      };

      final out = scrubEvent(event);
      expect(out.message!.formatted, 'fallo para [phone]');
      expect(out.message!.params, ['[phone]']);
      expect(out.exceptions!.single.value, 'Authorization: [redacted]');
      expect(out.tags, {'phone': redacted, 'screen': 'trip'});
      // ignore: deprecated_member_use
      expect(out.extra, {
        'payload': {
          'riders': [
            {'display_name': redacted, 'phone_e164': redacted},
          ],
        },
      });
      expect(out.request!.url, 'https://api.kyq.co/v1/auth/otp/verify');
      expect(out.request!.queryString, isNull);
      expect(out.request!.cookies, isNull);
      expect(out.request!.data, isNull);
      expect(out.request!.headers, {'Authorization': redacted, 'Accept': 'application/json'});
      expect(out.breadcrumbs!.single.message, 'llamada a [phone]');
      expect(out.contexts.device!.name, isNull);
      expect(out.contexts.device!.model, 'P30');
      expect(out.contexts['kyq'], {
        'session': {'access_token': redacted, 'trip_id': 't1'},
      });
    });
  });
}
