-- +goose Up
-- 002: alta autónoma, documentos con versiones (KYC), pagos con Bold, avisos y tarifas de costo.

ALTER TABLE drivers
    ADD COLUMN vehicle_brand text CHECK (vehicle_brand IS NULL OR char_length(vehicle_brand) BETWEEN 1 AND 40),
    ADD COLUMN vehicle_model text CHECK (vehicle_model IS NULL OR char_length(vehicle_model) BETWEEN 1 AND 40),
    ADD COLUMN vehicle_color text CHECK (vehicle_color IS NULL OR char_length(vehicle_color) BETWEEN 1 AND 30),
    ADD COLUMN vehicle_year  smallint CHECK (vehicle_year IS NULL OR vehicle_year >= 1990);

-- La tabla de 001 tenía una fila por tipo; 002 guarda versiones. Se crea un tipo nuevo (no ALTER
-- TYPE ... ADD VALUE) porque los valores añadidos no se pueden usar en la misma transacción.
ALTER TABLE driver_documents RENAME TO driver_documents_001;
ALTER INDEX driver_documents_pkey RENAME TO driver_documents_001_pkey;
ALTER INDEX driver_documents_driver_id_doc_type_key RENAME TO driver_documents_001_driver_id_doc_type_key;
ALTER TYPE driver_doc_type RENAME TO driver_doc_type_001;

CREATE TYPE driver_doc_type AS ENUM (
    'national_id', 'license', 'mandatory_insurance', 'technical_inspection', 'vehicle_registration'
);
CREATE TYPE document_status AS ENUM ('uploading', 'submitted', 'approved', 'rejected', 'superseded');

CREATE TABLE driver_documents (
    id            uuid PRIMARY KEY,
    driver_id     uuid NOT NULL REFERENCES drivers (user_id) ON DELETE CASCADE,
    doc_type      driver_doc_type NOT NULL,
    number        text NOT NULL DEFAULT '' CHECK (char_length(number) <= 40),
    expires_at    date,
    exempt_until  date CHECK (exempt_until IS NULL OR doc_type = 'technical_inspection'),
    status        document_status NOT NULL,
    reject_reason text,
    -- Migrado de 001 o marcador creado por esta migración: sin fotos; el conductor debe subir
    -- el documento real (research R7).
    legacy        boolean NOT NULL DEFAULT false,
    created_at    timestamptz NOT NULL DEFAULT now(),
    submitted_at  timestamptz,
    reviewed_by   uuid REFERENCES users (id),
    reviewed_at   timestamptz,
    CHECK (status <> 'rejected' OR coalesce(btrim(reject_reason), '') <> ''),
    CHECK (status <> 'approved' OR doc_type IN ('national_id', 'vehicle_registration')
           OR expires_at IS NOT NULL OR exempt_until IS NOT NULL)
);

-- Un solo documento vigente (aprobado) y un solo envío en curso por tipo.
CREATE UNIQUE INDEX driver_documents_one_approved ON driver_documents (driver_id, doc_type)
    WHERE status = 'approved';
CREATE UNIQUE INDEX driver_documents_one_in_flight ON driver_documents (driver_id, doc_type)
    WHERE status IN ('uploading', 'submitted');
CREATE INDEX driver_documents_review_queue ON driver_documents (submitted_at) WHERE status = 'submitted';

INSERT INTO driver_documents (id, driver_id, doc_type, number, expires_at, status, legacy,
                              created_at, submitted_at, reviewed_by, reviewed_at)
SELECT id, driver_id, doc_type::text::driver_doc_type, '', expires_at,
       CASE WHEN approved_by IS NOT NULL THEN 'approved' ELSE 'submitted' END::document_status,
       true, coalesce(approved_at, now()), coalesce(approved_at, now()), approved_by, approved_at
FROM driver_documents_001;

-- Conductores de 001 ya revisados por un administrador: los dos tipos nuevos se crean aprobados
-- como marcadores para que sigan trabajando. La cédula no vence; la revisión técnico-mecánica
-- queda exenta 60 días, plazo para subir la real (research R7).
INSERT INTO driver_documents (id, driver_id, doc_type, status, legacy, exempt_until, submitted_at, reviewed_at)
SELECT gen_random_uuid(), d.driver_id, t.doc_type, 'approved', true,
       CASE WHEN t.doc_type = 'technical_inspection' THEN (now() + interval '60 days')::date END,
       now(), now()
FROM (SELECT DISTINCT driver_id FROM driver_documents_001 WHERE approved_by IS NOT NULL) d
CROSS JOIN (VALUES ('national_id'::driver_doc_type), ('technical_inspection'::driver_doc_type)) AS t (doc_type);

DROP TABLE driver_documents_001;
DROP TYPE driver_doc_type_001;

CREATE TYPE document_side AS ENUM ('front', 'back');

CREATE TABLE document_photos (
    document_id uuid NOT NULL REFERENCES driver_documents (id) ON DELETE CASCADE,
    side        document_side NOT NULL,
    -- kyc/{driverId}/{docId}/{side}.jpg: sin datos personales en la clave.
    object_key  text NOT NULL,
    uploaded_at timestamptz,
    PRIMARY KEY (document_id, side)
);

CREATE TABLE subscription_prices (
    city_code      text NOT NULL REFERENCES fare_tables (city_code),
    currency       char(3) NOT NULL,
    amount_minor   bigint NOT NULL CHECK (amount_minor > 0),
    effective_from timestamptz NOT NULL,
    created_by     uuid NOT NULL REFERENCES users (id),
    created_at     timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (city_code, effective_from)
);

ALTER TABLE subscriptions ALTER COLUMN updated_by DROP NOT NULL;

