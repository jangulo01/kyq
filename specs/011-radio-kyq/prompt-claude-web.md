# Prompt para Claude Code web: implementar 011 Radio Kyq

Pegar en claude.ai/code con el repositorio `jangulo01/kyq` seleccionado.

---

Trabaja en el repositorio jangulo01/kyq, rama `011-radio-kyq` (ya existe en GitHub; parte de
`010-native-experience` e incluye `integracion`). No crees otra rama.

Reglas del proyecto (obligatorias):
- Todo en español: respuestas, comentarios, textos de interfaz, mensajes de commit y PR. Solo
  los identificadores del código quedan en inglés. Lee `CLAUDE.md`.
- Constitución en `.specify/memory/constitution.md`. Principio I (clean-room) es NO NEGOCIABLE:
  la Radio debe comportarse como la app walkie-talkie que los usuarios ya conocen (referencia
  funcional en `specs/011-radio-kyq/phva.md` §1.3), pero con diseño, textos, íconos, colores y
  tonos propios de Kyq. No uses nombres, recursos, sonidos ni protocolos de terceros.
- Flujo Spec Kit: implementa con `/speckit-implement` sobre `specs/011-radio-kyq/tasks.md`,
  marcando cada tarea `[X]` al terminarla, con pruebas primero (TDD).

Lee antes de empezar, en este orden: `specs/011-radio-kyq/spec.md`, `phva.md`, `plan.md`,
`research.md`, `data-model.md`, `contracts/api.yaml`, `quickstart.md`, `tasks.md`, y como
referencia del código existente `specs/006-cooperatives-delegation/` (canal de grupo),
`specs/005-ptt-extras/` (burbuja, botón, consulta) y `specs/003-sos-emergency-console/`.

Orden de trabajo:
1. Fases 1–4 (setup, base, US1 y US2): es el MVP. T004 es un spike que necesita la VM: no
   puedes ejecutarlo desde la nube; déjalo sin marcar, implementa el plan principal (egress
   automático por pista, research R3) detrás de la interfaz de salas para que el plan B se
   pueda cambiar sin tocar el resto, y anótalo en el resumen.
2. Luego fases 5, 7 y 8 (canales y cooperativa, clientes, migración y configuración).
3. Luego fases 6, 9, 10, 11 y 12.
4. Fase 13 menos T051 (despliegue en la VM y piloto: los hace el responsable desde su PC).

Pruebas: `cd backend && go vet ./... && go test ./...` (las de integración necesitan
`KYQ_TEST_DATABASE_URL` con PostgreSQL 17 + PostGIS; si puedes, levanta uno con Docker; si no,
deja que las corra la CI) y `melos run analyze` y `melos run test` en la raíz. No integres nada
con pruebas en rojo.

Commits: uno por fase como mínimo, mensaje en español que empiece con `011:` y termine con la
línea `Co-Authored-By: Claude <noreply@anthropic.com>`. Haz push a `origin 011-radio-kyq` al
terminar cada fase para no perder trabajo.

Al terminar: abre un PR en borrador de `011-radio-kyq` hacia `integracion` titulado
"011: Radio Kyq, walkie-talkie permanente" con el resumen por fase, las tareas pendientes (T004,
T051) y cómo probarlo (quickstart). No despliegues nada ni toques secretos; no hay acceso a la VM
ni a los teléfonos desde la nube.
