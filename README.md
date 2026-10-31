# Kyq

Plataforma de movilidad por suscripción mensual (0 % de comisión por viaje) para conductores
autónomos, con fidelización directa del pasajero y walkie-talkie (PTT) entre pasajero y conductor.
Incluye botón SOS con consola de emergencias y viaje compartido en vivo (003).

Principios y stack: [.specify/memory/constitution.md](.specify/memory/constitution.md).

## Estructura

| Ruta | Contenido |
|---|---|
| `apps/kyq_driver_app` | Kyq Conductor (Android, iOS). `com.kyq.driver` |
| `apps/kyq_rider_app` | Kyq Pasajero (Android, iOS, web). `com.kyq.rider` |
| `apps/kyq_admin_web` | Panel administrativo, torre de control y consola de emergencias (web) |
| `packages/kyq_domain` | Modelos y reglas de negocio RN-KYQ con pruebas |
| `packages/kyq_api` | Cliente REST del contrato `specs/*/contracts/api.yaml` |
| `packages/kyq_realtime` | Eventos en tiempo real (Centrifugo) |
| `packages/kyq_ptt` | Walkie-talkie PTT (LiveKit) |
| `packages/kyq_radio` | Radio Kyq (011): walkie-talkie permanente compartido por las dos apps (lista, conversación, historial, canales, modo auto) |
| `packages/kyq_ui` | Tema, login OTP y kit de seguridad comunes (botón SOS, contactos, PIN, compartir viaje) |
| `backend` | Monolito modular en Go |
| `backend/web/share` | Página pública del viaje compartido (HTML + MapLibre GL JS, embebida en la API) |
| `infra` | Entorno Docker: PostgreSQL+PostGIS, API, Centrifugo, LiveKit (+ Egress y Redis), MinIO, OSRM, teselas (ver `infra/README.md`) |

## Requisitos

- Flutter 3.44+ (Dart 3.12+)
- Melos 7: `dart pub global activate melos 7.8.2`
- Go 1.26+ (backend)
- Docker (entorno de desarrollo, normalmente en una VM)
- Python 3 con `requests` y `websockets` (solo para medir latencias)
- Android SDK (builds Android)

## Arranque completo

### 1. Servicios (Docker)

Todo lo que corre en Docker (PostgreSQL+PostGIS, migraciones, semilla, API, Centrifugo, LiveKit,
OSRM y teselas) está en `infra/docker-compose.yml`. En desarrollo se usa una VM con Docker.

```bash
cd infra
cp .env.example .env              # rellenar secretos (openssl rand -hex 32) y KYQ_PUBLIC_HOST
chmod 600 .env
docker compose up -d --build      # postgres → migrate (goose) → seed (admin) → api, centrifugo, livekit
```

- `migrate` aplica `backend/migrations` y termina; `seed` crea el admin de `KYQ_SEED_ADMIN_PHONE`.
- LiveKit corre sin creación automática de salas (`infra/livekit.yaml`): solo la API las crea, y
  su webhook alimenta los minutos de voz por conductor (`GET /v1/admin/usage`).
- Errores a Sentry: opcional con `KYQ_SENTRY_DSN` (vacío no envía nada; se filtran teléfonos,
  OTP y tokens).
- Documentos KYC (002): MinIO guarda las fotos en el bucket privado `kyq-kyc`; rellenar
  `KYQ_S3_ACCESS_KEY` y `KYQ_S3_SECRET_KEY` en el `.env` (detalle en `infra/README.md`).
- Bold (002 y 004): `KYQ_BOLD_ENV` (`sandbox` o `production`), `KYQ_BOLD_IDENTITY_KEY` y
  `KYQ_BOLD_SECRET_KEY`; vacío desactiva los pagos con Bold. En la VM los pagos se confirman
  consultando a Bold; en producción hay que publicar la API con HTTPS y registrar el webhook
  `https://<dominio>/v1/billing/bold/webhook` en el panel de Bold (ver `infra/README.md`).
- SOS (003): `redis` y `egress` graban el audio de cada alerta en el bucket privado `kyq-sos`
  (90 días). El admin de la semilla queda como operador de emergencias de guardia; la consola
  está en el panel (sección *Emergencias*). Los contactos de emergencia reciben el enlace
  `KYQ_PUBLIC_BASE_URL/s/{token}` (por defecto `http://KYQ_PUBLIC_HOST:8080`).

### 2. Datos de la ciudad (OSRM y mapa)

No se versionan (`infra/data/`). Rutas y teselas van en el perfil `routing`:

```bash
# Rutas: extracto OSM preprocesado en infra/data/osrm/city.osrm* (pasos en infra/README.md)
# Mapa: PMTiles + estilo + fuentes en infra/data/tiles
TILES_BASE_URL=http://<KYQ_PUBLIC_HOST>:8081 sh tiles/build.sh
docker compose --profile routing up -d osrm tiles
```

Detalle de ambos en [infra/README.md](infra/README.md). Repetir cada mes para tener calles al día.

### 3. Apps

```bash
flutter pub get
melos run analyze
melos run test
```

Apps contra el entorno de desarrollo (Android, debug; HTTP sin cifrar solo en debug y solo para
la IP de desarrollo):

```bash
cd apps/kyq_driver_app   # o apps/kyq_rider_app
flutter build apk --debug --dart-define=KYQ_API_URL=http://<host>:8080 --dart-define=KYQ_REALTIME_URL=ws://<host>:8000/connection/websocket
```

Opcionales: `--dart-define=KYQ_MAP_STYLE_URL=...` (por defecto `http://<host>:8081/style.json`) y
`--dart-define=KYQ_SENTRY_DSN=...`. El panel web (`apps/kyq_admin_web`) usa además
`--dart-define=KYQ_REALTIME_URL=...` para la cola en vivo de la consola de emergencias. Con `KYQ_DEV_OTP_CODE` en el `.env` no se envían SMS y se
entra con ese código.

**Radio Kyq (011)** va dentro de las dos apps en `/radio` (Kyq Conductor: entrada "Radio" en el
inicio; Kyq Pasajero: ícono de antena en Mis Conductores Elegidos). Los enlaces de invitación
`https://<host>/r/{code}` abren `kyq://radio/{code}` o la tienda; en el panel están
Configuración de Radio, Cargas masivas y Reportes. Buckets, registro y variables en
`infra/README.md` (sección Radio Kyq); la guía de prueba con dos teléfonos en
`specs/011-radio-kyq/quickstart.md`.

### 4. Backend fuera de Docker (opcional)

```bash
cd backend
cp .env.example .env            # y exportar sus variables
go run ./cmd/migrate up
go run ./cmd/seed
go run ./cmd/api
```

### Pruebas

- Flutter: `melos run test`.
- Go: `go test ./...`. Las de integración necesitan `KYQ_TEST_DATABASE_URL` apuntando a un
  PostgreSQL con PostGIS (por ejemplo la base `kyq_test` de la VM con un túnel SSH); sin ella se
  omiten.
- Latencias SC-002/SC-004 contra un entorno: `infra/measure/latency.py`
  (resultados en `specs/001-chosen-driver-trip-ptt/validation.md`).

## Flujo de trabajo

Cada funcionalidad sigue Spec Kit en Claude Code: `/speckit-specify` → `/speckit-clarify` →
`/speckit-plan` → `/speckit-tasks` → `/speckit-implement`.
