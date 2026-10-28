-- 003: SOS, consola de emergencias, viaje compartido, contactos y PIN.

-- name: GetTripForSOS :one
SELECT t.id, t.passenger_id, t.driver_id, t.status, t.completed_at, t.cancelled_at
FROM trips t
WHERE t.id = $1;

-- name: InsertSOSAlert :one
-- Si la persona ya tiene una alerta abierta en el viaje no se crea otra (índice parcial).
INSERT INTO sos_alerts (id, trip_id, raised_by, raised_role, room_name, created_at)
VALUES ($1, $2, $3, $4, $5, $6)
ON CONFLICT (trip_id, raised_by) WHERE status IN ('open', 'claimed') DO NOTHING
RETURNING *;

-- name: GetOpenSOSAlertFor :one
SELECT * FROM sos_alerts
WHERE trip_id = $1 AND raised_by = $2 AND status IN ('open', 'claimed');

-- name: GetActiveSOSAlertForUser :one
SELECT * FROM sos_alerts
WHERE raised_by = $1 AND status IN ('open', 'claimed')
ORDER BY created_at DESC
LIMIT 1;

-- name: GetSOSAlert :one
SELECT * FROM sos_alerts WHERE id = $1;

-- name: GetSOSAlertForUpdate :one
SELECT * FROM sos_alerts WHERE id = $1 FOR UPDATE;

-- name: SetSOSEgress :exec
UPDATE sos_alerts SET egress_id = $2, recording_key = $3
WHERE id = $1 AND voice_closed_at IS NULL;

-- name: ListSOSAlertsWithoutEgress :many
SELECT id, room_name FROM sos_alerts
WHERE status IN ('open', 'claimed') AND egress_id IS NULL
ORDER BY created_at
LIMIT 20;

-- name: InsertSOSLocation :exec
INSERT INTO sos_locations (alert_id, at, lat, lng, accuracy_m)
VALUES ($1, $2, $3, $4, $5)
ON CONFLICT (alert_id, at) DO NOTHING;

-- name: ListSOSLocations :many
SELECT at, lat, lng, accuracy_m FROM sos_locations
WHERE alert_id = $1
ORDER BY at
LIMIT 20000;

-- name: GetLastSOSLocations :many
SELECT DISTINCT ON (alert_id) alert_id, at, lat, lng, accuracy_m
FROM sos_locations
WHERE alert_id = ANY(sqlc.arg(alert_ids)::uuid[])
ORDER BY alert_id, at DESC;

-- name: MarkSOSCancelWithoutPIN :exec
UPDATE sos_alerts SET cancel_without_pin = true WHERE id = $1;

-- name: CancelSOSAlert :execrows
UPDATE sos_alerts
SET status = 'cancelled_by_user', closed_at = sqlc.arg(now)
WHERE id = sqlc.arg(id) AND status IN ('open', 'claimed');

-- name: ClaimSOSAlert :one
-- Toma la alerta si está libre o ya era del operador (reintento: vuelve a conceder la voz).
UPDATE sos_alerts
SET status = 'claimed', claimed_by = sqlc.arg(operator_id),
    claimed_at = CASE WHEN claimed_by = sqlc.arg(operator_id) THEN claimed_at ELSE sqlc.arg(now) END,
    voice_holder_id = sqlc.arg(operator_id)
WHERE id = sqlc.arg(id)
  AND (status = 'open' OR (status = 'claimed' AND claimed_by = sqlc.arg(operator_id)))
  AND (voice_holder_id IS NULL OR voice_holder_id = sqlc.arg(operator_id))
RETURNING *;

-- name: ReleaseSOSAlert :execrows
UPDATE sos_alerts
SET status = 'open', claimed_by = NULL, claimed_at = NULL, voice_holder_id = NULL
WHERE id = $1 AND status = 'claimed' AND claimed_by = $2;

