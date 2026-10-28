# Validación: Torre de control, Finanzas, Fidelización, moderación y salud

Resultados de T036 ([quickstart.md](quickstart.md)). Plantilla preparada antes del despliegue:
se rellena al recorrer los escenarios en la VM y en los teléfonos.

## Entorno

- Fecha:
- Commit desplegado (`git rev-parse --short HEAD`):
- VM (host, `KYQ_PUBLIC_HOST`):
- Teléfonos (modelo, Android, con o sin Google Play Services):
- Bold (`KYQ_BOLD_ENV`):

## Escenarios

| # | Paso | Resultado esperado | Ref. | Resultado | Notas |
|---|---|---|---|---|---|
| 1 | Abrir Torre con los dos conductores ONLINE en zonas distintas | Totales ONLINE 2, libres 2; dos hexágonos con un conductor libre cada uno; puntos verdes | FR-001–FR-004 | Pendiente | |
| 2 | El pasajero pide un viaje al conductor A y A lo acepta | En < 10 s: A ocupado (punto naranja), 1 viaje activo y 1 solicitud en su hexágono, sin recargar | FR-005, SC-001 | Pendiente | |
| 3 | El conductor B se pone OFFLINE | En < 10 s desaparece de la torre | FR-005 | Pendiente | |
| 4 | Detener `centrifugo` en la VM con la torre abierta | La torre sigue actualizándose cada 30 s y muestra "Actualización periódica" | FR-005 | Pendiente | |
| 5 | Cambiar la resolución a 7 y a 9 | Hexágonos más grandes / más pequeños con los mismos totales | FR-001 | Pendiente | |
| 6 | Con un token de pasajero: `GET /v1/admin/tower` y suscripción a `admin:tower` | 403 en ambos | FR-006 | Pendiente | |
| 7 | Abrir Finanzas (últimos 6 meses) | Una fila por mes; en el mes actual ingresos = pagos aprobados del mes y costo = suma de "Costos por conductor" del mes | FR-007, FR-008, SC-003 | Pendiente | |
| 8 | Finanzas en un mes anterior a las tarifas | Costo 0 y aviso "faltan tarifas" | FR-009 | Pendiente | |
| 9 | Abrir Fidelización con el periodo por defecto | Afiliaciones activas, serie semanal, repetición, SC-008 con la meta del 80 % y "en curso" para las de < 30 días | FR-010–FR-013 | Pendiente | |
| 10 | En Usuarios, buscar al conductor A (libre) y suspenderlo con motivo | A pasa a OFFLINE en la torre; al volver a abrir la app, la sesión no se renueva: "cuenta suspendida" | FR-014–FR-016 | Pendiente | |
| 11 | A intenta ponerse ONLINE con su sesión aún válida | Rechazo `account_suspended` | FR-016 | Pendiente | |
| 12 | Reactivar a A con motivo | Puede volver a entrar; el historial muestra suspensión y reactivación con autor y motivo | FR-017, SC-006 | Pendiente | |
| 13 | Abrir Salud | Todas "disponible" con latencia; Bold "desactivado" si `KYQ_BOLD_ENV` está vacío | FR-018 | Pendiente | |
| 14 | `docker compose stop osrm` y refrescar Salud | Rutas "caída" y estado global "degradado"; ningún secreto en la respuesta | FR-019, FR-020 | Pendiente | |

## Comprobaciones añadidas en la integración

Suspensión de conductores y pasajeros (cubiertas también por pruebas de integración en
`backend/internal/trips/suspension_test.go`).

| # | Paso | Resultado esperado | Ref. | Resultado | Notas |
|---|---|---|---|---|---|
| 15 | Suspender al conductor A durante un viaje aceptado y completar el viaje | El viaje termina con normalidad; A queda OFFLINE (no libre) en la torre y no recibe solicitudes | FR-016, edge case "no puede iniciar otro" | Pendiente | |
| 16 | Con A y B en la misma cooperativa (006), suspender a B y pedir a A con consentimiento estando A ocupado | B no recibe la oferta aunque esté cerca; sin otro compañero libre, `no_driver_available` | FR-016, RN-KYQ-008 | Pendiente | |
| 17 | Suspender al pasajero y, con su sesión aún válida, pedir un viaje | Rechazo `account_suspended` con "Tu cuenta está suspendida" | FR-016 | Pendiente | |
| 18 | Suspender a A con una oferta abierta e intentar aceptarla | Rechazo `account_suspended`; al rechazarla o caducar queda OFFLINE | FR-016 | Pendiente | |

## Incidencias

Ninguna registrada todavía.
