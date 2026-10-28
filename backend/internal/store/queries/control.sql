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

-- 009: detalle de un viaje para la inspección desde la torre (sin teléfonos, FR-002).

-- name: GetTripForInspection :one
SELECT t.id, t.status, t.cancel_reason, t.dispatch, t.handover_count, t.currency,
       t.pickup_lat, t.pickup_lng, t.dropoff_lat, t.dropoff_lng,
       t.route_distance_m, t.route_duration_s, t.list_fare_minor, t.suggested_fare_minor,
       t.agreed_fare_minor, t.preferential_discount_pct,
       t.created_at, t.accepted_at, t.arrived_at, t.started_at, t.completed_at, t.cancelled_at,
       t.passenger_id, pu.display_name AS passenger_name,
       t.driver_id, du.display_name AS driver_name,
       d.vehicle_plate, d.vehicle_description,
       d.last_lat, d.last_lng, d.last_location_at,
       c.name AS cooperative_name
FROM trips t
JOIN users pu ON pu.id = t.passenger_id
JOIN users du ON du.id = t.driver_id
JOIN drivers d ON d.user_id = t.driver_id
LEFT JOIN cooperatives c ON c.id = t.cooperative_id
WHERE t.id = $1;

-- name: GetTripPaymentStatusForInspection :one
SELECT status::text AS status, coalesce(method::text, '')::text AS method
FROM trip_payments
WHERE trip_id = $1;

-- name: GetOpenSosForTrip :one
SELECT id, status::text AS status
FROM sos_alerts
WHERE trip_id = $1 AND status IN ('open', 'claimed')
ORDER BY created_at DESC
LIMIT 1;

-- name: InsertTripInspection :exec
INSERT INTO trip_inspections (admin_id, trip_id, opened_at) VALUES ($1, $2, $3);

-- name: ListTripInspections :many
SELECT i.admin_id, u.display_name AS admin_name, i.opened_at
FROM trip_inspections i
JOIN users u ON u.id = i.admin_id
WHERE i.trip_id = $1
ORDER BY i.opened_at DESC
LIMIT 20;
