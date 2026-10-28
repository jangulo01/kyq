-- 009: megáfono por zonas H3 (research R5).

-- name: ListMegaphoneCandidates :many
-- Conductores ONLINE no suspendidos con ubicación reciente (FR-014).
SELECT d.user_id AS driver_id, d.last_lat, d.last_lng
FROM drivers d
JOIN users u ON u.id = d.user_id
WHERE d.presence <> 'offline' AND u.suspended_at IS NULL
  AND d.last_location_at >= sqlc.arg(since) AND d.last_lat IS NOT NULL AND d.last_lng IS NOT NULL;

-- name: InsertMegaphoneBroadcast :exec
INSERT INTO megaphone_broadcasts (id, admin_id, room_name, cells, resolution, started_at, ends_at, recipient_count)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8);

-- name: InsertMegaphoneRecipients :exec
INSERT INTO megaphone_recipients (broadcast_id, driver_id)
SELECT sqlc.arg(broadcast_id)::uuid, unnest(sqlc.arg(driver_ids)::uuid[]);

-- name: GetOpenMegaphoneForAdmin :one
SELECT * FROM megaphone_broadcasts WHERE admin_id = $1 AND ended_at IS NULL LIMIT 1;

-- name: EndMegaphoneBroadcast :one
UPDATE megaphone_broadcasts SET ended_at = sqlc.arg(ended_at)
WHERE id = sqlc.arg(id) AND ended_at IS NULL
RETURNING *;

-- name: ListDueMegaphoneBroadcasts :many
SELECT id FROM megaphone_broadcasts WHERE ended_at IS NULL AND ends_at <= $1;

-- name: ListMegaphoneRecipients :many
SELECT driver_id FROM megaphone_recipients WHERE broadcast_id = $1;

-- name: ListMegaphoneBroadcasts :many
SELECT sqlc.embed(b), u.display_name AS admin_name
FROM megaphone_broadcasts b
JOIN users u ON u.id = b.admin_id
ORDER BY b.started_at DESC
LIMIT $1;
