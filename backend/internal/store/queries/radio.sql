-- 011 Radio Kyq (specs/011-radio-kyq/data-model.md).

-- Configuración y acceso ---------------------------------------------------------------------

-- name: GetRadioSettings :one
SELECT s.trial_policy, s.trial_days, s.passengers_in_channels, s.retention_days, s.updated_at,
       coalesce(u.display_name, '')::text AS updated_by_name
FROM radio_settings s
LEFT JOIN users u ON u.id = s.updated_by
WHERE s.id = 1;

-- name: UpdateRadioSettings :exec
UPDATE radio_settings
SET trial_policy = $1, trial_days = $2, passengers_in_channels = $3, retention_days = $4,
    updated_by = $5, updated_at = $6
WHERE id = 1;

-- name: InsertRadioSettingsAudit :exec
INSERT INTO radio_settings_audit (id, admin_id, before, after, at) VALUES ($1, $2, $3, $4, $5);

-- name: GetRadioSubject :one
-- Lo que decide el acceso a Radio (FR-005): rol, suspensión (007), alta y suscripción (002).
SELECT u.role, u.display_name, (u.suspended_at IS NOT NULL)::boolean AS suspended, u.created_at,
       (s.paid_until IS NOT NULL)::boolean AS has_subscription,
       coalesce(s.paid_until, 'epoch'::timestamptz)::timestamptz AS paid_until
FROM users u
LEFT JOIN subscriptions s ON s.driver_id = u.id
WHERE u.id = $1;

-- name: GetRadioConsent :one
SELECT retention_days_accepted, accepted_at FROM radio_consents WHERE user_id = $1;

-- name: UpsertRadioConsent :exec
INSERT INTO radio_consents (user_id, retention_days_accepted, accepted_at) VALUES ($1, $2, $3)
ON CONFLICT (user_id) DO UPDATE SET retention_days_accepted = EXCLUDED.retention_days_accepted,
    accepted_at = EXCLUDED.accepted_at;

-- Presencia ----------------------------------------------------------------------------------

-- name: EnsureRadioPresence :one
INSERT INTO radio_presence (user_id, updated_at) VALUES ($1, $2)
ON CONFLICT (user_id) DO UPDATE SET user_id = EXCLUDED.user_id
RETURNING *;

-- name: UpdateRadioPresence :one
UPDATE radio_presence
SET status = coalesce(sqlc.narg(status)::radio_presence_status, status),
    -- Elegir un estado a mano termina el horario de silencio en curso.
    status_before_quiet = CASE WHEN sqlc.narg(status)::radio_presence_status IS NULL THEN status_before_quiet END,
    radio_on = coalesce(sqlc.narg(radio_on)::boolean, radio_on),
    push_mode = coalesce(sqlc.narg(push_mode)::text, push_mode),
    last_seen_at = CASE WHEN sqlc.narg(radio_on)::boolean THEN sqlc.arg(now)::timestamptz ELSE last_seen_at END,
    updated_at = sqlc.arg(now)::timestamptz
WHERE user_id = sqlc.arg(user_id)
RETURNING *;

-- name: TouchRadioPresence :one
-- Latido (R5): la radio sigue encendida.
UPDATE radio_presence SET last_seen_at = $2, radio_on = true WHERE user_id = $1
RETURNING user_id;

-- name: SetRadioClientsEnabled :exec
UPDATE radio_presence SET clients_enabled = $2, updated_at = $3 WHERE user_id = $1;

-- name: ListStaleRadioPresence :many
-- Radios encendidas sin latido: pasan a Desconectado (90 s, R5).
UPDATE radio_presence SET radio_on = false, updated_at = sqlc.arg(now)::timestamptz
WHERE radio_on AND (last_seen_at IS NULL OR last_seen_at < sqlc.arg(stale_before)::timestamptz)
RETURNING user_id;

-- name: ListQuietHoursDue :many
-- Usuarios con un horario de silencio y su zona horaria, para el barrido de cada minuto.
SELECT p.user_id, p.status, p.status_before_quiet, p.timezone,
       q.weekdays, q.starts, q.ends
FROM radio_quiet_hours q
JOIN radio_presence p ON p.user_id = q.user_id
WHERE q.enabled
ORDER BY p.user_id;