-- name: ClearSOSVoiceHolder :exec
UPDATE sos_alerts SET voice_holder_id = NULL WHERE id = $1 AND voice_holder_id = $2;

-- name: CloseSOSAlert :execrows
UPDATE sos_alerts
SET status = 'closed', outcome = sqlc.arg(outcome), closed_at = sqlc.arg(now)
WHERE id = sqlc.arg(id) AND status = 'claimed' AND claimed_by = sqlc.arg(operator_id);

-- name: ListSOSVoicePending :many
-- Alertas cerradas cuya sala o grabación siguen activas: el barrido las cierra.
SELECT id, room_name, egress_id FROM sos_alerts
WHERE closed_at IS NOT NULL AND voice_closed_at IS NULL
ORDER BY closed_at
LIMIT 100;

-- name: MarkSOSVoiceClosed :exec
UPDATE sos_alerts SET voice_closed_at = $2, voice_holder_id = NULL WHERE id = $1;

-- name: EscalateSOSAlerts :many
-- Alertas sin tomar desde hace más de 60 s; escalated_at garantiza un solo aviso (FR-011).
UPDATE sos_alerts
SET escalated_at = sqlc.arg(now)
WHERE status = 'open' AND escalated_at IS NULL AND created_at <= sqlc.arg(before)
RETURNING id, trip_id, raised_role;

-- name: ListOnDutyOperatorPhones :many
SELECT u.phone_e164 FROM emergency_operators o
JOIN users u ON u.id = o.user_id
WHERE u.role = 'admin' AND o.on_duty
ORDER BY o.granted_at;

-- name: IsEmergencyOperator :one
SELECT EXISTS (
    SELECT 1 FROM emergency_operators o JOIN users u ON u.id = o.user_id
    WHERE o.user_id = $1 AND u.role = 'admin'
);

-- name: GetOperatorDuty :one
SELECT on_duty FROM emergency_operators WHERE user_id = $1;

-- name: SetOperatorDuty :execrows
UPDATE emergency_operators SET on_duty = $2 WHERE user_id = $1;

-- name: GrantEmergencyOperator :exec
INSERT INTO emergency_operators (user_id, on_duty) VALUES ($1, $2)
ON CONFLICT (user_id) DO NOTHING;

-- name: ListOpenSOSAlerts :many
SELECT a.*, u.display_name AS raised_by_name, o.display_name AS claimed_by_name
FROM sos_alerts a
JOIN users u ON u.id = a.raised_by
LEFT JOIN users o ON o.id = a.claimed_by
WHERE a.status IN ('open', 'claimed')
ORDER BY a.created_at
LIMIT 200;

-- name: ListClosedSOSAlerts :many
SELECT a.*, u.display_name AS raised_by_name, o.display_name AS claimed_by_name
FROM sos_alerts a
JOIN users u ON u.id = a.raised_by
LEFT JOIN users o ON o.id = a.claimed_by
WHERE a.status IN ('closed', 'cancelled_by_user')
  AND a.created_at >= sqlc.arg(since)
  AND a.created_at < sqlc.arg(until)
  AND (sqlc.narg(outcome)::sos_outcome IS NULL OR a.outcome = sqlc.narg(outcome)::sos_outcome)
ORDER BY a.created_at DESC
LIMIT 200;

-- name: GetSOSDetail :one
SELECT a.*, u.display_name AS raised_by_name, u.phone_e164 AS raised_by_phone,
       o.display_name AS claimed_by_name,
       t.status AS trip_status, t.pickup_lat, t.pickup_lng, t.dropoff_lat, t.dropoff_lng,
       t.passenger_id, p.display_name AS passenger_name,
       t.driver_id, du.display_name AS driver_name, d.vehicle_plate, d.vehicle_description,
       d.vehicle_brand, d.vehicle_model, d.vehicle_color
