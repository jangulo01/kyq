-- name: GetDriverProfile :one
SELECT d.user_id, d.qr_token, d.presence, s.paid_until
FROM drivers d
LEFT JOIN subscriptions s ON s.driver_id = d.user_id
WHERE d.user_id = $1;