-- name: SetRadioQuietStatus :execrows
-- Entra o sale de un horario de silencio (FR-021).
UPDATE radio_presence
SET status = $2, status_before_quiet = $3, updated_at = $4
WHERE user_id = $1;

-- name: ListRadioQuietHours :many
SELECT * FROM radio_quiet_hours WHERE user_id = $1 ORDER BY starts, id;

-- name: DeleteRadioQuietHours :exec
DELETE FROM radio_quiet_hours WHERE user_id = $1;

-- name: InsertRadioQuietHours :exec
INSERT INTO radio_quiet_hours (id, user_id, weekdays, starts, ends, enabled) VALUES ($1, $2, $3, $4, $5, $6);

-- Conversaciones -----------------------------------------------------------------------------

-- name: InsertRadioConversation :one
INSERT INTO radio_conversations (id, kind, name, description, join_mode, passenger_role_max, cooperative_id,
                                 pair_a, pair_b, room_name, created_by, created_at)
VALUES ($1, $2, sqlc.narg(name), sqlc.narg(description), sqlc.narg(join_mode), sqlc.narg(passenger_role_max),
        sqlc.narg(cooperative_id), sqlc.narg(pair_a), sqlc.narg(pair_b), $3, sqlc.narg(created_by), $4)
ON CONFLICT DO NOTHING
RETURNING *;

-- name: GetRadioConversation :one
SELECT * FROM radio_conversations WHERE id = $1;

-- name: GetRadioConversationByRoom :one
SELECT * FROM radio_conversations WHERE room_name = $1;

-- name: GetRadioPair :one
SELECT * FROM radio_conversations
WHERE kind = $1 AND pair_a = $2 AND pair_b = $3 AND status <> 'deleted';

-- name: GetRadioCooperativeConversation :one
SELECT * FROM radio_conversations WHERE cooperative_id = $1;

-- name: UpdateRadioChannel :one
UPDATE radio_conversations
SET name = coalesce(sqlc.narg(name), name),
    description = coalesce(sqlc.narg(description), description),
    join_mode = coalesce(sqlc.narg(join_mode), join_mode),
    passenger_role_max = CASE WHEN sqlc.arg(set_passenger_role)::boolean THEN sqlc.narg(passenger_role_max) ELSE passenger_role_max END
WHERE id = sqlc.arg(id) AND kind = 'channel' AND status = 'active'
RETURNING *;

-- name: DeleteRadioConversation :execrows
UPDATE radio_conversations SET status = 'deleted', deleted_at = $2 WHERE id = $1 AND status <> 'deleted';

-- name: SetRadioConversationStatus :execrows
-- Suspender o reactivar un canal desde el panel (US11).
UPDATE radio_conversations
SET status = $2, suspended_at = CASE WHEN $2 = 'suspended'::radio_conversation_status THEN $3::timestamptz END
WHERE id = $1 AND status <> 'deleted';

-- name: RotateRadioRoom :execrows
-- Sala nueva tras expulsar, salir o bloquear (R1): el token viejo ya no abre nada.
UPDATE radio_conversations SET room_name = sqlc.arg(new_room) WHERE id = sqlc.arg(id) AND room_name = sqlc.arg(old_room);

-- name: CountRadioOwnedChannels :one
SELECT count(*)::int FROM radio_conversations c
JOIN radio_members m ON m.conversation_id = c.id
WHERE m.user_id = $1 AND m.role = 'owner' AND m.status IN ('active', 'muted')
  AND c.kind = 'channel' AND c.status <> 'deleted';

