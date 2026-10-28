# Contrato de tiempo real (Centrifugo)

El cliente obtiene un token de conexión con `POST /v1/realtime/token` y tokens de suscripción
con `POST /v1/realtime/subscription-token`. El backend autoriza cada canal. Todos los eventos
son JSON con `type`, `occurred_at` (RFC 3339) y `data`. Los canales guardan historial corto para
recuperar eventos tras reconectar.

## Canales

| Canal | Suscriptores | Eventos |
|---|---|---|
| `user:{userId}` | Solo ese usuario | Ofertas y cambios de sus viajes |
| `driver_presence:{driverId}` | Pasajeros afiliados a ese conductor | `driver.presence` |
| `trip:{tripId}` | Pasajero y conductor del viaje | `trip.location` |
| `ops:sos` | Administradores con permiso de operador de emergencias (003) | `sos.*` de la cola |
| `sos:{alertId}` | Administradores con permiso de operador de emergencias (003) | `sos.location` |

## Eventos

| type | Canal | data | Requisito |
|---|---|---|---|
| `trip.offer` | `user:{driverId}` | `trip_id`, `passenger_name`, `pickup`, `dropoff`, `distance_m`, `duration_s`, `suggested_fare_minor`, `currency`, `expires_at` | FR-011 |
| `trip.offer_closed` | `user:{driverId}` | `trip_id`, `reason` | FR-011, cancelación del pasajero |
| `trip.status` | `user:{passengerId}` y `user:{driverId}` | `trip_id`, `status`, `agreed_fare_minor?`, `cancel_reason?`, `driver?` (nombre, vehículo) | FR-013 |
| `trip.fare_proposal` | `user:{otherPartyId}` | `trip_id`, `proposal_id`, `proposed_by`, `amount_minor`, `expires_at` | FR-010a, FR-010c |
| `trip.negotiation_requested` | `user:{passengerId}` | `trip_id`, `expires_at` | FR-010c |
| `trip.location` | `trip:{tripId}` | `lat`, `lng`, `heading`, `speed_mps` | FR-014 |
| `driver.presence` | `driver_presence:{driverId}` | `driver_id`, `presence`, `busy_until_estimate?` | FR-008 |
| `ptt.closed` | `user:{passengerId}` y `user:{driverId}` | `trip_id` | FR-020 |
| `sos.created` | `ops:sos` | `alert_id`, `trip_id`, `raised_role`, `raised_by_name`, `created_at`, `location?` | 003 FR-007 |
| `sos.claimed` | `ops:sos` | `alert_id`, `operator_id`, `operator_name` | 003 FR-008 |
| `sos.released` | `ops:sos` | `alert_id` | 003 FR-008 |
| `sos.cancel_attempt` | `ops:sos` | `alert_id`, `cancel_without_pin`, `failed_attempts`, `locked` | 003 FR-005 |
| `sos.escalated` | `ops:sos` | `alert_id` | 003 FR-011 |
| `sos.closed` | `ops:sos` (y `user:{raisedBy}` al cerrarla el operador) | `alert_id`, `status`, `outcome?` | 003 FR-010 |
| `sos.location` | `sos:{alertId}` | `alert_id`, `lat`, `lng`, `accuracy_m`, `at` | 003 FR-003 |

Los eventos SOS nunca van a `trip:{tripId}` ni al canal de la otra parte del viaje (003 FR-006).

Los eventos de turno PTT (quién habla) viajan como mensajes de datos de LiveKit dentro de la sala
del viaje: `{"type":"floor.taken","user_id":...}` y `{"type":"floor.released"}`.
