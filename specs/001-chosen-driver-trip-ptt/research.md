# Research: MVP Conductor Elegido + Viaje + PTT 1 a 1

Decisiones de la Fase 0. Versiones concretas de dependencias se fijan al implementar, usando la
última estable con al menos dos semanas de publicación.

## R1. Voz PTT 1 a 1

- **Decision**: LiveKit (servidor autoalojado) con una sala por viaje `trip-{tripId}`. Ambos
  participantes se conectan al pasar a ACCEPTED con el micrófono publicado pero silenciado; al
  pulsar se pide el turno al backend y, concedido, se activa el micrófono. Al soltar se libera.
- **Rationale**: Opus, cancelación de eco, supresión de ruido, control de ganancia, NAT traversal
  y respaldo TCP/TURN ya resueltos (FR-017, edge case de red bloqueada). Conectar antes de
  hablar elimina el tiempo de unión a la sala de la latencia percibida (SC-005).
- **Alternatives considered**: protocolo UDP propio (rechazado por constitución II);
  mensajes de voz grabados y subidos (latencia de segundos, incumple SC-005).

## R2. Control de turno (floor control)

- **Decision**: endpoint `POST /v1/trips/{id}/ptt/floor` que concede el turno con un registro
  en PostgreSQL (`ptt_channels.floor_holder_id`, `floor_expires_at`, 60 s máx.) mediante
  `UPDATE ... WHERE floor_holder_id IS NULL OR floor_expires_at < now()`. Se notifica al otro
  participante por mensaje de datos de LiveKit.
- **Rationale**: atómico, sin Redis, una sola fuente de verdad (FR-017, escenario 3 de la
  historia 3).
- **Alternatives considered**: Redis SETNX (pieza extra sin necesidad en el MVP); resolver en
  el cliente con mensajes de datos (carreras entre dispositivos).

## R3. Tiempo real (ofertas, estados, posición)

- **Decision**: Centrifugo, nodo único con motor en memoria. El backend publica por la API HTTP
  de Centrifugo; los clientes se suscriben con el SDK oficial de Dart. Canales en
  [contracts/realtime.md](contracts/realtime.md).
- **Rationale**: reconexión con recuperación de historial (edge case de pérdida de conexión),
  sin código de WebSocket propio (constitución II).
- **Alternatives considered**: WebSocket propio en Go; SSE propio (clon de RAMEN).

## R4. Notificaciones push

- **Decision**: sin push en el MVP. El conductor ONLINE mantiene un servicio en primer plano con
  la conexión de tiempo real abierta; el pasajero solo espera respuestas mientras tiene la app
  abierta.
- **Rationale**: elimina FCM y HMS Push del MVP y con ello la dependencia de servicios de Google
  (FR-022). Cuando haga falta push (pre-consulta PTT, recordatorios) se añadirán FCM y HMS.
- **Alternatives considered**: FCM + HMS desde el inicio (dos integraciones sin caso de uso
  en el MVP).

## R5. Segundo plano y audio en el conductor

- **Decision**: `flutter_foreground_task` con tipos `location|microphone|mediaPlayback` mientras
  el conductor está ONLINE; `audio_session` para pedir foco de audio transitorio con atenuación
  (`gainTransientMayDuck`) al reproducir voz entrante y liberarlo al terminar.
- **Rationale**: cumple FR-018 y FR-019 con capas delgadas (constitución III). La atenuación
  depende de que la app de navegación respete el foco de audio; Waze y Google Maps lo hacen.
- **Alternatives considered**: servicio Kotlin propio desde el inicio (solo si el plugin no
  cubre un caso medido).

## R6. Ubicación sin servicios de Google

- **Decision**: `geolocator` con el proveedor `LocationManager` de Android cuando no hay Google
  Play Services (`forceLocationManager`), fused en el resto.
- **Rationale**: FR-022 sin integrar HMS Location en el MVP.
- **Alternatives considered**: HMS Location Kit (más código y otro SDK para el mismo resultado).