-- name: ListRadioConversations :many
-- Lista única (FR-001): contactos, clientes, canales y cooperativa donde el usuario participa.
-- Un cliente solo aparece si la afiliación sigue activa y el conductor tiene "Radio con mis
-- clientes" encendida (FR-003).
SELECT c.id, c.kind, c.status, c.name, c.cooperative_id,
       m.role, m.status AS member_status, m.listening, m.muted_by_peer, m.blocked_by_peer,
       coalesce(coop.name, c.name, peer_u.display_name, '')::text AS title,
       (peer_u.id IS NOT NULL)::boolean AS has_peer,
       coalesce(peer_u.id, '00000000-0000-0000-0000-000000000000'::uuid)::uuid AS peer_id,
       coalesce(peer_p.status::text, 'available')::text AS peer_status,
       ((peer_p.radio_on AND peer_p.last_seen_at > sqlc.arg(fresh_after)::timestamptz) IS TRUE)::boolean AS peer_online,
       (SELECT count(*)::int FROM radio_members om JOIN radio_presence op ON op.user_id = om.user_id
         WHERE om.conversation_id = c.id AND om.status IN ('active', 'muted')
           AND op.radio_on AND op.last_seen_at > sqlc.arg(fresh_after)::timestamptz) AS online_count,
       (SELECT count(*)::int FROM radio_messages rm
         LEFT JOIN radio_receipts rr ON rr.message_id = rm.id AND rr.user_id = m.user_id
         WHERE rm.conversation_id = c.id AND rm.status = 'ready' AND rm.created_at >= m.joined_at
           AND rm.expires_at > sqlc.arg(now)::timestamptz
           AND rm.author_id IS DISTINCT FROM m.user_id AND rr.heard_at IS NULL) AS unread_count,
       coalesce((SELECT max(rm.created_at) FROM radio_messages rm
         WHERE rm.conversation_id = c.id AND rm.status = 'ready'), 'epoch'::timestamptz)::timestamptz AS last_message_at,
       coalesce(pm.muted_by_peer, false)::boolean AS peer_muted,
       coalesce(pm.blocked_by_peer, false)::boolean AS peer_blocked
FROM radio_members m
JOIN radio_conversations c ON c.id = m.conversation_id
LEFT JOIN cooperatives coop ON coop.id = c.cooperative_id
LEFT JOIN users peer_u ON c.pair_a IS NOT NULL
    AND peer_u.id = CASE WHEN c.pair_a = m.user_id THEN c.pair_b ELSE c.pair_a END
LEFT JOIN radio_presence peer_p ON peer_p.user_id = peer_u.id
LEFT JOIN radio_members pm ON pm.conversation_id = c.id AND pm.user_id = peer_u.id
WHERE m.user_id = sqlc.arg(user_id)
  AND m.status IN ('active', 'muted', 'pending')
  AND c.status IN ('active', 'suspended')
  AND (c.kind <> 'client' OR EXISTS (
        SELECT 1 FROM affiliations a
        JOIN radio_presence dp ON dp.user_id = a.driver_id AND dp.clients_enabled
        WHERE a.removed_at IS NULL
          AND ((a.passenger_id = c.pair_a AND a.driver_id = c.pair_b) OR (a.passenger_id = c.pair_b AND a.driver_id = c.pair_a))))
ORDER BY last_message_at DESC, c.created_at DESC;

-- name: ListRadioActiveAffiliations :many
-- Clientes del conductor o conductores del pasajero, con "Radio con mis clientes" (FR-003).
SELECT a.passenger_id, a.driver_id
FROM affiliations a
JOIN radio_presence dp ON dp.user_id = a.driver_id AND dp.clients_enabled
WHERE a.removed_at IS NULL AND (a.passenger_id = $1 OR a.driver_id = $1);

-- name: IsRadioClientPair :one
SELECT EXISTS (
    SELECT 1 FROM affiliations a
    JOIN radio_presence dp ON dp.user_id = a.driver_id AND dp.clients_enabled
    WHERE a.removed_at IS NULL AND a.passenger_id = $1 AND a.driver_id = $2
) AS ok;

-- Miembros -----------------------------------------------------------------------------------

-- name: UpsertRadioMember :one
-- Una conversación nueva llega con "Escuchar" solo si el usuario aún escucha menos de 10 (FR-024).
INSERT INTO radio_members (conversation_id, user_id, role, status, listening, joined_at, updated_at)
VALUES (sqlc.arg(conversation_id), sqlc.arg(user_id), sqlc.arg(role), sqlc.arg(status),
        sqlc.arg(listening)::boolean AND (SELECT count(*) FROM radio_members l
                WHERE l.user_id = sqlc.arg(user_id) AND l.listening AND l.status IN ('active', 'muted')) < 10,
        sqlc.arg(joined_at), sqlc.arg(joined_at))
