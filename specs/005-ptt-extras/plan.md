# Implementation Plan: PTT extra — pre-consulta, botón físico y burbuja

**Branch**: `005-ptt-extras` | **Date**: 2026-10-27 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/005-ptt-extras/spec.md`

## Summary

La pre-consulta (RN-KYQ-010) es un canal walkie-talkie en vivo y corto entre un pasajero afiliado
y su conductor, que el conductor autoriza con un interruptor y puede silenciar por cliente. El
backend la modela en el módulo `ptt` con su propia tabla, sala LiveKit `pre-{id}` y el mismo
turno a prueba de fallos del viaje (15 s), y la cierra con el barrido existente. Las apps
reutilizan `PttController` con una `PttApi` de consulta. El botón físico y la burbuja
(RN-KYQ-012) son una capa Kotlin delgada en Kyq Conductor (sesión multimedia y vista flotante)
que manda pulsaciones a `HandsFreePtt` en `kyq_ptt`, que las aplica al canal abierto (viaje o
consulta).

## Technical Context

**Language/Version**: Dart 3.12 / Flutter 3.44 (apps); Go 1.26 (backend); Kotlin (capa nativa
de Kyq Conductor).

**Primary Dependencies**: las de 001 (LiveKit, Centrifugo, `livekit_client`, `audio_session`,
`audioplayers`, `permission_handler`). Nueva directa en Kyq Conductor: `shared_preferences`
(ya en el lockfile como transitiva) para las preferencias del manos libres. Sin plugins nuevos de
botón o burbuja (research R7, R8).

**Storage**: PostgreSQL (tabla `ptt_preconsults` y dos columnas, [data-model.md](data-model.md)).
Sin S3: la voz no se guarda (research R1).

**Testing**: integración Go con base real (reglas de apertura, límites, turno, barrido, borrado,
HTTP, contrato); unidad Dart (`HandsFreePtt`, API, eventos); widget/cubit en ambas apps.

**Target Platform**: Android 7+ (minSdk 24, compileSdk 36) para conductor y pasajero.

**Project Type**: mobile + API (monorepo existente).

**Performance Goals**: conductor conectado < 5 s (SC-001); turno por botón < 1 s (SC-005).

**Constraints**: voz nunca almacenada; botón y burbuja solo con canal abierto; capa nativa
mínima (constitución III).

**Scale/Scope**: piloto ~200 conductores; consultas acotadas por límites (≤ 6/día/pasajero).

## Constitution Check

| Principio | Cumplimiento |
|---|---|
| I. Clean-room | Flujos y nombres propios; la burbuja es una vista propia y los tonos se sintetizan (sin recursos de terceros). |
| II. Adoptar antes que construir | LiveKit y Centrifugo reutilizados; plugins de botón y burbuja evaluados y descartados con motivo (research R7, R8); la capa nativa usa APIs del sistema. |
| III. Flutter | Pantallas en Flutter; Kotlin solo para `MediaSession` y la ventana flotante, como permite el principio. |
| IV. Monolito modular Go | La consulta vive en el módulo `ptt`; sin servicios nuevos. |
| V. Reglas como contrato | RN-KYQ-010 (pruebas Go de apertura, límites, cierre) y RN-KYQ-012 (pruebas Dart de `HandsFreePtt`). |
| VI. Pruebas | Unidad, integración y widget según el principio. |
| VII. Coste medido | Segundos de voz de `pre-{id}` atribuidos al conductor; sin almacenamiento de audio ni segundo motor Flutter. |

Sin desviaciones. **Re-check post-diseño**: el contrato añade rutas al módulo `ptt` y no crea
servicios; la capa nativa queda en dos archivos Kotlin.

## Project Structure

### Documentation (this feature)

```text
specs/005-ptt-extras/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/api.yaml      # rutas nuevas (fusionadas en el contrato de 001)
├── checklists/requirements.md
└── tasks.md
```

### Source Code (repository root)

```text
backend/
├── migrations/00010_ptt_extras.sql
├── internal/store/queries/preconsults.sql
├── internal/ptt/
│   ├── floor.go            # turno a prueba de fallos compartido (viaje y consulta)
│   ├── preconsult.go       # reglas RN-KYQ-010, cierre y borrado
│   └── preconsult_handlers.go
└── internal/telemetry/livekit_webhook.go   # salas pre-{id}
packages/
├── kyq_api/lib/src/preconsult_models.dart  # + métodos del cliente
├── kyq_realtime/lib/src/events.dart        # preconsult.opened/joined/closed
└── kyq_ptt/lib/src/
    ├── hands_free.dart     # HandsFreePtt (RN-KYQ-012)
    └── ptt_api.dart        # PreconsultPttApi
apps/kyq_driver_app/
├── lib/preconsult/         # bandeja, consulta activa, ajustes
├── lib/handsfree/          # puente con la capa nativa y preferencias
└── android/app/src/main/kotlin/com/kyq/kyq_driver_app/
    ├── MainActivity.kt
    └── HandsFreeBridge.kt  # MediaSession + burbuja
apps/kyq_rider_app/lib/preconsult/          # abrir consulta, hablar, pedir viaje
```

**Structure Decision**: monorepo existente; la consulta es parte del módulo PTT del backend y del
paquete `kyq_ptt`.

## Complexity Tracking

Sin violaciones que justificar.
