import 'package:kyq_api/kyq_api.dart';
import 'package:test/test.dart';

void main() {
  test('RadioMe con acceso de prueba y aviso pendiente', () {
    final me = RadioMe.fromJson({
      'access': 'full',
      'access_reason': null,
      'trial_days_left': 9,
      'status': 'listen_only',
      'radio_on': true,
      'push_mode': 'toggle',
      'consent_required': true,
      'retention_days': 30,
      'clients_enabled': false,
    });
    expect(me.access, RadioAccess.full);
    expect(me.status, RadioPresence.listenOnly);
    expect(me.pushMode, RadioPushMode.toggle);
    expect(me.trialDaysLeft, 9);
    expect(me.clientsEnabled, isFalse);
  });

  test('conversación: contacto, canal y valores desconocidos', () {
    final contact = RadioConversation.fromJson({
      'id': 'c1',
      'kind': 'direct',
      'title': 'Jonathan',
      'peer_id': 'u2',
      'peer_status': 'busy',
      'listening': true,
      'unread_count': 3,
      'last_message_at': '2026-10-28T12:00:00Z',
      'status': 'active',
      'can_talk': true,
      'my_member_status': 'active',
    });
    expect(contact.isChannel, isFalse);
    expect(contact.peerStatus, RadioPresence.busy);
    expect(contact.unreadCount, 3);
    final channel = RadioConversation.fromJson({
      'id': 'c2',
      'kind': 'cooperative',
      'title': 'Cooperativa Andina',
      'online_count': 4,
      'my_role': 'moderator',
      'listening': false,
      'unread_count': 0,
      'status': 'suspended',
      'peer_status': 'raro',
    });
    expect(channel.isChannel, isTrue);
    expect(channel.moderates, isTrue);
    expect(channel.suspended, isTrue);
    expect(channel.peerStatus, RadioPresence.offline);
  });

  test('detalle con miembros y mensaje de voz', () {
    final d = RadioConversationDetail.fromJson({
      'id': 'c2',
      'kind': 'channel',
      'title': 'Taxistas Norte',
      'listening': true,
      'unread_count': 0,
      'join_mode': 'approval',
      'passenger_role_max': 'listener',
      'members': [
        {'user_id': 'u1', 'display_name': 'Jonathan', 'role': 'owner', 'status': 'active', 'presence': 'available'},
        {
          'user_id': 'u3',
          'display_name': 'Ana',
          'role': 'listener',
          'status': 'pending',
          'presence': 'offline',
          'is_passenger': true,
        },
      ],
    });
    expect(d.joinMode, 'approval');
    expect(d.passengerRoleMax, RadioRole.listener);
    expect(d.members.last.isPassenger, isTrue);
    expect(d.members.last.status, RadioMemberStatus.pending);

    final m = RadioMessage.fromJson({
      'id': 'm1',
      'conversation_id': 'c2',
      'author_id': 'u1',
      'author_name': 'Jonathan',
      'kind': 'voice',
      'status': 'ready',
      'duration_ms': 2300,
      'has_media': true,
      'created_at': '2026-10-28T12:00:00Z',
      'heard': false,
      'saved': true,
    });
    expect(m.kind, RadioMessageKind.voice);
    expect(m.durationMs, 2300);
    expect(m.hasMedia, isTrue);
    expect(m.saved, isTrue);
  });

  test('panel: configuración con costos y fila de carga masiva', () {
    final s = RadioSettings.fromJson({
      'trial_policy': 'trial',
      'trial_days': 14,
      'passengers_in_channels': 'none',
      'retention_days': 30,
      'estimated_monthly_cost_minor': {'7': 100, '30': 400, '90': 1200},
    });
    expect(s.estimatedMonthlyCostMinor['30'], 400);
    final detail = RadioBulkUploadDetail.fromJson({
      'id': 'b1',
      'file_name': 'norte.csv',
      'status': 'validated',
      'rows_total': 2,
      'counts': {'pending': 1, 'failed': 1},
      'created_at': '2026-10-28T12:00:00Z',
      'rows': [
        {
          'line': 2,
          'name': 'Pedro',
          'phone_masked': '+57 300 *** **12',
          'kind': 'driver',
          'channel': 'Norte',
          'role': 'member',
          'status': 'pending',
        },
        {'line': 3, 'status': 'failed', 'error': 'teléfono inválido'},
      ],
    });
    expect(detail.upload.counts['failed'], 1);
    expect(detail.rows.first.phoneMasked, '+57 300 *** **12');
    expect(detail.rows.last.error, 'teléfono inválido');
  });
}