ON CONFLICT (conversation_id, user_id) DO UPDATE
SET role = EXCLUDED.role, status = EXCLUDED.status, joined_at = EXCLUDED.joined_at, updated_at = EXCLUDED.updated_at,
    muted_by_peer = false, blocked_by_peer = false
RETURNING *;

-- name: GetRadioMember :one
SELECT m.*, c.kind, c.status AS conversation_status, c.room_name, c.cooperative_id, c.pair_a, c.pair_b
FROM radio_members m
JOIN radio_conversations c ON c.id = m.conversation_id
WHERE m.conversation_id = $1 AND m.user_id = $2;

-- name: UpdateRadioMember :one
UPDATE radio_members
SET role = coalesce(sqlc.narg(role)::radio_role, role),
    status = coalesce(sqlc.narg(status)::radio_member_status, status),
    updated_at = sqlc.arg(now)::timestamptz
WHERE conversation_id = sqlc.arg(conversation_id) AND user_id = sqlc.arg(user_id)
RETURNING *;

-- name: SetRadioPeerFlags :execrows
-- El conductor silencia o bloquea al pasajero en su conversación de cliente (FR-003).
UPDATE radio_members
SET muted_by_peer = $3, blocked_by_peer = $4, updated_at = $5
WHERE conversation_id = $1 AND user_id = $2;

-- name: SetRadioListening :execrows
UPDATE radio_members SET listening = $3, updated_at = $4
WHERE conversation_id = $1 AND user_id = $2 AND status IN ('active', 'muted');

-- name: CountRadioListening :one
SELECT count(*)::int FROM radio_members m
JOIN radio_conversations c ON c.id = m.conversation_id
WHERE m.user_id = $1 AND m.listening AND m.status IN ('active', 'muted') AND c.status <> 'deleted';

-- name: CountRadioActiveMembers :one
SELECT count(*)::int FROM radio_members WHERE conversation_id = $1 AND status IN ('active', 'muted');

-- name: ListRadioMembers :many
SELECT m.user_id, m.role, m.status, u.display_name, u.role AS user_role,
       coalesce(p.status::text, 'available')::text AS presence_status,
       ((p.radio_on AND p.last_seen_at > sqlc.arg(fresh_after)::timestamptz) IS TRUE)::boolean AS online
FROM radio_members m
JOIN users u ON u.id = m.user_id
LEFT JOIN radio_presence p ON p.user_id = m.user_id
WHERE m.conversation_id = sqlc.arg(conversation_id) AND m.status IN ('active', 'muted', 'pending', 'blocked')
ORDER BY CASE m.role WHEN 'owner' THEN 0 WHEN 'moderator' THEN 1 WHEN 'member' THEN 2 ELSE 3 END, u.display_name;

-- name: ListRadioRecipients :many
-- Quiénes reciben los eventos de una conversación: miembros activos o silenciados.
SELECT m.user_id, m.listening, m.muted_by_peer, coalesce(p.status::text, 'available')::text AS presence_status
FROM radio_members m
LEFT JOIN radio_presence p ON p.user_id = m.user_id
WHERE m.conversation_id = $1 AND m.status IN ('active', 'muted');

-- name: ListRadioModerators :many
SELECT user_id FROM radio_members WHERE conversation_id = $1 AND role IN ('owner', 'moderator') AND status IN ('active', 'muted');

-- name: ListRadioPassengerMembers :many
-- Pasajeros dentro de canales, para aplicar una política más restrictiva (FR-017).
SELECT m.conversation_id, m.user_id, m.role
FROM radio_members m
JOIN users u ON u.id = m.user_id AND u.role = 'passenger'
JOIN radio_conversations c ON c.id = m.conversation_id AND c.kind = 'channel' AND c.status <> 'deleted'
WHERE m.status IN ('active', 'muted', 'pending');

-- name: ListRadioConversationsOf :many
-- Conversaciones activas de un usuario, para avisar su presencia a sus contactos y canales.
SELECT DISTINCT o.user_id
FROM radio_members m
JOIN radio_members o ON o.conversation_id = m.conversation_id AND o.user_id <> m.user_id AND o.status IN ('active', 'muted')
JOIN radio_conversations c ON c.id = m.conversation_id AND c.status = 'active'
WHERE m.user_id = $1 AND m.status IN ('active', 'muted');

-- Invitaciones -------------------------------------------------------------------------------

