# Research: Cooperativas y delegación inteligente

## R1. Dónde vive la delegación: dentro del agregado del viaje

- **Decision**: la delegación es una transición más del agregado `trips.Trip`. Una oferta que
  termina sin conductor (`offer_rejected`, `offer_expired` o el nuevo paso `delegated`) en un
  viaje con cooperativa y consentimiento no se cierra: en la misma transacción el servicio busca
  el siguiente compañero y llama a `Trip.HandOver(next)`, que devuelve el viaje a `REQUESTED` con
  el nuevo conductor y 25 s nuevos. Si no hay candidato o se agotaron los 3 pasos,
  `Trip.GiveUp()` deja el viaje cancelado con `no_driver_available`.
- **Rationale**: reutiliza tal cual la oferta, el vencimiento, el barrido de 1 s, la reserva del
  conductor y los índices de un viaje activo por conductor de 001; el viaje conserva un solo id
  de principio a fin y el pasajero no tiene que pedir de nuevo.
- **Alternatives considered**: crear un viaje nuevo por cada paso (rompe la pantalla del
  pasajero y el historial); un módulo de despacho separado con su propia cola (duplica la lógica
  de ofertas que ya está probada).

## R2. Búsqueda del compañero más cercano con PostGIS

- **Decision**: una sola consulta sobre `drivers.last_location` (geography, ya mantenida por
  `POST /v1/driver/location`): miembros activos de la cooperativa activa, `presence = 'free'`,
  `last_location_at` de los últimos 5 min, `ST_DWithin(last_location, recogida, 10 km)`, sin
  ofertas previas en ese viaje (`trip_offers`), ordenada por `ST_Distance` y el id como
  desempate, `LIMIT 1 FOR UPDATE OF d SKIP LOCKED`.
- **Rationale**: el bloqueo de la fila del conductor dentro de la transacción del viaje evita que
  dos solicitudes reserven al mismo compañero (SC-002); el índice único de un viaje activo por
  conductor de 001 queda como red de seguridad. Distancia en línea recta: ninguna llamada a OSRM
  por candidato (coste medido, principio VII). Volumen: decenas de miembros por cooperativa, sin
  necesidad de índice espacial adicional.
- **Alternatives considered**: H3 (previsto para la bolsa zonal de la opción 3, innecesario para
  un conjunto acotado de miembros); ETA por carretera con OSRM (coste y latencia por candidato).

## R3. Consentimiento del pasajero

- **Decision**: campo `allow_delegation` en `POST /v1/trips`, guardado en el viaje. Con
  `dispatch = cooperative` vale siempre verdadero. Solo se acepta si el conductor pedido pertenece
  a una cooperativa activa al pedir; si no, se ignora (queda falso).
- **Rationale**: un consentimiento explícito y previo cumple "con consentimiento del pasajero" sin
  añadir una espera de respuesta del pasajero en cada paso, que alargaría el tiempo sin servicio.
- **Alternatives considered**: preguntar al pasajero en cada paso (30 s más por paso).

## R4. Historial de ofertas del viaje

- **Decision**: tabla `trip_offers (trip_id, driver_id, offered_at, handover)` con PK
  compuesta: una fila por conductor ofertado. Sirve para excluir a quien ya la tuvo y para
  auditar. La migración rellena una fila por viaje existente.
- **Alternatives considered**: un arreglo en `trips` (no se puede usar en el `NOT EXISTS` con la
  misma claridad ni indexar).

## R5. Canal PTT de grupo sobre el módulo `ptt`

- **Decision**: tabla `group_ptt_channels` (una fila por cooperativa, `channel_type =
  'COOP_GROUP'`, `room_name = coop-{id}`, turno). El servicio `ptt.Service` añade `GroupToken`,
  `TakeGroupFloor`, `ReleaseGroupFloor`, `LeaveGroup` y caduca los turnos de grupo en el mismo
  barrido. Mismo modelo fail-closed de 001: token sin permiso de publicar; el turno concede
  publicar en LiveKit y se libera solo después de que LiveKit confirme la retirada.
- **Rationale**: reutiliza el control de turno y el cliente LiveKit ya probados; la app usa el
  mismo `PttController` con otra implementación de `PttApi`.
- **Diferencias con el canal del viaje**: sala sin límite de 2 participantes (máximo 50), sin
  cierre programado (vive mientras la cooperativa esté activa; LiveKit la borra al quedar vacía
  y el siguiente token la crea), acceso según la membresía en cada token y turno. Al salir o ser
  retirado, `LeaveGroup` retira el permiso, libera su turno y lo saca de la sala
  (`RemoveParticipant`).
- **Alternatives considered**: generalizar `ptt_channels` (PK `trip_id`) con columna de tipo
  (migración invasiva sobre una tabla en uso).

## R6. Coordinadores y avisos

- **Decision**: rol en la membresía (`member | coordinator`) que asigna el administrador. Las
  decisiones publican `cooperative.membership` en `user:{driverId}` (Centrifugo) y la app
  recarga. Sin avisos persistentes ni SMS en esta etapa.
- **Alternatives considered**: usar `notices` de 002 (su tipo `notice_kind` es un enum cerrado de
  documentos y pagos; ampliarlo no aporta en esta etapa).

## R7. Enumeraciones nuevas en tipos existentes

- **Decision**: `ALTER TYPE trip_cancel_reason ADD VALUE 'no_driver_available'` en la migración.
  PostgreSQL ≥ 12 lo permite dentro de la transacción de goose siempre que el valor no se use en
  la misma transacción. `delegated` no se guarda nunca: es un estado transitorio dentro de la
  transacción (se convierte en paso a otro compañero o en `no_driver_available`).
- **Down**: no se pueden quitar valores de un enum; el `Down` lo deja documentado.
