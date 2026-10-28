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

  test('tipos nuevos no rompen la app', () {
    expect(RealtimeEvent.fromEnvelope(envelope('futuro.evento', {'x': 1})), isA<UnknownEvent>());
  });
}
