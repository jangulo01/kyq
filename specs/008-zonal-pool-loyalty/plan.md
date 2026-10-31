# Implementation Plan: Bolsa zonal y fidelización ampliada

**Branch**: `008-zonal-pool-loyalty` | **Date**: 2026-10-28 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/008-zonal-pool-loyalty/spec.md`

## Summary

La bolsa zonal es un tercer modo de despacho del agregado del viaje (`zone_pool`) que reutiliza
la maquinaria de traspaso de 006: el primer conductor se elige con una consulta PostGIS entre los
que activaron la bolsa (libres, no suspendidos, ubicación ≤ 5 min, ≤ 5 km), y si rechaza o deja
vencer la oferta, el mismo `handOverOrGiveUp` pasa al siguiente (hasta 3). El pasajero puede
pedir a la bolsa sin Conductor Elegido. Las preferencias de despacho del conductor (bolsa y
descuento preferencial de 0–30 %) son columnas nuevas de `drivers`; el descuento se aplica al
crear o traspasar la oferta solo si el conductor ofertado tiene al pasajero en su cartera. La
oferta lleva su origen (cartera, cooperativa, bolsa), los viajes juntos y la distancia a la
recogida. Las afiliaciones registran su origen (QR, después del viaje, enlace) y el informe de
fidelización de 007 lo desglosa. Cambios en `trips`, `affiliations`, `crm`, `drivers`; pantallas
nuevas o cambiadas en las apps de conductor, pasajero y panel.

## Technical Context

**Language/Version**: Dart 3.12 / Flutter 3.44 (apps); Go 1.26 (backend)

**Primary Dependencies**: las existentes (pgx, sqlc, goose, PostGIS, Centrifugo, `share_plus`
en las apps); sin dependencias nuevas.

**Storage**: PostgreSQL 17 + PostGIS; migración `00013_zonal_pool.sql` ([data-model.md](data-model.md)).

**Testing**: unidad (agregado del viaje, descuento), integración con base real (candidatos de la
bolsa, traspasos, descuento, afiliación por origen, informe), contrato (rutas cambiadas contra
`specs/001-…/contracts/api.yaml`), cubit y widget (apps).

**Target Platform**: Android 10+ (conductor y pasajero), navegador (panel).

**Project Type**: mobile + web admin + API (monorepo existente).

**Performance Goals**: oferta de la bolsa en < 2 s (SC-001): una consulta PostGIS con
`FOR UPDATE SKIP LOCKED` dentro de la transacción del pedido o del vencimiento.

**Constraints**: comisión 0 (RN-KYQ-001); sin consultas de ruta por candidato (línea recta, como
006); la página pública del enlace no expone teléfono, foto ni placa.

**Scale/Scope**: piloto en una ciudad, decenas de conductores en la bolsa.

## Constitution Check

| Principio | Cumplimiento |
|---|---|
| I. Clean-room | Nombres y flujos propios; el SDD de Kyq (selector triple, Prioridad Oro, orígenes de afiliación) es la fuente. |
| II. Adoptar antes que construir | PostGIS para la cercanía (sin H3 en el despacho: la distancia en línea recta ya resuelve la cercanía); Centrifugo para las ofertas; `share_plus` para compartir el enlace. |
| III. Flutter | Cambios en las tres apps; modelos en `kyq_api`, eventos en `kyq_realtime`. |
| IV. Monolito modular Go | Sin módulos nuevos: despacho en `trips`, preferencias en `drivers`, origen en `affiliations`, informe en `crm`. |
| V. Reglas como contrato | RN-KYQ-001 (bolsa y descuento con comisión 0), RN-KYQ-005 (afiliación por origen), RN-KYQ-007 (25 s en la bolsa), RN-KYQ-013 (tarifa preferencial). Se etiquetan además las pruebas existentes de RN-KYQ-006 y RN-KYQ-011, que no nombraban su regla. |
| VI. Pruebas | Unidad, integración, contrato y widget según Technical Context. |
| VII. Coste medido | Sin rutas por candidato; los eventos nuevos cuentan en el uso del conductor; sin servicios nuevos. |

Sin desviaciones. **Re-check post-diseño**: la migración solo añade columnas, valores de enum y
relaja una restricción (`dispatch = 'cooperative'` exige cooperativa, no `chosen_driver`).

## Project Structure

### Documentation (this feature)

```text
specs/008-zonal-pool-loyalty/
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
├── migrations/00013_zonal_pool.sql
├── internal/
│   ├── trips/          # modo zone_pool, candidatos de la bolsa, tarifa preferencial, origen de la oferta
│   ├── drivers/        # preferencias de despacho (GET/PUT /v1/driver/dispatch-settings), enlace
│   ├── affiliations/   # origen QR / después del viaje / enlace; página pública /a/{token}
│   ├── crm/            # nuevas afiliaciones por origen
│   └── store/queries/  # trips.sql, cooperatives.sql (candidatos), drivers.sql, affiliations.sql
apps/kyq_rider_app/lib/request/        # bolsa desde el inicio y opción 3 del selector
apps/kyq_rider_app/lib/chosen_drivers/ # botón "Pedir a un conductor cercano", afiliación por enlace
apps/kyq_rider_app/lib/trip/           # "Guardar como Conductor Elegido" en el resumen
apps/kyq_driver_app/lib/dispatch/      # ajustes: bolsa y tarifa preferencial
apps/kyq_driver_app/lib/offers/        # origen de la oferta, viajes juntos, distancia
apps/kyq_driver_app/lib/onboarding/    # compartir enlace (Mi QR), origen en Mis clientes
apps/kyq_admin_web/lib/crm/            # afiliaciones nuevas por origen
packages/kyq_api/                      # modelos y métodos nuevos
packages/kyq_realtime/                 # campos nuevos de trip.offer
```

**Structure Decision**: monorepo existente; sin paquetes nuevos.

## Complexity Tracking

Sin violaciones que justificar.
