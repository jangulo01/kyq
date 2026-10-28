-- name: InsertNotice :one
-- Sin fila si el aviso ya existía (misma dedup_key): el barrido puede repetirse sin duplicar.
INSERT INTO notices (id, driver_id, kind, dedup_key, title, body, sms, created_at)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
ON CONFLICT (driver_id, dedup_key) DO NOTHING
RETURNING *;

-- name: ListNotices :many
SELECT * FROM notices WHERE driver_id = $1 ORDER BY created_at DESC, id DESC LIMIT 100;

-- name: MarkNoticeRead :execrows
UPDATE notices SET read_at = coalesce(read_at, $3) WHERE id = $1 AND driver_id = $2;

-- name: ListPendingSMS :many
SELECT n.id, n.driver_id, n.body, u.phone_e164
FROM notices n
JOIN users u ON u.id = n.driver_id
WHERE n.sms AND n.sms_sent_at IS NULL AND n.created_at >= $1
ORDER BY n.created_at
LIMIT 50;

-- name: MarkNoticeSMSSent :exec
UPDATE notices SET sms_sent_at = $2 WHERE id = $1;
