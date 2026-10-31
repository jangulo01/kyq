# Validación: Radio Kyq

Resultados de T051 ([quickstart.md](quickstart.md)) y de la verificación PHVA
([phva.md](phva.md) §3). Plantilla preparada antes del despliegue.

## Entorno

- Fecha:
- Commit desplegado (`git rev-parse --short HEAD`):
- VM (host, `KYQ_PUBLIC_HOST`):
- Teléfonos (modelo, Android, con o sin Google Play Services):
- Configuración de Radio (política de acceso, días de prueba, pasajeros en canales, retención):

## Escenarios

| # | Paso | Resultado esperado | Ref. | Resultado | Notas |
|---|---|---|---|---|---|
| 1 | Agregar contacto por QR | Ambos en la lista, sin teléfono | FR-002, FR-004 | Pendiente | |
| 2 | Hablar por turnos con pantallas bloqueadas | Voz en el acto; ocupado visible | FR-006–FR-008 | Pendiente | |
| 3 | Latencia boca–oído en 4G | p95 < 250 ms | SC-002 | Pendiente | |
| 4 | Receptor sin red recibe 3 mensajes | 3 nuevos; reproduce en cola, 1,5x y 2x, guarda | FR-010–FR-012, SC-003 | Pendiente | |
| 5 | Canal con aprobación, moderador, silenciar y expulsar | Turno único; expulsado sin historial | FR-014–FR-016 | Pendiente | |
| 6 | Cooperativa en Radio | Aparece; no se puede salir | FR-018 | Pendiente | |
| 7 | 3 conversaciones con mensajes simultáneos, 1 h | Sin mezcla ni pérdida; viaje primero | FR-024, FR-025, SC-006 | Pendiente | |
| 8 | Radio con clientes: activar, silenciar, bloquear, pedir viaje | Según US3 | FR-003 | Pendiente | |
| 9 | Enlace de canal desde teléfono sin la app | Dentro del canal en < 3 min | FR-032, SC-004 | Pendiente | |
| 10 | Carga masiva de 50 filas con errores | Errores antes de enviar; estados; reenvío | FR-033–FR-035 | Pendiente | |
| 11 | Las tres políticas de acceso | Prueba / no entra / solo escucha | FR-005, FR-040 | Pendiente | |
| 12 | Cambio de retención | Costo estimado; bitácora; nuevo aviso | FR-012, FR-040 | Pendiente | |
| 13 | Ocupado y horario de silencio | No suena; cambia solo | FR-019–FR-021 | Pendiente | |
| 14 | Alerta de llamada | Suena en Ocupado; 4.ª rechazada | FR-022 | Pendiente | |
| 15 | Texto, foto y ubicación | En el historial; foto sin EXIF; abre Waze | FR-023 | Pendiente | |
| 16 | Segundo plano, botón Bluetooth, burbuja, modo auto | Según US8 | FR-026–FR-029 | Pendiente | |
| 17 | Emergencia sin viaje | Consola "Sin viaje · desde Radio"; aviso en Ocupado | FR-030, FR-031 | Pendiente | |
| 18 | Reporte y moderación | Solo ese mensaje; acceso registrado | FR-036, FR-037 | Pendiente | |
| 19 | Economía unitaria | Minutos y almacenamiento de Radio | FR-038 | Pendiente | |
| 20 | Usabilidad con 10 usuarios de la app anterior | ≥ 9/10 sin ayuda | SC-001 | Pendiente | |
| 21 | Piloto 30 días | ≥ 70 % de invitados activos | SC-007 | Pendiente | |

## Incidencias y decisiones (PHVA §4)

Ninguna registrada todavía.
