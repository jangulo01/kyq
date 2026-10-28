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
| `trip.delegated` | `user:{passengerId}` | `trip_id`, `cooperative_id`, `cooperative_name`, `reason` (`offer_rejected` \| `offer_expired` \| `delegated`), `expires_at` | 006 FR-018 |
| `cooperative.membership` | `user:{driverId}` | `membership_id`, `cooperative_id`, `status`, `role` | 006 FR-008 |

006 añade a `trip.offer`: `delegated` (bool), `can_delegate` (bool), `cooperative_name`
(string|null) y `requested_driver_name` (string|null, el Conductor Elegido cuando la oferta llega
derivada). `trip.offer_closed` puede traer `reason = delegated` (el conductor pasó la oferta a su
cooperativa) y `trip.status` puede traer `cancel_reason = no_driver_available`.

Los eventos de turno PTT (quién habla) viajan como mensajes de datos de LiveKit dentro de la sala
del viaje: `{"type":"floor.taken","user_id":...}` y `{"type":"floor.released"}`.

El canal de voz de grupo de la cooperativa (006, `COOP_GROUP`) usa los mismos mensajes de datos en
la sala `coop-{cooperativeId}`, con un único turno para todo el grupo.
