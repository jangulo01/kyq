import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:test/test.dart';

const _session = {'access_token': 'a1', 'refresh_token': 'r1', 'role': 'driver'};

Map<String, dynamic> _doc({String status = 'submitted', String type = 'license'}) => {
  'id': 'doc1',
  'doc_type': type,
  'number': '123',
  'expires_at': '2027-06-30',
  'exempt_until': null,
  'status': status,
  'expired': false,
  'reject_reason': null,
  'submitted_at': '2026-10-27T12:00:00Z',
};

Map<String, dynamic> _payment({String status = 'created'}) => {
  'id': 'p1',
  'amount_minor': 5000000,
  'currency': 'COP',
  'method': 'bold',
  'status': status,
  'checkout_url': 'https://checkout.bold.co/LNK_1',
  'payment_method_detail': null,
  'covers_from': null,
  'covers_until': null,
  'void_reason': null,
  'created_at': '2026-10-27T12:00:00Z',
};

void main() {
  late Dio dio;
  late DioAdapter adapter;
  late InMemoryTokenStore store;
  late _UploadServer uploads;
  late KyqApiClient client;

  setUp(() async {
    dio = Dio();
    adapter = DioAdapter(dio: dio, matcher: const UrlRequestMatcher());
    store = InMemoryTokenStore();
    await store.write(Tokens.fromJson(_session));
    uploads = _UploadServer();
    client = KyqApiClient(
      baseUrl: 'http://api.test',
      tokenStore: store,
      dio: dio,
      uploadDio: Dio()..httpClientAdapter = uploads,
    );
  });

  group('alta', () {
    test('verifyOtp envía el rol solo si se pide', () async {
      Object? body;
      adapter.onPost('/v1/auth/otp/verify', (s) => s.reply(200, _session), data: Matchers.any);
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (o, h) {
            body = o.data;
            h.next(o);
          },
        ),
      );

      await client.verifyOtp('+573001234567', '123456', role: UserRole.driver);
      expect(body, {'phone_e164': '+573001234567', 'code': '123456', 'role': 'driver'});

      await client.verifyOtp('+573001234567', '123456');
      expect(body, {'phone_e164': '+573001234567', 'code': '123456'});
    });

    test('teléfono con otro rol: 409 phone_has_other_role', () async {
      adapter.onPost(
        '/v1/auth/otp/verify',
        (s) => s.reply(409, {'code': 'phone_has_other_role', 'message': 'ya es pasajero'}),
        data: Matchers.any,
      );
      expect(
        client.verifyOtp('+573001234567', '123456', role: UserRole.driver),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', 'phone_has_other_role')),
      );
    });

    test('onboarding interpreta estado, vehículo y documentos por tipo', () async {
      adapter.onGet(
        '/v1/driver/onboarding',
        (s) => s.reply(200, {
          'status': 'in_review',
          'vehicle': {'plate': 'ABC123', 'brand': 'Kia', 'model': 'Picanto', 'color': 'Gris', 'year': 2020},
          'documents': [
            {'doc_type': 'mandatory_insurance', 'current': _doc(status: 'approved'), 'latest': _doc()},
            {'doc_type': 'national_id', 'current': null, 'latest': null},
          ],
        }),
      );
      final o = await client.driverOnboarding();
      expect(o.status, OnboardingStatus.inReview);
      expect(o.vehicle?.year, 2020);
      expect(o.documents.first.latest?.status, DocumentStatus.submitted);
      expect(o.documents.first.current?.expiresAt, DateTime(2027, 6, 30));
      expect(o.documents.last.docType, DocType.nationalId);
    });

    test('createDocument envía fecha sin hora y lados; devuelve las URLs de subida', () async {
      adapter.onPost(
        '/v1/driver/documents',
        (s) => s.reply(201, {
          'document': _doc(status: 'uploading'),
          'uploads': [
            {'side': 'front', 'url': 'https://s3.test/kyc/a?X-Amz-Signature=1'},
            {'side': 'back', 'url': 'https://s3.test/kyc/b?X-Amz-Signature=2'},
          ],
        }),
        data: {
          'doc_type': 'license',
          'number': '123',
          'expires_at': '2027-06-30',
          'sides': ['front', 'back'],
        },
      );
      final created = await client.createDocument(
        docType: DocType.license,
        number: '123',
        expiresAt: DateTime(2027, 6, 30, 15),
        sides: DocType.license.sides,
      );
      expect(created.document.status, DocumentStatus.uploading);
      expect(created.uploads.map((u) => u.side), [DocSide.front, DocSide.back]);
    });

    test('reglas por tipo: reverso y vencimiento', () {
      expect(DocType.nationalId.sides, [DocSide.front, DocSide.back]);
      expect(DocType.license.hasBack, isTrue);
      expect(DocType.mandatoryInsurance.sides, [DocSide.front]);
      expect(DocType.nationalId.expires, isFalse);
      expect(DocType.vehicleRegistration.expires, isFalse);
      expect(DocType.technicalInspection.expires, isTrue);
    });
  });

  group('subida de fotos', () {
    final jpeg = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xD9]);

    test('PUT image/jpeg sin token y reintenta tras un 503', () async {
      uploads.statuses.addAll([503, 200]);
      await client.uploadPhoto('https://s3.test/kyc/a?X-Amz-Signature=1', jpeg, backoff: Duration.zero);

      expect(uploads.requests, hasLength(2));
      final last = uploads.requests.last;
      expect(last.method, 'PUT');
      expect(last.contentType, 'image/jpeg');
      expect(last.headers['Authorization'], isNull);
      expect(uploads.bodies.last, jpeg);
    });

    test('un 403 (URL caducada) no se reintenta y el error no lleva la URL', () async {
      uploads.statuses.add(403);
      await expectLater(
        client.uploadPhoto('https://s3.test/kyc/a?X-Amz-Signature=1', jpeg, backoff: Duration.zero),
        throwsA(
          isA<ApiException>()
              .having((e) => e.code, 'code', 'upload_failed')
              .having((e) => e.toString(), 'texto', isNot(contains('Signature'))),
        ),
      );
      expect(uploads.requests, hasLength(1));
    });

    test('se rinde tras los intentos indicados', () async {
      uploads.statuses.addAll([500, 500, 500]);
      await expectLater(
        client.uploadPhoto('https://s3.test/x', jpeg, attempts: 3, backoff: Duration.zero),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 500)),
      );
      expect(uploads.requests, hasLength(3));
    });

    test('submitDocument: 409 photos_missing', () async {
      adapter.onPost(
        '/v1/driver/documents/doc1/submit',
        (s) => s.reply(409, {'code': 'photos_missing', 'message': 'faltan fotos'}),
      );
      expect(
        client.submitDocument('doc1'),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', 'photos_missing')),
      );
    });
  });

  group('suscripción y pagos', () {
    test('subscription interpreta estado, precio y pagos', () async {
      adapter.onGet(
        '/v1/driver/subscription',
        (s) => s.reply(200, {
          'status': 'grace',
          'paid_until': '2026-10-25T12:00:00Z',
          'grace_until': '2026-10-28T12:00:00Z',
          'price': {'amount_minor': 5000000, 'currency': 'COP'},
          'can_pay': true,
          'payments': [_payment(status: 'approved')],
        }),
      );
      final sub = await client.driverSubscription();
      expect(sub.canPay, isTrue);
      expect(sub.status, BillingStatus.grace);
      expect(sub.price?.amountMinor, 5000000);
      expect(sub.payments.single.status, PaymentStatus.approved);
    });

    test('createPayment y refreshPayment', () async {
      adapter.onPost('/v1/driver/payments', (s) => s.reply(201, _payment()));
      adapter.onPost('/v1/driver/payments/p1/refresh', (s) => s.reply(200, _payment(status: 'needs_review')));

      final p = await client.createPayment();
      expect(p.checkoutUrl, 'https://checkout.bold.co/LNK_1');
      expect(p.status.inProgress, isTrue);
      expect((await client.refreshPayment('p1')).status, PaymentStatus.needsReview);
    });

    test('costos del mes con importes fraccionarios', () async {
      adapter.onGet(
        '/v1/driver/costs',
        (s) => s.reply(200, {
          'month': '2026-10',
          'currency': 'COP',
          'paid_minor': 5000000,
          'items': [
            {'concept': 'voice_minute', 'usage': 120, 'cost_minor': 2400.5},
            {'concept': 'fixed_monthly', 'usage': 1, 'cost_minor': 1000000},
          ],
          'total_cost_minor': 1002400.5,
          'margin_minor': 3997599.5,
        }),
        queryParameters: {'month': '2026-10'},
      );
      final c = await client.driverCosts(month: DateTime(2026, 10, 15));
      expect(c.items.first.usage, 120.0);
      expect(c.marginMinor, 3997599.5);
    });

    test('avisos como arreglo o envueltos', () async {
      final notice = {
        'id': 'n1',
        'kind': 'doc_rejected',
        'title': 'Documento rechazado',
        'body': 'Foto borrosa',
        'created_at': '2026-10-27T12:00:00Z',
        'read_at': null,
      };
      adapter.onGet('/v1/driver/notices', (s) => s.reply(200, [notice]));
      expect((await client.driverNotices()).single.kind, 'doc_rejected');

      adapter.onGet(
        '/v1/driver/notices',
        (s) => s.reply(200, {
          'notices': [notice],
        }),
      );
      expect((await client.driverNotices()).single.id, 'n1');

      adapter.onPost('/v1/driver/notices/n1/read', (s) => s.reply(204, null));
      await client.markNoticeRead('n1');
    });
  });

  group('panel', () {
    test('revisión: aprobar con correcciones y rechazar con motivo', () async {
      adapter
        ..onPost(
          '/v1/admin/kyc/documents/doc1/review',
          (s) => s.reply(200, null),
          data: {'decision': 'approve', 'number': '999', 'exempt_until': '2028-01-01'},
        )
        ..onPost(
          '/v1/admin/kyc/documents/doc2/review',
          (s) => s.reply(200, null),
          data: {'decision': 'reject', 'reason': 'Foto borrosa'},
        );
      await client.adminReviewDocument('doc1', approve: true, number: '999', exemptUntil: DateTime(2028));
      await client.adminReviewDocument('doc2', approve: false, reason: 'Foto borrosa');
    });

    test('expediente con fotos firmadas', () async {
      adapter.onGet(
        '/v1/admin/kyc/drivers/d1',
        (s) => s.reply(200, {
          'driver_id': 'd1',
          'display_name': 'Carlos',
          'phone_e164': '+573001112233',
          'status': 'in_review',
          'vehicle': null,
          'documents': [
            {
              'doc_type': 'license',
              'label': 'Licencia de conducción',
              'current': {..._doc(status: 'approved'), 'legacy': true, 'photos': []},
              'latest': {
                ..._doc(),
                'photos': [
                  {'side': 'front', 'url': 'https://s3.test/a?sig=1'},
                ],
              },
              'rejected_count': 3,
              'suggest_support': true,
            },
          ],
          'blocked_documents': [
            {'doc_type': 'national_id', 'problem': 'missing'},
          ],
        }),
      );
      final file = await client.adminKycDriver('d1');
      final slot = file.documents.single;
      expect(file.status, OnboardingStatus.inReview);
      expect(slot.latest?.photos.single.side, DocSide.front);
      expect(slot.current?.legacy, isTrue);
      expect(slot.rejectedCount, 3);
      expect(slot.suggestSupport, isTrue);
      expect(file.blockedDocuments.single.problem, BlockedDocumentProblem.missing);
    });

    test('cola KYC con pending_documents', () async {
      adapter.onGet(
        '/v1/admin/kyc/queue',
        (s) => s.reply(200, [
          {
            'driver_id': 'd1',
            'display_name': 'Carlos',
            'vehicle_plate': 'ABC123',
            'pending_documents': 4,
            'oldest_submitted_at': '2026-10-20T15:00:00Z',
          },
        ]),
      );
      expect((await client.adminKycQueue()).single.pendingCount, 4);
    });

    test('driverMe de 002: sin pago aún y documentos que bloquean', () async {
      adapter.onGet(
        '/v1/driver/me',
        (s) => s.reply(200, {
          'driver_id': 'd1',
          'qr_token': 'q',
          'presence': 'offline',
          'subscription_status': 'suspended',
          'paid_until': null,
          'can_go_online': false,
          'block_reason': 'kyc_expired',
          'blocked_documents': [
            {'doc_type': 'mandatory_insurance', 'problem': 'expired'},
          ],
          'documents': [
            {'doc_type': 'license', 'expires_at': null, 'approved': true},
          ],
        }),
      );
      final me = await client.driverMe();
      expect(me.paidUntil, isNull);
      expect(me.blockedDocuments.single.docType, DocType.mandatoryInsurance);
      expect(me.documents.single.expiresAt, isNull);
    });

    test('suscripciones filtradas por estado y pagos manuales', () async {
      adapter
        ..onGet(
          '/v1/admin/subscriptions',
          (s) => s.reply(200, [
            {
              'driver_id': 'd1',
              'display_name': 'Carlos',
              'status': 'suspended',
              'paid_until': '2026-10-01T00:00:00Z',
              'last_payment': _payment(status: 'approved'),
            },
          ]),
          queryParameters: {'status': 'suspended'},
        )
        ..onPost(
          '/v1/admin/drivers/d1/payments',
          (s) => s.reply(201, _payment(status: 'approved')),
          data: {'method_detail': 'efectivo', 'reference': 'R-1'},
        )
        ..onPost('/v1/admin/payments/p1/void', (s) => s.reply(200, null), data: {'reason': 'contracargo'});

      final subs = await client.adminSubscriptions(status: BillingStatus.suspended);
      expect(subs.single.lastPayment?.status, PaymentStatus.approved);
      await client.adminManualPayment('d1', methodDetail: 'efectivo', reference: 'R-1');
      await client.adminVoidPayment('p1', 'contracargo');
    });

    test('tarifas de costo y costos por conductor', () async {
      adapter
        ..onPut(
          '/v1/admin/cost-rates',
          (s) => s.reply(200, null),
          data: {
            'concept': 'voice_minute',
            'currency': 'COP',
            'unit_cost_micro': 2000000,
            'effective_from': '2026-11-01',
          },
        )
        ..onGet(
          '/v1/admin/costs',
          (s) => s.reply(200, {
            'month': '2026-10',
            'drivers': [
              {
                'driver_id': 'd1',
                'display_name': 'Carlos',
                'paid_minor': 0,
                'total_cost_minor': 10,
                'margin_minor': -10,
              },
            ],
          }),
          queryParameters: {'month': '2026-10'},
        );
      await client.adminSetCostRate(
        CostRate(
          concept: CostConcepts.voiceMinute,
          currency: 'COP',
          unitCostMicro: 2000000,
          effectiveFrom: DateTime(2026, 11),
        ),
      );
      final costs = await client.adminCosts(DateTime(2026, 10));
      expect(costs.single.marginMinor, -10);
    });

    test('precio de suscripción con vigencia', () async {
      adapter.onPut(
        '/v1/admin/subscription-prices/bogota',
        (s) => s.reply(200, null),
        data: {'currency': 'COP', 'amount_minor': 5000000, 'effective_from': '2026-11-01T05:00:00.000Z'},
      );
      await client.adminSetSubscriptionPrice(
        'bogota',
        currency: 'COP',
        amountMinor: 5000000,
        effectiveFrom: DateTime.utc(2026, 11, 1, 5),
      );
    });
  });
}

/// Almacenamiento S3 falso: responde con [statuses] en orden y guarda lo recibido.
class _UploadServer implements HttpClientAdapter {
  final statuses = <int>[];
  final requests = <RequestOptions>[];
  final bodies = <List<int>>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final bytes = <int>[];
    if (requestStream != null) {
      await for (final chunk in requestStream) {
        bytes.addAll(chunk);
      }
    }
    bodies.add(bytes);
    final status = statuses.isEmpty ? 200 : statuses.removeAt(0);
    return ResponseBody.fromString(status < 400 ? '' : '<Error/>', status);
  }

  @override
  void close({bool force = false}) {}
}
