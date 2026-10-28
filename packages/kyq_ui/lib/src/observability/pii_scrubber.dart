import 'package:sentry_flutter/sentry_flutter.dart';

/// Texto que sustituye a un dato personal o secreto.
const redacted = '[redacted]';

// JWT: tres segmentos base64url y el primero empieza por `eyJ` ("{"").
final _jwt = RegExp(r'eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+(?:\.[A-Za-z0-9_-]*)?');
final _bearer = RegExp(r'\b(Bearer|Basic)\s+[A-Za-z0-9._~+/=-]+', caseSensitive: false);
final _authHeader = RegExp(r'\b(authorization|cookie)(["\x27]?\s*[:=]\s*)[^\n,;}]+', caseSensitive: false);
// Teléfonos en E.164 (con o sin separadores) y móviles colombianos de 10 dígitos (3xx).
final _e164 = RegExp(r'\+(?:\d[ -]?){7,14}\d');
final _coMobile = RegExp(r'(?<![\w+]|\d\.)3\d{2}[ -]?\d{3}[ -]?\d{4}(?!\w|\.\d)');
// Código OTP dentro de JSON o formularios: "code": "123456", otp=1234.
final _otpField = RegExp(
  r'''(["\x27]?\b(?:code|otp|otp_code)\b["\x27]?\s*[:=]\s*["\x27]?)\d{4,8}''',
  caseSensitive: false,
);
final _otpPath = RegExp(r'/v1/auth/otp\b');
final _bareOtp = RegExp(r'(?<![\w+]|\d\.)\d{4,8}(?!\w|\.\d)');
// URL firmada del almacenamiento (fotos de documentos): la consulta lleva la firma, que da acceso
// a la foto mientras no caduca. Se tapa la URL entera (002, T042).
final _urlWithQuery = RegExp(r'''https?://[^\s"'<>]*\?[^\s"'<>]*''', caseSensitive: false);
final _signatureParam = RegExp(
  r'[?&](?:x-amz-signature|x-amz-credential|x-amz-security-token|x-goog-signature|signature|sig)=',
  caseSensitive: false,
);
// Número de documento declarado (cédula, licencia, SOAT…) en JSON, formularios o texto libre.
final _docNumberField = RegExp(
  r'''(["\x27]?\b(?:number|document_number|doc_number|id_number|license_number|numero)\b["\x27]?\s*[:=]\s*["\x27]?)[A-Za-z0-9.-]{4,20}''',
  caseSensitive: false,
);
final _docNumberWords = RegExp(
  r'(\b(?:c[ée]dula|c\.c\.|licencia|soat)\s*(?:n[o°º.]*\s*)?[:#]?\s*)[A-Za-z]{0,3}-?\d[\d.-]{3,14}',
  caseSensitive: false,
);
final _uuid = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');

// Claves cuyo valor nunca se envía (comparación sin mayúsculas, `-` equivale a `_`).
const _sensitiveKeys = {
  'authorization',
  'proxy_authorization',
  'cookie',
  'set_cookie',
  'x_api_key',
  'password',
  'token',
  'access_token',
  'refresh_token',
  'id_token',
  'connection_token',
  'subscription_token',
  'otp',
  'otp_code',
  'phone',
  'phone_e164',
  'phone_number',
  'display_name',
  'full_name',
  'first_name',
  'last_name',
  'rider_name',
  'driver_name',
  'passenger_name',
  'email',
  'ip_address',
  // Documentos del conductor (002): números declarados y URLs firmadas de sus fotos.
  'number',
  'document_number',
  'doc_number',
  'id_number',
  'license_number',
  'upload_url',
  'signed_url',
  'photo_url',
  'uploads',
  'photos',
};

// Claves de cuerpos y consultas HTTP que se descartan siempre.
const _bodyKeys = {'body', 'data', 'request_body', 'response_body', 'http.query', 'http.fragment', 'query'};

// Datos de un breadcrumb http que se conservan.
const _httpKeepKeys = {
  'url',
  'method',
  'status_code',
  'reason',
  'duration',
  'request_body_size',
  'response_body_size',
  'start_timestamp',
  'end_timestamp',
};

String _normKey(String key) => key.toLowerCase().replaceAll('-', '_');

bool _isSensitiveKey(String key) => _sensitiveKeys.contains(_normKey(key));

// `code` suele ser un código de error útil; solo se tapa si parece un OTP (4 a 8 dígitos).
bool _isOtpCode(String key, Object? value) =>
    _normKey(key) == 'code' && (value is int || value is String) && RegExp(r'^\d{4,8}$').hasMatch('$value');

/// Elimina de [text] teléfonos, JWT, credenciales, códigos OTP, URLs firmadas y números de
/// documento.
String scrubText(String text) {
  var out = text
      .replaceAllMapped(_urlWithQuery, (m) => _signatureParam.hasMatch(m[0]!) ? '[signed-url]' : m[0]!)
      .replaceAllMapped(_docNumberField, (m) => '${m[1]}[doc]')
      .replaceAllMapped(_docNumberWords, (m) => '${m[1]}[doc]')
      .replaceAll(_jwt, '[jwt]')
      .replaceAllMapped(_bearer, (m) => '${m[1]} $redacted')
      .replaceAllMapped(_authHeader, (m) => '${m[1]}${m[2]}$redacted')
      .replaceAllMapped(_otpField, (m) => '${m[1]}[otp]')
      .replaceAll(_e164, '[phone]')
      .replaceAll(_coMobile, '[phone]');
  if (_otpPath.hasMatch(out)) out = out.replaceAll(_bareOtp, '[otp]');
  return out;
}

