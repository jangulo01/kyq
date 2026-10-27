import 'package:dio/dio.dart';

import 'models.dart';
import 'token_store.dart';

/// Error de la API con el cuerpo `Error{code,message}` del contrato.
class ApiException implements Exception {
  const ApiException(this.statusCode, this.code, this.message);

  final int? statusCode;
  final String code;
  final String message;

  @override
  String toString() => 'ApiException($statusCode, $code): $message';
}

/// Cliente de la API Kyq. Añade el token de acceso y lo renueva una vez ante un 401.
class KyqApiClient {
  KyqApiClient({
    required String baseUrl,
    required TokenStore tokenStore,
    this.onSessionExpired,
    Dio? dio,
    Dio? refreshDio,
  }) : _tokens = tokenStore,
       _dio = dio ?? Dio(),
       _refreshDio = refreshDio ?? Dio(BaseOptions(baseUrl: baseUrl)) {
    _dio.options
      ..baseUrl = baseUrl
      ..connectTimeout = const Duration(seconds: 10)
      ..receiveTimeout = const Duration(seconds: 15)
      ..contentType = Headers.jsonContentType;
    _dio.interceptors.add(_AuthInterceptor(this));
  }

  final Dio _dio;
  // Sin interceptores: el refresco no debe dispararse a sí mismo.
  final Dio _refreshDio;
  final TokenStore _tokens;

  /// Se llama cuando la sesión ya no se puede renovar y hay que volver al login.
  final void Function()? onSessionExpired;

  Dio get dio => _dio;

  // Auth

  Future<void> requestOtp(String phoneE164) =>
      _send(() => _dio.post<void>('/v1/auth/otp/request', data: {'phone_e164': phoneE164}));

  Future<Tokens> verifyOtp(String phoneE164, String code, {String? displayName}) async {
    final res = await _send(
      () => _dio.post<Map<String, dynamic>>(
        '/v1/auth/otp/verify',
        data: {
          'phone_e164': phoneE164,
          'code': code,
          if (displayName != null && displayName.trim().isNotEmpty) 'display_name': displayName.trim(),
        },
      ),
    );
    final tokens = Tokens.fromJson(res.data!);
    await _tokens.write(tokens);
    return tokens;
  }

  Future<Tokens?> currentSession() => _tokens.read();

  Future<void> logout() => _tokens.clear();

  Future<Tokens?> _refresh() async {
    final current = await _tokens.read();
    if (current == null) return null;
    try {
      final res = await _refreshDio.post<Map<String, dynamic>>(
        '/v1/auth/refresh',
        data: {'refresh_token': current.refreshToken},
      );
      final tokens = Tokens.fromJson(res.data!);
      await _tokens.write(tokens);
      return tokens;
    } on DioException {
      await _tokens.clear();
      onSessionExpired?.call();
      return null;
    }
  }

  // Tiempo real

  Future<String> realtimeToken() async {
    final res = await _send(() => _dio.post<Map<String, dynamic>>('/v1/realtime/token'));
    return res.data!['token'] as String;
  }

  Future<String> subscriptionToken(String channel) async {
    final res = await _send(
      () => _dio.post<Map<String, dynamic>>('/v1/realtime/subscription-token', data: {'channel': channel}),
    );
    return res.data!['token'] as String;
  }

  // Conductor

  Future<DriverMe> driverMe() async {
    final res = await _send(() => _dio.get<Map<String, dynamic>>('/v1/driver/me'));
    return DriverMe.fromJson(res.data!);
  }

  Future<List<DriverClient>> driverClients() async {
    final res = await _send(() => _dio.get<List<dynamic>>('/v1/driver/clients'));
    return res.data!.map((e) => DriverClient.fromJson(e as Map<String, dynamic>)).toList();
  }

  // Pasajero: Conductores Elegidos

  /// Afilia al conductor del QR. [created] es false si ya estaba en la lista.
  Future<({ChosenDriver driver, bool created})> affiliate(String qrToken) async {
    final res = await _send(() => _dio.post<Map<String, dynamic>>('/v1/affiliations', data: {'qr_token': qrToken}));
    return (driver: ChosenDriver.fromJson(res.data!), created: res.statusCode == 201);
  }

  Future<List<ChosenDriver>> chosenDrivers() async {
    final res = await _send(() => _dio.get<List<dynamic>>('/v1/affiliations'));
    return res.data!.map((e) => ChosenDriver.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> removeChosenDriver(String driverId) => _send(() => _dio.delete<void>('/v1/affiliations/$driverId'));

  // Admin

  Future<List<AdminDriver>> adminListDrivers() async {
    final res = await _send(() => _dio.get<List<dynamic>>('/v1/admin/drivers'));
    return res.data!.map((e) => AdminDriver.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<String> adminCreateDriver({
    required String phoneE164,
    required String displayName,
    required String vehiclePlate,
    required String vehicleDescription,
  }) async {
    final res = await _send(
      () => _dio.post<Map<String, dynamic>>(
        '/v1/admin/drivers',
        data: {
          'phone_e164': phoneE164,
          'display_name': displayName,
          'vehicle_plate': vehiclePlate,
          'vehicle_description': vehicleDescription,
        },
      ),
    );
    return res.data!['driver_id'] as String;
  }

  Future<void> adminSetSubscription(String driverId, DateTime paidUntil) => _send(
    () => _dio.put<void>(
      '/v1/admin/drivers/$driverId/subscription',
      data: {'paid_until': paidUntil.toUtc().toIso8601String()},
    ),
  );

  Future<void> adminSetDocument(
    String driverId,
    DocType type, {
    required DateTime expiresAt,
    required bool approved,
  }) => _send(
    () => _dio.put<void>(
      '/v1/admin/drivers/$driverId/documents/${docTypeToApi(type)}',
      data: {
        'expires_at':
            '${expiresAt.year.toString().padLeft(4, '0')}-${expiresAt.month.toString().padLeft(2, '0')}-${expiresAt.day.toString().padLeft(2, '0')}',
        'approved': approved,
      },
    ),
  );

  Future<Response<T>> _send<T>(Future<Response<T>> Function() request) async {
    try {
      return await request();
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }
}

ApiException _toApiException(DioException e) {
  final data = e.response?.data;
  if (data is Map && data['code'] is String) {
    return ApiException(e.response?.statusCode, data['code'] as String, (data['message'] ?? '') as String);
  }
  if (e.response == null) {
    return const ApiException(null, 'network', 'sin conexión con el servidor');
  }
  return ApiException(e.response?.statusCode, 'unknown', e.message ?? 'error desconocido');
}

class _AuthInterceptor extends QueuedInterceptor {
  _AuthInterceptor(this._client);

  final KyqApiClient _client;
  static const _retried = 'kyq_retried';

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (!options.path.startsWith('/v1/auth/')) {
      final tokens = await _client._tokens.read();
      if (tokens != null) options.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    final unauthorized = err.response?.statusCode == 401;
    if (!unauthorized || options.path.startsWith('/v1/auth/') || options.extra[_retried] == true) {
      return handler.next(err);
    }
    final tokens = await _client._refresh();
    if (tokens == null) return handler.next(err);
    try {
      options
        ..extra[_retried] = true
        ..headers['Authorization'] = 'Bearer ${tokens.accessToken}';
      handler.resolve(await _client._dio.fetch<dynamic>(options));
    } on DioException catch (e) {
      handler.next(e);
    }
  }
}
