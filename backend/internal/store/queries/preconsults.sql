-- Pre-consulta de voz (RN-KYQ-010, specs/005-ptt-extras).

-- name: GetPreconsultTarget :one
-- Afiliación activa del pasajero con el conductor y lo que decide si puede consultarle.
SELECT a.preconsults_blocked, d.accepts_preconsults, d.presence
FROM affiliations a
JOIN drivers d ON d.user_id = a.driver_id
WHERE a.passenger_id = $1 AND a.driver_id = $2 AND a.removed_at IS NULL;

-- name: GetOpenPreconsultByPassenger :one
SELECT id, driver_id FROM ptt_preconsults WHERE passenger_id = $1 AND closed_at IS NULL;

-- name: CountRecentPreconsults :one
SELECT
    (count(*) FILTER (WHERE driver_id = sqlc.arg(driver_id) AND opened_at > sqlc.arg(hour_ago)))::int AS last_hour_with_driver,
    count(*)::int AS last_day
FROM ptt_preconsults
WHERE passenger_id = sqlc.arg(passenger_id) AND opened_at > sqlc.arg(day_ago);

-- name: InsertPreconsult :exec
INSERT INTO ptt_preconsults (id, passenger_id, driver_id, room_name, opened_at, join_deadline, closes_at)
VALUES ($1, $2, $3, $4, $5, $6, $7);

-- name: GetPreconsult :one
SELECT p.*, pu.display_name AS passenger_name, du.display_name AS driver_name
FROM ptt_preconsults p
JOIN users pu ON pu.id = p.passenger_id
JOIN users du ON du.id = p.driver_id
WHERE p.id = $1;

-- name: ListDriverPreconsults :many
SELECT p.*, pu.display_name AS passenger_name, du.display_name AS driver_name
FROM ptt_preconsults p
JOIN users pu ON pu.id = p.passenger_id
JOIN users du ON du.id = p.driver_id
WHERE p.driver_id = sqlc.arg(driver_id) AND p.opened_at > sqlc.arg(since)
ORDER BY p.opened_at DESC, p.id
LIMIT 50;

-- name: MarkPreconsultJoined :execrows
UPDATE ptt_preconsults SET joined_at = sqlc.arg(now)
WHERE id = sqlc.arg(id) AND joined_at IS NULL AND closed_at IS NULL;

-- name: MarkPreconsultAnswered :exec
UPDATE ptt_preconsults SET answered_at = sqlc.arg(now) WHERE id = sqlc.arg(id) AND answered_at IS NULL;

-- name: EndPreconsult :execrows
-- Adelanta el cierre a ahora; el barrido borra la sala y avisa. Conserva el primer motivo.
UPDATE ptt_preconsults
SET closes_at = LEAST(closes_at, sqlc.arg(now)), close_reason = COALESCE(close_reason, sqlc.arg(reason)::text)
WHERE id = sqlc.arg(id) AND closed_at IS NULL;

-- name: EndDriverPreconsults :exec
UPDATE ptt_preconsults
SET closes_at = LEAST(closes_at, sqlc.arg(now)), close_reason = COALESCE(close_reason, 'disabled')
WHERE driver_id = sqlc.arg(driver_id) AND closed_at IS NULL;

-- name: EndPairPreconsults :exec
UPDATE ptt_preconsults
SET closes_at = LEAST(closes_at, sqlc.arg(now)), close_reason = COALESCE(close_reason, 'disabled')
WHERE driver_id = sqlc.arg(driver_id) AND passenger_id = sqlc.arg(passenger_id) AND closed_at IS NULL;

-- name: TakePreconsultFloor :one
-- Mismo turno exclusivo que el canal del viaje (FR-017 de 001), con su propia duración.
UPDATE ptt_preconsults
SET floor_holder_id = sqlc.arg(user_id), floor_expires_at = sqlc.arg(expires_at)
WHERE id = sqlc.arg(id)
  AND closed_at IS NULL
  AND closes_at > sqlc.arg(now)
  AND (floor_holder_id IS NULL OR floor_holder_id = sqlc.arg(user_id))
RETURNING floor_expires_at;

-- name: ReleasePreconsultFloor :exec
UPDATE ptt_preconsults SET floor_holder_id = NULL, floor_expires_at = NULL
WHERE id = $1 AND floor_holder_id = $2;

-- name: ListExpiredPreconsultFloors :many
SELECT id, room_name, floor_holder_id
FROM ptt_preconsults
WHERE closed_at IS NULL AND floor_holder_id IS NOT NULL AND floor_expires_at < $1
LIMIT 100;

-- name: ClearExpiredPreconsultFloor :execrows
UPDATE ptt_preconsults SET floor_holder_id = NULL, floor_expires_at = NULL
WHERE id = sqlc.arg(id) AND floor_holder_id = sqlc.arg(holder_id) AND floor_expires_at < sqlc.arg(now);

-- name: ListDuePreconsults :many
-- Consultas que hay que cerrar y su motivo: el ya fijado (terminar, desactivar) o el que toca.
SELECT p.id, p.room_name, p.passenger_id, p.driver_id,
       COALESCE(p.close_reason, CASE
           WHEN p.joined_at IS NULL AND p.join_deadline <= sqlc.arg(now) THEN 'missed'
           WHEN d.presence <> 'free' THEN 'driver_unavailable'
           ELSE 'expired'
       END)::text AS reason
FROM ptt_preconsults p
JOIN drivers d ON d.user_id = p.driver_id
WHERE p.closed_at IS NULL
  AND (p.closes_at <= sqlc.arg(now)
       OR (p.joined_at IS NULL AND p.join_deadline <= sqlc.arg(now))
       OR d.presence <> 'free')
ORDER BY p.opened_at
LIMIT 100;

-- name: MarkPreconsultClosed :execrows
UPDATE ptt_preconsults
SET closed_at = sqlc.arg(now), close_reason = sqlc.arg(reason)::text, floor_holder_id = NULL, floor_expires_at = NULL
WHERE id = sqlc.arg(id) AND closed_at IS NULL;

-- name: PurgePreconsults :execrows
DELETE FROM ptt_preconsults WHERE closed_at < $1;

-- name: GetPreconsultDriver :one
SELECT driver_id FROM ptt_preconsults WHERE id = $1;

-- name: GetAcceptsPreconsults :one
SELECT accepts_preconsults FROM drivers WHERE user_id = $1;

-- name: SetAcceptsPreconsults :execrows
UPDATE drivers SET accepts_preconsults = $2 WHERE user_id = $1;

-- name: ListBlockedPreconsultPassengers :many
SELECT passenger_id FROM affiliations
WHERE driver_id = $1 AND removed_at IS NULL AND preconsults_blocked
ORDER BY passenger_id;

-- name: SetPreconsultsBlocked :execrows
UPDATE affiliations SET preconsults_blocked = sqlc.arg(blocked)
WHERE driver_id = sqlc.arg(driver_id) AND passenger_id = sqlc.arg(passenger_id) AND removed_at IS NULL;

-- name: ListPreconsultDrivers :many
-- Conductores Elegidos del pasajero que aceptan sus consultas (sin mirar la presencia).
SELECT a.driver_id
FROM affiliations a
JOIN drivers d ON d.user_id = a.driver_id
WHERE a.passenger_id = $1 AND a.removed_at IS NULL AND NOT a.preconsults_blocked AND d.accepts_preconsults
ORDER BY a.driver_id;
