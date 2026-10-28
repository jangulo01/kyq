import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'admin_models.dart';
import 'models.dart';
import 'onboarding_models.dart';
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
    Dio? uploadDio,
  }) : _tokens = tokenStore,
       _dio = dio ?? Dio(),
       _refreshDio = refreshDio ?? Dio(BaseOptions(baseUrl: baseUrl)),
       _uploadDio = uploadDio ?? Dio(BaseOptions(sendTimeout: const Duration(seconds: 60))) {
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
  // Para las URLs firmadas del almacenamiento: sin base ni token, que invalidaría la firma.
  final Dio _uploadDio;
  final TokenStore _tokens;

  /// Se llama cuando la sesión ya no se puede renovar y hay que volver al login.
  final void Function()? onSessionExpired;

  Dio get dio => _dio;

  // Auth

  Future<void> requestOtp(String phoneE164) =>
      _send(() => _dio.post<void>('/v1/auth/otp/request', data: {'phone_e164': phoneE164}));

  /// [role] solo cuenta en el primer registro: con `driver` crea una cuenta de conductor. Si el
  /// teléfono ya existe con otro rol, lanza [ApiException] 409 `phone_has_other_role`.
  Future<Tokens> verifyOtp(String phoneE164, String code, {String? displayName, UserRole? role}) async {
    final res = await _send(
      () => _dio.post<Map<String, dynamic>>(
        '/v1/auth/otp/verify',
        data: {
          'phone_e164': phoneE164,
          'code': code,
          if (displayName != null && displayName.trim().isNotEmpty) 'display_name': displayName.trim(),
          'role': ?role?.name,
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

  // Conductor: alta y documentos (002)

  Future<Onboarding> driverOnboarding() async {
    final res = await _send(() => _dio.get<Map<String, dynamic>>('/v1/driver/onboarding'));
    return Onboarding.fromJson(res.data!);
  }

  Future<void> setVehicle({
    required String plate,
    required String brand,
    required String model,
    required String color,
    required int year,
  }) => _send(
    () => _dio.put<void>(
      '/v1/driver/vehicle',
      data: {'plate': plate, 'brand': brand, 'model': model, 'color': color, 'year': year},
    ),
  );

  /// Inicia el envío de un documento; devuelve una URL firmada de subida por lado.
  Future<CreatedDocument> createDocument({
    required DocType docType,
    required String number,
    DateTime? expiresAt,
    required List<DocSide> sides,
  }) async {
    final res = await _send(
      () => _dio.post<Map<String, dynamic>>(
        '/v1/driver/documents',
        data: {
          'doc_type': docTypeToApi(docType),
          'number': number,
          if (expiresAt != null) 'expires_at': formatApiDate(expiresAt),
          'sides': [for (final s in sides) s.name],
        },
      ),
    );
    return CreatedDocument.fromJson(res.data!);
  }

  /// Sube una foto JPEG a su URL firmada. Reintenta los fallos de red y los 5xx con espera
  /// creciente; un 4xx (URL caducada o rechazada) no se reintenta.
  Future<void> uploadPhoto(
    String url,
    Uint8List jpeg, {
    int attempts = 3,
    Duration backoff = const Duration(seconds: 1),
  }) async {
    for (var attempt = 1; ; attempt++) {
      try {
        await _uploadDio.put<void>(
          url,
          data: Stream<List<int>>.value(jpeg),
          options: Options(contentType: 'image/jpeg', headers: {Headers.contentLengthHeader: jpeg.length}),
        );
        return;
      } on DioException catch (e) {
        final status = e.response?.statusCode;
        final retriable = status == null || status >= 500;
        if (!retriable || attempt >= attempts) {
          // Sin la URL: lleva la firma y no debe acabar en registros ni en Sentry.
          throw status == null
              ? const ApiException(null, 'network', 'sin conexión al subir la foto')
              : ApiException(status, 'upload_failed', 'la subida de la foto falló ($status)');
        }
        await Future<void>.delayed(backoff * attempt);
      }
    }
  }

  /// Confirma que las fotos están subidas. 409 `photos_missing` si falta alguna.
  Future<void> submitDocument(String documentId) =>
      _send(() => _dio.post<void>('/v1/driver/documents/$documentId/submit'));

  // Conductor: suscripción, pagos, costos y avisos (002)

  Future<SubscriptionView> driverSubscription() async {
    final res = await _send(() => _dio.get<Map<String, dynamic>>('/v1/driver/subscription'));
    return SubscriptionView.fromJson(res.data!);
  }

  /// Crea un pago con Bold. 409 `documents_not_ok` o `payment_in_progress`; 503 `bold_unavailable`.
  Future<Payment> createPayment() async {
    final res = await _send(() => _dio.post<Map<String, dynamic>>('/v1/driver/payments'));
    return Payment.fromJson(res.data!);
  }

  /// Pide al backend que consulte ya a Bold el estado del pago.
  Future<Payment> refreshPayment(String paymentId) async {
    final res = await _send(() => _dio.post<Map<String, dynamic>>('/v1/driver/payments/$paymentId/refresh'));
    return Payment.fromJson(res.data!);
  }

  /// Costo medido del mes [month] (por defecto, el actual) frente a lo pagado.
  Future<CostBreakdown> driverCosts({DateTime? month}) async {
    final res = await _send(
      () => _dio.get<Map<String, dynamic>>(
        '/v1/driver/costs',
        queryParameters: {if (month != null) 'month': formatApiMonth(month)},
      ),
    );
    return CostBreakdown.fromJson(res.data!);
  }

  Future<List<Notice>> driverNotices() async {
    final res = await _send(() => _dio.get<dynamic>('/v1/driver/notices'));
    return _list(res.data, 'notices').map(Notice.fromJson).toList();
  }

  Future<void> markNoticeRead(String noticeId) => _send(() => _dio.post<void>('/v1/driver/notices/$noticeId/read'));

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

  // Conductor: presencia y ubicación

  /// Pasa a ONLINE u OFFLINE. Lanza [ApiException] con `subscription_suspended`, `kyc_expired`
  /// o `trip_in_progress` cuando no se permite.
  Future<DriverPresence> setOnline(bool online) async {
    final res = await _send(() => _dio.post<Map<String, dynamic>>('/v1/driver/presence', data: {'online': online}));
    return DriverPresence.values.byName(res.data!['presence'] as String);
  }

  Future<void> sendLocation(GeoPoint point, {double? heading, double? speedMps, DateTime? recordedAt}) => _send(
    () => _dio.post<void>(
      '/v1/driver/location',
      data: {
        'lat': point.lat,
        'lng': point.lng,
        'heading': ?heading,
        'speed_mps': ?speedMps,
        if (recordedAt != null) 'recorded_at': recordedAt.toUtc().toIso8601String(),
      },
    ),
  );

  // Viajes

  Future<FareQuote> quote(GeoPoint pickup, GeoPoint dropoff) async {
    final res = await _send(
      () => _dio.post<Map<String, dynamic>>(
        '/v1/fares/quote',
        data: {'pickup': pickup.toJson(), 'dropoff': dropoff.toJson()},
      ),
    );
    return FareQuote.fromJson(res.data!);
  }

  Future<Trip> requestTrip({required String driverId, required GeoPoint pickup, required GeoPoint dropoff}) => _trip(
    () => _dio.post('/v1/trips', data: {'driver_id': driverId, 'pickup': pickup.toJson(), 'dropoff': dropoff.toJson()}),
  );

  Future<Trip> getTrip(String tripId) => _trip(() => _dio.get('/v1/trips/$tripId'));

  /// Viaje sin terminar del usuario, o null; sirve para retomarlo al reabrir la app.
  Future<Trip?> activeTrip() async {
    final res = await _send(() => _dio.get('/v1/trips/active'));
    final data = res.data;
    return data is Map<String, dynamic> ? Trip.fromJson(data) : null;
  }

  /// El conductor acepta; con [fareMinor] distinto de la sugerida el pasajero debe confirmarla.
  Future<Trip> acceptTrip(String tripId, {int? fareMinor}) =>
      _trip(() => _dio.post('/v1/trips/$tripId/accept', data: {'fare_minor': ?fareMinor}));

  Future<Trip> rejectTrip(String tripId) => _trip(() => _dio.post('/v1/trips/$tripId/reject'));

  Future<Trip> requestNegotiation(String tripId) => _trip(() => _dio.post('/v1/trips/$tripId/negotiation'));

  Future<Trip> respondNegotiation(String tripId, {required bool accept}) =>
      _trip(() => _dio.post('/v1/trips/$tripId/negotiation/response', data: {'accept': accept}));

  Future<FareProposal> propose(String tripId, int amountMinor) async {
    final res = await _send(
      () => _dio.post<Map<String, dynamic>>('/v1/trips/$tripId/proposals', data: {'amount_minor': amountMinor}),
    );
    return FareProposal.fromJson(res.data!);
  }

  Future<Trip> decideProposal(String tripId, String proposalId, {required bool accept}) =>
      _trip(() => _dio.post('/v1/trips/$tripId/proposals/$proposalId/${accept ? 'accept' : 'reject'}'));

  Future<Trip> arrive(String tripId) => _trip(() => _dio.post('/v1/trips/$tripId/arrive'));

  Future<Trip> startTrip(String tripId) => _trip(() => _dio.post('/v1/trips/$tripId/start'));

  Future<Trip> completeTrip(String tripId) => _trip(() => _dio.post('/v1/trips/$tripId/complete'));

  Future<Trip> cancelTrip(String tripId) => _trip(() => _dio.post('/v1/trips/$tripId/cancel'));

  // Walkie-talkie (PTT)

  /// Credenciales de la sala de voz. Lanza [ApiException] con estado 410 si el canal ya cerró.
  Future<PttCredentials> pttToken(String tripId) async {
    final res = await _send(() => _dio.post<Map<String, dynamic>>('/v1/trips/$tripId/ptt/token'));
    return PttCredentials.fromJson(res.data!);
  }

  /// Pide el turno de palabra y devuelve cuándo caduca. 409 si habla la otra parte, 410 si cerró.
  Future<DateTime> requestFloor(String tripId) async {
    final res = await _send(() => _dio.post<Map<String, dynamic>>('/v1/trips/$tripId/ptt/floor'));
    return DateTime.parse(res.data!['expires_at'] as String);
  }

  Future<void> releaseFloor(String tripId) => _send(() => _dio.delete<void>('/v1/trips/$tripId/ptt/floor'));

  Future<Trip> _trip(Future<Response<dynamic>> Function() request) async {
    final res = await _send(request);
    return Trip.fromJson(res.data as Map<String, dynamic>);
  }

  // Admin

  Future<void> adminSetFareTable(String cityCode, FareTableInput table) =>
      _send(() => _dio.put<void>('/v1/admin/fare-tables/$cityCode', data: table.toJson()));

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

  Future<void> adminSetDocument(String driverId, DocType type, {required DateTime expiresAt, required bool approved}) =>
      _send(
        () => _dio.put<void>(
          '/v1/admin/drivers/$driverId/documents/${docTypeToApi(type)}',
          data: {'expires_at': formatApiDate(expiresAt), 'approved': approved},
        ),
      );

  // Admin: validación de documentos (002)

  /// Conductores con documentos en revisión, del más antiguo al más reciente.
  Future<List<KycQueueEntry>> adminKycQueue() async {
    final res = await _send(() => _dio.get<dynamic>('/v1/admin/kyc/queue'));
    return _list(res.data, 'drivers').map(KycQueueEntry.fromJson).toList();
  }

  Future<KycDriverFile> adminKycDriver(String driverId) async {
    final res = await _send(() => _dio.get<Map<String, dynamic>>('/v1/admin/kyc/drivers/$driverId'));
    return KycDriverFile.fromJson(res.data!);
  }

  /// Aprueba (con correcciones opcionales) o rechaza con [reason] un documento en revisión.
  Future<void> adminReviewDocument(
    String documentId, {
    required bool approve,
    String? reason,
    String? number,
    DateTime? expiresAt,
    DateTime? exemptUntil,
  }) => _send(
    () => _dio.post<void>(
      '/v1/admin/kyc/documents/$documentId/review',
      data: {
        'decision': approve ? 'approve' : 'reject',
        'reason': ?reason,
        'number': ?number,
        if (expiresAt != null) 'expires_at': formatApiDate(expiresAt),
        if (exemptUntil != null) 'exempt_until': formatApiDate(exemptUntil),
      },
    ),
  );

  // Admin: suscripciones y pagos (002)

  Future<List<AdminSubscription>> adminSubscriptions({BillingStatus? status}) async {
    final res = await _send(
      () => _dio.get<dynamic>('/v1/admin/subscriptions', queryParameters: {'status': ?status?.name}),
    );
    return _list(res.data, 'subscriptions').map(AdminSubscription.fromJson).toList();
  }

  Future<List<Payment>> adminDriverPayments(String driverId) async {
    final res = await _send(() => _dio.get<dynamic>('/v1/admin/drivers/$driverId/payments'));
    return _list(res.data, 'payments').map(Payment.fromJson).toList();
  }

  /// Pago recibido por otro medio (p. ej. efectivo); extiende la suscripción como uno de Bold.
  Future<void> adminManualPayment(String driverId, {required String methodDetail, required String reference}) => _send(
    () => _dio.post<void>(
      '/v1/admin/drivers/$driverId/payments',
      data: {'method_detail': methodDetail, 'reference': reference},
    ),
  );

  Future<void> adminVoidPayment(String paymentId, String reason) =>
      _send(() => _dio.post<void>('/v1/admin/payments/$paymentId/void', data: {'reason': reason}));

  Future<void> adminSetSubscriptionPrice(
    String cityCode, {
    required String currency,
    required int amountMinor,
    DateTime? effectiveFrom,
  }) => _send(
    () => _dio.put<void>(
      '/v1/admin/subscription-prices/$cityCode',
      data: {
        'currency': currency,
        'amount_minor': amountMinor,
        if (effectiveFrom != null) 'effective_from': effectiveFrom.toUtc().toIso8601String(),
      },
    ),
  );

  // Admin: costos (002, RN-KYQ-004)

  Future<List<CostRate>> adminCostRates() async {
    final res = await _send(() => _dio.get<dynamic>('/v1/admin/cost-rates'));
    return _list(res.data, 'rates').map(CostRate.fromJson).toList();
  }

  Future<void> adminSetCostRate(CostRate rate) => _send(
    () => _dio.put<void>(
      '/v1/admin/cost-rates',
      data: {
        'concept': rate.concept,
        'currency': rate.currency,
        'unit_cost_micro': rate.unitCostMicro,
        'effective_from': formatApiDate(rate.effectiveFrom),
      },
    ),
  );

  Future<List<CostBreakdown>> adminCosts(DateTime month) async {
    final res = await _send(
      () => _dio.get<dynamic>('/v1/admin/costs', queryParameters: {'month': formatApiMonth(month)}),
    );
    return _list(res.data, 'drivers').map(CostBreakdown.fromJson).toList();
  }

  // Admin: torre de control, finanzas, fidelización, moderación y salud (007)

  /// Instantánea de la torre agregada en hexágonos H3 de [resolution] (6 a 9).
  Future<TowerSnapshot> adminTower({int resolution = 8}) async {
    final res = await _send(
      () => _dio.get<Map<String, dynamic>>('/v1/admin/tower', queryParameters: {'res': resolution}),
    );
    return TowerSnapshot.fromJson(res.data!);
  }

  /// [months] meses (1 a 24) que terminan en [to] (por defecto, el actual).
  Future<FinanceReport> adminFinance({DateTime? to, int months = 6}) async {
    final res = await _send(
      () => _dio.get<Map<String, dynamic>>(
        '/v1/admin/finance',
        queryParameters: {'months': months, if (to != null) 'to': formatApiMonth(to)},
      ),
    );
    return FinanceReport.fromJson(res.data!);
  }

  /// Indicadores de fidelización de los días [from] a [to] (incluidos); por defecto, las
  /// últimas 12 semanas.
  Future<CrmReport> adminCrm({DateTime? from, DateTime? to}) async {
    final res = await _send(
      () => _dio.get<Map<String, dynamic>>(
        '/v1/admin/crm',
        queryParameters: {if (from != null) 'from': formatApiDate(from), if (to != null) 'to': formatApiDate(to)},
      ),
    );
    return CrmReport.fromJson(res.data!);
  }

  /// Busca usuarios por parte del nombre o del teléfono; [suspended] filtra por estado.
  Future<List<ModeratedUser>> adminUsers({String? query, UserRole? role, bool? suspended}) async {
    final q = query?.trim();
    final res = await _send(
      () => _dio.get<dynamic>(
        '/v1/admin/users',
        queryParameters: {
          if (q != null && q.isNotEmpty) 'q': q,
          'role': ?role?.name,
          if (suspended != null) 'status': suspended ? 'suspended' : 'active',
        },
      ),
    );
    return _list(res.data, 'users').map(ModeratedUser.fromJson).toList();
  }

  Future<ModeratedUser> adminSuspendUser(String userId, String reason) async {
    final res = await _send(
      () => _dio.post<Map<String, dynamic>>('/v1/admin/users/$userId/suspend', data: {'reason': reason}),
    );
    return ModeratedUser.fromJson(res.data!);
  }

  Future<ModeratedUser> adminReactivateUser(String userId, String reason) async {
    final res = await _send(
      () => _dio.post<Map<String, dynamic>>('/v1/admin/users/$userId/reactivate', data: {'reason': reason}),
    );
    return ModeratedUser.fromJson(res.data!);
  }

  Future<List<ModerationAction>> adminModerationHistory(String userId) async {
    final res = await _send(() => _dio.get<dynamic>('/v1/admin/users/$userId/moderation'));
    return _list(res.data, 'actions').map(ModerationAction.fromJson).toList();
  }

  Future<HealthReport> adminHealth() async {
    final res = await _send(() => _dio.get<Map<String, dynamic>>('/v1/admin/health'));
    return HealthReport.fromJson(res.data!);
  }

  Future<Response<T>> _send<T>(Future<Response<T>> Function() request) async {
    try {
      return await request();
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }
}

/// Fecha sin hora del contrato (`format: date`): `2027-06-30`.
String formatApiDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Mes del contrato: `2026-10`.
String formatApiMonth(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}';

/// Listas de 002: se aceptan como arreglo o envueltas en un objeto (`{key: [...]}` o
/// `{items: [...]}`), porque el contrato no fija la forma de esas respuestas.
List<Map<String, dynamic>> _list(Object? data, String key) {
  final raw = data is Map ? (data[key] ?? data['items']) : data;
  if (raw is! List) return const [];
  return [for (final e in raw) (e as Map).cast<String, dynamic>()];
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
