# Quickstart: validar alta, KYC y suscripción con Bold

## Preparación

- Entorno de 001 en la VM (`infra/README.md`) más el servicio `minio` (bucket privado
  `kyq-kyc`) y en `infra/.env`: `KYQ_BOLD_ENV=sandbox`, `KYQ_BOLD_IDENTITY_KEY`,
  `KYQ_BOLD_SECRET_KEY` (llaves de pruebas de Bold) y `KYQ_S3_*`.
- Precio de prueba: `PUT /v1/admin/subscription-prices/bogota` (p. ej. 50 000 COP).
- Tarifas de costo de ejemplo con `PUT /v1/admin/cost-rates`.
- Tarjetas y medios de prueba: los del ambiente de pruebas de Bold
  (developers.bold.co → Botón de pagos → Ambiente de pruebas).

## Escenarios

| # | Paso | Resultado esperado | Ref. |
|---|---|---|---|
| 1 | Teléfono nuevo → "Soy conductor" → OTP → vehículo | Cuenta en `documents_pending`, lista de 5 documentos | FR-001, FR-002 |
| 2 | Teléfono de un pasajero intenta registrarse como conductor | 409 `phone_has_other_role` con mensaje claro | FR-003 |
| 3 | Subir los 5 documentos con foto | Estado `in_review`; no puede ponerse ONLINE | FR-004–006 |
| 4 | Admin rechaza el SOAT con motivo, aprueba el resto | Conductor ve el motivo y un aviso; reenvía solo el SOAT | FR-007, FR-008 |
| 5 | Admin aprueba el SOAT reenviado | `documents_ok`; aún bloqueado por suscripción sin pagar | FR-004 |
| 6 | Conductor paga en el sandbox de Bold con tarjeta aprobada | Pago `approved` < 1 min; suscripción activa un mes; puede ponerse ONLINE | FR-014–016, SC-003 |
| 7 | Repetir la comprobación del mismo pago / simular webhook duplicado firmado | La suscripción no se extiende dos veces | FR-016, SC-005 |
| 8 | Pago rechazado en el sandbox | Estado `rejected`, botón para reintentar | escenario US3-4 |
| 9 | Webhook con firma inválida | 401 y registro; nada cambia | FR-016 |
| 10 | Admin registra un pago manual y luego lo anula con motivo | Vence un mes después y vuelve al estado anterior; ambos auditados | FR-021 |
| 11 | Poner un SOAT a vencer en 3 días (fecha de prueba) y correr el barrido | Aviso en la app y SMS (en desarrollo: registro) una sola vez | FR-010, FR-027 |
| 12 | Conductor con usos del mes abre "Tu suscripción" | Desglose voz / tiempo real / rutas / fijo y margen; mismo número en el panel | FR-024–026 |
| 13 | Conductor de 001 (alta manual) abre la app nueva | Sus documentos aparecen aprobados; puede pagar con Bold | Assumptions |

## Pruebas automáticas

- `go test ./...` con `KYQ_TEST_DATABASE_URL`: extensión de suscripción, idempotencia
  webhook/sondeo, firma Bold, cola KYC, gate con los nuevos tipos, avisos deduplicados, costos.
- `melos run test`: alta, documentos, pago (Custom Tab simulada), costos, panel.
