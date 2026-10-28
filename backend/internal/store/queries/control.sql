-- 007: torre de control (research R2, R3).

-- name: ListOnlineDriversForTower :many
SELECT d.user_id AS driver_id, u.display_name, d.presence, d.last_lat, d.last_lng, d.last_location_at
FROM drivers d
JOIN users u ON u.id = d.user_id
WHERE d.presence <> 'offline'
ORDER BY u.display_name, d.user_id;

-- name: ListActiveTripsForTower :many
SELECT id, driver_id, status, pickup_lat, pickup_lng
FROM trips
WHERE status IN ('ACCEPTED', 'ARRIVED', 'IN_PROGRESS');

-- name: ListRecentRequestsForTower :many
-- Solicitudes de la ventana: viajes creados desde since, terminen como terminen.
SELECT pickup_lat, pickup_lng, status, cancel_reason
FROM trips
WHERE created_at >= sqlc.arg(since);

-- name: TowerFingerprint :one
-- Huella barata del estado de la torre: si no cambia, no se avisa al panel.
SELECT (SELECT count(*) FROM drivers d1 WHERE d1.presence <> 'offline')::bigint AS online,
       (SELECT count(*) FROM drivers d2 WHERE d2.presence = 'busy')::bigint AS busy,
       (SELECT coalesce(max(d3.last_location_at), 'epoch'::timestamptz) FROM drivers d3 WHERE d3.presence <> 'offline')::timestamptz AS last_location_at,
       (SELECT count(*) FROM trips t1 WHERE t1.status NOT IN ('COMPLETED', 'CANCELLED'))::bigint AS open_trips,
       (SELECT coalesce(max(greatest(t2.created_at, t2.accepted_at, t2.arrived_at, t2.started_at, t2.completed_at, t2.cancelled_at)), 'epoch'::timestamptz)
        FROM trips t2 WHERE t2.created_at >= sqlc.arg(since)::timestamptz)::timestamptz AS last_trip_change;
