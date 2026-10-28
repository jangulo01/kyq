# Data Model: Alta autónoma, KYC y suscripción con Bold

Extiende el modelo de 001. Importes en unidades mínimas de moneda (`bigint`), fechas `timestamptz`.

## drivers (cambios)

| Campo | Tipo | Reglas |
|---|---|---|
| vehicle_brand, vehicle_model, vehicle_color | text NULL | Obligatorios para enviar documentos (FR-002) |
| vehicle_year | smallint NULL | 1990–año actual + 1 |
| onboarding_status | derivado | `profile_incomplete` (sin vehículo) → `documents_pending` → `in_review` → `documents_ok` |

`vehicle_description` de 001 se mantiene como texto mostrado (marca + modelo + color).

## driver_documents (reemplaza la tabla de 001)

| Campo | Tipo | Reglas |
|---|---|---|
| id | uuid PK | |
| driver_id | uuid FK drivers | |
| doc_type | enum `national_id` \| `license` \| `mandatory_insurance` \| `technical_inspection` \| `vehicle_registration` | |
| number | text | Declarado por el conductor; el admin puede corregirlo |
| expires_at | date NULL | Obligatorio salvo `national_id` y `vehicle_registration` |
| exempt_until | date NULL | Solo `technical_inspection` (vehículo nuevo) |
| status | enum `uploading` \| `submitted` \| `approved` \| `rejected` \| `superseded` | |
| reject_reason | text NULL | Obligatorio si `rejected` |
| legacy | boolean | Migrado de 001 o marcador de la migración: sin fotos (research R7) |
| created_at | timestamptz | |
| submitted_at | timestamptz NULL | |
| reviewed_by | uuid FK users NULL | |
| reviewed_at | timestamptz NULL | |

Las fotos confirmadas se cuentan en `document_photos.uploaded_at` (no hay columna `photos`).
Índices únicos parciales: un `approved` y un envío en curso (`uploading`/`submitted`) por tipo.

Transiciones: `uploading → submitted` (todas las fotos confirmadas); `submitted → approved |
rejected` (admin); `approved → superseded` cuando se aprueba otro del mismo tipo. Vigente = último
`approved` del tipo con `expires_at > hoy` (o exento). Migración: los documentos de 001 pasan a
`approved` con sus fechas; cédula y revisión técnico-mecánica se crean como marcadores `legacy`
(research R7).

## document_photos

| Campo | Tipo | Reglas |
|---|---|---|
| document_id | uuid FK driver_documents | |
| side | enum `front` \| `back` | |
| object_key | text | `kyc/{driverId}/{docId}/{side}.jpg` en bucket privado |
| uploaded_at | timestamptz NULL | Al confirmar la subida |

PK (document_id, side).

## subscription_prices

| Campo | Tipo | Reglas |
|---|---|---|
| city_code | text FK fare_tables | |
| currency | char(3) | |
| amount_minor | bigint > 0 | |
| effective_from | timestamptz | El vigente es el último ≤ ahora |
| created_by | uuid FK users | |

PK (city_code, effective_from).

## payments

| Campo | Tipo | Reglas |
|---|---|---|
| id | uuid PK | También es `reference` en Bold |
| driver_id | uuid FK drivers | |
| amount_minor, currency | bigint, char(3) | Precio vigente al crear |
| method | enum `bold` \| `manual` | |
| status | enum `created` \| `processing` \| `approved` \| `rejected` \| `expired` \| `voided` \| `needs_review` | |
| bold_link_id | text UNIQUE NULL | `LNK_*` |
| checkout_url | text NULL | |
| bold_payment_id | text NULL | Del webhook (`data.payment_id`) |
| payment_method_detail | text NULL | CREDIT_CARD, PSE, NEQUI… |
| manual_reference | text NULL | Pago manual |
| covers_from, covers_until | timestamptz NULL | Periodo extendido al aprobarse |
| prev_paid_until | timestamptz NULL | Vencimiento anterior, para deshacer al anular (R3) |
| review_note | text NULL | Por qué quedó en `needs_review` (importe o moneda distintos) |
| created_by | uuid FK users | Conductor o admin |
| voided_by, void_reason | uuid NULL, text NULL | |
| created_at, updated_at | timestamptz | |

Solo `approved` extiende `subscriptions.paid_until` (R3). Índice parcial de pagos en curso para el
sondeo.

## subscriptions (cambios)

`updated_by` pasa a NULL (lo actualiza un pago). Estado derivado sin cambios (ACTIVE / GRACE /
SUSPENDED; 001).

## notices

| Campo | Tipo | Reglas |
|---|---|---|
| id | uuid PK | |
| driver_id | uuid FK drivers | |
| kind | text | `doc_expiring`, `doc_expired`, `doc_rejected`, `doc_approved`, `sub_expiring`, `sub_grace`, `payment_approved`, `payment_rejected` |
| dedup_key | text | p. ej. `doc_expiring:{docId}:3` |
| title, body | text | Español, sin datos sensibles |
| sms | boolean | Envía SMS además del aviso en app |
| created_at, sms_sent_at, read_at | timestamptz | |

UNIQUE (driver_id, dedup_key).

## cost_rates

| Campo | Tipo | Reglas |
|---|---|---|
| concept | enum `voice_minute` \| `realtime_event` \| `route_request` \| `fixed_monthly` | |
| currency | char(3) | |
| unit_cost_micro | bigint ≥ 0 | Millonésimas de unidad mínima (costos por evento son fracciones) |
| effective_from | date | |
| created_by | uuid FK users NULL | |

PK (concept, currency, effective_from).
