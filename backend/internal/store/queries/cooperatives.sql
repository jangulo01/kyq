-- name: CreateCooperative :one
INSERT INTO cooperatives (id, name, city_code, nit, created_by)
VALUES ($1, btrim(sqlc.arg(name)::text), $2, $3, $4)
RETURNING *;

-- name: CreateGroupPTTChannel :exec
INSERT INTO group_ptt_channels (cooperative_id, room_name)
VALUES ($1, $2)
ON CONFLICT (cooperative_id) DO NOTHING;

-- name: GetCooperative :one
SELECT * FROM cooperatives WHERE id = $1;

-- name: GetCooperativeForUpdate :one
SELECT * FROM cooperatives WHERE id = $1 FOR UPDATE;

-- name: UpdateCooperative :one
UPDATE cooperatives
SET name = btrim(sqlc.arg(name)::text),
    city_code = sqlc.arg(city_code),
    nit = sqlc.arg(nit),
    status = sqlc.arg(status),
    updated_at = now()
WHERE id = sqlc.arg(id)
RETURNING *;

-- name: ListCooperativesWithCounts :many
SELECT c.*,
       (SELECT count(*) FROM cooperative_memberships m WHERE m.cooperative_id = c.id AND m.status = 'active')::int AS members_count,
       (SELECT count(*) FROM cooperative_memberships m WHERE m.cooperative_id = c.id AND m.status = 'pending')::int AS pending_count
FROM cooperatives c
WHERE sqlc.arg(only_active)::boolean = false OR c.status = 'active'
ORDER BY lower(c.name), c.id;

-- name: CountCooperativeMemberships :one
SELECT
    (SELECT count(*) FROM cooperative_memberships m WHERE m.cooperative_id = $1 AND m.status = 'active')::int AS members_count,
    (SELECT count(*) FROM cooperative_memberships m WHERE m.cooperative_id = $1 AND m.status = 'pending')::int AS pending_count;

-- name: InsertMembership :one
INSERT INTO cooperative_memberships (id, cooperative_id, driver_id, role, status, requested_at, decided_by, decided_at)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
RETURNING *;

-- name: GetMembership :one
SELECT * FROM cooperative_memberships WHERE id = $1;

-- name: GetMembershipForUpdate :one
SELECT * FROM cooperative_memberships WHERE id = $1 FOR UPDATE;

-- name: GetCurrentMembership :one
-- Membresía en curso del conductor (activa o pendiente), como máximo una (FR-003).
SELECT m.*, c.name AS cooperative_name, c.status AS cooperative_status
FROM cooperative_memberships m
JOIN cooperatives c ON c.id = m.cooperative_id
WHERE m.driver_id = $1 AND m.status IN ('pending', 'active');

-- name: GetLastEndedMembership :one
-- Última solicitud rechazada, para mostrar el motivo al conductor.
SELECT m.*, c.name AS cooperative_name, c.status AS cooperative_status
FROM cooperative_memberships m
JOIN cooperatives c ON c.id = m.cooperative_id
WHERE m.driver_id = $1 AND m.status = 'rejected'
ORDER BY m.decided_at DESC NULLS LAST
LIMIT 1;

-- name: GetActiveMembershipInCooperative :one
SELECT * FROM cooperative_memberships
WHERE cooperative_id = $1 AND driver_id = $2 AND status = 'active'
FOR UPDATE;

-- name: DecideMembership :execrows
UPDATE cooperative_memberships
SET status = sqlc.arg(status), reject_reason = sqlc.arg(reject_reason), decided_by = sqlc.arg(decided_by), decided_at = sqlc.arg(decided_at)
WHERE id = sqlc.arg(id) AND status = 'pending';

-- name: EndMembership :execrows
UPDATE cooperative_memberships
SET status = sqlc.arg(status), ended_by = sqlc.arg(ended_by), ended_at = sqlc.arg(ended_at)
WHERE id = sqlc.arg(id) AND status = sqlc.arg(from_status);

-- name: SetMembershipRole :execrows
UPDATE cooperative_memberships SET role = $2 WHERE id = $1 AND status = 'active';

-- name: ListCooperativeMembers :many
SELECT m.id AS membership_id, m.driver_id, u.display_name, d.vehicle_plate, m.role, d.presence,
       coalesce(m.decided_at, m.requested_at)::timestamptz AS since
