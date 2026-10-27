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
INSERT INTO affiliations (passenger_id, driver_id, source)
VALUES ($1, $2, 'qr_scan');

-- name: ReactivateAffiliation :exec
UPDATE affiliations
SET removed_at = NULL, created_at = now()
WHERE passenger_id = $1 AND driver_id = $2;

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
SELECT d.user_id AS driver_id, u.display_name, d.vehicle_description, d.presence, d.busy_until_estimate
FROM affiliations a
JOIN drivers d ON d.user_id = a.driver_id
JOIN users u ON u.id = d.user_id
WHERE a.passenger_id = $1 AND a.removed_at IS NULL
ORDER BY u.display_name, d.user_id;

-- name: ListDriverClients :many
SELECT u.id AS passenger_id, u.display_name, a.created_at AS affiliated_at
FROM affiliations a
JOIN users u ON u.id = a.passenger_id
WHERE a.driver_id = $1 AND a.removed_at IS NULL
ORDER BY a.created_at DESC, u.id;
