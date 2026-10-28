# Implementation Plan: Cooperativas y delegación inteligente

**Branch**: `006-cooperatives-delegation` | **Date**: 2026-10-27 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/006-cooperatives-delegation/spec.md`

## Summary

El administrador crea cooperativas y gestiona sus miembros y coordinadores desde el panel; los
conductores piden entrar desde la app y un admin o un coordinador decide. Al pedir un viaje, el
pasajero elige entre su Conductor Elegido (con consentimiento opcional de delegación) y la
cooperativa de ese conductor. La delegación (RN-KYQ-008) es una transición del agregado del viaje
de 001: cuando la oferta termina sin conductor, en la misma transacción se reasigna al compañero
libre más cercano según PostGIS, con la misma oferta de 25 s, hasta 3 pasos. Cada cooperativa
tiene un canal PTT de grupo (`COOP_GROUP`) que reutiliza el control de turno del módulo `ptt`.
Nuevo módulo Go `cooperatives`; cambios en `trips`, `ptt`, `affiliations`; pantallas nuevas en
las tres apps.

## Technical Context

**Language/Version**: Dart 3.12 / Flutter 3.44 (apps); Go 1.26 (backend)

**Primary Dependencies**: las de 001 y 002, sin dependencias nuevas.

**Storage**: PostgreSQL 17 + PostGIS (tablas nuevas en [data-model.md](data-model.md)).

**Testing**: unidad (agregado del viaje), integración con base real (delegación, membresías,
canal de grupo), contrato (rutas nuevas contra `contracts/api.yaml` fusionado), widget y cubit
(apps).

**Target Platform**: Android 10+ (conductor y pasajero), navegador (panel).

**Project Type**: mobile + web admin + API (monorepo existente).

**Performance Goals**: paso a un compañero < 2 s (SC-001): una consulta PostGIS dentro de la
transacción del vencimiento o del rechazo; el barrido de 001 corre cada segundo.

**Constraints**: comisión 0 (RN-KYQ-001); sin consultas de ruta por candidato (coste medido);
voz del grupo sin almacenar.

**Scale/Scope**: piloto con pocas cooperativas de decenas de miembros.

## Constitution Check

| Principio | Cumplimiento |
|---|---|
| I. Clean-room | Flujos y nombres propios; el SDD de Kyq es la única fuente. |
| II. Adoptar antes que construir | PostGIS para la cercanía; LiveKit para la sala de grupo; Centrifugo para avisos de membresía. |
| III. Flutter | Pantallas en las tres apps; modelos en `kyq_api`; `PttController` reutilizado. |
| IV. Monolito modular Go | Módulo nuevo `cooperatives` en el mismo servicio; la delegación vive en `trips`. |
| V. Reglas como contrato | RN-KYQ-008 (nueva: pruebas de integración y de unidad), RN-KYQ-001 (viaje derivado con comisión 0), RN-KYQ-007 (25 s también en cada paso). |
| VI. Pruebas | Unidad, integración, contrato y widget según Technical Context. |
| VII. Coste medido | Eventos nuevos cuentan en `driver_usage_daily`; sin rutas extra; la sala de grupo se borra vacía. |

Sin desviaciones. **Re-check post-diseño**: sin servicios nuevos; la migración solo añade tablas,
columnas y un valor de enum.

## Project Structure

### Documentation (this feature)

```text
specs/006-cooperatives-delegation/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/api.yaml      # rutas nuevas y cambiadas (fusionadas en 001)
├── checklists/requirements.md
└── tasks.md
```

### Source Code (repository root)

```text
backend/
├── migrations/00011_cooperatives.sql
├── internal/
│   ├── cooperatives/   # cooperativas, membresías, coordinadores (admin, conductor)
│   ├── trips/          # despacho, delegación (HandOver/GiveUp), candidatos PostGIS
│   ├── ptt/            # canal de grupo COOP_GROUP
│   ├── affiliations/   # cooperativa del Conductor Elegido en la lista del pasajero
│   └── store/queries/cooperatives.sql
apps/kyq_driver_app/lib/cooperative/   # mi cooperativa, solicitudes, canal de grupo
apps/kyq_driver_app/lib/offers/        # "Pasar a mi cooperativa", oferta derivada
apps/kyq_rider_app/lib/request/        # selector de despacho y consentimiento
apps/kyq_rider_app/lib/trip/           # aviso de derivación y nombre del compañero
apps/kyq_admin_web/lib/cooperatives/   # lista, alta, detalle, solicitudes, roles
packages/kyq_api/                      # modelos y métodos nuevos
packages/kyq_realtime/                 # trip.delegated, cooperative.membership, campos de oferta
packages/kyq_ptt/                      # PttApi del canal de grupo
```

**Structure Decision**: monorepo existente; un paquete Go por módulo con handlers, servicio y
consultas sqlc; las apps añaden carpetas por funcionalidad.

## Complexity Tracking

Sin violaciones que justificar.
