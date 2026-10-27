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
SELECT driver_id, doc_type, expires_at, (approved_by IS NOT NULL)::boolean AS approved
FROM driver_documents
WHERE driver_id = ANY (sqlc.arg(driver_ids)::uuid[])
ORDER BY driver_id, doc_type;

-- name: UpsertSubscription :exec
INSERT INTO subscriptions (driver_id, paid_until, updated_by)
VALUES ($1, $2, $3)
ON CONFLICT (driver_id) DO UPDATE
SET paid_until = EXCLUDED.paid_until,
    updated_by = EXCLUDED.updated_by,
    updated_at = now();

-- name: UpsertDriverDocument :exec
INSERT INTO driver_documents (id, driver_id, doc_type, expires_at, approved_by, approved_at)
VALUES ($1, $2, $3, $4, $5, $6)
ON CONFLICT (driver_id, doc_type) DO UPDATE
SET expires_at  = EXCLUDED.expires_at,
    approved_by = EXCLUDED.approved_by,
    approved_at = EXCLUDED.approved_at;
