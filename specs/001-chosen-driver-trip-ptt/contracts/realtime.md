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
| `preconsult.opened` | `user:{driverId}` | `preconsult_id`, `passenger_id`, `passenger_name`, `join_deadline`, `closes_at` | 005 FR-005 |
| `preconsult.joined` | `user:{passengerId}` | `preconsult_id` | 005 FR-005 |
| `preconsult.closed` | `user:{passengerId}` y `user:{driverId}` | `preconsult_id`, `reason` | 005 FR-006 |

Los eventos de turno PTT (quién habla) viajan como mensajes de datos de LiveKit dentro de la sala
del viaje (y de la pre-consulta de 005): `{"type":"floor.taken","user_id":...}` y `{"type":"floor.released"}`.
