# Quickstart: validar SOS y consola de emergencias

## Preparación

Entorno de 002 en la VM más `redis` y `egress` (LiveKit) en `infra/docker-compose.yml`, bucket
`kyq-sos` con expiración de 90 días y un administrador con `emergency_operator` y `on_duty`.

## Escenarios

| # | Paso | Resultado esperado | Ref. |
|---|---|---|---|
| 1 | Viaje aceptado; pasajero mantiene SOS 2 s | Alerta en la consola < 5 s con aviso sonoro; ubicación cada segundo | FR-001–003, SC-001 |
| 2 | Pulsación corta | No se crea alerta | FR-002 |
| 3 | Operador toma la alerta y habla | El pasajero lo oye en altavoz; otro operador escucha pero no habla | FR-004, FR-008 |
| 4 | Pasajero cancela con PIN correcto / con PIN incorrecto | Cancelada / sigue abierta y marcada "sin PIN" | FR-005 |
| 5 | La app del conductor durante el SOS del pasajero | No muestra nada del SOS | FR-006 |
| 6 | Operador añade notas y cierra como "falsa alarma" | Historial con notas, desenlace y grabación reproducible | FR-010, FR-018 |
| 7 | Alerta sin tomar 60 s | SMS a los operadores de guardia (en desarrollo: registro) | FR-011 |
| 8 | Compartir viaje y abrir el enlace en otro navegador | Mapa con el vehículo, placa y nombre; sin teléfonos | FR-013–015 |
| 9 | Completar el viaje y abrir el enlace 16 min después | "Viaje finalizado", sin datos | FR-014 |
| 10 | Pasajero con 2 contactos activa SOS | Ambos reciben SMS con el enlace | FR-016, FR-017 |
| 11 | Conductor activa SOS | Igual que el pasajero, con su servicio en primer plano enviando ubicación | US1-5 |
