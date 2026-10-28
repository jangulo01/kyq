# Quickstart: validar la bolsa zonal y la fidelización ampliada

## Preparación

- Entorno de 006/007 en la VM con la migración `00013_zonal_pool.sql` aplicada
  (`docker compose up -d --build`).
- Tres conductores con documentos y suscripción al día (A, B y C) y dos pasajeros: P1 afiliado a
  A y P2 sin Conductores Elegidos.
- Kyq Pasajero instalada en el teléfono de P2 (para el enlace).

## Escenarios

| # | Paso | Resultado esperado | Ref. |
|---|---|---|---|
| 1 | A, B y C abren "Despacho y tarifas" | Bolsa zonal desactivada por defecto; descuento 0 % | FR-008, FR-011 |
| 2 | B (a 1 km) y C (a 3 km) activan la bolsa y se ponen ONLINE; A, ONLINE sin bolsa, a 500 m | — | — |
| 3 | P2 abre la app y toca "Pedir un viaje a un conductor cercano" | Pantalla de solicitud sin conductor; tarifa de la tabla | FR-001 |
| 4 | P2 pide | Oferta a B con "Bolsa zonal" y la distancia; A no recibe nada | FR-002, FR-009, FR-010 |
| 5 | B rechaza | Oferta a C (25 s); P2 ve "Buscando un conductor cercano" | FR-003, FR-004 |
| 6 | C acepta y completa el viaje | Ciclo normal, walkie-talkie y pago; 100 % para C, comisión 0 | FR-007, RN-KYQ-001 |
| 7 | En el resumen, P2 toca "Guardar a C como Conductor Elegido" | C aparece en la lista de P2; en "Mis clientes" de C, origen "Después del viaje" | FR-014, FR-016 |
| 8 | A fija descuento 10 %; P1 cotiza un viaje con A | Tarifa con −10 % y aviso "Tarifa preferencial" | FR-011, FR-012 |
| 9 | P1 pide a A | Oferta con "⭐ Cliente de tu cartera", viajes juntos y la tarifa con descuento | FR-010, FR-012 |
| 10 | A cambia el descuento a 0 % con la oferta abierta y la acepta | El viaje conserva el −10 % | FR-013 |
| 11 | P1 pide a A con consentimiento de cooperativa; A rechaza y pasa a un compañero | El compañero ve la tarifa sin descuento y "De tu cooperativa" | FR-012 |
| 12 | A comparte su enlace (Mi QR → Compartir enlace) y P2 lo abre | Página con el nombre de A; "Abrir en Kyq" lleva a confirmar; origen "Enlace" | FR-015, FR-016 |
| 13 | Abrir el enlace de un conductor suspendido | "Este conductor no está disponible" | FR-017 |
| 14 | Panel → Fidelización | Nuevas afiliaciones por origen que suman el total | FR-016, SC-005 |
| 15 | Nadie con la bolsa cerca: P2 pide a la bolsa | "No hay conductores libres cerca ahora"; no se crea oferta | FR-004 |

## Pruebas automáticas

- `cd backend && KYQ_TEST_DATABASE_URL=... go test ./...`: candidatos de la bolsa (activación,
  distancia, frescura, suspensión, sin repetir), traspasos y cierre, tarifa preferencial (aplicar,
  revertir al traspasar, conservar), afiliación por origen e informe, contrato.
- `melos run analyze && melos run test`: modelos y eventos, solicitud a la bolsa, ajustes del
  conductor, tarjeta de oferta, resumen con "Guardar", enlace.
