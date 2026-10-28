-- 007: indicadores de fidelización (research R6).

-- name: ListAffiliationTimeline :many
-- Altas y bajas de las afiliaciones creadas antes de until (serie y abandono se calculan en Go).
SELECT created_at, removed_at
FROM affiliations
WHERE created_at < sqlc.arg(until);

-- name: CompletedTripsByPair :many
SELECT passenger_id, driver_id, count(*)::bigint AS trips
FROM trips
WHERE status = 'COMPLETED' AND completed_at >= sqlc.arg(from_ts) AND completed_at < sqlc.arg(to_ts)
GROUP BY passenger_id, driver_id;

-- name: AffiliationsWithFirstRequest :many
-- SC-008 de 001: si el pasajero pidió un viaje a ese conductor en los 30 días siguientes.
SELECT a.created_at,
       EXISTS (
           SELECT 1 FROM trips t
           WHERE t.passenger_id = a.passenger_id AND t.driver_id = a.driver_id
             AND t.created_at >= a.created_at AND t.created_at < a.created_at + interval '30 days'
       ) AS requested
FROM affiliations a
WHERE a.created_at >= sqlc.arg(from_ts) AND a.created_at < sqlc.arg(to_ts);

-- name: TopDriversByRemovals :many
SELECT a.driver_id, u.display_name, count(*)::bigint AS removed,
       (SELECT count(*) FROM affiliations x WHERE x.driver_id = a.driver_id AND x.removed_at IS NULL)::bigint AS active_now
FROM affiliations a
JOIN users u ON u.id = a.driver_id
WHERE a.removed_at >= sqlc.arg(from_ts) AND a.removed_at < sqlc.arg(to_ts)
GROUP BY a.driver_id, u.display_name
ORDER BY removed DESC, u.display_name, a.driver_id
LIMIT 10;

-- name: InactiveChosenDrivers :many
-- Conductores con afiliados activos y sin viajes completados desde since.
SELECT a.driver_id, u.display_name, count(*)::bigint AS active_affiliations,
       -- 'epoch' = nunca completó un viaje.
       (SELECT coalesce(max(t.completed_at), 'epoch'::timestamptz)
        FROM trips t WHERE t.driver_id = a.driver_id AND t.status = 'COMPLETED')::timestamptz AS last_completed_at
FROM affiliations a
JOIN users u ON u.id = a.driver_id
WHERE a.removed_at IS NULL
  AND NOT EXISTS (
      SELECT 1 FROM trips t
      WHERE t.driver_id = a.driver_id AND t.status = 'COMPLETED' AND t.completed_at >= sqlc.arg(since)::timestamptz
  )
GROUP BY a.driver_id, u.display_name
ORDER BY active_affiliations DESC, u.display_name, a.driver_id
LIMIT 20;
