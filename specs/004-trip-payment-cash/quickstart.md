# Quickstart: validar el pago del viaje con Bold o en efectivo

## Preparación

- Entorno de 002 en la VM con la migración `00009_trip_payments.sql` aplicada y Bold de pruebas
  (`KYQ_BOLD_ENV=sandbox`, llaves de pruebas en `infra/.env`). No hay variables nuevas.
- Un conductor con documentos al día y suscripción activa, un pasajero afiliado y la tabla de
  tarifas de la ciudad (como en 001).
- Medios de prueba de Bold: los del ambiente de pruebas (developers.bold.co).

## Escenarios

| # | Paso | Resultado esperado | Ref. |
|---|---|---|---|
| 1 | Completar un viaje (tarifa acordada 18 000 COP) | Ambos ven el resumen con "Total $ 18.000", 100 % al conductor, comisión 0 y el pago "Pendiente" con efectivo y Bold | FR-001, FR-002 |
| 2 | Pasajero: "Pagué en efectivo" | Pasajero ve "Esperando confirmación"; el conductor ve el reporte en vivo | FR-004, US1-2 |
| 3 | Conductor: "Recibí el efectivo" | Ambos ven "Pagado en efectivo" con la hora | FR-005, US1-3 |
| 4 | Otro viaje: pasajero reporta efectivo y el conductor toca "No recibí el efectivo" | "En disputa" en ambas apps; aparece en Panel → Pagos de viajes → Incidencias | FR-005, FR-017 |
| 5 | Panel: resolver la disputa como "pagado en efectivo" con nota | Pagado; la nota y el administrador quedan en el pago | FR-017 |
| 6 | Otro viaje: pasajero "Pagar con Bold" y paga con tarjeta de pruebas aprobada | Checkout con 18 000 COP; al volver, "Pagado con Bold" < 1 min; el conductor recibe aviso; su saldo por girar sube 18 000 | FR-003, FR-009, FR-011, SC-002 |
| 7 | Repetir "refresh" / webhook firmado duplicado del mismo pago | Un solo abono en el libro | FR-009, SC-003 |
| 8 | Pago rechazado o enlace caducado en el sandbox | "El pago no se completó"; puede reintentar o reportar efectivo | US2-4 |
| 9 | Viaje sin pago ni reporte; esperar 10 min | Recordatorio en vivo al pasajero y aviso al conductor, una vez; al abrir la app del pasajero, "Tienes un viaje sin pagar" | FR-015, FR-016 |
| 10 | Conductor: "No me pagó" | "No pagado" en ambas apps y en Incidencias; luego el pasajero paga con Bold → pagado | FR-006, US3-4 |
| 11 | Conductor desactiva efectivo en Pagos de viajes y completa otro viaje | El pasajero solo ve "Pagar con Bold"; desactivar ambos da error | FR-018 |
| 12 | Panel → Liquidaciones: giro por el saldo con referencia | Saldo 0; el conductor ve el giro y un aviso; un giro mayor al saldo se rechaza | FR-012, FR-013 |
| 13 | Panel: anular el pago del escenario 6 con motivo "reembolsado" | Pago anulado y débito de 18 000 en el libro | FR-014 |

## Pruebas automáticas

- `go test ./...` con `KYQ_TEST_DATABASE_URL`: transiciones (tabla), RN-KYQ-001 (comisión 0 y
  abono del 100 %), efectivo, Bold con servidor falso (sondeo, webhook delegado, idempotencia,
  valor distinto, segundo cobro, anulación), libro y giros, recordatorios, medios aceptados y
  contrato de las rutas nuevas.
- `melos run test`: modelos y cliente, eventos en vivo, resumen del pasajero (Bold y efectivo),
  aviso de pendientes, resumen y pagos del conductor, panel de pagos y liquidaciones.
