# Research: Bolsa zonal y fidelización ampliada

## R1. Cómo elegir el conductor de la bolsa

- **Decision**: misma estrategia que la delegación de 006: consulta PostGIS `ST_DWithin` +
  `ST_Distance` sobre `drivers.last_location`, filtrando `accepts_zone_pool`, `presence = 'free'`,
  usuario no suspendido, ubicación ≤ 5 min, sin oferta previa en el viaje; orden por distancia y
  `user_id`; `FOR UPDATE OF d SKIP LOCKED`.
- **Rationale**: ya probada en 006 contra condiciones de carrera (dos solicitudes no reservan al
  mismo conductor); no requiere índices nuevos con decenas de conductores.
- **Alternatives considered**: anillos H3 (`gridDisk`) en Redis como sugiere el SDD — descartado:
  añade una pieza sin necesidad medida (principio VII); la torre ya usa H3 solo para mostrar.

## R2. Modelo del viaje para la bolsa

- **Decision**: nuevo valor `zone_pool` del enum `trip_dispatch`. `requested_driver_id` guarda el
  primer conductor ofertado (sigue NOT NULL). `AwaitsHandOver` admite el traspaso también cuando
  `dispatch = zone_pool` (sin cooperativa ni consentimiento). `findCandidate` elige la consulta de
  la bolsa o la de la cooperativa según el modo.
- **Rationale**: reutiliza `HandOver`, `GiveUp`, `afterHandOver`, el barrido de vencimientos y los
  eventos de 006 sin duplicar la máquina de estados.
- **Alternatives considered**: `requested_driver_id` nulo — obligaba a tocar todas las vistas,
  el informe CRM y el contrato; sin beneficio funcional.

## R3. Tarifa preferencial (RN-KYQ-013)

- **Decision**: `drivers.preferential_discount_pct` (0–30). El viaje guarda `list_fare_minor`
  (tarifa de la tabla) y `preferential_discount_pct` aplicado; `suggested_fare_minor` es la tarifa
  ofrecida. Al crear o traspasar la oferta, si el conductor ofertado tiene al pasajero en su
  cartera y un descuento > 0, `suggested = redondeo(list × (100 − pct) / 100)` con el redondeo de
  la tabla de la ciudad; si no, `suggested = list`. La cotización (`POST /v1/fares/quote`) acepta
  `driver_id` opcional para mostrar el mismo cálculo.
- **Rationale**: una sola fuente de verdad (la tabla) y un solo punto de cálculo; el traspaso a un
  compañero vuelve a la tarifa de lista (FR-012).
- **Alternatives considered**: descuento por cliente o cupones — fuera del alcance (Assumptions).

## R4. Origen de la oferta

- **Decision**: el evento `trip.offer` añade `origin` (`chosen_driver` | `cooperative` |
  `zone_pool`), `loyal_client` (el pasajero está en la cartera del conductor ofertado),
  `trips_together` (viajes completados de la pareja) y `pickup_distance_m` (línea recta desde la
  última ubicación del conductor). Se calculan en el servicio antes de publicar, en la misma
  transacción.
- **Rationale**: la app del conductor ya pinta la tarjeta desde el evento; no hace falta una
  consulta extra al abrirla.

## R5. Afiliación por origen y enlace

- **Decision**: el enum `affiliation_source` gana `post_trip` y `link`. `POST /v1/affiliations`
  acepta `{qr_token, source: qr_scan|link}` o `{trip_id}` (después del viaje: el conductor sale
  del viaje, que debe estar COMPLETED y ser del pasajero). Reactivar actualiza el origen. El
  enlace es `KYQ_PUBLIC_BASE_URL/a/{qr_token}`: una página HTML sin datos de contacto con un botón
  `kyq://affiliate/{qr_token}` que abre Kyq Pasajero (intent-filter del esquema `kyq`).
- **Rationale**: el token del QR ya es público (va pegado en el vehículo); no hace falta un
  identificador nuevo. El esquema propio evita depender de App Links verificados.
- **Alternatives considered**: App Links `https` verificados — requieren `assetlinks.json` en un
  dominio fijo; se puede añadir con el dominio de producción.

## R6. Afiliación después del viaje en la app

- **Decision**: el resumen del viaje del pasajero consulta su lista de Conductores Elegidos y, si
  el conductor del viaje no está, muestra "Guardar a X como Conductor Elegido".
- **Rationale**: sin campos nuevos en la vista del viaje (compartida por ambas partes).
