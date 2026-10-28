# Research: Torre de control H3, CRM y economía unitaria

## R1. H3 sin cgo

- **Decision**: paquete propio `backend/internal/hexgrid` en Go puro:
  - Índice (latitud/longitud → celda): `github.com/ziprecruiter/h3-go` v0.5.0 (Apache-2.0,
    publicado 2025-04-09), reimplementación de H3 en Go puro.
  - Centro y contorno de la celda (`cellToLatLng`, `cellToBoundary`), que esa biblioteca no
    expone: portados de la biblioteca oficial H3 v4.4.1 (Uber, Apache-2.0), ~400 líneas
    (`h3_faceijk.c`, `h3_coordijk.c`, `h3_h3Index.c`, `h3_latLng.c`, `h3_vec2d.c`). Las tablas
    (`baseCellData`, `faceCenterGeo`, `faceAxesAzRadsCII`, `faceNeighbors`, `adjacentFaceDir`) se
    generaron con un script desde el C (`tables.go`, marcado como generado).
  - Verificación: `testdata/h3js_fixtures.json` con 204 casos de referencia generados con h3-js
    4.4.0 (la biblioteca oficial compilada a JS): ciudades de Colombia y Perú (res 5–10), 120
    puntos pseudoaleatorios del globo (res 0–11) y todos los pentágonos de las res 0, 2, 5 y 8.
    Índice, centro y cada vértice coinciden con tolerancia de 1e-7° (~1 cm).
- **Rationale**: la constitución (II) fija H3. El binding oficial `github.com/uber/h3-go/v4`
  (v4.4.1, 2026-04-07) usa cgo, y (a) la imagen del backend se compila con `CGO_ENABLED=0` sobre
  `distroless/static` (sin libc), (b) en el Windows de desarrollo no hay compilador C, así que ni
  las pruebas compilarían. La imagen `postgis/postgis:17-3.5` no trae la extensión `h3-pg`, así
  que calcular en PostgreSQL exigiría cambiar la imagen de base de datos (más operación) para un
  cálculo que con ~200 conductores cuesta microsegundos en Go.
- **Alternatives considered**: `uber/h3-go` con cgo (descartado por lo anterior);
  `github.com/akhenakh/goh3` (H3 transpilado a Go con ccgo, sin cgo, pero experimental y sin
  archivos para Windows: no compila aquí); `ThingsIXFoundation/h3-light` (2023, subconjunto
  mínimo) y `dimchansky/h3-go` (abandonado en 2019); extensión `h3-pg` (no está en la imagen);
  dibujar los contornos en el navegador con h3-js (el backend seguiría necesitando el índice y
  añadiría interop JS en el panel). Desviación registrada en el plan (Complexity Tracking).

## R2. Qué se agrega y cómo (torre)

- **Decision**: la instantánea se calcula al pedirla (`GET /v1/admin/tower?res=`), sin guardar
  la celda H3 en la base de datos: tres consultas (conductores ONLINE con su última posición,
  viajes activos, solicitudes de la última hora) y agregación en memoria con `hexgrid.CellAt`.
  Viajes activos (`ACCEPTED`, `ARRIVED`, `IN_PROGRESS`) en la celda de la posición actual del
  conductor (o de la recogida si no se conoce); solicitudes (viajes creados en los últimos 60 min,
  cualquier estado) en la celda de recogida; "no atendidas" = canceladas por `offer_expired`,
  `offer_rejected` o `negotiation_failed`. Nivel de presión: sin demanda (0 solicitudes), sin
  oferta (solicitudes y 0 libres), alta (solicitudes / libres ≥ 2), equilibrado. Ubicación
  desactualizada: > 120 s.
- **Rationale**: con el piloto (~200 conductores, < 1 000 solicitudes/h) la agregación es
  trivial; guardar celdas obligaría a recalcular al cambiar la resolución. Un índice en
  `trips (created_at)` acota la consulta de solicitudes.
- **Alternatives considered**: columna `h3_cell` por resolución en `drivers` y `trips`
  (innecesaria a esta escala); agregación en SQL (sin H3 en PostgreSQL, ver R1).

## R3. Torre en vivo

- **Decision**: canal Centrifugo `admin:tower` (namespace nuevo `admin`, historial 1, 60 s). Un
  barrido del backend cada 3 s calcula una huella barata (`count` y `max` de presencia, última
  ubicación y marcas de tiempo de viajes) y publica `tower.changed` `{}` solo si la huella cambió.
  El panel, al recibirlo, vuelve a pedir la instantánea en su resolución (sin solapar peticiones),
  y además la pide cada 30 s: así avanza la ventana de una hora aunque nada cambie y la torre sigue
  viva si el canal falla. La suscripción la autoriza el backend solo para el rol
  admin (`POST /v1/realtime/subscription-token`).
- **Rationale**: el aviso no lleva datos personales ni depende de la resolución; coste acotado a
  ≤ 1 evento cada 3 s (~29 000/día como máximo, sin atribuir a conductores). Centrifugo ya es la
  pieza de tiempo real (constitución II).