FROM cooperative_memberships m
JOIN drivers d ON d.user_id = m.driver_id
JOIN users u ON u.id = m.driver_id
WHERE m.cooperative_id = $1 AND m.status = 'active'
ORDER BY m.role DESC, lower(u.display_name), m.driver_id;

-- name: ListCooperativeRequests :many
SELECT m.id AS membership_id, m.driver_id, u.display_name, d.vehicle_plate, m.requested_at
FROM cooperative_memberships m
JOIN drivers d ON d.user_id = m.driver_id
JOIN users u ON u.id = m.driver_id
WHERE m.cooperative_id = $1 AND m.status = 'pending'
ORDER BY m.requested_at, m.id;

-- name: GetDriverCooperative :one
-- Cooperativa activa del conductor con membresía activa; base de la delegación (RN-KYQ-008).
SELECT c.id, c.name
FROM cooperative_memberships m
JOIN cooperatives c ON c.id = m.cooperative_id
WHERE m.driver_id = $1 AND m.status = 'active' AND c.status = 'active';

-- name: FindDelegationCandidate :one
-- Compañero libre más cercano a la recogida (FR-015): miembro activo de la cooperativa activa,
-- con ubicación reciente, dentro del radio y sin oferta previa en el viaje. La fila del conductor
-- queda bloqueada para que otra solicitud no lo reserve a la vez (research R2).
SELECT d.user_id AS driver_id,
       ST_Distance(d.last_location, ST_SetSRID(ST_MakePoint(sqlc.arg(lng)::float8, sqlc.arg(lat)::float8), 4326)::geography)::float8 AS distance_m
FROM cooperative_memberships m
JOIN cooperatives c ON c.id = m.cooperative_id AND c.status = 'active'
JOIN drivers d ON d.user_id = m.driver_id
WHERE m.cooperative_id = sqlc.arg(cooperative_id)
  AND m.status = 'active'
  AND d.presence = 'free'
  AND d.last_location IS NOT NULL
  AND d.last_location_at >= sqlc.arg(fresh_since)::timestamptz
  AND ST_DWithin(d.last_location, ST_SetSRID(ST_MakePoint(sqlc.arg(lng)::float8, sqlc.arg(lat)::float8), 4326)::geography, sqlc.arg(radius_m)::float8)
  AND NOT EXISTS (SELECT 1 FROM trip_offers o WHERE o.trip_id = sqlc.arg(trip_id) AND o.driver_id = d.user_id)
ORDER BY distance_m, d.user_id
LIMIT 1
FOR UPDATE OF d SKIP LOCKED;

-- name: InsertTripOffer :exec
INSERT INTO trip_offers (trip_id, driver_id, offered_at, handover)
VALUES ($1, $2, $3, $4)
ON CONFLICT (trip_id, driver_id) DO NOTHING;

-- name: GetGroupPTTChannel :one
SELECT * FROM group_ptt_channels WHERE cooperative_id = $1;

-- name: TakeGroupPTTFloor :one
-- Turno único del grupo (FR-023): libre o ya del llamante. Uno caducado lo libera el barrido.
UPDATE group_ptt_channels
SET floor_holder_id = sqlc.arg(user_id), floor_expires_at = sqlc.arg(expires_at)
WHERE cooperative_id = sqlc.arg(cooperative_id)
  AND (floor_holder_id IS NULL OR floor_holder_id = sqlc.arg(user_id))
RETURNING floor_expires_at;

-- name: ReleaseGroupPTTFloor :exec
UPDATE group_ptt_channels SET floor_holder_id = NULL, floor_expires_at = NULL
WHERE cooperative_id = $1 AND floor_holder_id = $2;

-- name: ListExpiredGroupPTTFloors :many
SELECT cooperative_id, room_name, floor_holder_id
FROM group_ptt_channels
WHERE floor_holder_id IS NOT NULL AND floor_expires_at < $1
LIMIT 100;

-- name: ClearExpiredGroupPTTFloor :execrows
UPDATE group_ptt_channels SET floor_holder_id = NULL, floor_expires_at = NULL
WHERE cooperative_id = sqlc.arg(cooperative_id) AND floor_holder_id = sqlc.arg(holder_id) AND floor_expires_at < sqlc.arg(now);

-- name: ListActiveMemberIDs :many
SELECT driver_id FROM cooperative_memberships WHERE cooperative_id = $1 AND status = 'active';
