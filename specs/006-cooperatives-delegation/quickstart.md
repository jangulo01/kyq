# Quickstart: validar cooperativas y delegación

## Preparación

- Entorno de 001/002 en la VM (`infra/README.md`) con la migración `00011` aplicada.
- Tres conductores con documentos y suscripción al día (A = Conductor Elegido, B y C =
  compañeros), un pasajero afiliado a A y un administrador.
- Ubicaciones de prueba: B a ~1 km de la recogida, C a ~5 km, ambos ONLINE.

## Escenarios

| # | Paso | Resultado esperado | Ref. |
|---|---|---|---|
| 1 | Admin crea "Cooperativa Andina" en el panel | Aparece activa con 0 miembros | FR-001 |
| 2 | B pide entrar desde la app; admin aprueba | B miembro; ve la cooperativa | FR-004, FR-005 |
| 3 | Admin agrega a A y C y nombra coordinador a A | Roles visibles en panel y app | FR-006 |
| 4 | Otro conductor pide entrar; A (coordinador) lo rechaza con motivo | El conductor ve el motivo | FR-005 |
| 5 | B intenta pedir entrar a otra cooperativa | 409 `already_in_cooperative` | FR-003 |
| 6 | A ocupado; pasajero pide a A con "Si no puede…" marcado | Oferta a B (más cercano); pasajero ve la derivación | FR-011, FR-015 |
| 7 | B rechaza | Oferta a C con 25 s nuevos | FR-012, FR-016 |
| 8 | C acepta y completa | Pasajero ve a C; pago 100 % a C, comisión 0 | FR-018, FR-020 |
| 9 | A libre; pasajero pide con la casilla; A pulsa "Pasar a mi cooperativa" | Oferta a B | FR-013 |
| 10 | Pasajero sin la casilla; A rechaza | Solicitud cerrada como en 001 | FR-010 |
| 11 | Pasajero elige "Su cooperativa" con A libre lejos y B cerca | Oferta a B | FR-014 |
| 12 | Todos ocupados; pasajero pide a la cooperativa | 409 `no_driver_available` | FR-017 |
| 13 | A, B y C entran al canal de grupo; A habla; B pulsa a la vez | B y C oyen a A; B recibe "ocupado" | FR-022, FR-023 |
| 14 | Admin retira a C con el canal abierto | C sale del canal y no puede volver | FR-024 |
| 15 | Admin suspende la cooperativa | Sin delegación ni canal de grupo | FR-001 |

## Pruebas automáticas

- `go test ./...` con `KYQ_TEST_DATABASE_URL`: delegación (automática, por rechazo, por
  vencimiento, iniciada por el conductor, sin consentimiento, máximo de pasos, cercanía
  PostGIS, cooperativa suspendida), RN-KYQ-001 en viaje derivado, membresías (una por conductor,
  coordinador), canal de grupo (solo miembros, turno único, retiro), contrato.
- `melos run test`: selector de despacho, oferta derivada, mi cooperativa, panel.
