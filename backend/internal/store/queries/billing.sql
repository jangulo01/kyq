-- name: GetCurrentPrice :one
SELECT city_code, currency, amount_minor, effective_from
FROM subscription_prices
WHERE city_code = $1 AND effective_from <= $2
ORDER BY effective_from DESC
LIMIT 1;

-- name: InsertSubscriptionPrice :exec
INSERT INTO subscription_prices (city_code, currency, amount_minor, effective_from, created_by)
VALUES ($1, $2, $3, $4, $5)
ON CONFLICT (city_code, effective_from) DO UPDATE
SET currency = EXCLUDED.currency, amount_minor = EXCLUDED.amount_minor, created_by = EXCLUDED.created_by,
    created_at = now();

-- name: FareTableExists :one
SELECT EXISTS (SELECT 1 FROM fare_tables WHERE city_code = $1);

-- name: InsertPayment :one
INSERT INTO payments (id, driver_id, amount_minor, currency, method, status, manual_reference,
                      payment_method_detail, created_by, created_at, updated_at)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $10)
RETURNING *;

-- name: GetPayment :one
SELECT * FROM payments WHERE id = $1;

-- name: GetPaymentForUpdate :one
SELECT * FROM payments WHERE id = $1 FOR UPDATE;

-- name: GetInFlightPayment :one
SELECT * FROM payments WHERE driver_id = $1 AND status IN ('created', 'processing') FOR UPDATE;

-- name: SetPaymentLink :exec
UPDATE payments SET bold_link_id = $2, checkout_url = $3, updated_at = now() WHERE id = $1;

-- name: SetPaymentStatus :exec
UPDATE payments
SET status = $2,
    payment_method_detail = coalesce(sqlc.narg(detail), payment_method_detail),
    bold_payment_id = coalesce(sqlc.narg(bold_payment_id), bold_payment_id),
    review_note = coalesce(sqlc.narg(review_note), review_note),
    updated_at = now()
WHERE id = $1;

-- name: ApprovePayment :exec
UPDATE payments
SET status = 'approved', covers_from = $2, covers_until = $3, prev_paid_until = $4,
    payment_method_detail = coalesce(sqlc.narg(detail), payment_method_detail),
    bold_payment_id = coalesce(sqlc.narg(bold_payment_id), bold_payment_id),
    updated_at = now()
WHERE id = $1;

-- name: VoidPayment :exec
UPDATE payments SET status = 'voided', voided_by = $2, void_reason = $3, updated_at = now() WHERE id = $1;

-- name: ListPaymentsForDriver :many
SELECT * FROM payments WHERE driver_id = $1 ORDER BY created_at DESC, id DESC LIMIT 100;

-- name: ListInFlightPayments :many
SELECT id FROM payments
WHERE status IN ('created', 'processing') AND bold_link_id IS NOT NULL AND created_at >= $1
ORDER BY created_at
LIMIT 100;

-- name: ExpireStalePayments :execrows
UPDATE payments SET status = 'expired', updated_at = now()
WHERE status IN ('created', 'processing') AND created_at < $1;

-- name: LockDriver :one
SELECT user_id FROM drivers WHERE user_id = $1 FOR UPDATE;

-- name: GetSubscription :one
SELECT paid_until FROM subscriptions WHERE driver_id = $1;

-- name: DeleteSubscription :exec
DELETE FROM subscriptions WHERE driver_id = $1;

-- name: ListSubscriptionsForAdmin :many
SELECT d.user_id AS driver_id, u.display_name, u.phone_e164, d.vehicle_plate, s.paid_until
FROM drivers d
JOIN users u ON u.id = d.user_id
LEFT JOIN subscriptions s ON s.driver_id = d.user_id
ORDER BY s.paid_until NULLS FIRST, u.display_name, d.user_id;

-- name: ListLastPayments :many
SELECT DISTINCT ON (driver_id) driver_id, id, amount_minor, currency, method, status, created_at
FROM payments
ORDER BY driver_id, created_at DESC, id DESC;

-- name: ListSubscriptionsDue :many
-- Suscripciones que vencen entre since y until (recordatorios 5/1 días y entrada en gracia).
SELECT driver_id, paid_until FROM subscriptions
WHERE paid_until BETWEEN sqlc.arg(since) AND sqlc.arg(until)
ORDER BY paid_until, driver_id;

-- name: SumApprovedPayments :many
-- Pagos aprobados cuyo periodo empieza en [from, to): el precio cobrado de ese mes (RN-KYQ-004).
SELECT driver_id, currency, sum(amount_minor)::bigint AS paid_minor
FROM payments
WHERE status = 'approved' AND covers_from >= sqlc.arg(from_ts) AND covers_from < sqlc.arg(to_ts)
  AND (sqlc.narg(driver_id)::uuid IS NULL OR driver_id = sqlc.narg(driver_id)::uuid)
GROUP BY driver_id, currency;

-- name: DeletePayment :exec
DELETE FROM payments WHERE id = $1;

-- name: UpsertSubscriptionPaidUntil :exec
INSERT INTO subscriptions (driver_id, paid_until, updated_by)
VALUES ($1, $2, $3)
ON CONFLICT (driver_id) DO UPDATE
SET paid_until = EXCLUDED.paid_until, updated_by = EXCLUDED.updated_by, updated_at = now();
