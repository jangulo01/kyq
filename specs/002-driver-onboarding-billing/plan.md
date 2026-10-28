# Implementation Plan: Alta autónoma del conductor, validación documental y suscripción con Bold

**Branch**: `002-driver-onboarding-billing` | **Date**: 2026-10-27 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/002-driver-onboarding-billing/spec.md`

## Summary

El conductor se registra solo desde Kyq Conductor, completa vehículo y sube fotos de cinco
documentos; el administrador los valida en una cola del panel y el sistema avisa y bloquea por
vencimiento. La suscripción mensual se paga con un enlace de pago de Bold abierto en una Custom
Tab; el backend confirma el pago consultando el estado del enlace (y por webhook firmado en
producción) y extiende `paid_until` una sola vez por pago. La app y el panel muestran el costo
medido de cada conductor frente a su suscripción (RN-KYQ-004). Extiende los módulos `auth`,
`drivers` y `admin` del monolito de 001 y añade `kyc`, `billing` y `notify`.

## Technical Context

**Language/Version**: Dart 3.12 / Flutter 3.44 (apps); Go 1.26 (backend)

**Primary Dependencies**: las de 001. Nuevas: Apps: `image_picker` (cámara/galería),
`flutter_image_compress` (fotos ≤ 1 MB), `url_launcher` con Custom Tabs para el checkout de Bold.
Backend: `minio-go` v7 (S3 compatible: MinIO en la VM, R2 en producción) para fotos y URLs
firmadas. Bold por HTTP directo (sin SDK oficial en Go).

**Storage**: PostgreSQL 17 (nuevas tablas en [data-model.md](data-model.md)); fotos en un bucket
privado S3 compatible (`kyq-kyc`), nunca públicas.

**Testing**: como 001. Pruebas Go de integración con base real; cliente Bold contra un servidor
HTTP falso en pruebas y contra el sandbox de Bold en el quickstart.

**Target Platform**: Android 10+ (conductor), navegador (panel). Sin cambios en el pasajero.

**Project Type**: mobile + web admin + API (monorepo existente).

**Performance Goals**: pago aprobado reflejado < 1 min (SC-003); subida de una foto < 5 s en 4G.

**Constraints**: Kyq no toca datos de tarjeta (Bold aloja el checkout); fotos de documentos solo
para el conductor y admins (FR-011); sin push (avisos en app + SMS); sandbox de Bold sin webhooks.

**Scale/Scope**: piloto ~200 conductores; ~200 pagos/mes; ~1 000 fotos.

## Constitution Check

| Principio | Cumplimiento |
|---|---|
| I. Clean-room | Flujos propios; nada tomado de los APK de referencia. |
| II. Adoptar antes que construir | Checkout alojado por Bold; almacenamiento S3 (MinIO/R2) en vez de guardar fotos en disco o BD; SMS con la interfaz existente. |
| III. Flutter | Pantallas nuevas en `kyq_driver_app` y `kyq_admin_web`; modelos en `kyq_api`. |
| IV. Monolito modular Go | Módulos nuevos `kyc`, `billing`, `notify` dentro del mismo servicio. Sin Redis (como 001, R13). |
| V. Reglas como contrato | RN-KYQ-001 (sin comisión, solo suscripción), 002/003 (gracia y bloqueo, ya probadas; se amplían a pagos), 004 (transparencia, nueva prueba), 016 (documentos: nuevos tipos y estados). |
| VI. Pruebas | Unidad (reglas de extensión, firma Bold, estados), integración (webhook idempotente, sondeo, cola KYC), widget (alta, documentos, pago). |
| VII. Coste medido | RN-KYQ-004 reutiliza `driver_usage_daily` de 001 y añade tarifas configurables; MinIO va en la VM existente. |

Sin desviaciones. **Re-check post-diseño**: el modelo y los contratos no añaden servicios fuera
del monolito; MinIO es infraestructura de almacenamiento ya prevista (principio IV, "S3").

## Project Structure

### Documentation (this feature)

```text
specs/002-driver-onboarding-billing/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/api.yaml      # rutas nuevas y cambiadas
├── checklists/requirements.md
└── tasks.md                # /speckit-tasks
```

### Source Code (repository root)

```text
backend/
├── migrations/00007_kyc_billing.sql
├── internal/
│   ├── kyc/            # documentos, fotos (S3), cola de revisión, vencimientos
│   ├── billing/        # precios, pagos, cliente Bold, webhook, sondeo, recordatorios
│   ├── notify/         # avisos en app + SMS, programados y deduplicados
│   ├── auth/           # alta como conductor (rol en verify)
│   ├── drivers/        # gate: nuevos tipos de documento y estados
│   ├── telemetry/      # costos por conductor (RN-KYQ-004)
│   └── storage/        # cliente S3 (MinIO/R2), URLs firmadas
apps/kyq_driver_app/lib/
│   ├── onboarding/     # alta, vehículo, documentos (cámara)
│   ├── subscription/   # estado, pagar (Custom Tab), historial, costos
│   └── notices/        # avisos en la app
apps/kyq_admin_web/lib/
│   ├── kyc/            # cola de revisión y expediente
│   ├── billing/        # suscripciones, pagos, precios, pago manual/anulación
│   └── costs/          # costos por conductor y tarifas
packages/kyq_api/       # modelos y métodos nuevos
infra/                  # servicio minio + bucket; KYQ_BOLD_* y KYQ_S3_* en .env
```

**Structure Decision**: monorepo de 001; un paquete Go por módulo con handlers, servicio y
consultas sqlc; las apps añaden carpetas por funcionalidad.

## Complexity Tracking

Sin violaciones que justificar.
