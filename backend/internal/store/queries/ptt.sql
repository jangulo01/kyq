-- name: OpenPTTChannel :exec
INSERT INTO ptt_channels (trip_id, room_name, opened_at)
VALUES ($1, $2, $3)
ON CONFLICT (trip_id) DO NOTHING;

-- name: SchedulePTTClose :exec
UPDATE ptt_channels SET closes_at = $2 WHERE trip_id = $1 AND closed_at IS NULL;

-- name: GetPTTChannel :one
SELECT * FROM ptt_channels WHERE trip_id = $1;

-- name: TakePTTFloor :one
-- Turno exclusivo: se concede si está libre, ya era del llamante o caducó (FR-017).
UPDATE ptt_channels
SET floor_holder_id = sqlc.arg(user_id), floor_expires_at = sqlc.arg(expires_at)
WHERE trip_id = sqlc.arg(trip_id)
  AND closed_at IS NULL
  AND (closes_at IS NULL OR closes_at > sqlc.arg(now))
  AND (floor_holder_id IS NULL OR floor_holder_id = sqlc.arg(user_id) OR floor_expires_at < sqlc.arg(now))
RETURNING floor_expires_at;

-- name: ReleasePTTFloor :exec
UPDATE ptt_channels SET floor_holder_id = NULL, floor_expires_at = NULL
WHERE trip_id = $1 AND floor_holder_id = $2;

-- name: ListDuePTTChannels :many
SELECT c.trip_id, c.room_name, t.passenger_id, t.driver_id
FROM ptt_channels c
JOIN trips t ON t.id = c.trip_id
WHERE c.closed_at IS NULL AND c.closes_at <= $1
ORDER BY c.closes_at
LIMIT 100;

-- name: MarkPTTClosed :execrows
UPDATE ptt_channels SET closed_at = $2, floor_holder_id = NULL, floor_expires_at = NULL
WHERE trip_id = $1 AND closed_at IS NULL;

-- name: GetTripParties :one
SELECT passenger_id, driver_id FROM trips WHERE id = $1;

-- name: ListExpiredPTTFloors :many
SELECT trip_id, room_name, floor_holder_id
FROM ptt_channels
WHERE closed_at IS NULL AND floor_holder_id IS NOT NULL AND floor_expires_at < $1
LIMIT 100;

-- name: ClearExpiredPTTFloor :execrows
UPDATE ptt_channels SET floor_holder_id = NULL, floor_expires_at = NULL
WHERE trip_id = sqlc.arg(trip_id) AND floor_holder_id = sqlc.arg(holder_id) AND floor_expires_at < sqlc.arg(now);
