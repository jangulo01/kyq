# Research: Experiencia nativa

## R1. Reservas

- **Decision**: tabla `reservations` con estados `pending`, `confirmed`, `rejected`, `cancelled`,
  `expired` (no confirmada a 15 min), `fulfilled` (se creó el viaje) y `missed` (a la hora el
  conductor no estaba libre). Tarifa cotizada al reservar (con la preferencial de 008) y guardada.
  Barrido cada 10 s con `FOR UPDATE SKIP LOCKED`: vence pendientes, recuerda 30 minutos antes y,
  a la hora, llama a `trips.Service.RequestWith` con `RequestOptions{ReservedFare, Reservation}`.
  Si el pasajero tiene otro viaje activo se reintenta hasta 30 minutos después de la hora.
- **Rationale**: reutiliza el pedido nominal de 001 (25 s, reserva del conductor, eventos), sin
  duplicar la máquina del viaje; el barrido ya es el patrón de 001–009.
- **Alternatives considered**: crear el viaje al confirmar con estado "programado" — obligaba a
  cambiar el agregado del viaje, la presencia y todas las vistas.

## R2. Notas del conductor

- **Decision**: tabla `client_notes (driver_id, passenger_id)`; solo rutas `/v1/driver/*` y el
  campo `client_note` de `trip.offer` (canal `user:{driverId}`). `affiliations` la borra al quitar
  la afiliación en la misma transacción.
- **Rationale**: SC-005 exige que nunca llegue al pasajero; ninguna ruta de pasajero la lee.

## R3. Llegada automática

- **Decision**: evaluación en el backend con cada ubicación (cada 3 s): distancia Haversine a la
  recogida, `trips.near_pickup_since` y `Arrive` del agregado cuando lleva 10 s a < 60 m. Solo
  cuentan ubicaciones con `accuracy_m` ≤ 50; una ubicación imprecisa ni suma ni reinicia.
- **Rationale**: funciona con la app en segundo plano (el servicio ONLINE ya envía la ubicación) y
  no requiere geocercas del sistema operativo.
- **Alternatives considered**: Geofencing API de Android — exige Google Play Services (Huawei sin
  GMS) y permisos extra.

## R4. Escaneo de documentos

- **Decision**: `google_mlkit_document_scanner` (ML Kit Document Scanner: detección de bordes,
  recorte, perspectiva y su propio ajuste manual). Si falla por falta de Google Play Services, la
  foto de `image_picker` pasa a una pantalla de cuatro esquinas arrastrables y se endereza con
  `copyRectify` de `image`. Nitidez: varianza del laplaciano sobre la imagen en gris a 512 px;
  por debajo de 60 se avisa ("parece borrosa") con opción de repetir o usar igual.
- **Rationale**: principio II; el recorte manual cubre los teléfonos sin GMS (FR-013).

## R5. Direcciones

- **Decision**: geocodificador Photon (OpenStreetMap) alojado en `infra/` y proxy
  `GET /v1/places?q=` con `KYQ_GEOCODER_URL` y la caja de la ciudad `KYQ_CITY_BBOX`
  (`minLng,minLat,maxLng,maxLat`, por defecto Bogotá); resultados fuera de la caja se descartan.
  Caché en memoria de 10 minutos por consulta. Sin geocodificador: `503 places_unavailable` y la
  app sigue con el mapa (FR-016). Destinos guardados en `shared_preferences` del teléfono.
- **Rationale**: sin coste por consulta (principio VII) y sin enviar búsquedas a terceros.
- **Alternatives considered**: Nominatim — importación más pesada; servicios comerciales — coste
  por consulta y datos personales fuera.

## R6. Mapa del pasajero

- **Decision**: interpolación lineal de la posición del conductor durante el intervalo entre
  ubicaciones (máx. 3 s) con un `AnimationController`, rumbo por `heading` o, si falta, por el
  vector entre puntos; en MapLibre se actualiza un símbolo con `iconRotate`. Pines dorados: el
  backend añade a `ChosenDriver` `zone {cell, lat, lng}` (centro del hexágono de res. 8) solo si
  está libre y su ubicación tiene ≤ 5 minutos.
- **Rationale**: la zona aproximada se calcula en el servidor: la posición exacta no sale nunca.
