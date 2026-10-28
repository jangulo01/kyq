-- name: GetDriverForPresence :one
-- suspended (007, FR-016): un conductor suspendido nunca cuenta como libre para recibir viajes.
SELECT d.user_id, d.presence, d.last_lat, d.last_lng, d.busy_until_estimate, d.busy_estimate_updated_at, s.paid_until,
       (u.suspended_at IS NOT NULL)::boolean AS suspended
FROM drivers d
JOIN users u ON u.id = d.user_id
LEFT JOIN subscriptions s ON s.driver_id = d.user_id
WHERE d.user_id = $1
FOR UPDATE OF d;

-- name: SetDriverPresence :exec
UPDATE drivers
SET presence = $2,
    busy_until_estimate = $3,
    busy_estimate_updated_at = CASE WHEN $3::timestamptz IS NULL THEN NULL ELSE now() END
WHERE user_id = $1;

-- name: SetDriverLocation :exec
UPDATE drivers
SET last_lat = sqlc.arg(lat)::float8,
    last_lng = sqlc.arg(lng)::float8,
    last_location = ST_SetSRID(ST_MakePoint(sqlc.arg(lng)::float8, sqlc.arg(lat)::float8), 4326)::geography,
    last_location_at = sqlc.arg(recorded_at)::timestamptz
WHERE user_id = sqlc.arg(user_id);
