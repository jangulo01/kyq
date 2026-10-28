-- name: GetChosenDriverByQRToken :one
SELECT d.user_id AS driver_id, u.display_name, d.vehicle_description, d.presence, d.busy_until_estimate
FROM drivers d
JOIN users u ON u.id = d.user_id
WHERE d.qr_token = $1;

-- name: GetAffiliation :one
SELECT passenger_id, driver_id, created_at, removed_at
FROM affiliations
WHERE passenger_id = $1 AND driver_id = $2;

-- name: InsertAffiliation :exec
-- 008: sin origen (llamadas anteriores) cuenta como QR.
INSERT INTO affiliations (passenger_id, driver_id, source)
VALUES ($1, $2, coalesce(nullif(sqlc.arg(source)::text, ''), 'qr_scan')::affiliation_source);

-- name: ReactivateAffiliation :exec
-- Volver a afiliarse cuenta como afiliación nueva (007) con el origen de esta vez (008).
UPDATE affiliations
SET removed_at = NULL, created_at = now(),
    source = coalesce(nullif(sqlc.arg(source)::text, ''), 'qr_scan')::affiliation_source
WHERE passenger_id = $1 AND driver_id = $2;

-- name: GetDriverByID :one
-- 008: conductor de un viaje completado, para afiliarse después del viaje.
SELECT d.user_id AS driver_id, u.display_name, d.vehicle_description, d.presence, d.busy_until_estimate, d.qr_token
FROM drivers d
JOIN users u ON u.id = d.user_id
WHERE d.user_id = $1;

-- name: GetPublicDriverByQRToken :one
-- 008: página pública del enlace: solo el nombre y si puede recibir clientes (no suspendido).
SELECT d.user_id AS driver_id, u.display_name, (u.suspended_at IS NOT NULL)::boolean AS suspended
FROM drivers d
JOIN users u ON u.id = d.user_id
WHERE d.qr_token = $1;

-- name: RemoveAffiliation :execrows
UPDATE affiliations
SET removed_at = now()
WHERE passenger_id = $1 AND driver_id = $2 AND removed_at IS NULL;

-- name: IsAffiliated :one
SELECT EXISTS (
    SELECT 1 FROM affiliations
    WHERE passenger_id = $1 AND driver_id = $2 AND removed_at IS NULL
);

-- name: ListChosenDrivers :many
-- 006: con la cooperativa activa del conductor, si tiene (selector de despacho).
SELECT d.user_id AS driver_id, u.display_name, d.vehicle_description, d.presence, d.busy_until_estimate,
       c.id AS cooperative_id, c.name AS cooperative_name
FROM affiliations a
JOIN drivers d ON d.user_id = a.driver_id
JOIN users u ON u.id = d.user_id
LEFT JOIN cooperative_memberships m ON m.driver_id = d.user_id AND m.status = 'active'
LEFT JOIN cooperatives c ON c.id = m.cooperative_id AND c.status = 'active'
WHERE a.passenger_id = $1 AND a.removed_at IS NULL
ORDER BY u.display_name, d.user_id;

-- name: ListDriverClients :many
SELECT u.id AS passenger_id, u.display_name, a.created_at AS affiliated_at, a.source::text AS source
FROM affiliations a
JOIN users u ON u.id = a.passenger_id
WHERE a.driver_id = $1 AND a.removed_at IS NULL
ORDER BY a.created_at DESC, u.id;

-- name: GetCompletedTripDriver :one
-- 008: conductor de un viaje COMPLETED del pasajero (afiliación después del viaje).
SELECT driver_id FROM trips WHERE id = $1 AND passenger_id = $2 AND status = 'COMPLETED';