-- name: InsertRadioInvite :one
INSERT INTO radio_invites (id, code, inviter_id, conversation_id, contact_of, phone_e164, invitee_kind, role,
                           bulk_id, line, invitee_name, channel_name, status, error, created_at, expires_at)
VALUES ($1, $2, sqlc.narg(inviter_id), sqlc.narg(conversation_id), sqlc.narg(contact_of), sqlc.narg(phone_e164), $3,
        sqlc.narg(role), sqlc.narg(bulk_id), sqlc.narg(line), sqlc.narg(invitee_name), sqlc.narg(channel_name),
        $4, sqlc.narg(error), $5, $6)
RETURNING *;

-- name: GetRadioInviteByCode :one
SELECT i.*, coalesce(u.display_name, 'Kyq')::text AS inviter_name, c.name AS conversation_name
FROM radio_invites i
LEFT JOIN users u ON u.id = i.inviter_id
LEFT JOIN radio_conversations c ON c.id = i.conversation_id
WHERE i.code = $1;

-- name: LockRadioInvite :one
SELECT * FROM radio_invites WHERE id = $1 FOR UPDATE;

-- name: SetRadioInviteStatus :exec
UPDATE radio_invites
SET status = $2, accepted_by = coalesce(sqlc.narg(accepted_by), accepted_by), error = sqlc.narg(error),
    sent_at = coalesce(sqlc.narg(sent_at), sent_at)
WHERE id = $1;

-- name: ListPendingRadioInvitesForPhone :many
-- Invitaciones con ese teléfono que se aplican solas al verificar el OTP (R9).
SELECT * FROM radio_invites
WHERE phone_e164 = $1 AND status IN ('pending', 'sent') AND expires_at > $2
ORDER BY created_at
FOR UPDATE;

-- name: ExpireRadioInvites :execrows
UPDATE radio_invites SET status = 'expired'
WHERE status IN ('pending', 'sent', 'failed') AND expires_at <= $1;

-- Turno --------------------------------------------------------------------------------------

-- name: TakeRadioFloor :one
-- Un turno por conversación (FR-006). La fila solo se borra cuando LiveKit confirma que el
-- permiso de publicar quedó retirado (fail-closed, como 001).
INSERT INTO radio_floors (conversation_id, holder_id, message_id, granted_at, expires_at)
VALUES ($1, $2, $3, $4, $5)
ON CONFLICT (conversation_id) DO NOTHING
RETURNING *;

-- name: GetRadioFloor :one
SELECT f.*, u.display_name AS holder_name FROM radio_floors f
JOIN users u ON u.id = f.holder_id
WHERE f.conversation_id = $1;

-- name: ReleaseRadioFloor :one
DELETE FROM radio_floors WHERE conversation_id = $1 AND holder_id = $2 RETURNING *;

-- name: SetRadioFloorAudio :execrows
UPDATE radio_floors SET last_audio_at = $3 WHERE conversation_id = $1 AND holder_id = $2;

-- name: ListDueRadioFloors :many
-- Turnos vencidos (60 s) o concedidos sin audio en 3 s (edge cases): se retiran en el barrido.
SELECT f.conversation_id, f.holder_id, f.message_id, c.room_name
FROM radio_floors f
JOIN radio_conversations c ON c.id = f.conversation_id
WHERE f.expires_at <= sqlc.arg(now)::timestamptz
   OR (f.last_audio_at IS NULL AND f.granted_at <= sqlc.arg(silent_before)::timestamptz);

-- Mensajes -----------------------------------------------------------------------------------

-- name: InsertRadioMessage :one
INSERT INTO radio_messages (id, conversation_id, author_id, kind, status, body, lat, lng, object_key,
                            sos_alert_id, expires_at, created_at)
VALUES ($1, $2, sqlc.narg(author_id), $3, $4, sqlc.narg(body), sqlc.narg(lat), sqlc.narg(lng), sqlc.narg(object_key),
        sqlc.narg(sos_alert_id), $5, $6)
RETURNING *;

-- name: GetRadioMessage :one
SELECT * FROM radio_messages WHERE id = $1;

