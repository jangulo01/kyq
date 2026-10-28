-- name: CreateDriver :exec
INSERT INTO drivers (user_id, qr_token, vehicle_plate, vehicle_description)
VALUES ($1, $2, $3, $4);

-- name: DriverExists :one
SELECT EXISTS (SELECT 1 FROM drivers WHERE user_id = $1);

-- name: ListDriversForAdmin :many
SELECT u.id,
       u.phone_e164,
       u.display_name,
       d.qr_token,
       d.vehicle_plate,
       d.vehicle_description,
       d.presence,
       s.paid_until
FROM drivers d
JOIN users u ON u.id = d.user_id
LEFT JOIN subscriptions s ON s.driver_id = d.user_id
ORDER BY u.display_name, u.id;

-- name: ListDocumentsForDrivers :many
-- Documentos vigentes para el gate: el aprobado de cada tipo (uno como máximo).
SELECT driver_id, doc_type, expires_at, exempt_until
FROM driver_documents
WHERE driver_id = ANY (sqlc.arg(driver_ids)::uuid[]) AND status = 'approved'
ORDER BY driver_id, doc_type;

-- name: UpsertSubscription :exec
INSERT INTO subscriptions (driver_id, paid_until, updated_by)
VALUES ($1, $2, $3)
ON CONFLICT (driver_id) DO UPDATE
SET paid_until = EXCLUDED.paid_until,
    updated_by = EXCLUDED.updated_by,
    updated_at = now();

-- name: GetDispatchSettings :one
-- 008: preferencias de despacho del conductor y su token para el enlace de afiliación.
SELECT accepts_zone_pool, preferential_discount_pct, qr_token FROM drivers WHERE user_id = $1;

-- name: SetDispatchSettings :one
UPDATE drivers
SET accepts_zone_pool = sqlc.arg(accepts_zone_pool), preferential_discount_pct = sqlc.arg(preferential_discount_pct)
WHERE user_id = sqlc.arg(user_id)
RETURNING accepts_zone_pool, preferential_discount_pct, qr_token;
