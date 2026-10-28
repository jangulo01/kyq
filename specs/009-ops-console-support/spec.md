# Feature Specification: Operación del panel: inspección, megáfono, soporte, sesiones sin fallos y dominios espejo

**Feature Branch**: `009-ops-console-support`

**Created**: 2026-10-28

**Status**: Draft

**Input**: User description: "Lo que 007 dejó fuera y el SDD pide en el panel (§5): 1) inspección
en 1 clic de cada viaje activo desde la torre H3; 3) megáfono PTT: comunicados de voz a zonas H3
(CHK-KYQ-06); 5) centro de soporte y disputas, con casos abiertos desde las dos apps (con o sin
viaje), respondidos desde el panel e integrando las disputas de efectivo de 004; 6) monitoreo de
sesiones libres de fallos (crash-free rate) y activación en caliente de dominios espejo
anti-bloqueo (CHK-KYQ-09), con rotación automática de dominio en las apps (SDD §6.2, 'Rotador de
Dominios Failover')."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Inspeccionar un viaje activo con un clic desde la torre (Priority: P1)

En la torre de control, el administrador hace clic en un conductor ocupado o en un hexágono con
viajes activos y ve el detalle del viaje: estado y hora de cada paso, pasajero y conductor (nombre,
sin teléfonos), vehículo y placa, recogida y destino, ruta y posición actual del conductor en vivo,
tarifa, modo de despacho (elegido, cooperativa, bolsa), estado del pago y si hay un SOS abierto
(con acceso a la consola). Cada apertura queda registrada.

**Why this priority**: el SDD lo pide en la torre; permite actuar sobre un viaje concreto sin
salir del mapa.

**Independent Test**: con un viaje en curso, el administrador hace clic en el punto naranja del
conductor y ve el detalle con la posición actualizándose; un pasajero no puede ver ese detalle.

**Acceptance Scenarios**:

1. **Given** un conductor ocupado en la torre, **When** el administrador hace clic en él,
   **Then** se abre el detalle del viaje activo en menos de 2 s.
2. **Given** un hexágono con 3 viajes activos, **When** hace clic en él, **Then** ve la lista de
   esos viajes y abre cualquiera.
3. **Given** el detalle abierto, **When** el conductor se mueve, **Then** su posición se
   actualiza en menos de 10 s sin recargar.
4. **Given** un viaje con SOS abierto, **When** abre el detalle, **Then** ve el aviso y un acceso
   directo a la alerta en la consola.
5. **Given** un usuario que no es administrador, **When** pide el detalle, **Then** se rechaza.

---

### User Story 2 - Centro de soporte y disputas (Priority: P1)

Pasajeros y conductores abren casos desde su app ("Ayuda"): eligen un tema (viaje, pago, objeto
olvidado, seguridad, cuenta, otro), pueden asociar uno de sus viajes de los últimos 30 días y
escriben el problema. El caso tiene una conversación por texto. En el panel, el administrador ve la
bandeja con filtros (estado, tema, antigüedad, sin respuesta), se asigna casos, responde, cambia el
estado (abierto, en atención, esperando al usuario, resuelto, cerrado) y deja notas internas que el
usuario no ve. El usuario recibe las respuestas en vivo y puede contestar mientras el caso no esté
cerrado. Las disputas de efectivo y los "no me pagó" de 004 aparecen automáticamente como casos de
tema "pago" vinculados al pago del viaje, y se resuelven desde el propio caso con las mismas
acciones de 004.

**Why this priority**: el SDD lo pide en el módulo 5; hoy no hay forma de pedir ayuda dentro de
Kyq y las disputas de 004 viven aparte.

**Independent Test**: un pasajero abre un caso por un objeto olvidado asociado a su último viaje;
el administrador lo toma, responde y lo resuelve; el pasajero ve la respuesta en vivo. Un
conductor marca "No recibí el efectivo" y aparece un caso de pago vinculado que el administrador
resuelve como pagado.

**Acceptance Scenarios**:

1. **Given** un pasajero con viajes recientes, **When** abre "Ayuda" → nuevo caso, **Then** puede
   elegir tema, asociar uno de sus viajes de los últimos 30 días y enviarlo.
2. **Given** un caso abierto, **When** el administrador responde, **Then** el usuario lo ve en
   menos de 10 s y puede contestar.
3. **Given** la bandeja, **When** el administrador filtra "sin respuesta", **Then** ve los casos
   cuyo último mensaje es del usuario, del más antiguo al más reciente.
4. **Given** una nota interna, **When** el usuario abre su caso, **Then** no la ve.
5. **Given** una disputa de efectivo de 004, **When** se crea, **Then** aparece un caso de pago
   vinculado al pago del viaje, visible para pasajero y conductor.
6. **Given** ese caso, **When** el administrador lo resuelve como "pagado en efectivo", **Then**
   el pago del viaje queda pagado (como en 004) y el caso pasa a resuelto.
7. **Given** un caso cerrado, **When** el usuario intenta escribir, **Then** se le ofrece abrir
   uno nuevo.
8. **Given** un usuario, **When** intenta ver el caso de otro, **Then** no lo encuentra.

---

### User Story 3 - Megáfono de voz a zonas H3 (Priority: P2)

Desde la torre, el administrador selecciona uno o varios hexágonos (o un hexágono y sus vecinos) y
mantiene pulsado "Megáfono" para hablar. Los conductores ONLINE cuya última ubicación está en esas
zonas oyen el comunicado en su app (también con la app en segundo plano), con un aviso visual
"Comunicado de Kyq". Solo escuchan; no responden por ese canal. Si el conductor está hablando con
su pasajero, el comunicado espera a que termine el turno. Cada comunicado queda registrado (quién,
cuándo, zonas, duración y a cuántos conductores llegó); la voz no se guarda.

**Why this priority**: el SDD lo pide en la consola (CHK-KYQ-06): avisos de cierres de vías,
eventos o seguridad por zona.

**Independent Test**: con un conductor ONLINE en el hexágono A y otro en el B, el administrador
selecciona A y habla; solo el conductor de A lo oye; el registro muestra 1 destinatario.

**Acceptance Scenarios**:

1. **Given** dos conductores en zonas distintas, **When** el administrador emite a una zona,
   **Then** solo lo oye el conductor de esa zona.
2. **Given** un conductor con la app en segundo plano, **When** llega un comunicado, **Then** lo
   oye por el altavoz o el Bluetooth y ve el aviso al volver.
3. **Given** un conductor hablando con su pasajero, **When** llega un comunicado, **Then** se
   reproduce cuando termina ese turno.
4. **Given** un comunicado de más de 60 s, **When** se alcanza el límite, **Then** se corta.
5. **Given** el registro de comunicados, **When** el administrador lo abre, **Then** ve autor,
   hora, zonas, duración y número de destinatarios.

---

### User Story 4 - Sesiones sin fallos en Salud (Priority: P3)

En Salud (007), el administrador ve el porcentaje de sesiones sin fallos de cada app (Kyq
Conductor, Kyq Pasajero y el panel) en las últimas 24 horas y 7 días, con la versión más usada y
un enlace al detalle en la herramienta de errores. Si la herramienta no está configurada, se
muestra "no configurado" sin romper la página.

**Why this priority**: el SDD pide monitorear el crash-free rate; los datos ya se recogen.

**Independent Test**: con datos de sesiones en la herramienta de errores, Salud muestra los
porcentajes; sin credenciales, muestra "no configurado".

**Acceptance Scenarios**:

1. **Given** datos de sesiones, **When** el administrador abre Salud, **Then** ve el porcentaje
   sin fallos por app para 24 h y 7 días.
2. **Given** un porcentaje por debajo del 99 %, **When** se muestra, **Then** aparece resaltado.
3. **Given** la herramienta sin configurar o caída, **When** se abre Salud, **Then** muestra
   "no configurado" o "no disponible" y el resto de la página funciona.

---

### User Story 5 - Dominios espejo anti-bloqueo (Priority: P2)

El administrador mantiene una lista de dominios espejo de la API y del tiempo real: los añade,
ordena, activa o desactiva en caliente y ve si cada uno responde. Las apps (conductor, pasajero y
panel) reciben la lista firmada por Kyq, la guardan y, si el dominio que usan deja de responder,
pasan solas al siguiente dominio activo y lo recuerdan, sin cerrar la sesión. Una lista que no esté
firmada por Kyq se ignora. Las apps traen una lista inicial para el primer arranque.

**Why this priority**: el SDD (módulo 6, CHK-KYQ-09) lo pide para resistir bloqueos de dominio; sin
él, un bloqueo deja a todos los conductores sin servicio.

**Independent Test**: con dos dominios activos, se bloquea el primero en la red del teléfono; la
app sigue funcionando por el segundo en menos de 30 s y el panel muestra el primero como caído.

**Acceptance Scenarios**:

1. **Given** dos dominios activos, **When** el primero deja de responder, **Then** la app pasa
   al segundo en menos de 30 s sin perder la sesión.
2. **Given** que el administrador desactiva un dominio, **When** las apps actualizan la lista
   (en menos de 10 minutos o al reconectar), **Then** dejan de usarlo.
3. **Given** una lista con firma inválida, **When** la app la recibe, **Then** la descarta y
   conserva la última válida.
4. **Given** la página de dominios, **When** el administrador la abre, **Then** ve el estado y la
   latencia de cada dominio.
5. **Given** que el administrador intenta dejar la lista sin ningún dominio activo, **When**
   guarda, **Then** se rechaza.

### Edge Cases

- El viaje termina mientras el administrador mira su detalle: el detalle muestra el estado final
  y deja de actualizar la posición.
- Un conductor entra en la zona durante un comunicado: no lo recibe a mitad (se fija la lista de
  destinatarios al empezar).
- Dos administradores emiten a la vez a zonas que se solapan: un conductor recibe uno y luego el
  otro, nunca superpuestos.
- Un usuario suspendido (007) puede abrir casos de soporte y responder en los suyos (para
  reclamar), pero no puede usar el resto de la app.
- Un caso asociado a un viaje que no es del usuario: se rechaza.
- Una disputa de 004 resuelta desde la pantalla de pagos de 004: el caso vinculado se resuelve
  también (y al revés).
- Todos los dominios caen: la app muestra "Sin conexión con Kyq" y reintenta con la lista guardada.
- La lista firmada llega con un dominio nuevo que no responde: la app sigue con el actual.
- Sin herramienta de errores configurada, los porcentajes no se inventan: "no configurado".

## Requirements *(mandatory)*

### Functional Requirements

**Inspección de viaje (torre)**

- **FR-001**: Desde la torre, el administrador MUST poder abrir con un clic el detalle del viaje
  activo de un conductor ocupado, o la lista de viajes activos de un hexágono.
- **FR-002**: El detalle MUST mostrar estado y hora de cada paso, nombres de pasajero y conductor,
  vehículo y placa, recogida, destino, ruta, posición actual del conductor, tarifa, modo de
  despacho, estado del pago y alerta SOS abierta si existe; MUST NOT mostrar teléfonos.
- **FR-003**: La posición y el estado del detalle MUST actualizarse en menos de 10 s mientras el
  viaje está activo.
- **FR-004**: Solo administradores MUST poder abrir el detalle; cada apertura MUST registrarse
  (administrador, viaje, hora).

**Centro de soporte y disputas**

- **FR-005**: Pasajeros y conductores MUST poder abrir casos con tema (viaje, pago, objeto
  olvidado, seguridad, cuenta, otro), descripción (10 a 2 000 caracteres) y, opcionalmente, uno de
  sus viajes de los últimos 30 días.
- **FR-006**: Cada caso MUST tener una conversación de mensajes de texto (hasta 2 000 caracteres)
  entre el usuario y los administradores, y notas internas solo visibles para administradores.
- **FR-007**: El caso MUST tener estado (abierto, en atención, esperando al usuario, resuelto,
  cerrado) y administrador asignado; el usuario MUST poder responder salvo si está cerrado;
  responder a un caso "esperando al usuario" o "resuelto" lo reabre.
- **FR-008**: El panel MUST ofrecer una bandeja con filtros por estado, tema, asignado y "sin
  respuesta", ordenada por antigüedad, con el tiempo desde el último mensaje del usuario.
- **FR-009**: Usuario y administrador MUST recibir en vivo los mensajes nuevos y los cambios de
  estado del caso.
- **FR-010**: Una disputa de efectivo o un "no me pagó" de 004 MUST crear un caso de tema "pago"
  vinculado al pago del viaje y visible para las dos partes; resolverlo desde el caso MUST aplicar
  la resolución de 004 (y resolverlo en 004 MUST resolver el caso).
- **FR-011**: Un usuario MUST ver solo sus casos; un usuario suspendido MUST poder seguir usando
  soporte.
- **FR-012**: Cerrar un caso inactivo: un caso "resuelto" sin respuesta del usuario en 7 días MUST
  pasar a "cerrado".

**Megáfono por zonas**

- **FR-013**: El administrador MUST poder elegir una o varias zonas H3 en la torre y emitir un
  comunicado de voz de hasta 60 s.
- **FR-014**: Los destinatarios MUST ser los conductores ONLINE cuya última ubicación (de los
  últimos 5 minutos) está en las zonas elegidas al empezar el comunicado.
- **FR-015**: El conductor MUST oír el comunicado aunque la app esté en segundo plano, con aviso
  visual; MUST NOT poder hablar por ese canal; el turno del viaje en curso tiene prioridad.
- **FR-016**: Cada comunicado MUST registrarse con autor, hora, zonas, duración y número de
  destinatarios; la voz MUST NOT almacenarse.

**Sesiones sin fallos**

- **FR-017**: Salud MUST mostrar el porcentaje de sesiones sin fallos por app en 24 h y 7 días,
  resaltando valores bajo el 99 %, a partir de la herramienta de errores ya integrada.
- **FR-018**: Sin configuración o con la herramienta caída, Salud MUST mostrar "no configurado" o
  "no disponible" sin afectar al resto ni exponer credenciales (FR-020 de 007).

**Dominios espejo**

- **FR-019**: El administrador MUST poder añadir, ordenar, activar y desactivar dominios espejo
  (URL de la API y del tiempo real) y ver si cada uno responde y con qué latencia; no puede dejar
  la lista sin ningún dominio activo.
- **FR-020**: Las apps MUST obtener la lista de dominios activos firmada por Kyq al conectar y al
  menos cada 10 minutos, verificar la firma con una clave pública incluida en la app y descartar
  listas inválidas o más antiguas que la guardada.
- **FR-021**: Si el dominio en uso no responde, las apps MUST pasar al siguiente dominio activo en
  menos de 30 s, sin cerrar la sesión, y recordarlo hasta que falle.
- **FR-022**: Las apps MUST traer una lista inicial firmada para el primer arranque.

### Key Entities

- **Acceso a viaje**: administrador, viaje, fecha (auditoría de inspección).
- **Caso de soporte**: usuario que lo abre, rol, tema, viaje asociado (opcional), pago del viaje
  vinculado (opcional), estado, administrador asignado, fechas de apertura, último mensaje y
  cierre.
- **Mensaje del caso**: caso, autor (usuario o administrador), texto, si es nota interna, fecha.
- **Comunicado de megáfono**: administrador, zonas, inicio, fin, número de destinatarios.
- **Dominio espejo**: URL de API, URL de tiempo real, orden, activo, último estado y latencia.
- **Lista de dominios firmada**: versión, fecha, dominios activos en orden, firma.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: El detalle de un viaje activo se abre en menos de 2 s desde la torre en el 95 % de
  los casos.
- **SC-002**: El 100 % de las disputas de efectivo y "no me pagó" de 004 tienen su caso vinculado
  y su resolución coincide en las dos pantallas.
- **SC-003**: Un mensaje del administrador llega al usuario en menos de 10 s en el 95 % de los
  casos.
- **SC-004**: Un comunicado llega solo a los conductores de las zonas elegidas (0 casos fuera de
  zona en las pruebas) y empieza a oírse en menos de 2 s en red Wi-Fi o 4G.
- **SC-005**: Con el dominio principal bloqueado, el 100 % de las apps de prueba siguen operando
  por un espejo en menos de 30 s.
- **SC-006**: Ninguna lista de dominios sin firma válida cambia el dominio de una app (0 casos).

## Assumptions

- **Soporte por texto**: sin adjuntos ni voz en esta etapa; sin correo ni SMS (avisos en la app).
- **Equipo de soporte**: cualquier administrador atiende casos; no hay roles de soporte aparte.
- **Disputas de 004**: el caso es la vista unificada; las reglas de 004 no cambian.
- **Megáfono**: solo administradores; un comunicado a la vez por administrador; 60 s como el turno
  de 001; sin grabación (como 001 y 006).
- **Zonas**: hexágonos H3 de la resolución que muestra la torre (6 a 9).
- **Sesiones sin fallos**: se leen de la herramienta de errores que ya usa Kyq (Sentry, 001); si
  no hay token de lectura configurado, "no configurado".
- **Dominios**: la lista la firma el backend con una clave privada que solo él tiene; las apps
  llevan la pública. Cambiar la clave exige publicar nuevas versiones de las apps.
- **Rotación**: se considera caído un dominio con 3 fallos de red seguidos o sin respuesta en 10 s.
- Android para conductor y pasajero, web para el panel; iOS fuera de alcance (fase 2).
