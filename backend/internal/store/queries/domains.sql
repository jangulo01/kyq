-- 009: dominios espejo (research R7).

-- name: ListMirrorDomains :many
SELECT * FROM mirror_domains ORDER BY position, created_at;

-- name: GetMirrorDomain :one
SELECT * FROM mirror_domains WHERE id = $1;

-- name: InsertMirrorDomain :one
INSERT INTO mirror_domains (id, api_url, realtime_url, position, active, created_at, updated_at)
VALUES ($1, $2, $3, (SELECT coalesce(max(position), 0) + 1 FROM mirror_domains), $4, $5, $5)
RETURNING *;

-- name: UpdateMirrorDomain :one
UPDATE mirror_domains SET api_url = $2, realtime_url = $3, active = $4, updated_at = $5
WHERE id = $1
RETURNING *;

-- name: SetMirrorDomainPosition :exec
UPDATE mirror_domains SET position = $2, updated_at = $3 WHERE id = $1;

-- name: DeleteMirrorDomain :execrows
DELETE FROM mirror_domains WHERE id = $1;

-- name: CountActiveMirrorDomains :one
SELECT count(*) FROM mirror_domains WHERE active;

-- name: LockMirrorDomainsVersion :one
SELECT version FROM mirror_domains_version WHERE id FOR UPDATE;

-- name: BumpMirrorDomainsVersion :one
UPDATE mirror_domains_version SET version = version + 1, updated_at = $1 WHERE id
RETURNING version;

-- name: GetMirrorDomainsVersion :one
SELECT version, updated_at FROM mirror_domains_version WHERE id;
