# Data Model: SOS y consola de emergencias

## sos_alerts

| Campo | Tipo | Reglas |
|---|---|---|
| id | uuid PK | |
| trip_id | uuid FK trips | |
| raised_by | uuid FK users | Pasajero o conductor del viaje |
| raised_role | enum `passenger` \| `driver` | |
| status | enum `open` \| `claimed` \| `closed` \| `cancelled_by_user` | |
| cancel_without_pin | boolean | Intento de cancelar sin PIN válido (FR-005) |
| claimed_by | uuid FK users NULL | Operador |
| outcome | enum `false_alarm` \| `resolved` \| `escalated_authorities` \| `no_response` NULL | Obligatorio al cerrar |
| room_name | text UNIQUE | `sos-{id}` |
| egress_id | text NULL | Grabación LiveKit |
| recording_key | text NULL | Objeto en `kyq-sos` |
| escalated_at | timestamptz NULL | SMS a guardia a los 60 s sin tomar |
| created_at, claimed_at, closed_at | timestamptz | |

Una alerta abierta por persona y viaje (índice único parcial).

## sos_locations

| Campo | Tipo | Reglas |
|---|---|---|
| alert_id | uuid FK | |
| at | timestamptz | |
| lat, lng | double precision | |
| accuracy_m | real NULL | |

PK (alert_id, at).

## sos_notes

| alert_id | operator_id | body | created_at |
|---|---|---|---|

## share_links

| Campo | Tipo | Reglas |
|---|---|---|
| token | text PK | 128 bits aleatorios, base64url |
| trip_id | uuid FK | |
| created_by | uuid FK users | |
| created_at | timestamptz | Vigente hasta 15 min tras COMPLETED/CANCELLED |

## emergency_contacts

| user_id | name | phone_e164 | created_at |
|---|---|---|---|

Máximo 3 por usuario (comprobado en el servicio).

## safety_pins

| Campo | Tipo | Reglas |
|---|---|---|
| user_id | uuid PK | |
| pin_hash | text | bcrypt |
| failed_attempts | smallint | Bloqueo a 5 durante una alerta |

## users (cambios)

`emergency_operator boolean`, `on_duty boolean` (solo administradores).
