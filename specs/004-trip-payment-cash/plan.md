# Implementation Plan: Pago del viaje con Bold o en efectivo

**Branch**: `004-trip-payment-cash` | **Date**: 2026-10-27 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/004-trip-payment-cash/spec.md`

## Summary

Al completarse un viaje, el módulo de viajes abre en la misma transacción un **pago del viaje**
(tarifa acordada, 100 % para el conductor, comisión 0, medios que acepta el conductor). El
pasajero paga con un enlace de pago de Bold (el mismo cliente, sondeo y webhook de 002) o reporta
efectivo; el conductor confirma, disputa o marca "no pagado". Los pagos aprobados por Bold abonan
el 100 % en un libro de liquidación por conductor; el administrador registra los giros hechos por
fuera. Nuevo módulo `trippay` en el monolito; `billing` expone la clasificación de enlaces y
delega en `trippay` los webhooks cuya referencia no es un pago de suscripción.

## Technical Context

**Language/Version**: Dart 3.12 / Flutter 3.44 (apps); Go 1.26 (backend)

**Primary Dependencies**: las de 001 y 002. Nueva en la app del pasajero: `url_launcher` (la
misma versión que ya usa la app del conductor) para abrir el checkout de Bold en una Custom Tab.
Backend sin dependencias nuevas.

**Storage**: PostgreSQL 17, migración `00009_trip_payments.sql` (ver [data-model.md](data-model.md)).

**Testing**: como 002. Integración Go con base real y un servidor Bold falso (`httptest`) detrás
del `BoldClient` real; pruebas de contrato con kin-openapi; widget y cubit en las tres apps.

**Target Platform**: Android 10+ (pasajero y conductor), navegador (panel).

**Project Type**: mobile + web admin + API (monorepo existente).

**Performance Goals**: pago aprobado visible < 1 min (SC-002): sondeo cada 10 s + comprobación al
volver del checkout + webhook.

**Constraints**: Kyq no toca datos de tarjeta; el valor lo fija el servidor; un único webhook de
Bold por cuenta (se comparte con la suscripción); sin push (eventos en vivo y avisos en la app).

**Scale/Scope**: piloto ~200 conductores; ~5 000 viajes/mes.

## Constitution Check

| Principio | Cumplimiento |
|---|---|
| I. Clean-room | Flujo de pago propio; nada tomado de los APK de referencia. |
| II. Adoptar antes que construir | Checkout alojado por Bold; se reutiliza el cliente Bold, el sondeo y el webhook de 002 en vez de duplicarlos. |
| III. Flutter | Pantallas nuevas en las tres apps; modelos en `kyq_api`, eventos en `kyq_realtime`, etiquetas en `kyq_ui`. |
| IV. Monolito modular Go | Módulo nuevo `trippay` en el mismo servicio; `trips` no lo importa (gancho por interfaz). |
| V. Reglas como contrato | RN-KYQ-001: `platform_commission_minor = 0` y `driver_amount_minor = amount_minor` como CHECK en la base, prueba unitaria de la liquidación y prueba de integración del abono 100 % en el libro. |
| VI. Pruebas | Unidad (transiciones del pago, comisión), integración (efectivo, Bold con sondeo y webhook idempotentes, libro, giros, recordatorios), contrato (rutas nuevas), widget (resumen del pasajero y del conductor, panel). |
| VII. Coste medido | Sin infraestructura nueva; el sondeo comparte el ritmo del de 002. La comisión de Bold la asume Kyq (Assumptions); su medición en RN-KYQ-004 queda para una fase posterior. |

Sin desviaciones. **Re-check post-diseño**: el modelo y los contratos no añaden servicios; el
webhook sigue siendo uno solo.

## Project Structure

### Documentation (this feature)

```text
specs/004-trip-payment-cash/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/api.yaml      # rutas nuevas (fusionadas en el contrato principal de 001)
├── checklists/requirements.md
└── tasks.md
```

### Source Code (repository root)

```text
backend/
├── migrations/00009_trip_payments.sql
├── internal/
│   ├── trippay/        # pago del viaje, transiciones, Bold, libro, giros, barrido, rutas
│   ├── billing/        # ClassifyLink exportado; webhook delega referencias de viajes
│   ├── trips/          # gancho PaymentOpener al completar
│   ├── store/queries/trip_payments.sql
│   └── contracttest/   # recorrido de las rutas nuevas contra el contrato
apps/kyq_rider_app/lib/
│   ├── trip/           # sección de pago en el resumen, cubit y checkout
│   └── payments/       # aviso de viajes sin pagar en la pantalla principal
apps/kyq_driver_app/lib/
│   ├── trip/           # pago en el resumen (confirmar, disputar, no pagado)
│   └── trip_payments/  # pagos de viajes, saldo, libro y medios aceptados
apps/kyq_admin_web/lib/
│   └── trip_payments/  # pagos por estado, resolución, anulación, liquidaciones y giros
packages/kyq_api/       # modelos y métodos nuevos
packages/kyq_realtime/  # trip_payment.updated y trip_payment.reminder
packages/kyq_ui/        # etiquetas de estado del pago
```

**Structure Decision**: monorepo de 001/002; un paquete Go por módulo; las apps añaden carpetas
por funcionalidad.

## Complexity Tracking

Sin violaciones que justificar.
