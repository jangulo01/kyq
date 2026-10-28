# Implementation Plan: Torre de control H3, CRM y economía unitaria

**Branch**: `007-control-tower-crm` | **Date**: 2026-10-27 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/007-control-tower-crm/spec.md`

## Summary

Cuatro módulos del panel de administración del SDD, solo para el rol admin: (1) torre de control
que agrega en hexágonos H3 los conductores ONLINE, los viajes activos y las solicitudes de la
última hora, dibujada con MapLibre sobre el mapa base propio y actualizada en vivo por un aviso en
Centrifugo; (2) Finanzas, el agregado mensual de ingresos por suscripción frente al costo de
infraestructura, reutilizando el cálculo de costos de 002; (3) Fidelización (afiliaciones,
repetición, SC-008 de 001, abandono) y moderación (suspender/reactivar con motivo y auditoría);
(4) Healthline, la salud de las dependencias con latencias. Backend: módulos nuevos `hexgrid`,
`control` (torre y su aviso en vivo), `crm` (indicadores y moderación) y `health`; cambios
pequeños en `auth`, `drivers`, `realtime` y `telemetry`; migración `00012_control_tower.sql`.

## Technical Context

**Language/Version**: Dart 3.12 / Flutter 3.44 (panel); Go 1.26 (backend)

**Primary Dependencies**: las de 001/002. Nuevas: backend `github.com/ziprecruiter/h3-go` v0.5.0
(H3 en Go puro, research R1). Panel: `maplibre_gl` ^0.27.1 (ya en el monorepo por la app de
pasajero) y `kyq_realtime`; en `web/index.html`, MapLibre GL JS 6.4.1 y `pmtiles` 4.4.1 por CDN con
versión exacta (research R4).

**Storage**: PostgreSQL 17 + PostGIS 3.5; migración `00012_control_tower.sql` (suspensión,
auditoría e índices; [data-model.md](data-model.md)). Nada nuevo en S3.

**Testing**: Go: unitarias (H3 contra h3-js, agregación de la torre, niveles, salud con
servidores falsos, autorización del canal), integración con base real (torre, finanzas, CRM,
moderación) y contrato (todas las rutas nuevas contra el contrato principal). Flutter: modelos y
cliente en `kyq_api`; cubits y widgets del panel (mapa sustituido).

**Target Platform**: navegador (panel). Sin cambios en las apps móviles.

**Project Type**: web admin + API (monorepo existente).

**Performance Goals**: torre < 2 s con 200 conductores ONLINE y 1 000 solicitudes/h (SC-002);
cambio visible < 10 s (SC-001); salud < 5 s (límite de 3 s por comprobación en paralelo).

**Constraints**: binario sin cgo (`CGO_ENABLED=0`, distroless); solo admins; el canal en vivo no
lleva datos personales; ninguna respuesta de salud con secretos.

**Scale/Scope**: piloto ~200 conductores, ~2 000 pasajeros; 1 ciudad, 1 moneda.

## Constitution Check

| Principio | Cumplimiento |
|---|---|
| I. Clean-room | Pantallas y cálculos propios. El código H3 portado es de la biblioteca abierta de Uber (Apache-2.0), no de los APK de referencia; se conserva la atribución. |
| II. Adoptar antes que construir | H3 para los hexágonos, Centrifugo para el aviso en vivo, MapLibre + PMTiles para el mapa. Desviación: se porta una parte de H3 a Go en vez de usar el binding oficial (cgo); ver Complexity Tracking. |
| III. Flutter | Pantallas nuevas en `kyq_admin_web`; modelos y métodos en `kyq_api`; evento nuevo en `kyq_realtime`. |
| IV. Monolito modular Go | Módulos `hexgrid`, `control`, `crm` y `health` dentro del mismo servicio. |
| V. Reglas como contrato | No cambia ninguna RN-KYQ. RN-KYQ-004 (transparencia de costos) se amplía al agregado mensual reutilizando su cálculo y su prueba; nueva prueba de que el total mensual = suma por conductor. |
| VI. Pruebas | Unidad, integración y contrato en Go; cubits y widgets en el panel. |
| VII. Coste medido | Finanzas es el panel de economía unitaria que exige VII. El aviso en vivo cuesta ≤ 1 evento cada 3 s (research R3); la torre no añade tablas ni servicios. |

**Re-check post-diseño**: sin servicios nuevos; la única dependencia Go nueva es de Go puro;
las dependencias web van fijadas por versión exacta.

## Project Structure

### Documentation (this feature)

```text
specs/007-control-tower-crm/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/api.yaml      # rutas nuevas y cambiadas (fusionadas en el contrato de 001)
├── checklists/requirements.md
└── tasks.md
```

### Source Code (repository root)

```text
backend/
├── migrations/00012_control_tower.sql
├── internal/
│   ├── hexgrid/        # H3 sin cgo: índice (ziprecruiter) + centro y contorno portados
│   ├── control/        # torre: instantánea, agregación, aviso tower.changed
│   ├── crm/            # indicadores de fidelización y moderación de usuarios
│   ├── health/         # Healthline: comprobaciones en paralelo
│   ├── auth/           # 403 account_suspended en verify y refresh
│   ├── drivers/        # 409 account_suspended al ponerse ONLINE
│   ├── realtime/       # canal admin:tower solo para admins
│   ├── telemetry/      # GET /v1/admin/finance sobre los costos de 002
│   └── storage/        # Ping del bucket para la salud
infra/centrifugo.json   # namespace admin
apps/kyq_admin_web/
├── web/index.html      # MapLibre GL JS + protocolo pmtiles
└── lib/{tower,finance,crm,users,health}/
packages/kyq_api/       # modelos y métodos nuevos
packages/kyq_realtime/  # evento tower.changed y canal admin:tower
```

**Structure Decision**: monorepo de 001/002; un paquete Go por módulo con handlers, servicio y
consultas sqlc (`internal/store/queries/{control,crm,moderation,finance}.sql`); el panel añade una
carpeta por sección.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|---|---|---|
| Portar ~400 líneas de H3 (centro y contorno) a Go en vez de usar `uber/h3-go` | El binding oficial exige cgo: la imagen se compila con `CGO_ENABLED=0` sobre distroless y el entorno de desarrollo no tiene compilador C | `h3-pg` no está en la imagen de PostGIS; `goh3` no compila en Windows; las demás bibliotecas puras no exponen el contorno. El port se verifica contra 204 casos de h3-js (research R1). |
