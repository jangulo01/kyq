# Validación: Pago del viaje con Bold o en efectivo

Resultados de T033 ([quickstart.md](quickstart.md)). Plantilla preparada antes del despliegue:
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
| 1 | Completar un viaje (tarifa acordada 18 000 COP) | Ambos ven el resumen con "Total $ 18.000", 100 % al conductor, comisión 0 y el pago "Pendiente" con efectivo y Bold | FR-001, FR-002 | Pendiente | |
| 2 | Pasajero: "Pagué en efectivo" | Pasajero ve "Esperando confirmación"; el conductor ve el reporte en vivo | FR-004, US1-2 | Pendiente | |
| 3 | Conductor: "Recibí el efectivo" | Ambos ven "Pagado en efectivo" con la hora | FR-005, US1-3 | Pendiente | |
| 4 | Otro viaje: pasajero reporta efectivo y el conductor toca "No recibí el efectivo" | "En disputa" en ambas apps; aparece en Panel → Pagos de viajes → Incidencias | FR-005, FR-017 | Pendiente | |
| 5 | Panel: resolver la disputa como "pagado en efectivo" con nota | Pagado; la nota y el administrador quedan en el pago | FR-017 | Pendiente | |
| 6 | Otro viaje: pasajero "Pagar con Bold" y paga con tarjeta de pruebas aprobada | Checkout con 18 000 COP; al volver, "Pagado con Bold" < 1 min; el conductor recibe aviso; su saldo por girar sube 18 000 | FR-003, FR-009, FR-011, SC-002 | Pendiente | |
| 7 | Repetir "refresh" / webhook firmado duplicado del mismo pago | Un solo abono en el libro | FR-009, SC-003 | Pendiente | |
| 8 | Pago rechazado o enlace caducado en el sandbox | "El pago no se completó"; puede reintentar o reportar efectivo | US2-4 | Pendiente | |
| 9 | Viaje sin pago ni reporte; esperar 10 min | Recordatorio en vivo al pasajero y aviso al conductor, una vez; al abrir la app del pasajero, "Tienes un viaje sin pagar" | FR-015, FR-016 | Pendiente | |
| 10 | Conductor: "No me pagó" | "No pagado" en ambas apps y en Incidencias; luego el pasajero paga con Bold → pagado | FR-006, US3-4 | Pendiente | |
| 11 | Conductor desactiva efectivo en Pagos de viajes y completa otro viaje | El pasajero solo ve "Pagar con Bold"; desactivar ambos da error | FR-018 | Pendiente | |
| 12 | Panel → Liquidaciones: giro por el saldo con referencia | Saldo 0; el conductor ve el giro y un aviso; un giro mayor al saldo se rechaza | FR-012, FR-013 | Pendiente | |
| 13 | Panel: anular el pago del escenario 6 con motivo "reembolsado" | Pago anulado y débito de 18 000 en el libro | FR-014 | Pendiente | |

## Incidencias

Ninguna registrada todavía.