-- name: AttachRadioEgress :one
-- egress_started (R3): la grabación de la pista corresponde al mensaje en curso del autor.
UPDATE radio_messages SET egress_id = sqlc.arg(egress_id)
WHERE id = (
    SELECT rm.id FROM radio_messages rm
    WHERE rm.conversation_id = sqlc.arg(conversation_id) AND rm.kind = 'voice' AND rm.status = 'recording'
      AND rm.egress_id IS NULL AND (sqlc.narg(author_id)::uuid IS NULL OR rm.author_id = sqlc.narg(author_id)::uuid)
    ORDER BY rm.created_at
    LIMIT 1
)
RETURNING *;

-- name: GetRadioMessageByEgress :one
SELECT * FROM radio_messages WHERE egress_id = $1;

-- name: CompleteRadioMessage :one
UPDATE radio_messages
SET status = 'ready', object_key = $2, duration_ms = $3, size_bytes = $4
WHERE id = $1 AND status = 'recording'
RETURNING *;

-- name: DiscardRadioMessage :one
-- Devuelve el objeto que tenía, para borrarlo.
UPDATE radio_messages rm SET status = 'discarded', object_key = NULL
FROM (SELECT o.id, o.object_key FROM radio_messages o WHERE o.id = $1 FOR UPDATE) old
WHERE rm.id = old.id AND rm.status = 'recording'
RETURNING old.object_key;

-- name: DeleteRadioMessage :one
-- Borrado por moderación o cuenta eliminada; devuelve el objeto que tenía.
UPDATE radio_messages rm SET status = 'deleted', body = NULL, lat = NULL, lng = NULL, object_key = NULL
FROM (SELECT o.id, o.object_key FROM radio_messages o WHERE o.id = $1 FOR UPDATE) old
WHERE rm.id = old.id AND rm.status <> 'deleted'
RETURNING rm.id, rm.conversation_id, old.object_key;

-- name: ListStaleRecordingRadioMessages :many
-- Mensajes de voz que nunca recibieron su archivo (el emisor se cortó antes de publicar).
SELECT id, object_key FROM radio_messages
WHERE status = 'recording' AND created_at < $1;

-- name: ListRadioMessages :many
-- Historial hacia atrás (FR-010, FR-011); solo desde que el usuario entró.
SELECT rm.*, coalesce(u.display_name, 'Usuario eliminado')::text AS author_name,
       (rr.heard_at IS NOT NULL OR rm.author_id = sqlc.arg(user_id)::uuid)::boolean AS heard,
       (rr.saved_at IS NOT NULL)::boolean AS saved
FROM radio_messages rm
LEFT JOIN users u ON u.id = rm.author_id
LEFT JOIN radio_receipts rr ON rr.message_id = rm.id AND rr.user_id = sqlc.arg(user_id)::uuid
WHERE rm.conversation_id = sqlc.arg(conversation_id)
  AND rm.status = 'ready'
  AND rm.created_at >= sqlc.arg(since)::timestamptz
  -- Vencido: solo lo sigue viendo quien lo guardó (FR-012).
  AND (rm.expires_at > sqlc.arg(now)::timestamptz OR rr.saved_at IS NOT NULL)
  AND (sqlc.narg(before)::uuid IS NULL OR (rm.created_at, rm.id) < (
        SELECT b.created_at, b.id FROM radio_messages b WHERE b.id = sqlc.narg(before)::uuid))
ORDER BY rm.created_at DESC, rm.id DESC
LIMIT sqlc.arg(max_rows);

-- name: GetRadioMessageView :one
SELECT rm.*, coalesce(u.display_name, 'Usuario eliminado')::text AS author_name
FROM radio_messages rm
LEFT JOIN users u ON u.id = rm.author_id
WHERE rm.id = $1;

-- name: CountRadioRecentMessages :one
-- Límite de mensajes por hora o de alertas cada 10 minutos (FR-022, US3-7).
SELECT count(*)::int FROM radio_messages
WHERE conversation_id = $1 AND author_id = $2 AND kind::text = ANY(sqlc.arg(kinds)::text[])
  AND created_at > $3 AND status <> 'discarded';

-- name: UpsertRadioHeard :exec
INSERT INTO radio_receipts (message_id, user_id, heard_at) VALUES ($1, $2, $3)
ON CONFLICT (message_id, user_id) DO UPDATE SET heard_at = coalesce(radio_receipts.heard_at, EXCLUDED.heard_at);

