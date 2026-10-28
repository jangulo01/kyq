import 'package:kyq_realtime/kyq_realtime.dart';
import 'package:test/test.dart';

Map<String, dynamic> envelope(String type, Map<String, dynamic> data) => {
  'type': type,
  'occurred_at': '2026-10-27T12:00:00Z',
  'data': data,
};

void main() {
  test('canales', () {
    expect(Channels.user('u1'), 'user:u1');
    expect(Channels.driverPresence('d1'), 'driver_presence:d1');
    expect(Channels.trip('t1'), 'trip:t1');
    expect(Channels.adminTower, 'admin:tower');
  });

  test('tower.changed (007) no lleva datos', () {
    final e = RealtimeEvent.fromEnvelope(envelope('tower.changed', {}));
    expect(e, isA<TowerChanged>());
    expect(e.occurredAt, DateTime.utc(2026, 10, 27, 12));
  });

  test('driver.presence', () {
    final e = RealtimeEvent.fromEnvelope(
      envelope('driver.presence', {
        'driver_id': 'd1',
        'presence': 'busy',
        'busy_until_estimate': '2026-10-27T12:12:00Z',
      }),
    );
    expect(e, isA<DriverPresenceChanged>());
    e as DriverPresenceChanged;
    expect(e.presence, 'busy');
    expect(e.busyUntilEstimate, DateTime.utc(2026, 10, 27, 12, 12));
    expect(e.occurredAt, DateTime.utc(2026, 10, 27, 12));
  });

  test('trip.offer', () {
    final e =
        RealtimeEvent.fromEnvelope(
              envelope('trip.offer', {
                'trip_id': 't1',
                'passenger_name': 'Ana',
                'pickup': {'lat': 4.6, 'lng': -74.08},
                'dropoff': {'lat': 4.65, 'lng': -74.05},
                'distance_m': 5200,
                'duration_s': 900,
                'suggested_fare_minor': 1250000,
                'currency': 'COP',
                'expires_at': '2026-10-27T12:00:25Z',
              }),
            )
            as TripOffered;
    expect(e.pickup.lat, 4.6);
    expect(e.suggestedFareMinor, 1250000);
    expect(e.expiresAt.difference(e.occurredAt), const Duration(seconds: 25));
    expect(e.origin, OfferOrigin.chosenDriver, reason: 'sin origin, viene de su cartera');
    expect(e.loyalClient, isFalse);
    expect(e.pickupDistanceM, isNull);
  });

  test('trip.offer con el origen de 008', () {
    final base = {
      'trip_id': 't1',
      'passenger_name': 'Ana',
      'pickup': {'lat': 4.6, 'lng': -74.08},
      'dropoff': {'lat': 4.65, 'lng': -74.05},
      'distance_m': 5200,
      'duration_s': 900,
      'suggested_fare_minor': 1320000,
      'currency': 'COP',
      'expires_at': '2026-10-27T12:00:25Z',
    };
    final loyal =
        RealtimeEvent.fromEnvelope(
              envelope('trip.offer', {
                ...base,
                'origin': 'chosen_driver',
                'loyal_client': true,
                'trips_together': 4,
                'preferential_discount_pct': 10,
              }),
            )
            as TripOffered;
    expect(loyal.loyalClient, isTrue);
    expect(loyal.tripsTogether, 4);
    expect(loyal.preferentialDiscountPct, 10);

    final pool =
        RealtimeEvent.fromEnvelope(envelope('trip.offer', {...base, 'origin': 'zone_pool', 'pickup_distance_m': 3000}))
            as TripOffered;
    expect(pool.origin, OfferOrigin.zonePool);
    expect(pool.pickupDistanceM, 3000);
    expect(offerOriginFromApi('cooperative'), OfferOrigin.cooperative);
  });

  test('trip.status, propuesta, negociación, ubicación y cierre PTT', () {
    expect(
      RealtimeEvent.fromEnvelope(
        envelope('trip.status', {'trip_id': 't1', 'status': 'ACCEPTED', 'agreed_fare_minor': 1000}),
      ),
      isA<TripStatusChanged>().having((e) => e.agreedFareMinor, 'fare', 1000),
    );
    expect(
      RealtimeEvent.fromEnvelope(
        envelope('trip.fare_proposal', {
          'trip_id': 't1',
          'proposal_id': 'p1',
          'proposed_by': 'driver',
          'amount_minor': 1100,
          'expires_at': '2026-10-27T12:00:30Z',
        }),
      ),
      isA<FareProposed>().having((e) => e.proposedBy, 'by', 'driver'),
    );
    expect(
      RealtimeEvent.fromEnvelope(
        envelope('trip.negotiation_requested', {'trip_id': 't1', 'expires_at': '2026-10-27T12:00:30Z'}),
      ),
      isA<NegotiationRequested>(),
    );
    expect(
      RealtimeEvent.fromEnvelope(envelope('trip.location', {'lat': 4, 'lng': -74, 'heading': 90})),
      isA<DriverLocation>().having((e) => e.lat, 'lat', 4.0),
    );
    expect(RealtimeEvent.fromEnvelope(envelope('ptt.closed', {'trip_id': 't1'})), isA<PttClosed>());
    expect(
      RealtimeEvent.fromEnvelope(envelope('trip.offer_closed', {'trip_id': 't1', 'reason': 'offer_expired'})),
      isA<TripOfferClosed>(),
    );
  });

  test('preconsult.*', () {
    final opened = RealtimeEvent.fromEnvelope(
      envelope('preconsult.opened', {
        'preconsult_id': 'pc1',
        'passenger_id': 'p1',
        'passenger_name': 'Ana',
        'join_deadline': '2026-10-27T12:00:30Z',
        'closes_at': '2026-10-27T12:02:00Z',
      }),
    );
    expect(opened, isA<PreconsultOpened>());
    opened as PreconsultOpened;
    expect(opened.passengerName, 'Ana');
    expect(opened.closesAt, DateTime.utc(2026, 10, 27, 12, 2));
    expect(
      RealtimeEvent.fromEnvelope(envelope('preconsult.joined', {'preconsult_id': 'pc1'})),
      isA<PreconsultJoined>().having((e) => e.preconsultId, 'id', 'pc1'),
    );
    expect(
      RealtimeEvent.fromEnvelope(envelope('preconsult.closed', {'preconsult_id': 'pc1', 'reason': 'missed'})),
      isA<PreconsultClosed>().having((e) => e.reason, 'reason', 'missed'),
    );
  });

  test('notice.created', () {
    final e =
        RealtimeEvent.fromEnvelope(
              envelope('notice.created', {
                'id': 'n1',
                'kind': 'doc_rejected',
                'title': 'Documento rechazado',
                'body': 'SOAT: foto borrosa',
              }),
            )
            as NoticeCreated;
    expect(e.noticeId, 'n1');
    expect(e.kind, 'doc_rejected');
    expect(e.title, 'Documento rechazado');
    expect(
      RealtimeEvent.fromEnvelope(envelope('notice.created', {'notice_id': 'n2', 'kind': 'sub_grace', 'title': 't'})),
      isA<NoticeCreated>().having((e) => e.noticeId, 'id', 'n2').having((e) => e.body, 'body', ''),
    );
  });

  test('trip_payment.updated y trip_payment.reminder (004)', () {
    final updated =
        RealtimeEvent.fromEnvelope(
              envelope('trip_payment.updated', {
                'trip_id': 't1',
                'payment_id': 'tp1',
                'status': 'cash_reported',
                'method': 'cash',
              }),
            )
            as TripPaymentUpdated;
    expect(updated.tripId, 't1');
    expect(updated.status, 'cash_reported');
    expect(updated.method, 'cash');
    expect(
      RealtimeEvent.fromEnvelope(
        envelope('trip_payment.updated', {'trip_id': 't1', 'payment_id': 'tp1', 'status': 'pending', 'method': null}),
      ),
      isA<TripPaymentUpdated>().having((e) => e.method, 'method', isNull),
    );
    final reminder =
        RealtimeEvent.fromEnvelope(
              envelope('trip_payment.reminder', {
                'trip_id': 't1',
                'payment_id': 'tp1',
                'amount_minor': 1800000,
                'currency': 'COP',
              }),
            )
            as TripPaymentReminder;
    expect(reminder.amountMinor, 1800000);
    expect(reminder.currency, 'COP');
  });

  test('tipos nuevos no rompen la app', () {
    expect(RealtimeEvent.fromEnvelope(envelope('futuro.evento', {'x': 1})), isA<UnknownEvent>());
  });

  test('006: trip.offer derivada, trip.delegated y cooperative.membership', () {
    final offer =
        RealtimeEvent.fromEnvelope(
              envelope('trip.offer', {
                'trip_id': 't1',
                'passenger_name': 'Ana',
                'pickup': {'lat': 4.6, 'lng': -74.08},
                'dropoff': {'lat': 4.65, 'lng': -74.05},
                'distance_m': 5200,
                'duration_s': 900,
                'suggested_fare_minor': 1470000,
                'currency': 'COP',
                'expires_at': '2026-10-27T12:00:25Z',
                'delegated': true,
                'can_delegate': true,
                'cooperative_name': 'Cooperativa Andina',
                'requested_driver_name': 'Carlos',
              }),
            )
            as TripOffered;
    expect(offer.delegated, isTrue);
    expect(offer.canDelegate, isTrue);
    expect(offer.cooperativeName, 'Cooperativa Andina');
    expect(offer.requestedDriverName, 'Carlos');

    final delegated =
        RealtimeEvent.fromEnvelope(
              envelope('trip.delegated', {
                'trip_id': 't1',
                'cooperative_id': 'c1',
                'cooperative_name': 'Cooperativa Andina',
                'reason': 'offer_rejected',
                'expires_at': '2026-10-27T12:00:50Z',
              }),
            )
            as TripDelegated;
    expect(delegated.reason, 'offer_rejected');
    expect(delegated.expiresAt, DateTime.utc(2026, 10, 27, 12, 0, 50));

    final membership =
        RealtimeEvent.fromEnvelope(
              envelope('cooperative.membership', {
                'membership_id': 'm1',
                'cooperative_id': 'c1',
                'status': 'active',
                'role': 'coordinator',
              }),
            )
            as CooperativeMembershipChanged;
    expect(membership.status, 'active');
    expect(membership.role, 'coordinator');
  });

  test('006: trip.offer de 001 sin campos nuevos', () {
    final offer =
        RealtimeEvent.fromEnvelope(
              envelope('trip.offer', {
                'trip_id': 't1',
                'passenger_name': 'Ana',
                'pickup': {'lat': 4.6, 'lng': -74.08},
                'dropoff': {'lat': 4.65, 'lng': -74.05},
                'distance_m': 5200,
                'duration_s': 900,
                'suggested_fare_minor': 1470000,
                'currency': 'COP',
                'expires_at': '2026-10-27T12:00:25Z',
              }),
            )
            as TripOffered;
    expect(offer.delegated, isFalse);
    expect(offer.canDelegate, isFalse);
  });

  group('sos (003)', () {
    test('canales de la consola', () {
      expect(Channels.opsSos, 'ops:sos');
      expect(Channels.sos('a1'), 'sos:a1');
    });

    test('sos.created y sos.claimed', () {
      final created = RealtimeEvent.fromEnvelope(
        envelope('sos.created', {
          'alert_id': 'a1',
          'trip_id': 't1',
          'raised_role': 'driver',
          'raised_by_name': 'Carlos',
          'created_at': '2026-10-27T12:00:00Z',
          'location': null,
        }),
      );
      expect(created, isA<SosCreated>().having((e) => e.raisedRole, 'role', 'driver'));
      final claimed = RealtimeEvent.fromEnvelope(
        envelope('sos.claimed', {'alert_id': 'a1', 'operator_id': 'op', 'operator_name': 'Lucía'}),
      );
      expect(claimed, isA<SosClaimed>().having((e) => e.operatorName, 'name', 'Lucía'));
    });

    test('sos.location, sos.cancel_attempt y sos.closed', () {
      final loc = RealtimeEvent.fromEnvelope(
        envelope('sos.location', {
          'alert_id': 'a1',
          'lat': 4.6,
          'lng': -74.1,
          'accuracy_m': null,
          'at': '2026-10-27T12:00:01Z',
        }),
      );
      expect(loc, isA<SosLocationUpdate>().having((e) => e.at, 'at', DateTime.utc(2026, 10, 27, 12, 0, 1)));
      final attempt = RealtimeEvent.fromEnvelope(
        envelope('sos.cancel_attempt', {
          'alert_id': 'a1',
          'cancel_without_pin': true,
          'failed_attempts': 5,
          'locked': true,
        }),
      );
      expect(attempt, isA<SosCancelAttempt>().having((e) => e.locked, 'locked', isTrue));
      final closed = RealtimeEvent.fromEnvelope(envelope('sos.closed', {'alert_id': 'a1'}));
      expect(closed, isA<SosClosed>().having((e) => e.status, 'status', isNull));
      expect(RealtimeEvent.fromEnvelope(envelope('sos.escalated', {'alert_id': 'a1'})), isA<SosEscalated>());
      expect(RealtimeEvent.fromEnvelope(envelope('sos.released', {'alert_id': 'a1'})), isA<SosReleased>());
    });
  });

  test('009: support.case y megáfono', () {
    expect(
      RealtimeEvent.fromEnvelope(envelope('support.case', {'case_id': 'c1', 'status': 'open'})),
      isA<SupportCaseChanged>().having((e) => e.caseId, 'case', 'c1'),
    );
    final started =
        RealtimeEvent.fromEnvelope(
              envelope('megaphone.started', {
                'broadcast_id': 'b1',
                'url': 'wss://lk',
                'token': 'tk',
                'ends_at': '2026-10-27T12:01:00Z',
              }),
            )
            as MegaphoneStarted;
    expect(started.token, 'tk');
    expect(started.endsAt, DateTime.utc(2026, 10, 27, 12, 1));
    expect(RealtimeEvent.fromEnvelope(envelope('megaphone.ended', {'broadcast_id': 'b1'})), isA<MegaphoneEnded>());
  });

  test('010: reservas y nota en la oferta', () {
    expect(
      RealtimeEvent.fromEnvelope(envelope('reservation.updated', {'reservation_id': 'r1', 'status': 'confirmed'})),
      isA<ReservationUpdated>().having((e) => e.status, 'status', 'confirmed'),
    );
    expect(
      RealtimeEvent.fromEnvelope(
        envelope('reservation.notice', {'reservation_id': 'r1', 'status': 'missed', 'message': 'Tu conductor no está'}),
      ),
      isA<ReservationNotice>().having((e) => e.message, 'message', 'Tu conductor no está'),
    );
    final offer =
        RealtimeEvent.fromEnvelope(
              envelope('trip.offer', {
                'trip_id': 't1',
                'passenger_name': 'Ana',
                'pickup': {'lat': 4.6, 'lng': -74.08},
                'dropoff': {'lat': 4.65, 'lng': -74.05},
                'distance_m': 5200,
                'duration_s': 900,
                'suggested_fare_minor': 1320000,
                'currency': 'COP',
                'expires_at': '2026-10-27T12:00:25Z',
                'reservation': true,
                'client_note': 'Portería 2',
              }),
            )
            as TripOffered;
    expect(offer.reservation, isTrue);
    expect(offer.clientNote, 'Portería 2');
  });
}
