-- name: GetUserByPhone :one
SELECT id, phone_e164, role, display_name, created_at, suspended_at, suspension_reason
FROM users
WHERE phone_e164 = $1;

-- name: GetUserByID :one
SELECT id, phone_e164, role, display_name, created_at, suspended_at, suspension_reason
FROM users
WHERE id = $1;

-- name: CreateUser :one
INSERT INTO users (id, phone_e164, role, display_name)
VALUES ($1, $2, $3, $4)
RETURNING id, phone_e164, role, display_name, created_at, suspended_at, suspension_reason;

-- name: InsertRefreshToken :exec
INSERT INTO refresh_tokens (id, user_id, token_hash, expires_at)
VALUES ($1, $2, $3, $4);

-- name: GetRefreshTokenByHash :one
SELECT id, user_id, expires_at, rotated_at
FROM refresh_tokens
WHERE token_hash = $1;

-- name: MarkRefreshTokenRotated :execrows
UPDATE refresh_tokens
SET rotated_at = now()
WHERE id = $1 AND rotated_at IS NULL;

-- name: RevokeUserRefreshTokens :exec
UPDATE refresh_tokens
SET rotated_at = now()
WHERE user_id = $1 AND rotated_at IS NULL;
