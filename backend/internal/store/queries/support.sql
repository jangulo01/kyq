-- 009: centro de soporte y disputas (research R2, R3).

-- name: InsertSupportCase :exec
INSERT INTO support_cases (id, user_id, user_role, counterpart_id, topic, subject, trip_id, trip_payment_id,
                           status, created_at, last_message_at, last_user_message_at, last_author_is_user)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13);

-- name: InsertSupportMessage :exec
INSERT INTO support_messages (id, case_id, author_id, author_kind, body, internal, created_at)
VALUES ($1, $2, $3, $4, $5, $6, $7);

-- name: GetSupportCase :one
SELECT sqlc.embed(sc), u.display_name AS user_name, cu.display_name AS counterpart_name, au.display_name AS assigned_name
FROM support_cases sc
JOIN users u ON u.id = sc.user_id
LEFT JOIN users cu ON cu.id = sc.counterpart_id
LEFT JOIN users au ON au.id = sc.assigned_to
WHERE sc.id = $1;

-- name: LockSupportCase :one
SELECT * FROM support_cases WHERE id = $1 FOR UPDATE;

-- name: GetSupportCaseByPayment :one
SELECT * FROM support_cases WHERE trip_payment_id = $1;

-- name: UpdateSupportCase :exec
UPDATE support_cases
SET status = $2, assigned_to = $3, last_message_at = $4, last_user_message_at = $5,
    last_author_is_user = $6, resolved_at = $7, closed_at = $8
WHERE id = $1;

-- name: ListUserSupportCases :many
-- Casos que abrió el usuario o de los que es contraparte (FR-011).
SELECT sqlc.embed(sc), u.display_name AS user_name, cu.display_name AS counterpart_name, au.display_name AS assigned_name
FROM support_cases sc
JOIN users u ON u.id = sc.user_id
LEFT JOIN users cu ON cu.id = sc.counterpart_id
LEFT JOIN users au ON au.id = sc.assigned_to
WHERE sc.user_id = $1 OR sc.counterpart_id = $1
ORDER BY sc.last_message_at DESC
LIMIT 100;

-- name: ListSupportMessages :many
SELECT m.id, m.case_id, m.author_id, m.author_kind, m.body, m.internal, m.created_at,
       u.display_name AS author_name
FROM support_messages m
LEFT JOIN users u ON u.id = m.author_id
WHERE m.case_id = $1 AND (sqlc.arg(include_internal)::boolean OR NOT m.internal)
ORDER BY m.created_at, m.id;

-- name: ListAdminSupportCases :many
-- Bandeja del panel (FR-008): del más antiguo sin atender al más reciente.
SELECT sqlc.embed(sc), u.display_name AS user_name, cu.display_name AS counterpart_name, au.display_name AS assigned_name
FROM support_cases sc
JOIN users u ON u.id = sc.user_id
LEFT JOIN users cu ON cu.id = sc.counterpart_id
LEFT JOIN users au ON au.id = sc.assigned_to
WHERE (sqlc.narg(status)::support_status IS NULL OR sc.status = sqlc.narg(status))
  AND (sqlc.narg(topic)::support_topic IS NULL OR sc.topic = sqlc.narg(topic))
  AND (sqlc.narg(assigned_to)::uuid IS NULL OR sc.assigned_to = sqlc.narg(assigned_to))
  AND (NOT sqlc.arg(unanswered)::boolean OR (sc.last_author_is_user AND sc.status <> 'closed'))
  AND (sqlc.arg(include_closed)::boolean OR sqlc.narg(status)::support_status IS NOT NULL OR sc.status <> 'closed')
ORDER BY coalesce(sc.last_user_message_at, sc.created_at), sc.id
LIMIT 200;

-- name: CloseStaleSupportCases :many
-- FR-012: un caso resuelto sin respuesta del usuario en 7 días se cierra.
UPDATE support_cases
SET status = 'closed', closed_at = sqlc.arg(now)
WHERE status = 'resolved' AND resolved_at <= sqlc.arg(cutoff)
  AND (last_user_message_at IS NULL OR last_user_message_at <= resolved_at)
RETURNING id, user_id, counterpart_id;

-- name: ListRecentTripsForSupport :many
-- Viajes del usuario de los últimos 30 días para asociarlos a un caso (FR-005).
SELECT t.id, t.status, t.created_at, t.passenger_id, t.driver_id,
       pu.display_name AS passenger_name, du.display_name AS driver_name
FROM trips t
JOIN users pu ON pu.id = t.passenger_id
JOIN users du ON du.id = t.driver_id
WHERE (t.passenger_id = sqlc.arg(user_id) OR t.driver_id = sqlc.arg(user_id)) AND t.created_at >= sqlc.arg(since)
ORDER BY t.created_at DESC
LIMIT 20;

-- name: GetTripPartiesForSupport :one
SELECT passenger_id, driver_id, created_at FROM trips WHERE id = $1;

-- name: GetUserRoleForSupport :one
SELECT role FROM users WHERE id = $1;
