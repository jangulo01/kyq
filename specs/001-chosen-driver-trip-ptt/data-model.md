# Data Model: MVP Conductor Elegido + Viaje + PTT 1 a 1

PostgreSQL 17 + PostGIS. Identificadores UUID v7. Importes en unidades mínimas de moneda
(`BIGINT`) con código ISO 4217 en la tabla de tarifas. Fechas en `timestamptz` (UTC).

## users

| Campo | Tipo | Reglas |
|---|---|---|
| id | uuid PK | |
| phone_e164 | text UNIQUE | Verificado por OTP (FR-001) |
| role | enum `passenger` \| `driver` \| `admin` | Un teléfono, un rol en el MVP |
| display_name | text | 2–60 caracteres |
| created_at | timestamptz | |

## drivers

| Campo | Tipo | Reglas |
|---|---|---|
| user_id | uuid PK FK users | role = driver |
| qr_token | text UNIQUE | Aleatorio 128 bits, rotable por admin (FR-005) |
| vehicle_plate | text | |
| vehicle_description | text | Marca, modelo, color |
| presence | enum `offline` \| `free` \| `busy` | Ver transiciones |
| last_location | geography(Point) | Actualizada cada 3 s ONLINE |
| last_location_at | timestamptz | |
| busy_until_estimate | timestamptz NULL | Solo con presence = busy (FR-008) |

**Presencia**: `offline → free` solo si pasa `evaluateOnline` (FR-002);
`free → busy` al aceptar oferta; `busy → free` al COMPLETED/CANCELLED;
`free|busy → offline` por el conductor, salvo con viaje activo (RN-KYQ-003).

## subscriptions

| Campo | Tipo | Reglas |
|---|---|---|
| driver_id | uuid PK FK drivers | Una vigente por conductor |
| paid_until | timestamptz | Registrado por admin (FR-004) |
| updated_by | uuid FK users | admin |

Estado derivado: ACTIVE si `now < paid_until`; GRACE_PERIOD si `now < paid_until + 72h`;
si no, SUSPENDED (RN-KYQ-002, RN-KYQ-003).

## driver_documents

| Campo | Tipo | Reglas |
|---|---|---|
| id | uuid PK | |
| driver_id | uuid FK drivers | |
| doc_type | enum `license` \| `mandatory_insurance` \| `vehicle_registration` | Los tres obligatorios |
| expires_at | date | |
| approved_by | uuid FK users NULL | Sin aprobar = no cuenta como vigente |

Bloqueo RN-KYQ-016: falta un tipo, no está aprobado o `expires_at <= hoy`.

## affiliations

| Campo | Tipo | Reglas |
|---|---|---|
| passenger_id | uuid FK users | PK compuesta |
| driver_id | uuid FK drivers | PK compuesta (sin duplicados, FR-006) |
| source | enum `qr_scan` | |
| created_at | timestamptz | |
| removed_at | timestamptz NULL | Borrado lógico; re-escanear lo reactiva |

## fare_tables

| Campo | Tipo | Reglas |
|---|---|---|
| city_code | text PK | Una ciudad en el MVP |
| currency | char(3) | ISO 4217 |
| base_minor | bigint | ≥ 0 |
| per_km_minor | bigint | ≥ 0 |
| per_minute_minor | bigint | ≥ 0 |
| minimum_minor | bigint | ≥ 0 |
| updated_by | uuid FK users | admin (FR-010b) |

Tarifa sugerida = `max(minimum, base + per_km × km + per_minute × min)`, redondeada a la unidad
de cobro habitual de la ciudad.

## trips

| Campo | Tipo | Reglas |
|---|---|---|
| id | uuid PK | |
| passenger_id | uuid FK users | |
| driver_id | uuid FK drivers | Debe estar afiliado y `free` al solicitar |
| city_code | text FK fare_tables | |
| pickup | geography(Point) | |
| dropoff | geography(Point) | |
| route_distance_m | int | De OSRM |
| route_duration_s | int | De OSRM |
| suggested_fare_minor | bigint | FR-010 |
| agreed_fare_minor | bigint NULL | Fijada al pasar a ACCEPTED |
| driver_payout_minor | bigint NULL | = agreed_fare_minor (RN-KYQ-001) |
| platform_commission_minor | bigint | Siempre 0, CHECK (RN-KYQ-001) |
| status | enum | Ver máquina de estados |
| cancel_reason | enum NULL | `passenger`, `driver`, `offer_expired`, `offer_rejected`, `fare_rejected`, `negotiation_failed` |
| created_at, accepted_at, arrived_at, started_at, completed_at, cancelled_at | timestamptz NULL | |

**Máquina de estados**:

```text
REQUESTED ──accept(sugerida)──────────────▶ ACCEPTED
REQUESTED ──accept(otra tarifa)──▶ FARE_PENDING ──pasajero confirma──▶ ACCEPTED
REQUESTED ──negociar──▶ NEGOTIATION_PENDING ──pasajero acepta──▶ NEGOTIATING ──acuerdo──▶ ACCEPTED
                         NEGOTIATION_PENDING ──pasajero rechaza──▶ REQUESTED (tarifa sugerida)
ACCEPTED ──▶ ARRIVED ──▶ IN_PROGRESS ──▶ COMPLETED
REQUESTED | FARE_PENDING | NEGOTIATION_PENDING | NEGOTIATING | ACCEPTED | ARRIVED ──▶ CANCELLED
```

- REQUESTED vence a los 25 s sin respuesta (RN-KYQ-007). Al volver de NEGOTIATION_PENDING, el
  conductor tiene de nuevo 25 s.
- FARE_PENDING vence a los 30 s (FR-010a).
- NEGOTIATING: cada propuesta vence a los 30 s; la negociación completa a los 3 min (FR-010c).
- Restricción: un conductor tiene como máximo un viaje en estados distintos de COMPLETED y
  CANCELLED (índice único parcial, FR-012).

## fare_proposals

| Campo | Tipo | Reglas |
|---|---|---|
| id | uuid PK | |
| trip_id | uuid FK trips | |
| proposed_by | enum `driver` \| `passenger` | |
| amount_minor | bigint | > 0 |
| status | enum `open` \| `accepted` \| `superseded` \| `expired` | Solo una `open` por viaje |
| created_at, expires_at | timestamptz | `expires_at = created_at + 30 s` |

Usada por FR-010a (una propuesta del conductor) y FR-010c (intercambio).

## ptt_channels

| Campo | Tipo | Reglas |
|---|---|---|
| trip_id | uuid PK FK trips | Uno por viaje |
| room_name | text UNIQUE | `trip-{tripId}` |
| opened_at | timestamptz | Al pasar a ACCEPTED (RN-KYQ-009) |
| closes_at | timestamptz NULL | `completed_at + 15 min` o `cancelled_at` (RN-KYQ-014) |
| closed_at | timestamptz NULL | Al ejecutar el cierre |
| floor_holder_id | uuid FK users NULL | Turno actual (FR-017) |
| floor_expires_at | timestamptz NULL | Máx. 60 s por turno |

Los mensajes de voz no se almacenan (FR-021).

## refresh_tokens

| Campo | Tipo | Reglas |
|---|---|---|
| id | uuid PK | |
| user_id | uuid FK users | |
| token_hash | bytea UNIQUE | Solo el hash |
| expires_at | timestamptz | 30 días |
| rotated_at | timestamptz NULL | Rotación en cada uso |
