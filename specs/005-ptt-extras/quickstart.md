# Quickstart: validar la pre-consulta, el botón físico y la burbuja

## Preparación

- Entorno de 001/002 en la VM (`infra/README.md`) con la migración `00010_ptt_extras.sql`
  aplicada (la aplica `cmd/migrate` al desplegar).
- Un conductor ONLINE (Kyq Conductor en un Android real) y un pasajero afiliado a él (Kyq
  Pasajero en otro teléfono). Para el botón: un auricular o manos libres Bluetooth con botón
  multimedia. Para la burbuja: Waze o Google Maps instalados.
- Apps compiladas con `--dart-define=KYQ_API_URL=http://192.168.1.66:8080` y
  `--dart-define=KYQ_REALTIME_URL=ws://192.168.1.66:8000/connection/websocket`.

## Escenarios

| # | Paso | Resultado esperado | Ref. |
|---|---|---|---|
| 1 | Conductor abre Inicio → "Consultas de voz" → Ajustes | Interruptor "Recibir consultas de voz" desactivado | FR-001 |
| 2 | Pasajero mira su lista | Sin "Preguntar por voz" junto al conductor | FR-003 |
| 3 | Conductor activa el interruptor; pasajero desliza para refrescar | Aparece "Preguntar por voz" (conductor libre) | FR-001, FR-003 |
| 4 | Pasajero toca "Preguntar por voz" | "Llamando a Carlos…"; en < 5 s el conductor oye el tono y el pasajero ve "Carlos te escucha" | FR-005, SC-001 |
| 5 | Pasajero mantiene pulsado 20 s | El turno se corta a los 15 s; el conductor oye la voz con la navegación atenuada | FR-004, FR-009 |
| 6 | Conductor responde con el botón de pantalla o el botón Bluetooth | El pasajero lo oye; la bandeja marca "respondida" | FR-004, FR-012 |
| 7 | Pasajero toca "Pedir viaje" en la consulta | Abre la solicitud de viaje a ese conductor | FR-011 |
| 8 | Esperar 2 min con una consulta abierta | Se cierra para ambos con "La consulta terminó" | FR-006 |
| 9 | Cerrar la app del conductor (o quitarle datos) y abrir una consulta | A los 30 s el pasajero ve "Carlos no respondió"; la bandeja la muestra "perdida" | FR-006, FR-010 |
| 10 | Abrir 4 consultas en una hora al mismo conductor | La 4.ª responde "Has hecho varias consultas seguidas…" (429) | FR-007 |
| 11 | Conductor silencia al pasajero en Ajustes con una consulta abierta | La consulta se cierra; el pasajero deja de ver la opción | FR-002 |
| 12 | Viaje aceptado; conductor con Waze delante | Aparece la burbuja; mantenerla pulsada transmite; arrastrarla la mueve | FR-014 |
| 13 | Viaje aceptado; clic en el botón del auricular, hablar, otro clic | Tono de inicio, el pasajero oye, tono de fin | FR-012, SC-005 |
| 14 | Mantener el botón del auricular 2 s y soltar (si el botón lo permite) | Habla mientras lo mantiene | FR-012 |
| 15 | Sin viaje ni consulta: pulsar el botón del auricular con música | Lo recibe la app de música | FR-013 |
| 16 | Desactivar botón y burbuja en Ajustes y repetir 12–13 | Ni burbuja ni captura del botón | FR-015 |

## Pruebas automáticas

- `go test ./...` con `KYQ_TEST_DATABASE_URL`: apertura y permisos (RN-KYQ-010), límites,
  unión del conductor, turno de 15 s a prueba de fallos, cierre con motivo, borrado a 30 días,
  HTTP y contrato.
- `melos run test`: `HandsFreePtt` (RN-KYQ-012: clic alterna, pulsación mantiene, burbuja solo en
  segundo plano y con canal), cliente API, eventos, bandeja y ajustes del conductor, consulta del
  pasajero.