## R7. Ruta, distancia, tiempo y ETA

- **Decision**: OSRM autoalojado con el extracto OSM de la ciudad piloto, detrás de una interfaz
  `RouteEstimator` en Go. Se usa para tarifa sugerida (FR-010) y minutos para liberarse
  (FR-008, recalculados como máximo cada 30 s por conductor ocupado).
- **Rationale**: sin coste por petición; una ciudad cabe en un contenedor pequeño
  (constitución VII).
- **Alternatives considered**: API comercial de rutas (coste variable por viaje y por
  recálculo de ETA); Valhalla (más capacidades de las necesarias).

## R8. Mapas en la app

- **Decision**: `maplibre_gl` con teselas vectoriales PMTiles de la ciudad publicadas en
  almacenamiento S3 compatible (Cloudflare R2).
- **Rationale**: sin licencia ni coste por carga de mapa; el MVP solo necesita mapa de origen,
  destino y posición del conductor.
- **Alternatives considered**: Google Maps SDK (requiere servicios de Google, coste por uso).

## R9. Autenticación

- **Decision**: OTP por SMS con un proveedor de verificación (Twilio Verify en el MVP) detrás de
  la interfaz `OTPSender`; en desarrollo, código fijo por variable de entorno. Tras verificar,
  JWT de acceso (15 min) y token de refresco rotativo (30 días). Roles: `passenger`, `driver`,
  `admin`.
- **Rationale**: FR-001 sin contraseñas. Interfaz permite cambiar de proveedor por país.
- **Alternatives considered**: Firebase Auth (atado a Google), OTP por WhatsApp (fase 2).

## R10. Temporizadores de negocio

- **Decision**: cola de trabajos sobre PostgreSQL (River) para vencimientos: oferta 25 s,
  confirmación de tarifa 30 s, propuesta de negociación 30 s, negociación 3 min, cierre de canal
  PTT 15 min. Cada transición se valida de nuevo al ejecutar el trabajo (idempotente).
- **Rationale**: sobreviven a reinicios, transaccionales con el cambio de estado, sin Redis.
- **Alternatives considered**: `time.AfterFunc` en memoria (se pierden al reiniciar);
  cron por sondeo (latencia y carga).

**Revisión (implementación US2):** se sustituyó River por una columna `respond_by` en `trips` y
un barrido (`Service.ExpireDue`, `SELECT ... FOR UPDATE SKIP LOCKED`) cada segundo. Mismas
garantías (sobrevive a reinicios, transaccional, idempotente) con una dependencia y un esquema de
tablas menos; latencia máxima de vencimiento ~1 s. El cierre del canal PTT (US3) usará el mismo
mecanismo.

## R11. Acceso a datos y migraciones en Go

- **Decision**: `pgx` v5 + `sqlc` para consultas tipadas; `goose` para migraciones; router
  `net/http` estándar (patrones de Go 1.22+).
- **Rationale**: pocas dependencias, SQL explícito (PostGIS), sin ORM.
- **Alternatives considered**: GORM (oculta SQL espacial), chi/echo (no hacen falta).

## R12. Reglas de negocio en cliente y servidor

- **Decision**: el backend Go es la fuente de verdad de RN-KYQ-001, 002, 003, 005, 006, 007,
  009, 011 (parte servidor), 013, 014 y 016, con pruebas en Go. `kyq_domain` (Dart) replica
  solo lo necesario para mostrar estados y bloqueos en la UI, con las mismas pruebas.
- **Rationale**: la constitución V exige prueba por regla; el servidor decide para evitar
  manipulación desde el cliente.
- **Alternatives considered**: lógica solo en cliente (inseguro); generar Dart desde Go
  (complejidad sin beneficio en el MVP).

## R13. Redis

- **Decision**: no se usa en el MVP. Se retira del entorno local en la implementación.
- **Rationale**: R2, R3 y R10 cubren sus usos previstos (constitución VII).