FROM sos_alerts a
JOIN users u ON u.id = a.raised_by
LEFT JOIN users o ON o.id = a.claimed_by
JOIN trips t ON t.id = a.trip_id
JOIN users p ON p.id = t.passenger_id
JOIN drivers d ON d.user_id = t.driver_id
JOIN users du ON du.id = t.driver_id
WHERE a.id = $1;

-- name: ListSOSAlertIDsForTrip :many
SELECT id FROM sos_alerts WHERE trip_id = $1 ORDER BY created_at;

-- name: CountSOSAlertsByUser :one
-- Historial de abusos: alertas de la persona y cuántas acabaron como falsa alarma.
SELECT count(*)::int AS total, count(*) FILTER (WHERE outcome = 'false_alarm')::int AS false_alarms
FROM sos_alerts WHERE raised_by = $1;

-- name: GetSOSAlertRoom :one
-- Viaje de la alerta (nulo si se levantó desde Radio sin viaje, 011) y quién la levantó.
SELECT trip_id, raised_by FROM sos_alerts WHERE room_name = $1;

-- name: InsertSOSNote :one
INSERT INTO sos_notes (id, alert_id, operator_id, body, created_at)
VALUES ($1, $2, $3, $4, $5)
RETURNING *;

-- name: ListSOSNotes :many
SELECT n.id, n.body, n.created_at, n.operator_id, u.display_name AS operator_name
FROM sos_notes n
JOIN users u ON u.id = n.operator_id
WHERE n.alert_id = $1
ORDER BY n.created_at, n.id;

-- name: InsertSOSAudit :exec
INSERT INTO sos_audit (operator_id, alert_id, action, created_at)
VALUES ($1, $2, $3, $4);

-- name: ListSOSAudit :many
SELECT operator_id, alert_id, action, created_at FROM sos_audit
WHERE operator_id = $1
ORDER BY id;

-- name: UpsertShareLink :one
-- Un enlace por persona y viaje: compartir otra vez devuelve el mismo.
INSERT INTO share_links (token, trip_id, created_by, created_at)
VALUES ($1, $2, $3, $4)
ON CONFLICT (trip_id, created_by) DO UPDATE SET trip_id = EXCLUDED.trip_id
RETURNING token;

-- name: GetSharedTrip :one
SELECT t.id AS trip_id, t.status, t.completed_at, t.cancelled_at,
       du.display_name AS driver_name, d.vehicle_plate, d.vehicle_description,
       d.vehicle_brand, d.vehicle_model, d.vehicle_color,
       d.last_lat, d.last_lng, d.last_location_at
FROM share_links s
JOIN trips t ON t.id = s.trip_id
JOIN drivers d ON d.user_id = t.driver_id
JOIN users du ON du.id = t.driver_id
WHERE s.token = $1;

-- name: ListEmergencyContacts :many
SELECT position, name, phone_e164 FROM emergency_contacts
WHERE user_id = $1
ORDER BY position;

-- name: DeleteEmergencyContacts :exec
DELETE FROM emergency_contacts WHERE user_id = $1;

-- name: InsertEmergencyContact :exec
INSERT INTO emergency_contacts (user_id, position, name, phone_e164, created_at)
VALUES ($1, $2, $3, $4, $5);

-- name: GetSafetyPin :one
SELECT * FROM safety_pins WHERE user_id = $1;

-- name: GetSafetyPinForUpdate :one
SELECT * FROM safety_pins WHERE user_id = $1 FOR UPDATE;

-- name: UpsertSafetyPin :exec
INSERT INTO safety_pins (user_id, pin_hash, failed_attempts, updated_at)
VALUES ($1, $2, 0, $3)
ON CONFLICT (user_id) DO UPDATE SET pin_hash = EXCLUDED.pin_hash, failed_attempts = 0, updated_at = EXCLUDED.updated_at;

-- name: SetSafetyPinAttempts :exec
UPDATE safety_pins SET failed_attempts = $2 WHERE user_id = $1;
