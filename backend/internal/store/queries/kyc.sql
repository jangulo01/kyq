-- name: SetDriverVehicle :exec
UPDATE drivers
SET vehicle_plate = $2, vehicle_brand = $3, vehicle_model = $4, vehicle_color = $5, vehicle_year = $6,
    vehicle_description = $7
WHERE user_id = $1;

-- name: GetDriverOnboardingProfile :one
SELECT d.user_id, u.display_name, d.vehicle_plate, d.vehicle_description, d.vehicle_brand, d.vehicle_model,
       d.vehicle_color, d.vehicle_year, s.paid_until
FROM drivers d
JOIN users u ON u.id = d.user_id
LEFT JOIN subscriptions s ON s.driver_id = d.user_id
WHERE d.user_id = $1;

-- name: ListDriverDocuments :many
SELECT id, driver_id, doc_type, number, expires_at, exempt_until, status, reject_reason, legacy, created_at,
       submitted_at, reviewed_by, reviewed_at
FROM driver_documents
WHERE driver_id = $1
ORDER BY created_at DESC, id DESC;

-- name: InsertDocument :one
INSERT INTO driver_documents (id, driver_id, doc_type, number, expires_at, exempt_until, status, submitted_at,
                              reviewed_by, reviewed_at)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
RETURNING id, driver_id, doc_type, number, expires_at, exempt_until, status, reject_reason, legacy, created_at,
          submitted_at, reviewed_by, reviewed_at;

-- name: GetInFlightDocument :one
SELECT id, status
FROM driver_documents
WHERE driver_id = $1 AND doc_type = $2 AND status IN ('uploading', 'submitted');

-- name: DeleteDocument :exec
DELETE FROM driver_documents WHERE id = $1;

-- name: GetDocumentForUpdate :one
SELECT id, driver_id, doc_type, number, expires_at, exempt_until, status, reject_reason, legacy, created_at,
       submitted_at, reviewed_by, reviewed_at
FROM driver_documents
WHERE id = $1
FOR UPDATE;

-- name: InsertDocumentPhoto :exec
INSERT INTO document_photos (document_id, side, object_key)
VALUES ($1, $2, $3);

-- name: ListDocumentPhotos :many
SELECT document_id, side, object_key, uploaded_at
FROM document_photos
WHERE document_id = ANY (sqlc.arg(document_ids)::uuid[])
ORDER BY document_id, side;

-- name: MarkPhotoUploaded :exec
UPDATE document_photos SET uploaded_at = $3 WHERE document_id = $1 AND side = $2;

-- name: SubmitDocument :exec
UPDATE driver_documents SET status = 'submitted', submitted_at = $2 WHERE id = $1;

-- name: SupersedeApprovedDocument :exec
UPDATE driver_documents SET status = 'superseded'
WHERE driver_id = $1 AND doc_type = $2 AND status = 'approved';

-- name: ApproveDocument :exec
UPDATE driver_documents
SET status = 'approved', number = $2, expires_at = $3, exempt_until = $4, reviewed_by = $5, reviewed_at = $6,
    reject_reason = NULL
WHERE id = $1;

-- name: RejectDocument :exec
UPDATE driver_documents
SET status = 'rejected', reject_reason = $2, reviewed_by = $3, reviewed_at = $4
WHERE id = $1;

-- name: CountRejectedDocuments :one
SELECT count(*) FROM driver_documents WHERE driver_id = $1 AND doc_type = $2 AND status = 'rejected';

-- name: ListKYCQueue :many
SELECT d.user_id AS driver_id, u.display_name, d.vehicle_plate,
       count(*)::bigint AS pending_documents,
       min(dd.submitted_at)::timestamptz AS oldest_submitted_at
FROM driver_documents dd
JOIN drivers d ON d.user_id = dd.driver_id
JOIN users u ON u.id = d.user_id
WHERE dd.status = 'submitted'
GROUP BY d.user_id, u.display_name, d.vehicle_plate
ORDER BY oldest_submitted_at, d.user_id;

-- name: GetDriverForKYC :one
SELECT d.user_id, u.display_name, u.phone_e164, d.vehicle_plate, d.vehicle_description, d.vehicle_brand,
       d.vehicle_model, d.vehicle_color, d.vehicle_year
FROM drivers d
JOIN users u ON u.id = d.user_id
WHERE d.user_id = $1;

-- name: ListDocumentsDue :many
-- Aprobados que vencen entre since y until sin un reemplazo en revisión (avisos 15/3/0 días).
SELECT dd.id, dd.driver_id, dd.doc_type, coalesce(dd.expires_at, dd.exempt_until)::date AS due
FROM driver_documents dd
WHERE dd.status = 'approved'
  AND coalesce(dd.expires_at, dd.exempt_until) BETWEEN sqlc.arg(since)::date AND sqlc.arg(until)::date
  AND NOT EXISTS (SELECT 1 FROM driver_documents n
                  WHERE n.driver_id = dd.driver_id AND n.doc_type = dd.doc_type AND n.status = 'submitted')
ORDER BY due, dd.id;
