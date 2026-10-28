-- 007: moderación de usuarios (FR-014–FR-017).

-- name: SearchUsers :many
-- pattern ya viene escapado para LIKE (\, % y _).
SELECT id, phone_e164, role, display_name, created_at, suspended_at, suspension_reason
FROM users
WHERE (sqlc.narg(pattern)::text IS NULL
       OR display_name ILIKE '%' || sqlc.narg(pattern)::text || '%'
       OR phone_e164 LIKE '%' || sqlc.narg(pattern)::text || '%')
  AND (sqlc.narg(role)::user_role IS NULL OR role = sqlc.narg(role)::user_role)
  AND (sqlc.narg(suspended)::boolean IS NULL OR (suspended_at IS NOT NULL) = sqlc.narg(suspended)::boolean)
ORDER BY created_at DESC, id
LIMIT 50;

-- name: GetUserForUpdate :one
SELECT id, phone_e164, role, display_name, created_at, suspended_at, suspension_reason
FROM users
WHERE id = $1
FOR UPDATE;

-- name: SetUserSuspension :exec
UPDATE users
SET suspended_at = sqlc.narg(suspended_at), suspension_reason = sqlc.narg(suspension_reason)
WHERE id = sqlc.arg(id);

-- name: InsertModerationAction :exec
INSERT INTO moderation_actions (id, user_id, action, reason, actor_id)
VALUES ($1, $2, $3, $4, $5);

-- name: ListModerationActions :many
SELECT m.id, m.action, m.reason, m.actor_id, u.display_name AS actor_name, m.created_at
FROM moderation_actions m
JOIN users u ON u.id = m.actor_id
WHERE m.user_id = $1
ORDER BY m.created_at DESC, m.id DESC;

-- name: IsUserSuspended :one
SELECT (suspended_at IS NOT NULL)::boolean AS suspended
FROM users
WHERE id = $1;
