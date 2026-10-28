-- 007: Finanzas sobre los costos de 002 (research R5).

-- name: ListDriversCreatedBefore :many
-- Conductores que ya existían antes de until (los demás no cuentan en ese mes).
SELECT d.user_id AS driver_id, u.display_name
FROM drivers d
JOIN users u ON u.id = d.user_id
WHERE u.created_at < sqlc.arg(until)
ORDER BY u.display_name, d.user_id;
