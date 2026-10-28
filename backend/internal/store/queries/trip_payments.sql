-- 004: pago del viaje, medios aceptados, libro de liquidación y giros.

-- name: GetDriverPaymentMethods :one
SELECT accepts_cash, accepts_bold FROM drivers WHERE user_id = $1;

-- name: SetDriverPaymentMethods :execrows
UPDATE drivers SET accepts_cash = $2, accepts_bold = $3 WHERE user_id = $1;

-- name: InsertTripPayment :execrows
-- Al completarse el viaje (research R5); repetirlo no hace nada.
INSERT INTO trip_payments (id, trip_id, driver_id, passenger_id, amount_minor, currency, driver_amount_minor,
                           accepts_cash, accepts_bold, status, created_at, updated_at)
SELECT $1, $2, $3, $4, $5, $6, $7, d.accepts_cash, d.accepts_bold, 'pending', $8, $8
FROM drivers d
WHERE d.user_id = $3
ON CONFLICT (trip_id) DO NOTHING;

-- name: GetTripPaymentByTrip :one
SELECT sqlc.embed(tp), du.display_name AS driver_name, pu.display_name AS passenger_name
FROM trip_payments tp
JOIN users du ON du.id = tp.driver_id
JOIN users pu ON pu.id = tp.passenger_id
WHERE tp.trip_id = $1;

-- name: GetTripPaymentWithNames :one
SELECT sqlc.embed(tp), du.display_name AS driver_name, pu.display_name AS passenger_name
FROM trip_payments tp
JOIN users du ON du.id = tp.driver_id
JOIN users pu ON pu.id = tp.passenger_id
WHERE tp.id = $1;

-- name: GetTripPayment :one
SELECT * FROM trip_payments WHERE id = $1;

-- name: GetTripPaymentForUpdate :one
SELECT * FROM trip_payments WHERE id = $1 FOR UPDATE;

-- name: UpdateTripPayment :exec
UPDATE trip_payments
SET status = $2,
    method = $3,
    bold_link_id = $4,
    checkout_url = $5,
    link_created_at = $6,
    bold_payment_id = $7,
    payment_method_detail = $8,
    cash_reported_at = $9,
    cash_confirmed_at = $10,
    disputed_at = $11,
    unpaid_marked_at = $12,
    paid_at = $13,
    reminded_at = $14,
    review_note = $15,
    resolved_by = $16,
    resolution_note = $17,
    resolved_at = $18,
    voided_by = $19,
    void_reason = $20,
    voided_at = $21,
    updated_at = now()
WHERE id = $1;

-- name: ListBoldInFlightTripPayments :many
-- Enlaces en curso creados desde $1: el barrido los consulta a Bold (research R1).
SELECT id FROM trip_payments
WHERE status = 'bold_in_progress' AND link_created_at >= $1
ORDER BY link_created_at
LIMIT 100;

-- name: ListStaleBoldTripPayments :many
-- Enlaces en curso fuera de la ventana de sondeo: se dan por caducados.
SELECT id FROM trip_payments
WHERE status = 'bold_in_progress' AND link_created_at < $1
ORDER BY link_created_at
LIMIT 100;

-- name: ListTripPaymentsToRemind :many
-- Pagos pendientes de viajes completados antes de $1 sin recordatorio (FR-015).
SELECT id FROM trip_payments
WHERE status = 'pending' AND reminded_at IS NULL AND created_at <= $1
ORDER BY created_at
LIMIT 100;

-- name: ListOpenTripPaymentsForPassenger :many
SELECT sqlc.embed(tp), du.display_name AS driver_name, pu.display_name AS passenger_name
FROM trip_payments tp
JOIN users du ON du.id = tp.driver_id
JOIN users pu ON pu.id = tp.passenger_id
WHERE tp.passenger_id = $1 AND tp.status IN ('pending', 'unpaid', 'bold_in_progress')
ORDER BY tp.created_at DESC, tp.id DESC
LIMIT 20;