/// Quita consulta y fragmento de una URL y limpia el resto.
String scrubUrl(String url) {
  final cut = url.indexOf(RegExp('[?#]'));
  return scrubText(cut < 0 ? url : url.substring(0, cut));
}

/// Limpia recursivamente mapas, listas y textos; otros valores se devuelven tal cual.
Object? scrubValue(Object? value) {
  if (value is String) return scrubText(value);
  if (value is Map) return scrubMap(value);
  if (value is Iterable) return [for (final v in value) scrubValue(v)];
  return value;
}

/// Copia de [map] sin claves sensibles ni cuerpos, con los textos limpios.
Map<String, dynamic> scrubMap(Map<dynamic, dynamic> map) {
  final otp = map.values.any((v) => v is String && _otpPath.hasMatch(v));
  return {
    for (final e in map.entries)
      '${e.key}':
          _isSensitiveKey('${e.key}') ||
              _isOtpCode('${e.key}', e.value) ||
              (otp && _bodyKeys.contains(_normKey('${e.key}')))
          ? redacted
          : scrubValue(e.value),
  };
}

bool _isHttpCrumb(Breadcrumb b) =>
    b.type == 'http' || const {'http', 'xhr', 'fetch'}.contains(b.category?.toLowerCase());

/// Filtro de `beforeBreadcrumb`: limpia mensaje y datos; en los http solo deja URL sin consulta,
/// método, estado, tamaños y tiempos.
Breadcrumb? scrubBreadcrumb(Breadcrumb? crumb) {
  if (crumb == null) return null;
  final message = crumb.message;
  if (message != null) crumb.message = scrubText(message);
  final data = crumb.data;
  if (data == null) return crumb;
  if (_isHttpCrumb(crumb)) {
    crumb.data = {
      for (final e in data.entries)
        if (_httpKeepKeys.contains(e.key))
          e.key: e.key == 'url' && e.value is String ? scrubUrl(e.value as String) : e.value,
    };
  } else {
    // Las etiquetas de los toques en pantalla pueden llevar nombres de personas.
    final isUi = crumb.category?.startsWith('ui.') ?? false;
    crumb.data = scrubMap({
      for (final e in data.entries)
        if (!(isUi && e.key == 'label')) e.key: e.value,
    });
  }
  return crumb;
}

/// Solo se conserva el id del usuario si es un UUID; nombre, IP, correo, etc. se descartan.
SentryUser? scrubUser(SentryUser? user) {
  final id = user?.id;
  if (id == null || !_uuid.hasMatch(id)) return null;
  return SentryUser(id: id);
}

/// Filtro de `beforeSend`: quita datos personales y secretos de todo el evento.
SentryEvent scrubEvent(SentryEvent event) {
  event.user = scrubUser(event.user);
  event.serverName = null;

  final message = event.message;
  if (message != null) {
    message.formatted = scrubText(message.formatted);
    final template = message.template;
    if (template != null) message.template = scrubText(template);
    final params = message.params;
    if (params != null) message.params = scrubValue(params) as List<dynamic>;
  }
  for (final ex in event.exceptions ?? const <SentryException>[]) {
    final value = ex.value;
    if (value != null) ex.value = scrubText(value);
  }
  final transaction = event.transaction;
  if (transaction != null) event.transaction = scrubUrl(transaction);
  final culprit = event.culprit;
  if (culprit != null) event.culprit = scrubText(culprit);

  final tags = event.tags;
  if (tags != null) {
    event.tags = {for (final e in tags.entries) e.key: _isSensitiveKey(e.key) ? redacted : scrubText(e.value)};
  }
  // `extra` está obsoleto en Sentry pero aún se envía.
  // ignore: deprecated_member_use
  final extra = event.extra;
  // ignore: deprecated_member_use
  if (extra != null) event.extra = scrubMap(extra);

  final request = event.request;
  if (request != null) {
    // Sin cuerpo, cookies, consulta ni variables de entorno; cabeceras sensibles tapadas.
    event.request = SentryRequest(
      url: request.url == null ? null : scrubUrl(request.url!),
      method: request.method,
      headers: {for (final e in request.headers.entries) e.key: _isSensitiveKey(e.key) ? redacted : scrubText(e.value)},
      apiTarget: request.apiTarget,
    );
  }

  final contexts = event.contexts;
  contexts.device?.name = null;
  contexts.response = null;
  contexts.feedback = null;
  // Contextos propios (mapas, listas o textos); los tipados de Sentry no llevan datos personales.
  for (final key in contexts.keys.toList()) {
    final value = contexts[key];
    if (key != SentryRuntime.listType && (value is Map || value is List || value is String)) {
      contexts[key] = scrubValue(value);
    }
  }

  final crumbs = event.breadcrumbs;
  if (crumbs != null) event.breadcrumbs = [for (final b in crumbs) ?scrubBreadcrumb(b)];
  return event;
}