-- name: SaveRadioReceipt :exec
INSERT INTO radio_receipts (message_id, user_id, heard_at, saved_at, saved_key) VALUES ($1, $2, $3, $3, $4)
ON CONFLICT (message_id, user_id) DO UPDATE
SET saved_at = EXCLUDED.saved_at, saved_key = EXCLUDED.saved_key,
    heard_at = coalesce(radio_receipts.heard_at, EXCLUDED.heard_at);

-- name: UnsaveRadioReceipt :one
-- Devuelve la copia que tenía, para borrarla.
UPDATE radio_receipts rr SET saved_at = NULL, saved_key = NULL
FROM (SELECT o.message_id, o.user_id, o.saved_key FROM radio_receipts o WHERE o.message_id = $1 AND o.user_id = $2 FOR UPDATE) old
WHERE rr.message_id = old.message_id AND rr.user_id = old.user_id AND rr.saved_at IS NOT NULL
RETURNING old.saved_key;

-- name: GetRadioReceipt :one
SELECT * FROM radio_receipts WHERE message_id = $1 AND user_id = $2;

-- name: CountRadioSaved :one
SELECT count(*)::int FROM radio_receipts WHERE user_id = $1 AND saved_at IS NOT NULL;

-- Retención ----------------------------------------------------------------------------------

-- name: ListExpiredRadioMessages :many
-- Vencidos según la retención vigente (FR-012): el plazo se cuenta desde created_at con la
-- retención actual, sin borrar antes de lo anunciado (expires_at). guarded indica que alguien
-- lo guardó: entonces solo se borra el audio original y el mensaje sigue para quien lo guardó.
SELECT rm.id, rm.object_key,
       EXISTS (SELECT 1 FROM radio_receipts rr WHERE rr.message_id = rm.id AND rr.saved_at IS NOT NULL) AS guarded
FROM radio_messages rm
WHERE rm.status IN ('ready', 'recording', 'discarded')
  AND rm.expires_at <= sqlc.arg(now)::timestamptz
  AND rm.created_at + make_interval(days => sqlc.arg(retention_days)::int) <= sqlc.arg(now)::timestamptz
  AND (rm.object_key IS NOT NULL OR NOT EXISTS (
        SELECT 1 FROM radio_receipts rr WHERE rr.message_id = rm.id AND rr.saved_at IS NOT NULL))
ORDER BY rm.expires_at
LIMIT sqlc.arg(max_rows);

-- name: DropRadioMessageObject :exec
UPDATE radio_messages SET object_key = NULL WHERE id = $1;

-- name: ExtendRadioExpiry :execrows
-- Una retención más larga alarga los mensajes no vencidos.
UPDATE radio_messages SET expires_at = created_at + make_interval(days => sqlc.arg(retention_days)::int)
WHERE status IN ('ready', 'recording') AND expires_at > sqlc.arg(now)::timestamptz
  AND expires_at < created_at + make_interval(days => sqlc.arg(retention_days)::int);

-- name: ListExpiredRadioSaved :many
-- Guardados de más de un año (FR-012).
SELECT message_id, user_id, saved_key FROM radio_receipts
WHERE saved_at IS NOT NULL AND saved_at <= $1
LIMIT $2;

-- name: ExpireRadioSaved :exec
UPDATE radio_receipts SET saved_at = NULL, saved_key = NULL WHERE message_id = $1 AND user_id = $2;

-- name: PurgeRadioMessage :exec
UPDATE radio_messages SET status = 'deleted', body = NULL, lat = NULL, lng = NULL, object_key = NULL WHERE id = $1;

-- name: ListRadioSavedKeysOf :many
SELECT saved_key FROM radio_receipts WHERE message_id = $1 AND saved_key IS NOT NULL;

-- name: ListRadioConversationObjects :many
-- Objetos de una conversación borrada: audios, fotos y copias guardadas (US4-7).
SELECT rm.object_key AS key, false::boolean AS saved FROM radio_messages rm
WHERE rm.conversation_id = $1 AND rm.object_key IS NOT NULL
UNION ALL
SELECT rr.saved_key AS key, true::boolean AS saved FROM radio_receipts rr
JOIN radio_messages rm ON rm.id = rr.message_id
WHERE rm.conversation_id = $1 AND rr.saved_key IS NOT NULL;