CREATE TYPE payment_method AS ENUM ('bold', 'manual');
CREATE TYPE payment_status AS ENUM (
    'created', 'processing', 'approved', 'rejected', 'expired', 'voided', 'needs_review'
);

CREATE TABLE payments (
    id                    uuid PRIMARY KEY, -- también es la referencia en Bold
    driver_id             uuid NOT NULL REFERENCES drivers (user_id) ON DELETE CASCADE,
    amount_minor          bigint NOT NULL CHECK (amount_minor > 0),
    currency              char(3) NOT NULL,
    method                payment_method NOT NULL,
    status                payment_status NOT NULL,
    bold_link_id          text UNIQUE,
    checkout_url          text,
    bold_payment_id       text,
    payment_method_detail text,
    manual_reference      text,
    review_note           text,
    -- Periodo extendido al aprobarse y vencimiento anterior, para deshacerlo al anular.
    covers_from           timestamptz,
    covers_until          timestamptz,
    prev_paid_until       timestamptz,
    created_by            uuid NOT NULL REFERENCES users (id),
    voided_by             uuid REFERENCES users (id),
    void_reason           text,
    created_at            timestamptz NOT NULL DEFAULT now(),
    updated_at            timestamptz NOT NULL DEFAULT now(),
    CHECK (status <> 'voided' OR coalesce(btrim(void_reason), '') <> ''),
    CHECK (status NOT IN ('approved', 'voided') OR (covers_from IS NOT NULL AND covers_until IS NOT NULL))
);

CREATE INDEX payments_driver_idx ON payments (driver_id, created_at DESC);
-- Sondeo de pagos en curso (research R2) y un solo pago en curso por conductor.
CREATE INDEX payments_in_flight_idx ON payments (created_at) WHERE status IN ('created', 'processing');
CREATE UNIQUE INDEX payments_one_in_flight ON payments (driver_id) WHERE status IN ('created', 'processing');

CREATE TABLE notices (
    id          uuid PRIMARY KEY,
    driver_id   uuid NOT NULL REFERENCES drivers (user_id) ON DELETE CASCADE,
    kind        text NOT NULL,
    dedup_key   text NOT NULL,
    title       text NOT NULL,
    body        text NOT NULL,
    sms         boolean NOT NULL DEFAULT false,
    created_at  timestamptz NOT NULL DEFAULT now(),
    sms_sent_at timestamptz,
    read_at     timestamptz,
    UNIQUE (driver_id, dedup_key)
);

CREATE INDEX notices_driver_idx ON notices (driver_id, created_at DESC);
CREATE INDEX notices_sms_pending_idx ON notices (created_at) WHERE sms AND sms_sent_at IS NULL;

INSERT INTO notices (id, driver_id, kind, dedup_key, title, body)
SELECT gen_random_uuid(), driver_id, 'doc_legacy', 'doc_legacy:002', 'Completa tus documentos',
       'Sube la foto de tu cédula y de tu revisión técnico-mecánica desde Documentos. Tienes 60 días; '
           || 'mientras tanto puedes seguir trabajando.'
FROM driver_documents WHERE legacy AND doc_type = 'technical_inspection';

CREATE TYPE cost_concept AS ENUM ('voice_minute', 'realtime_event', 'route_request', 'fixed_monthly');

CREATE TABLE cost_rates (
    concept         cost_concept NOT NULL,
    currency        char(3) NOT NULL,
    -- Millonésimas de unidad mínima: un evento cuesta fracciones de centavo.
    unit_cost_micro bigint NOT NULL CHECK (unit_cost_micro >= 0),
    effective_from  date NOT NULL,
    created_by      uuid REFERENCES users (id),
    created_at      timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (concept, currency, effective_from)
);

-- +goose Down
DROP TABLE cost_rates;
DROP TYPE cost_concept;
DROP TABLE notices;
DROP TABLE payments;
DROP TYPE payment_status;
DROP TYPE payment_method;
UPDATE subscriptions SET updated_by = (SELECT id FROM users WHERE role = 'admin' ORDER BY created_at LIMIT 1)
WHERE updated_by IS NULL;
ALTER TABLE subscriptions ALTER COLUMN updated_by SET NOT NULL;
DROP TABLE subscription_prices;
DROP TABLE document_photos;
DROP TYPE document_side;

CREATE TYPE driver_doc_type_001 AS ENUM ('license', 'mandatory_insurance', 'vehicle_registration');
CREATE TABLE driver_documents_001 (
    id          uuid PRIMARY KEY,
    driver_id   uuid NOT NULL REFERENCES drivers (user_id) ON DELETE CASCADE,
    doc_type    driver_doc_type_001 NOT NULL,
    expires_at  date NOT NULL,
    approved_by uuid REFERENCES users (id),
    approved_at timestamptz,
    UNIQUE (driver_id, doc_type)
);
INSERT INTO driver_documents_001 (id, driver_id, doc_type, expires_at, approved_by, approved_at)
SELECT id, driver_id, doc_type::text::driver_doc_type_001, expires_at, reviewed_by, reviewed_at
FROM driver_documents
WHERE status = 'approved' AND expires_at IS NOT NULL
  AND doc_type IN ('license', 'mandatory_insurance', 'vehicle_registration');
DROP TABLE driver_documents;
DROP TYPE document_status;
DROP TYPE driver_doc_type;
ALTER TABLE driver_documents_001 RENAME TO driver_documents;
ALTER TYPE driver_doc_type_001 RENAME TO driver_doc_type;

ALTER TABLE drivers
    DROP COLUMN vehicle_year,
    DROP COLUMN vehicle_color,
    DROP COLUMN vehicle_model,
    DROP COLUMN vehicle_brand;
