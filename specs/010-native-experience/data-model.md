# Data Model: Experiencia nativa

Migración `backend/migrations/00015_native_experience.sql`.

## reservations (FR-001–FR-006)

| Columna | Tipo | Notas |
|---|---|---|
| id | uuid PK | |
| passenger_id | uuid FK users | |
| driver_id | uuid FK drivers | debe ser su Conductor Elegido al reservar |
| pickup_lat, pickup_lng, dropoff_lat, dropoff_lng | double | |
| pickup_label, dropoff_label | text NULL | dirección elegida en el buscador |
| scheduled_at | timestamptz | entre 30 min y 7 días al reservar |
| distance_m, duration_s | integer | de la cotización |
| currency | char(3) | |
| fare_minor | bigint | tarifa reservada (con la preferencial de 008 si aplica) |
| list_fare_minor | bigint | |
| preferential_discount_pct | smallint | |
| status | reservation_status | `pending`, `confirmed`, `rejected`, `cancelled`, `expired`, `fulfilled`, `missed` |
| cancelled_by | uuid NULL | quién canceló |
| reminded_at | timestamptz NULL | recordatorio de 30 min enviado |
| trip_id | uuid NULL FK trips | viaje creado a la hora |
| created_at, updated_at | timestamptz | |

Índices: `(passenger_id, scheduled_at)`, `(driver_id, scheduled_at)`, `(status, scheduled_at)`.

**Transiciones**: `pending → confirmed | rejected` (conductor), `pending → expired` (barrido,
15 min antes), `pending|confirmed → cancelled` (cualquiera de las partes antes de la hora o al
quitar la afiliación), `confirmed → fulfilled` (viaje creado), `confirmed → missed` (conductor no
libre a la hora) o `confirmed → expired` (el pasajero siguió con otro viaje 30 min después).

## client_notes (FR-008, FR-009)

| Columna | Tipo | Notas |
|---|---|---|
| driver_id | uuid FK drivers | PK compuesta |
| passenger_id | uuid FK users | PK compuesta |
| body | text | 1–500 caracteres |
| updated_at | timestamptz | |

## trips (FR-010)

`near_pickup_since timestamptz NULL`: primera ubicación precisa a < 60 m de la recogida de la
racha actual.

## Vistas

- `ChosenDriver.zone`: `{cell, lat, lng}` del hexágono de res. 8, solo si está libre y con
  ubicación de ≤ 5 min.
- `trip.offer`: `reservation` (bool) y `client_note` (string|null, solo al conductor).
- `POST /v1/driver/location`: `accuracy_m` opcional.
