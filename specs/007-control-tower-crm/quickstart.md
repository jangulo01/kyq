# Quickstart: validar la torre de control, Finanzas, Fidelización, moderación y salud

## Preparación

- Entorno de 001/002 en la VM (`infra/README.md`) con la migración `00012` aplicada
  (`docker compose up -d --build` la aplica con el job `migrate`), el perfil `routing` (OSRM y
  `tiles`) y `infra/centrifugo.json` con el namespace `admin` (reiniciar `centrifugo`).
- Panel: `flutter run -d chrome --dart-define=KYQ_API_URL=http://<vm>:8080
  --dart-define=KYQ_REALTIME_URL=ws://<vm>:8000/connection/websocket` desde
  `apps/kyq_admin_web` (opcional `KYQ_MAP_STYLE_URL`; por defecto `http://<vm>:8081/style.json`).
- Dos teléfonos de conductor con documentos y suscripción al día, y uno de pasajero afiliado.
- Tarifas de costo y precio de suscripción de 002 configurados.

## Escenarios

| # | Paso | Resultado esperado | Ref. |
|---|---|---|---|
| 1 | Abrir Torre con los dos conductores ONLINE en zonas distintas | Totales ONLINE 2, libres 2; dos hexágonos con un conductor libre cada uno; puntos verdes | FR-001–FR-004 |
| 2 | El pasajero pide un viaje al conductor A y A lo acepta | En < 10 s: A ocupado (punto naranja), 1 viaje activo y 1 solicitud en su hexágono, sin recargar | FR-005, SC-001 |
| 3 | El conductor B se pone OFFLINE | En < 10 s desaparece de la torre | FR-005 |
| 4 | Detener `centrifugo` en la VM con la torre abierta | La torre sigue actualizándose cada 30 s y muestra "Actualización periódica" | FR-005 |
| 5 | Cambiar la resolución a 7 y a 9 | Hexágonos más grandes / más pequeños con los mismos totales | FR-001 |
| 6 | Con un token de pasajero: `GET /v1/admin/tower` y suscripción a `admin:tower` | 403 en ambos | FR-006 |
| 7 | Abrir Finanzas (últimos 6 meses) | Una fila por mes; en el mes actual ingresos = pagos aprobados del mes y costo = suma de "Costos por conductor" del mes | FR-007, FR-008, SC-003 |
| 8 | Finanzas en un mes anterior a las tarifas | Costo 0 y aviso "faltan tarifas" | FR-009 |
| 9 | Abrir Fidelización con el periodo por defecto | Afiliaciones activas, serie semanal, repetición, SC-008 con la meta del 80 % y "en curso" para las de < 30 días | FR-010–FR-013 |
| 10 | En Usuarios, buscar al conductor A (libre) y suspenderlo con motivo | A pasa a OFFLINE en la torre; al volver a abrir la app, la sesión no se renueva: "cuenta suspendida" | FR-014–FR-016 |
| 11 | A intenta ponerse ONLINE con su sesión aún válida | Rechazo `account_suspended` | FR-016 |
| 12 | Reactivar a A con motivo | Puede volver a entrar; el historial muestra suspensión y reactivación con autor y motivo | FR-017, SC-006 |
| 13 | Abrir Salud | Todas "disponible" con latencia; Bold "desactivado" si `KYQ_BOLD_ENV` está vacío | FR-018 |
| 14 | `docker compose stop osrm` y refrescar Salud | Rutas "caída" y estado global "degradado"; ningún secreto en la respuesta | FR-019, FR-020 |

## Pruebas automatizadas

```bash
cd backend && KYQ_TEST_DATABASE_URL=... go test -count=1 ./...
melos run analyze && melos run test
cd apps/kyq_admin_web && flutter build web
```
