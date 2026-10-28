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
| voice_holder_id | uuid FK users NULL | Operador al que LiveKit pudo conceder hablar; se borra solo cuando LiveKit confirma la retirada (fail-closed, como el turno PTT) |
| created_at, claimed_at, closed_at | timestamptz | `claimed_by` se conserva al cerrar (quién atendió) |
| voice_closed_at | timestamptz NULL | Sala borrada y grabación detenida; el barrido reintenta mientras sea NULL |

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

| id | alert_id | operator_id | body (1–2000) | created_at |
|---|---|---|---|---|

## sos_audit

Cada acceso y acción de un operador en la consola (FR-012): `operator_id`, `alert_id` (NULL para
la cola o la guardia), `action` (`list_open`, `list_history`, `view`, `claim`, `release`, `note`,
`close:{desenlace}`, `listen`, `duty_on`, `duty_off`) y `created_at`.

## share_links

| Campo | Tipo | Reglas |
|---|---|---|
| token | text PK | 128 bits aleatorios, base64url |
| trip_id | uuid FK | |
| created_by | uuid FK users | |
| created_at | timestamptz | Vigente hasta 15 min tras COMPLETED/CANCELLED |

Único por `(trip_id, created_by)`: compartir otra vez devuelve el mismo enlace.

## emergency_contacts

| user_id | position (1–3) | name | phone_e164 | created_at |
|---|---|---|---|---|

PK `(user_id, position)`: máximo 3 por usuario (también comprobado en el servicio).

## safety_pins

| Campo | Tipo | Reglas |
|---|---|---|
| user_id | uuid PK | |
| pin_hash | text | bcrypt |
| failed_attempts | smallint | Bloqueo a 5 durante una alerta |

## emergency_operators

| user_id (PK, FK users) | on_duty | granted_at |
|---|---|---|

Permiso de operador de emergencias de un administrador y su guardia. Implementado como tabla
aparte en vez de las columnas `users.emergency_operator` / `users.on_duty` previstas, para no
cambiar las consultas de usuarios de 001 (sqlc generaba tipos nuevos para todas ellas).
