-- name: UpsertCostRate :exec
INSERT INTO cost_rates (concept, currency, unit_cost_micro, effective_from, created_by)
VALUES ($1, $2, $3, $4, $5)
ON CONFLICT (concept, currency, effective_from) DO UPDATE
SET unit_cost_micro = EXCLUDED.unit_cost_micro, created_by = EXCLUDED.created_by, created_at = now();

-- name: ListCostRates :many
SELECT concept, currency, unit_cost_micro, effective_from
FROM cost_rates
ORDER BY concept, currency, effective_from;

-- name: ListDailyUsage :many
SELECT driver_id, day, voice_participant_seconds, realtime_events, route_requests
FROM driver_usage_daily
WHERE day >= sqlc.arg(from_day) AND day < sqlc.arg(to_day)
  AND driver_id <> '00000000-0000-0000-0000-000000000000'::uuid
  AND (sqlc.narg(driver_id)::uuid IS NULL OR driver_id = sqlc.narg(driver_id)::uuid)
ORDER BY driver_id, day;

-- name: ListDriverNames :many
SELECT d.user_id AS driver_id, u.display_name
FROM drivers d JOIN users u ON u.id = d.user_id
ORDER BY u.display_name, d.user_id;
