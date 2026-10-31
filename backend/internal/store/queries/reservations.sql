-- 010: agenda de reservas (research R1).

-- name: InsertReservation :exec
INSERT INTO reservations (id, passenger_id, driver_id, pickup_lat, pickup_lng, dropoff_lat, dropoff_lng,
                          pickup_label, dropoff_label, scheduled_at, distance_m, duration_s, currency,
                          fare_minor, list_fare_minor, preferential_discount_pct, status, created_at, updated_at)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, 'pending', $17, $17);

-- name: CountActiveReservationsForPassenger :one
SELECT count(*) FROM reservations
WHERE passenger_id = $1 AND status IN ('pending', 'confirmed') AND scheduled_at > sqlc.arg(now);

-- name: LockReservation :one
SELECT * FROM reservations WHERE id = $1 FOR UPDATE;

-- name: GetReservationView :one
SELECT sqlc.embed(r), pu.display_name AS passenger_name, du.display_name AS driver_name
FROM reservations r
JOIN users pu ON pu.id = r.passenger_id
JOIN users du ON du.id = r.driver_id
WHERE r.id = $1;

-- name: UpdateReservationStatus :exec
UPDATE reservations SET status = $2, cancelled_by = $3, trip_id = $4, reminded_at = $5, updated_at = $6
WHERE id = $1;

-- name: ListPassengerReservations :many
-- Futuras y las de las últimas 24 horas, para ver qué pasó.
SELECT sqlc.embed(r), pu.display_name AS passenger_name, du.display_name AS driver_name
FROM reservations r
JOIN users pu ON pu.id = r.passenger_id
JOIN users du ON du.id = r.driver_id
WHERE r.passenger_id = $1 AND r.scheduled_at >= sqlc.arg(since)
ORDER BY r.scheduled_at
LIMIT 50;

-- name: ListDriverAgenda :many
SELECT sqlc.embed(r), pu.display_name AS passenger_name, du.display_name AS driver_name
FROM reservations r
JOIN users pu ON pu.id = r.passenger_id
JOIN users du ON du.id = r.driver_id
WHERE r.driver_id = $1 AND r.scheduled_at >= sqlc.arg(since)
ORDER BY r.scheduled_at
LIMIT 100;

-- name: ListDueReservations :many
-- Reservas que el barrido debe atender ahora: vencer, recordar o cumplir.
SELECT id FROM reservations
WHERE (status = 'pending' AND scheduled_at <= sqlc.arg(expire_before))
   OR (status = 'confirmed' AND reminded_at IS NULL AND scheduled_at <= sqlc.arg(remind_before))
   OR (status = 'confirmed' AND scheduled_at <= sqlc.arg(now))
ORDER BY scheduled_at
LIMIT 100;

-- name: LockReservationSkipLocked :one
SELECT * FROM reservations WHERE id = $1 FOR UPDATE SKIP LOCKED;

-- name: CancelReservationsForPair :many
-- Al quitar la afiliación se cancelan sus reservas abiertas (edge case).
UPDATE reservations SET status = 'cancelled', cancelled_by = sqlc.arg(passenger_id)::uuid, updated_at = sqlc.arg(now)
WHERE passenger_id = sqlc.arg(passenger_id) AND driver_id = sqlc.arg(driver_id) AND status IN ('pending', 'confirmed')
RETURNING id;

-- name: ListUpcomingReservationsForPair :many
SELECT * FROM reservations
WHERE passenger_id = $1 AND driver_id = $2 AND status IN ('pending', 'confirmed') AND scheduled_at > sqlc.arg(now)
ORDER BY scheduled_at
LIMIT 10;

-- 010: notas del conductor (FR-008).

-- name: GetClientNote :one
SELECT body, updated_at FROM client_notes WHERE driver_id = $1 AND passenger_id = $2;

-- name: UpsertClientNote :exec
INSERT INTO client_notes (driver_id, passenger_id, body, updated_at) VALUES ($1, $2, $3, $4)
ON CONFLICT (driver_id, passenger_id) DO UPDATE SET body = EXCLUDED.body, updated_at = EXCLUDED.updated_at;

-- name: DeleteClientNote :exec
DELETE FROM client_notes WHERE driver_id = $1 AND passenger_id = $2;

-- name: GetClientSummary :one
-- Ficha de un cliente activo del conductor (FR-007).
SELECT u.display_name, a.created_at AS affiliated_at, a.source::text AS source,
       (SELECT count(*) FROM trips t WHERE t.passenger_id = a.passenger_id AND t.driver_id = a.driver_id AND t.status = 'COMPLETED')::bigint AS trips_together,
       -- 0 sin viajes; segundos Unix del último completado.
       coalesce(extract(epoch FROM (SELECT max(t.completed_at) FROM trips t WHERE t.passenger_id = a.passenger_id AND t.driver_id = a.driver_id AND t.status = 'COMPLETED')), 0)::bigint AS last_trip_unix
FROM affiliations a
JOIN users u ON u.id = a.passenger_id
WHERE a.driver_id = $1 AND a.passenger_id = $2 AND a.removed_at IS NULL;

-- 010: llegada automática (FR-010).

-- name: SetNearPickupSince :exec
UPDATE trips SET near_pickup_since = $2 WHERE id = $1;

-- name: GetArrivalCheck :one
SELECT id, driver_id, status, pickup_lat, pickup_lng, near_pickup_since FROM trips WHERE id = $1;
