-- name: UpsertFareTable :exec
INSERT INTO fare_tables (city_code, currency, base_minor, per_km_minor, per_minute_minor, minimum_minor, rounding_minor, updated_by)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
ON CONFLICT (city_code) DO UPDATE
SET currency = EXCLUDED.currency,
    base_minor = EXCLUDED.base_minor,
    per_km_minor = EXCLUDED.per_km_minor,
    per_minute_minor = EXCLUDED.per_minute_minor,
    minimum_minor = EXCLUDED.minimum_minor,
    rounding_minor = EXCLUDED.rounding_minor,
    updated_by = EXCLUDED.updated_by,
    updated_at = now();

-- name: GetFareTable :one
SELECT city_code, currency, base_minor, per_km_minor, per_minute_minor, minimum_minor, rounding_minor
FROM fare_tables
WHERE city_code = $1;

-- name: InsertTrip :exec
INSERT INTO trips (
    id, passenger_id, driver_id, city_code, currency,
    pickup_lat, pickup_lng, dropoff_lat, dropoff_lng,
    route_distance_m, route_duration_s, suggested_fare_minor,
    status, respond_by, created_at
) VALUES (
    $1, $2, $3, $4, $5,
    $6, $7, $8, $9,
    $10, $11, $12,
    $13, $14, $15
);

-- name: GetTrip :one
SELECT * FROM trips WHERE id = $1;

-- name: GetTripForUpdate :one
SELECT * FROM trips WHERE id = $1 FOR UPDATE;

-- name: UpdateTrip :exec
UPDATE trips
SET status = $2,
    agreed_fare_minor = $3,
    driver_payout_minor = $4,
    cancel_reason = $5,
    respond_by = $6,
    negotiation_expires_at = $7,
    accepted_at = $8,
    arrived_at = $9,
    started_at = $10,
    completed_at = $11,
    cancelled_at = $12
WHERE id = $1;

-- name: GetOpenProposal :one
SELECT id, trip_id, proposed_by, amount_minor, status, created_at, expires_at
FROM fare_proposals
WHERE trip_id = $1 AND status = 'open';

-- name: UpsertProposal :exec
INSERT INTO fare_proposals (id, trip_id, proposed_by, amount_minor, status, created_at, expires_at)
VALUES ($1, $2, $3, $4, $5, $6, $7)
ON CONFLICT (id) DO UPDATE SET status = EXCLUDED.status;

-- name: ListDueTripIDs :many
SELECT id
FROM trips
WHERE respond_by IS NOT NULL AND respond_by <= $1
ORDER BY respond_by
LIMIT 100
FOR UPDATE SKIP LOCKED;

-- name: GetActiveTripForDriver :one
SELECT * FROM trips
WHERE driver_id = $1 AND status NOT IN ('COMPLETED', 'CANCELLED');

-- name: GetActiveTripForPassenger :one
SELECT * FROM trips
WHERE passenger_id = $1 AND status NOT IN ('COMPLETED', 'CANCELLED');

-- name: IsTripParticipant :one
SELECT EXISTS (SELECT 1 FROM trips WHERE id = $1 AND (passenger_id = $2 OR driver_id = $2));

-- name: GetUserDisplayName :one
SELECT display_name FROM users WHERE id = $1;

-- name: GetDriverPublic :one
SELECT u.display_name, d.vehicle_plate, d.vehicle_description, d.presence, d.last_lat, d.last_lng
FROM drivers d
JOIN users u ON u.id = d.user_id
WHERE d.user_id = $1;
