# Validación: Alta, KYC y suscripción con Bold

Resultados de T043 ([quickstart.md](quickstart.md)). Plantilla preparada antes del despliegue:
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
| 1 | Teléfono nuevo → "Soy conductor" → OTP → vehículo | Cuenta en `documents_pending`, lista de 5 documentos | FR-001, FR-002 | Pendiente | |
| 2 | Teléfono de un pasajero intenta registrarse como conductor | 409 `phone_has_other_role` con mensaje claro | FR-003 | Pendiente | |
| 3 | Subir los 5 documentos con foto | Estado `in_review`; no puede ponerse ONLINE | FR-004–006 | Pendiente | |
| 4 | Admin rechaza el SOAT con motivo, aprueba el resto | Conductor ve el motivo y un aviso; reenvía solo el SOAT | FR-007, FR-008 | Pendiente | |
| 5 | Admin aprueba el SOAT reenviado | `documents_ok`; aún bloqueado por suscripción sin pagar | FR-004 | Pendiente | |
| 6 | Conductor paga en el sandbox de Bold con tarjeta aprobada | Pago `approved` < 1 min; suscripción activa un mes; puede ponerse ONLINE | FR-014–016, SC-003 | Pendiente | |
| 7 | Repetir la comprobación del mismo pago / simular webhook duplicado firmado | La suscripción no se extiende dos veces | FR-016, SC-005 | Pendiente | |
| 8 | Pago rechazado en el sandbox | Estado `rejected`, botón para reintentar | escenario US3-4 | Pendiente | |
| 9 | Webhook con firma inválida | 401 y registro; nada cambia | FR-016 | Pendiente | |
| 10 | Admin registra un pago manual y luego lo anula con motivo | Vence un mes después y vuelve al estado anterior; ambos auditados | FR-021 | Pendiente | |
| 11 | Poner un SOAT a vencer en 3 días (fecha de prueba) y correr el barrido | Aviso en la app y SMS (en desarrollo: registro) una sola vez | FR-010, FR-027 | Pendiente | |
| 12 | Conductor con usos del mes abre "Tu suscripción" | Desglose voz / tiempo real / rutas / fijo y margen; mismo número en el panel | FR-024–026 | Pendiente | |
| 13 | Conductor de 001 (alta manual) abre la app nueva | Sus documentos aparecen aprobados; puede pagar con Bold | Assumptions | Pendiente | |

## Incidencias

Ninguna registrada todavía.
