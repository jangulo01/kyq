# Implementation Plan: MVP Conductor Elegido + Viaje + PTT 1 a 1 (Android)

**Branch**: `001-chosen-driver-trip-ptt` | **Date**: 2026-10-27 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/001-chosen-driver-trip-ptt/spec.md`

## Summary

Pasajero y conductor se vinculan por QR; el pasajero ve la presencia en vivo de sus conductores
elegidos y les pide viajes nominales con tarifa sugerida, editable por el conductor o negociable
con consentimiento del pasajero. Al aceptar se abre una sala de voz PTT privada que se cierra 15
minutos después del viaje. Enfoque: apps Flutter Android sobre un backend Go monolítico que es
fuente de verdad del estado del viaje, PostgreSQL+PostGIS, Centrifugo para eventos, LiveKit para
voz y OSRM para rutas y tarifas ([research.md](research.md)).

## Technical Context

**Language/Version**: Dart 3.12 / Flutter 3.44 (apps); Go 1.24 (backend)

**Primary Dependencies**: Apps: flutter_bloc, freezed, go_router, dio, centrifuge (Dart),
livekit_client, flutter_foreground_task, audio_session, geolocator, maplibre_gl, mobile_scanner,
qr_flutter. Backend: pgx v5, sqlc, goose, River, LiveKit server SDK, golang-jwt. Servicios:
Centrifugo v6, LiveKit server, OSRM, Twilio Verify.

**Storage**: PostgreSQL 17 + PostGIS ([data-model.md](data-model.md)); PMTiles en R2. Sin
almacenamiento de audio.

**Testing**: Dart `test` + `bloc_test` + `mocktail`; Flutter widget tests; Go `testing` contra
PostgreSQL real en CI; pruebas de contrato contra [contracts/api.yaml](contracts/api.yaml).

**Target Platform**: Android 10+ (API 29), con y sin Google Play Services; admin en navegador
de escritorio; backend Linux en contenedores.

**Project Type**: mobile apps + web admin + API (monorepo).

**Performance Goals**: oferta al conductor < 3 s p95; presencia < 5 s; voz < 250 ms p95 en 4G;
transiciones de viaje < 1 s p95.

**Constraints**: sin pagos en app; sin push; app del conductor operativa con pantalla apagada;
sin grabar voz; coste de infraestructura medido por conductor.

**Scale/Scope**: piloto en una ciudad, ~200 conductores y ~2.000 pasajeros; ~50 viajes
simultáneos en hora pico.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principio | Verificación | Estado |
|---|---|---|
| I. Clean-room | Spec y diseño propios; nada de código, sonidos ni protocolos de terceros. Tonos PTT se generarán o se tomarán de bancos con licencia | ✅ |
| II. Adoptar antes que construir | Voz LiveKit, tiempo real Centrifugo, rutas OSRM, mapas MapLibre, jobs River. Sin C/C++ propio | ✅ |
| III. Flutter en clientes | Conductor, pasajero y admin en Flutter; nativo solo vía plugins | ✅ |
| IV. Monolito Go | Un servicio con módulos; sin microservicios | ✅ |
| V. Reglas como contrato | RN-KYQ-001, 002, 003, 005, 006, 007, 009, 011, 013, 014, 016 con pruebas en Go; las que la UI muestra, también en `kyq_domain` | ✅ |
| VI. Pruebas y CI | Unit, widget, integración con PostgreSQL y contrato API en CI | ✅ |
| VII. Simplicidad y coste | Sin Redis, sin push, sin TimescaleDB; OSRM sin coste por petición | ✅ |
| Restricción HMS | El MVP no usa push; ubicación con LocationManager sin Google. HMS Push/Location se difieren hasta que exista push | ✅ (desviación documentada en research R4/R6) |

**Re-check post-diseño (Fase 1)**: el modelo de datos, los contratos y el quickstart no
introducen componentes nuevos; sin violaciones.

## Project Structure

### Documentation (this feature)

```text
specs/001-chosen-driver-trip-ptt/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── api.yaml
│   └── realtime.md
├── checklists/requirements.md
└── tasks.md            # /speckit-tasks
```

### Source Code (repository root)

```text
apps/
├── kyq_driver_app/lib/
│   ├── app/              # router, tema, arranque
│   ├── auth/             # OTP
│   ├── onboarding/       # estado ONLINE, bloqueos, QR propio, cartera
│   ├── offers/           # oferta 25 s, aceptar, cambiar tarifa, negociar
│   ├── trip/             # ciclo del viaje, navegación externa
│   └── background/       # servicio en primer plano y ubicación
├── kyq_rider_app/lib/
│   ├── app/
│   ├── auth/
│   ├── chosen_drivers/   # escáner QR, lista con presencia
│   ├── request/          # origen, destino, tarifa, solicitud, negociación
│   └── trip/             # seguimiento del viaje
└── kyq_admin_web/lib/
    ├── drivers/          # alta, suscripción, documentos
    └── fares/            # tabla de tarifas

packages/
├── kyq_domain/           # reglas y modelos compartidos (existente)
├── kyq_api/              # cliente REST generado o escrito a partir de contracts/api.yaml
├── kyq_realtime/         # wrapper de Centrifugo: canales y eventos tipados
├── kyq_ptt/              # sala LiveKit, turno, foco de audio, botón PTT
└── kyq_ui/               # tema y componentes comunes

backend/
├── cmd/api/              # servidor HTTP (existente)
├── cmd/migrate/          # migraciones goose
├── migrations/
├── internal/
│   ├── httpapi/          # router y middleware (existente)
│   ├── auth/             # OTP, JWT, refresco
│   ├── drivers/          # perfil, presencia, ubicación, gate ONLINE
│   ├── affiliations/
│   ├── fares/            # tabla, cotización, RouteEstimator (OSRM)
│   ├── trips/            # máquina de estados, propuestas, temporizadores River
│   ├── ptt/              # salas LiveKit, tokens, turno
│   ├── realtime/         # publicación a Centrifugo
│   └── admin/
└── internal/store/       # consultas sqlc

infra/
├── docker-compose.yml    # + osrm; - redis
└── centrifugo.json
```

**Structure Decision**: monorepo existente. Cada módulo backend tiene su paquete con handlers,
servicio y pruebas; las apps se organizan por funcionalidad y comparten paquetes en
`packages/`. `kyq_ptt` y `kyq_realtime` se reutilizarán en iOS (fase 2) sin cambios de API.

## Complexity Tracking

Sin violaciones de la constitución que justificar.