- **Alternatives considered**: publicar la instantánea completa (pesada, ligada a una resolución,
  con nombres de conductores en el canal); solo sondeo (no cumple el "en vivo" con coste similar);
  consultar la presencia del canal en Centrifugo antes de publicar (exige activar presencia y una
  llamada más cada 3 s para ahorrar eventos de coste despreciable).

## R4. Mapa en el panel web

- **Decision**: `maplibre_gl` 0.27.1 (ya usado por la app de pasajero) con el estilo propio
  (`KYQ_MAP_STYLE_URL` o el servicio `tiles` en el puerto 8081 del host de la API). Como el estilo
  apunta a `pmtiles://`, `web/index.html` carga MapLibre GL JS 6.4.1 (la versión contra la que está
  escrito el plugin) y `pmtiles` 4.4.1 (2026-04-08), registra el protocolo y publica
  `globalThis.maplibregl`; la app usa `MapLibreJsSource.preloaded()`. Hexágonos como fuente GeoJSON
  con capa de relleno (color por nivel de presión) y conductores como capa de círculos.
- **Rationale**: un solo motor de mapas en todo Kyq (constitución II); el plugin web no registra
  protocolos, y MapLibre GL JS no lee PMTiles sin el protocolo.
- **Alternatives considered**: `flutter_map` (otro motor y sin PMTiles vectoriales); dejar que el
  plugin cargue MapLibre (no habría dónde registrar el protocolo antes de cargar el estilo).
- **Pruebas**: el mapa se inyecta (`TowerMapBuilder`) y en las pruebas de widget se sustituye,
  igual que en la app de pasajero.

## R5. Finanzas sobre 002

- **Decision**: `GET /v1/admin/finance?to=AAAA-MM&months=N` en `telemetry` reutiliza
  `CostHandlers.breakdowns` y `ComputeCosts` de 002 mes a mes. Conductores considerados: los
  creados antes del fin del mes (los demás no existían), con el costo fijo de 002 aunque no tengan
  uso, igual que la tabla por conductor. Activo = uso medido o pago en el mes.
- **Rationale**: un solo cálculo de costo (FR-008); 24 meses × 2 consultas es despreciable.
- **Nota**: la tabla por conductor de 002 (`GET /v1/admin/costs`) incluye en meses pasados a
  conductores creados después; Finanzas no. Se corrige en 002 aplicando el mismo filtro (T014),
  para que las dos vistas sumen igual (SC-003).

## R6. Indicadores de fidelización

- **Decision**: consultas SQL agregadas en el módulo `crm`:
  - Activa en el instante t: `created_at <= t AND (removed_at IS NULL OR removed_at > t)`.
    Como el MVP reescribe `created_at` al reactivar una afiliación (001), una baja seguida de
    reactivación cuenta como afiliación nueva (aproximación documentada en la spec).
  - Serie semanal con `generate_series` por lunes.
  - Repetición: viajes `COMPLETED` con `completed_at` en el periodo agrupados por pareja.
  - SC-008: afiliaciones creadas en el periodo con `created_at + 30 días <= ahora`; cumple si
    existe un viaje (cualquier estado) de ese pasajero a ese conductor con `created_at` en
    `[afiliación, afiliación + 30 días)`.
- **Rationale**: SQL directo sobre tablas pequeñas, sin tablas de hechos ni ETL (YAGNI).

## R7. Moderación

- **Decision**: columnas `suspended_at` y `suspension_reason` en `users` y tabla de auditoría
  `moderation_actions`. Suspender (transacción): marca el usuario, registra la acción, revoca los
  refresh tokens y, si es conductor sin viaje activo, lo pone OFFLINE y publica
  `driver.presence`. `auth` rechaza `otp/verify` y `refresh` de un suspendido con 403
  `account_suspended`; `POST /v1/driver/presence` con `online: true` responde 409
  `account_suspended`. El token de acceso vigente (15 min) no se revoca.
- **Rationale**: comprobar la suspensión en cada petición añadiría una consulta a todas las rutas
  de todos los módulos; 15 min de margen es aceptable para moderación manual y las acciones
  críticas (conectarse, renovar sesión) ya se cortan al instante.
- **Alternatives considered**: lista de usuarios suspendidos en memoria consultada por
  `RequireAuth` (estado por proceso; con un solo proceso funcionaría, pero añade invalidación);
  acortar el token de acceso (más renovaciones para todos).

## R8. Healthline

- **Decision**: módulo `health` con comprobaciones en paralelo y 3 s de límite:
  base de datos (`Ping` + `SELECT 1`), Centrifugo (`POST {api}/info` con su llave: 200),
  LiveKit (`GET {api}/`: 200), OSRM (`GET /route/v1/driving/…` de dos puntos de la ciudad:
  cualquier respuesta < 500 cuenta como disponible, porque fuera de cobertura responde 400),
  almacenamiento (`BucketExists` del bucket KYC), Bold (si está activo:
  `GET /online/link/v1/payment_methods` con la llave de identidad; 401/403 = llave rechazada).
  El detalle es un texto corto propio ("HTTP 503", "sin respuesta en 3 s"), nunca el error crudo
  (que puede contener URLs internas).
- **Rationale**: cada comprobación usa la misma vía que el uso real; sin histórico (Sentry y los
  logs ya lo cubren).