-- name: ListTripPaymentsForDriver :many
SELECT sqlc.embed(tp), du.display_name AS driver_name, pu.display_name AS passenger_name
FROM trip_payments tp
JOIN users du ON du.id = tp.driver_id
JOIN users pu ON pu.id = tp.passenger_id
WHERE tp.driver_id = $1
ORDER BY tp.created_at DESC, tp.id DESC
LIMIT 50;

-- name: ListTripPaymentsForAdmin :many
-- Por estado, o solo incidencias (no pagado, en disputa, en revisión) (FR-017).
SELECT sqlc.embed(tp), du.display_name AS driver_name, pu.display_name AS passenger_name
FROM trip_payments tp
JOIN users du ON du.id = tp.driver_id
JOIN users pu ON pu.id = tp.passenger_id
WHERE (sqlc.narg(status)::trip_payment_status IS NULL OR tp.status = sqlc.narg(status)::trip_payment_status)
  AND (NOT sqlc.arg(issues)::boolean OR tp.status IN ('unpaid', 'disputed', 'needs_review'))
ORDER BY tp.created_at DESC, tp.id DESC
LIMIT 200;

-- name: InsertLedgerEntry :execrows
-- Un abono y un débito por pago como máximo: repetirlo no hace nada (SC-003).
INSERT INTO driver_ledger_entries (id, driver_id, kind, amount_minor, currency, trip_payment_id, payout_id,
                                   created_by, created_at)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
ON CONFLICT (trip_payment_id, kind) WHERE trip_payment_id IS NOT NULL DO NOTHING;

-- name: HasLedgerEntry :one
SELECT EXISTS (SELECT 1 FROM driver_ledger_entries WHERE trip_payment_id = $1 AND kind = $2);

-- name: GetDriverBalances :many
SELECT currency,
       coalesce(sum(amount_minor) FILTER (WHERE kind = 'trip_credit'), 0)::bigint AS credited_minor,
       coalesce(-sum(amount_minor) FILTER (WHERE kind = 'void_debit'), 0)::bigint AS debited_minor,
       coalesce(-sum(amount_minor) FILTER (WHERE kind = 'payout'), 0)::bigint AS paid_out_minor,
       coalesce(sum(amount_minor), 0)::bigint AS balance_minor
FROM driver_ledger_entries
WHERE driver_id = $1
GROUP BY currency
ORDER BY currency;

-- name: ListLedgerEntries :many
SELECT e.id, e.kind, e.amount_minor, e.currency, e.trip_payment_id, tp.trip_id, e.payout_id, p.reference,
       e.created_at
FROM driver_ledger_entries e
LEFT JOIN trip_payments tp ON tp.id = e.trip_payment_id
LEFT JOIN driver_payouts p ON p.id = e.payout_id
WHERE e.driver_id = $1
ORDER BY e.created_at DESC, e.id DESC
LIMIT 200;

-- name: InsertPayout :one
INSERT INTO driver_payouts (id, driver_id, amount_minor, currency, reference, note, created_by, created_at)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
RETURNING *;

-- name: ListSettlements :many
-- Saldo por conductor y moneda; los que tienen saldo, primero (FR-012).
SELECT d.user_id AS driver_id, u.display_name, u.phone_e164, d.vehicle_plate, e.currency,
       coalesce(sum(e.amount_minor) FILTER (WHERE e.kind = 'trip_credit'), 0)::bigint AS credited_minor,
       coalesce(-sum(e.amount_minor) FILTER (WHERE e.kind = 'void_debit'), 0)::bigint AS debited_minor,
       coalesce(-sum(e.amount_minor) FILTER (WHERE e.kind = 'payout'), 0)::bigint AS paid_out_minor,
       coalesce(sum(e.amount_minor), 0)::bigint AS balance_minor
FROM driver_ledger_entries e
JOIN drivers d ON d.user_id = e.driver_id
JOIN users u ON u.id = d.user_id
GROUP BY d.user_id, u.display_name, u.phone_e164, d.vehicle_plate, e.currency
ORDER BY balance_minor DESC, u.display_name, d.user_id;

-- name: ListLastPayouts :many
SELECT DISTINCT ON (driver_id, currency) driver_id, currency, created_at
FROM driver_payouts
ORDER BY driver_id, currency, created_at DESC;
