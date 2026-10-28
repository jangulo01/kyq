# Implementation Plan: Operación del panel: inspección, megáfono, soporte, sesiones sin fallos y dominios espejo

**Branch**: `009-ops-console-support` | **Date**: 2026-10-28 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/009-ops-console-support/spec.md`

## Summary

Cinco piezas de operación sobre lo que ya existe:

1. **Inspección**: la instantánea de la torre (007) añade el viaje activo de cada conductor
   ocupado y los viajes de cada hexágono; `GET /v1/admin/trips/{tripId}` devuelve el detalle
   (pasos, nombres, vehículo, ruta, posición, tarifa, despacho, pago, SOS abierto) y registra la
   apertura. El panel lo refresca cada 5 s mientras el viaje está activo.
2. **Soporte**: módulo nuevo `support` con casos y mensajes (notas internas incluidas), bandeja
   del panel, eventos en vivo (`support.case` a los usuarios y `admin:support` al panel) y cierre
   automático a los 7 días. `trippay` crea el caso de pago al pasar a disputa o "no pagado" y lo
   resuelve al resolverse el pago; el caso resuelve el pago llamando a `trippay.Resolve`. Un
   usuario suspendido recibe una sesión con alcance `support` que solo abre las rutas de soporte.
3. **Megáfono**: `POST /v1/admin/megaphone` fija los destinatarios (conductores ONLINE con
   ubicación de ≤ 5 min en los hexágonos), crea una sala LiveKit de un solo uso, devuelve al
   administrador un token para hablar y avisa a cada conductor con `megaphone.started` (token
   solo de escucha). Termina al soltar o a los 60 s; se registra autor, zonas, duración y
   destinatarios, sin grabar.
4. **Sesiones sin fallos**: `GET /v1/admin/health/sessions` consulta la API de sesiones de
   Sentry por proyecto (24 h y 7 días, versión más usada), con caché de 5 min y estados
   `not_configured` / `unavailable`.
5. **Dominios espejo**: tabla `mirror_domains` administrada desde el panel, comprobación de cada
   dominio, y `GET /v1/domains` pública con la lista activa firmada con Ed25519. `kyq_api` añade un
   rotador que verifica la firma con la clave pública incluida en la app, guarda la lista, cambia
   de dominio tras 3 fallos de red seguidos y la refresca cada 10 min.

## Technical Context

**Language/Version**: Dart 3.12 / Flutter 3.44 (apps); Go 1.26 (backend)

**Primary Dependencies**: las existentes (pgx, sqlc, goose, PostGIS, h3-go, Centrifugo, LiveKit,
Sentry). Nuevas: `crypto/ed25519` de la biblioteca estándar de Go y `cryptography` (Ed25519 en
Dart puro) en `kyq_api`; `shared_preferences` para guardar la lista de dominios.

**Storage**: PostgreSQL 17; migración `00014_ops_support.sql` ([data-model.md](data-model.md)).

**Testing**: unidad (máquina de estados del caso, firma y verificación de la lista, rotador,
destinatarios del megáfono, lectura de Sentry con servidor falso), integración con base real
(detalle y auditoría, casos y disputas de 004, megáfono, dominios), contrato (rutas nuevas contra
`specs/001-…/contracts/api.yaml`), cubit y widget (apps).

**Target Platform**: Android 10+ (conductor y pasajero), navegador (panel).

**Project Type**: mobile + web admin + API (monorepo existente).

**Performance Goals**: detalle del viaje < 2 s (SC-001); mensajes en < 10 s (SC-003); comunicado
audible en < 2 s (SC-004); cambio de dominio < 30 s (SC-005).

**Constraints**: sin teléfonos en el detalle (FR-002); notas internas nunca en rutas de usuario;
sin grabación del megáfono; credenciales de Sentry y clave privada de dominios solo en el
backend; una lista sin firma válida no cambia nada (SC-006).

**Scale/Scope**: piloto en una ciudad; decenas de conductores, pocos administradores.

## Constitution Check

| Principio | Cumplimiento |
|---|---|
| I. Clean-room | Flujos y textos propios a partir del SDD de Kyq; sin código ni recursos de terceros. |
| II. Adoptar antes que construir | LiveKit para el megáfono (salas de un solo uso, como 006), Centrifugo para los avisos, Sentry para las sesiones (ya integrado), Ed25519 de la biblioteca estándar. Sin servicio de tickets externo: el centro de soporte es pequeño y debe unirse a las disputas de 004. |
| III. Flutter | Pantallas nuevas en las tres apps; modelos en `kyq_api`, eventos en `kyq_realtime`, megáfono con `kyq_ptt`. |
| IV. Monolito modular Go | Módulos nuevos `support`, `megaphone`, `domains`; inspección en `control`; sesiones en `health`. |
| V. Reglas como contrato | RN-KYQ-001 sin cambios; FR de 004 se respetan (el caso es una vista, las reglas de pago no cambian). |
| VI. Pruebas | Según Technical Context. |
| VII. Coste medido | El detalle se refresca por consulta (5 s) solo con el panel abierto; Sentry con caché de 5 min; salas LiveKit de ≤ 60 s. |

Sin desviaciones. **Re-check post-diseño**: la sesión de alcance `support` amplía FR-016 de 007
(antes el suspendido no entraba); se limita en el middleware a `/v1/support/*`, la renovación y
el token de tiempo real.

## Project Structure

### Documentation (this feature)

```text
specs/009-ops-console-support/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/api.yaml      # vista de rutas nuevas (fusionadas en 001)
├── checklists/requirements.md
└── tasks.md
```

### Source Code (repository root)

```text
backend/
├── migrations/00014_ops_support.sql
├── cmd/domainsign/            # firma la lista inicial de dominios para las apps
├── internal/
│   ├── control/               # trip_id en la torre, detalle del viaje y auditoría
│   ├── support/               # casos, mensajes, bandeja, eventos, cierre automático
│   ├── trippay/               # caso de pago al disputar o marcar no pagado; sincroniza la resolución
│   ├── megaphone/             # comunicados de voz por hexágonos
│   ├── domains/               # dominios espejo, comprobación y lista firmada
│   ├── health/                # sesiones sin fallos desde Sentry
│   ├── auth/                  # sesión de alcance support para suspendidos
│   └── realtime/              # canal admin:support
apps/kyq_admin_web/lib/tower/      # detalle del viaje, selección de hexágonos y megáfono
apps/kyq_admin_web/lib/support/    # bandeja y caso
apps/kyq_admin_web/lib/domains/    # dominios espejo
apps/kyq_admin_web/lib/health/     # sesiones sin fallos
apps/kyq_rider_app/lib/support/    # Ayuda: casos del pasajero
apps/kyq_driver_app/lib/support/   # Ayuda: casos del conductor
apps/kyq_driver_app/lib/megaphone/ # comunicados de Kyq
packages/kyq_api/                  # modelos, métodos y rotador de dominios
packages/kyq_realtime/             # support.case, megaphone.*
packages/kyq_ui/                   # pantallas de soporte compartidas y modo suspendido
```

**Structure Decision**: monorepo existente; las pantallas de soporte del usuario viven en
`kyq_ui` porque son iguales en las dos apps.

## Complexity Tracking

Sin violaciones que justificar.
