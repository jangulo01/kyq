# Kyq

Plataforma de movilidad por suscripción mensual (0 % de comisión por viaje) para conductores
autónomos, con fidelización directa del pasajero y walkie-talkie (PTT) entre pasajero y conductor.

Principios y stack: [.specify/memory/constitution.md](.specify/memory/constitution.md).

## Estructura

| Ruta | Contenido |
|---|---|
| `apps/kyq_driver_app` | Kyq Conductor (Android, iOS). `com.kyq.driver` |
| `apps/kyq_rider_app` | Kyq Pasajero (Android, iOS, web). `com.kyq.rider` |
| `apps/kyq_admin_web` | Panel administrativo y torre de control (web) |
| `packages/kyq_domain` | Modelos y reglas de negocio RN-KYQ con pruebas |
| `packages/kyq_api` | Cliente REST del contrato `specs/*/contracts/api.yaml` |
| `packages/kyq_realtime` | Eventos en tiempo real (Centrifugo) |
| `packages/kyq_ptt` | Walkie-talkie PTT (LiveKit), en US3 |
| `packages/kyq_ui` | Tema y login OTP comunes |
| `backend` | Monolito modular en Go |
| `infra` | Entorno local: PostgreSQL+PostGIS, Centrifugo, LiveKit, OSRM (ver `infra/README.md`) |

## Requisitos

- Flutter 3.44+ (Dart 3.12+)
- Melos 7: `dart pub global activate melos 7.8.2`
- Go 1.26+ (backend)
- Docker (entorno local)
- Android SDK (builds Android)

## Comandos

```bash
flutter pub get
melos run analyze
melos run test
```

Backend y servicios locales:

```bash
docker compose -f infra/docker-compose.yml up -d
cd backend
cp .env.example .env            # y exportar sus variables
go run ./cmd/migrate up
go run ./cmd/seed               # crea el admin de KYQ_SEED_ADMIN_PHONE
go run ./cmd/api
```

Pruebas: `go test ./...`. Las de integración necesitan `KYQ_TEST_DATABASE_URL` apuntando a un
PostgreSQL con PostGIS; sin ella se omiten.

## Flujo de trabajo

Cada funcionalidad sigue Spec Kit en Claude Code: `/speckit-specify` → `/speckit-clarify` →
`/speckit-plan` → `/speckit-tasks` → `/speckit-implement`.