-- name: DeleteRadioConversationMessages :exec
DELETE FROM radio_messages WHERE conversation_id = $1;

-- name: IsRadioOptedOut :one
SELECT EXISTS (SELECT 1 FROM radio_sms_optouts WHERE phone_e164 = $1) AS opted_out;

-- name: InsertRadioOptOut :exec
INSERT INTO radio_sms_optouts (phone_e164, at) VALUES ($1, $2) ON CONFLICT DO NOTHING;

-- name: GetRadioHeir :one
-- Quien hereda un canal cuyo dueño sale: el moderador más antiguo o, si no hay, el miembro más
-- antiguo (edge cases).
SELECT user_id FROM radio_members
WHERE conversation_id = $1 AND user_id <> $2 AND status IN ('active', 'muted') AND role IN ('moderator', 'member')
ORDER BY CASE role WHEN 'moderator' THEN 0 ELSE 1 END, joined_at
LIMIT 1;

-- Cargas masivas (FR-033, FR-034) --------------------------------------------------------------

-- name: InsertRadioBulkUpload :one
INSERT INTO radio_bulk_uploads (id, admin_id, file_name, rows_total, rows_valid, rows_invalid, status, created_at)
VALUES ($1, $2, $3, $4, $5, $6, 'validated', $7)
RETURNING *;

-- name: GetRadioBulkUpload :one
SELECT * FROM radio_bulk_uploads WHERE id = $1;

-- name: ListRadioBulkUploads :many
SELECT * FROM radio_bulk_uploads ORDER BY created_at DESC LIMIT 100;

-- name: SetRadioBulkUploadStatus :execrows
-- Solo desde los estados permitidos: no se confirma dos veces a la vez.
UPDATE radio_bulk_uploads
SET status = sqlc.arg(status), confirmed_at = coalesce(confirmed_at, sqlc.narg(confirmed_at))
WHERE id = sqlc.arg(id) AND status = ANY(sqlc.arg(from_statuses)::text[]);

-- name: ListRadioBulkRows :many
SELECT * FROM radio_invites WHERE bulk_id = $1 ORDER BY line;

-- name: CountRadioBulkRows :many
-- Totales por estado; las pendientes o enviadas vencidas cuentan como vencidas.
SELECT CASE WHEN status IN ('pending', 'sent') AND expires_at <= sqlc.arg(now)::timestamptz THEN 'expired'
            ELSE status::text END::text AS status,
       count(*)::int AS n
FROM radio_invites
WHERE bulk_id = sqlc.arg(bulk_id)
GROUP BY 1;

-- name: SetRadioBulkInviteChannel :exec
UPDATE radio_invites SET conversation_id = $2, inviter_id = sqlc.narg(inviter_id) WHERE id = $1;

-- name: GetRadioActiveChannelByName :one
SELECT * FROM radio_conversations
WHERE kind = 'channel' AND status <> 'deleted' AND lower(name) = lower(sqlc.arg(name)::text);

-- name: GetRadioUserByPhone :one
SELECT id, role, display_name FROM users WHERE phone_e164 = $1;

-- name: GetRadioChannelOwner :one
SELECT u.id, u.display_name
FROM radio_members m JOIN users u ON u.id = m.user_id
WHERE m.conversation_id = $1 AND m.role = 'owner' AND m.status = 'active';

-- Costo de almacenamiento (FR-040) ---------------------------------------------------------------

-- name: SumRadioStorageBytes :one
-- Bytes de Radio guardados en los últimos días: base del costo estimado por retención.
SELECT coalesce(sum(radio_storage_bytes), 0)::bigint AS bytes
FROM driver_usage_daily
WHERE day >= sqlc.arg(since)::date;

-- name: GetCostRateAt :one
SELECT unit_cost_micro FROM cost_rates
WHERE concept = sqlc.arg(concept)::cost_concept AND currency = sqlc.arg(currency) AND effective_from <= sqlc.arg(day)::date
ORDER BY effective_from DESC
LIMIT 1;

-- name: ListRadioUsers :many
-- Quienes usaron Radio: reciben `radio.settings` cuando el panel cambia la configuración.
SELECT user_id FROM radio_presence;
