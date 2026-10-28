# Feature Specification: Cooperativas y delegación inteligente

**Feature Branch**: `006-cooperatives-delegation`

**Created**: 2026-10-27

**Status**: Draft

**Input**: User description: "Etapa 006 'Cooperativas y delegación'. RN-KYQ-008 Delegación
Inteligente a Cooperativa: si el Conductor Elegido está ocupado, puede derivar la solicitud
automáticamente a un compañero de su cooperativa. Selector triple de despacho del pasajero:
1) Pedir a mi Conductor Elegido, 2) Pedir a su Cooperativa, 3) Autónomo libre más cercano (la
opción 3 queda fuera de esta etapa). Canal PTT de grupo de la cooperativa (COOP_GROUP) y el
'Centro de Validación Documental KYC y Cooperativas' del panel. Alcance: cooperativas (alta y
gestión por el administrador; un conductor pertenece como máximo a una; rol de coordinador),
solicitudes de ingreso y su aprobación, delegación cuando el elegido está ocupado, desconectado o
no responde (automática o iniciada por el conductor, con consentimiento del pasajero; la oferta
va a los compañeros libres más cercanos primero, con las mismas reglas de oferta y vencimiento de
001), elección del pasajero entre su conductor y la cooperativa de ese conductor, canal PTT de
grupo por cooperativa con control de turno y pantallas del panel. Comisión 0 % (RN-KYQ-001)."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - El administrador crea y gestiona cooperativas (Priority: P1)

El administrador da de alta en el panel una cooperativa con su nombre, ciudad y NIT, ve la lista
de cooperativas con cuántos miembros y solicitudes pendientes tiene cada una, abre una para ver
sus miembros y sus solicitudes, aprueba o rechaza solicitudes (con motivo), retira miembros,
nombra o quita coordinadores y puede suspender la cooperativa.

**Why this priority**: sin cooperativas no hay a quién delegar; es la base de la etapa.

**Independent Test**: el administrador crea "Cooperativa Andina", agrega a dos conductores, nombra
coordinador a uno y los ve listados con su rol.

**Acceptance Scenarios**:

1. **Given** el panel, **When** el administrador crea una cooperativa con nombre, ciudad y NIT,
   **Then** aparece activa en la lista con 0 miembros.
2. **Given** una cooperativa existente, **When** se intenta crear otra con el mismo nombre (sin
   distinguir mayúsculas), **Then** se rechaza con un mensaje claro.
3. **Given** una cooperativa con una solicitud pendiente, **When** el administrador la aprueba,
   **Then** el conductor queda como miembro y la solicitud desaparece de pendientes.
4. **Given** una solicitud pendiente, **When** el administrador la rechaza, **Then** debe indicar
   un motivo y el conductor lo ve en la app.
5. **Given** un miembro, **When** el administrador lo nombra coordinador, **Then** su rol cambia y
   desde la app puede gestionar las solicitudes de esa cooperativa.
6. **Given** una cooperativa activa, **When** el administrador la suspende, **Then** deja de
   recibir delegaciones y su canal de grupo se cierra hasta que se reactive; sus miembros siguen
   siéndolo.

---

### User Story 2 - El conductor pide entrar a una cooperativa (Priority: P1)

Desde Kyq Conductor, el conductor ve las cooperativas activas, pide entrar a una y espera la
aprobación de un administrador o de un coordinador. Ve el estado de su solicitud (pendiente,
rechazada con motivo) y, una vez dentro, la cooperativa con sus compañeros y quién está libre.
Puede retirar su solicitud o salir de la cooperativa. Un coordinador ve y decide las solicitudes
de su cooperativa desde la app.

**Why this priority**: es la forma normal de crecer la cooperativa sin que el administrador dé de
alta a cada miembro.

**Independent Test**: un conductor pide entrar; el coordinador lo aprueba desde su app; el
conductor ve la cooperativa y a sus compañeros.

**Acceptance Scenarios**:

1. **Given** un conductor sin cooperativa, **When** pide entrar a "Cooperativa Andina", **Then**
   su solicitud queda pendiente y no puede pedir entrar a otra mientras tanto.
2. **Given** un conductor miembro de una cooperativa, **When** intenta pedir entrar a otra,
   **Then** se le indica que primero debe salir de la actual (un conductor, una cooperativa).
3. **Given** una solicitud pendiente, **When** el conductor la retira, **Then** puede pedir
   entrar a otra cooperativa.
4. **Given** un coordinador, **When** abre su cooperativa en la app, **Then** ve las solicitudes
   pendientes y puede aprobarlas o rechazarlas con motivo.
5. **Given** un miembro (no coordinador), **When** intenta aprobar una solicitud, **Then** no
   puede.
6. **Given** un miembro, **When** sale de la cooperativa, **Then** deja de recibir delegaciones
   y de poder entrar al canal de grupo de inmediato.

---

### User Story 3 - Delegación inteligente cuando el Conductor Elegido no puede (Priority: P1)

El pasajero pide un viaje a su Conductor Elegido y marca "Si no puede, que me atienda un
compañero de su cooperativa". Si el elegido está ocupado o desconectado, la solicitud va de
inmediato al compañero libre más cercano al punto de recogida. Si el elegido está libre, recibe la
oferta exclusiva de 25 s como siempre; si la rechaza, no responde a tiempo o pulsa "Pasar a mi
cooperativa", la solicitud pasa al compañero libre más cercano, que también tiene 25 s; así hasta
tres compañeros. El pasajero ve en todo momento que su solicitud fue derivada y, al aceptar el
compañero, ve su nombre y su vehículo. Sin la casilla marcada, el comportamiento es el de 001.

**Why this priority**: RN-KYQ-008; es el valor central de la etapa: el pasajero leal no se queda
sin servicio cuando su conductor no puede.

**Independent Test**: con el elegido ocupado y dos compañeros libres a 1 km y 5 km, el pasajero
pide con la casilla marcada; la oferta llega al de 1 km; este la rechaza; llega al de 5 km, que
acepta; el viaje sigue el ciclo normal con comisión 0.

**Acceptance Scenarios**:

1. **Given** el elegido ocupado y la casilla marcada, **When** el pasajero pide, **Then** la
   oferta llega al compañero libre más cercano a la recogida y el pasajero ve "Tu solicitud pasó a
   un compañero de Cooperativa Andina".
2. **Given** el elegido ocupado y la casilla sin marcar, **When** el pasajero pide, **Then** se
   le indica que su conductor no está libre, como en 001, y no se envía nada.
3. **Given** el elegido libre y la casilla marcada, **When** deja vencer la oferta (25 s),
   **Then** la oferta pasa al siguiente compañero libre más cercano con 25 s nuevos.
4. **Given** el elegido libre y la casilla marcada, **When** pulsa "Pasar a mi cooperativa",
   **Then** la oferta sale de su pantalla y llega al compañero libre más cercano.
5. **Given** la casilla sin marcar, **When** el elegido ve la oferta, **Then** no tiene el botón
   "Pasar a mi cooperativa" y rechazar cierra la solicitud como en 001.
6. **Given** que ningún compañero está libre o cerca, **When** toca derivar, **Then** la solicitud
   se cierra con "No hay compañeros libres ahora" y el pasajero puede volver a intentarlo.
7. **Given** tres compañeros que no respondieron, **When** vence la tercera oferta derivada,
   **Then** la solicitud se cierra sin buscar un cuarto.
8. **Given** un viaje derivado y aceptado, **When** se completa, **Then** el compañero recibe el
   100 % de la tarifa acordada y la comisión es 0 (RN-KYQ-001).

---

### User Story 4 - El pasajero elige entre su conductor y su cooperativa (Priority: P2)

En la pantalla de solicitud, el pasajero elige cómo despachar: "Pedir a mi Conductor Elegido" o
"Pedir a su cooperativa". Con la segunda, la solicitud va directamente al miembro libre más cercano
de la cooperativa del conductor elegido (que puede ser él mismo si es el más cercano), con las
mismas reglas de oferta y paso al siguiente. La opción "Autónomo libre más cercano" aparece como
"Próximamente" y no se puede elegir.

**Why this priority**: da al pasajero control explícito; la delegación de US3 ya cubre el caso
más común (conductor ocupado).

**Independent Test**: el pasajero elige "Pedir a su cooperativa"; la oferta llega al miembro libre
más cercano aunque el elegido esté libre y más lejos.

**Acceptance Scenarios**:

1. **Given** un Conductor Elegido miembro de una cooperativa activa, **When** el pasajero abre la
   solicitud, **Then** ve las opciones "Mi conductor" y "Su cooperativa (nombre)", y "Autónomo
   libre más cercano — Próximamente" deshabilitada.
2. **Given** un Conductor Elegido sin cooperativa, **When** el pasajero abre la solicitud,
   **Then** solo puede pedir a su conductor y no ve la casilla de delegación.
3. **Given** "Su cooperativa" elegida, **When** el pasajero pide, **Then** la oferta va al miembro
   libre más cercano a la recogida; si lo rechaza o vence, pasa al siguiente (hasta tres pasos).
4. **Given** "Su cooperativa" elegida y ningún miembro libre cerca, **When** pide, **Then** se le
   informa que no hay miembros libres y no se crea la solicitud.

---

### User Story 5 - Canal walkie-talkie de grupo de la cooperativa (Priority: P2)

Cada cooperativa activa tiene un canal de voz de grupo para sus miembros. Desde "Mi cooperativa",
el conductor entra al canal y habla manteniendo pulsado el botón; solo uno habla a la vez (turno
de 60 s como en 001) y los demás escuchan. Quien sale o es retirado de la cooperativa pierde el
acceso al instante.

**Why this priority**: coordina a los compañeros (p. ej. avisar que alguien cubre una
solicitud), pero la delegación funciona sin él.

**Independent Test**: tres miembros entran al canal; uno habla y los otros dos lo oyen; un
segundo intenta hablar a la vez y recibe "ocupado".

**Acceptance Scenarios**:

1. **Given** un miembro de una cooperativa activa, **When** abre el canal de grupo, **Then** se
   conecta y puede escuchar sin pasos adicionales.
2. **Given** un miembro hablando, **When** otro pulsa el botón, **Then** recibe "ocupado" y no
   transmite.
3. **Given** un conductor sin cooperativa o con la cooperativa suspendida, **When** intenta
   entrar al canal, **Then** no puede.
4. **Given** un miembro conectado, **When** el coordinador o el administrador lo retira,
   **Then** queda fuera del canal y no puede volver a entrar.

---

### Edge Cases

- El elegido sale de la cooperativa mientras su pasajero tiene una solicitud derivada en curso:
  la solicitud sigue con la cooperativa que había al pedir.
- El compañero al que se deriva deja de estar libre en el mismo instante: se toma el siguiente;
  dos solicitudes no pueden reservar al mismo compañero.
- Un compañero sin ubicación reciente (más de 5 minutos) o a más de 10 km de la recogida no recibe
  derivaciones: no podría llegar a tiempo.
- El pasajero cancela mientras la solicitud está derivada: se cierra para todos y el compañero
  queda libre.
- Un compañero ya ofertado en esa solicitud no la vuelve a recibir.
- El elegido pulsa "Pasar a mi cooperativa" cuando ya venció su plazo: se aplica el vencimiento.
- La cooperativa se suspende con solicitudes derivadas en curso: las ofertas abiertas siguen su
  curso, pero no se deriva más.
- Un conductor con solicitud pendiente en una cooperativa es aprobado en otra por un
  administrador: no es posible; primero se resuelve la pendiente (una a la vez).
- El último coordinador sale: la cooperativa queda sin coordinador y solo el administrador
  aprueba solicitudes.
- Un coordinador no puede retirar a otro coordinador ni a sí mismo (para salir usa "Salir").
- El pasajero no gana como Conductor Elegido al compañero que lo atendió; puede escanear su QR si
  quiere.
- Varios miembros se conectan al canal de grupo: el turno es uno solo para todo el grupo.

## Requirements *(mandatory)*

### Functional Requirements

**Cooperativas**

- **FR-001**: El administrador MUST poder crear cooperativas con nombre (único sin distinguir
  mayúsculas, 3–80 caracteres), ciudad y NIT opcional, editarlas y suspenderlas o reactivarlas.
- **FR-002**: El panel MUST listar las cooperativas con estado, número de miembros activos y de
  solicitudes pendientes, y mostrar el detalle de cada una con miembros (nombre, placa, rol,
  presencia) y solicitudes pendientes ordenadas por antigüedad.
- **FR-003**: Un conductor MUST pertenecer como máximo a una cooperativa y tener como máximo una
  solicitud en curso; mientras sea miembro o tenga una solicitud pendiente no puede pedir otra.
- **FR-004**: Un conductor MUST poder ver las cooperativas activas, pedir entrar a una, retirar su
  solicitud pendiente y salir de su cooperativa.
- **FR-005**: Una solicitud MUST poder aprobarla o rechazarla un administrador o un coordinador de
  esa cooperativa; rechazar exige motivo, que el conductor ve.
- **FR-006**: El administrador MUST poder agregar directamente a un conductor sin cooperativa,
  retirar miembros y nombrar o quitar coordinadores; un coordinador MUST poder retirar miembros
  que no sean coordinadores.
- **FR-007**: El conductor MUST ver su cooperativa, su rol y a sus compañeros con su presencia
  (libre, ocupado, desconectado); el coordinador además ve las solicitudes pendientes.
- **FR-008**: Toda decisión sobre membresías (aprobación, rechazo, retiro, cambio de rol, salida)
  MUST quedar registrada con quién y cuándo; el conductor afectado recibe un aviso en vivo.

**Despacho y delegación (RN-KYQ-008)**

- **FR-009**: Al pedir un viaje, el pasajero MUST poder elegir entre "Mi Conductor Elegido" y "Su
  cooperativa" cuando el conductor pertenece a una cooperativa activa; la tercera opción,
  "Autónomo libre más cercano", MUST mostrarse como no disponible.
- **FR-010**: Con "Mi Conductor Elegido", el pasajero MUST poder dar su consentimiento para que la
  solicitud pase a un compañero de la cooperativa del conductor si este no puede atenderla; sin
  consentimiento el comportamiento es el de 001.
- **FR-011**: Con consentimiento, si el elegido está ocupado o desconectado al pedir, la
  solicitud MUST ir de inmediato al compañero libre más cercano.
- **FR-012**: Con consentimiento, si el elegido rechaza, deja vencer la oferta o pulsa "Pasar a mi
  cooperativa", la solicitud MUST pasar al compañero libre más cercano no ofertado aún.
- **FR-013**: Solo el conductor que tiene la oferta y solo con consentimiento del pasajero MUST
  poder pasarla a su cooperativa, dentro de su plazo de 25 s.
- **FR-014**: Con "Su cooperativa", la solicitud MUST ir al miembro libre más cercano (incluido el
  propio elegido si es el más cercano) y pasar al siguiente con las mismas reglas.
- **FR-015**: El compañero elegido MUST ser un miembro activo de una cooperativa activa, estar
  libre, con ubicación de los últimos 5 minutos y a no más de 10 km por línea recta de la
  recogida; se elige el de menor distancia, y a igual distancia, uno estable.
- **FR-016**: Cada oferta derivada MUST tener las reglas de 001: exclusiva, 25 s para responder,
  y el conductor queda reservado mientras la tiene (RN-KYQ-007).
- **FR-017**: Una solicitud MUST pasar como máximo a tres compañeros; agotados o sin candidatos,
  se cierra con el motivo "sin conductores disponibles".
- **FR-018**: El pasajero MUST ver que su solicitud fue derivada y a qué cooperativa, y al aceptar
  el compañero ver su nombre y vehículo; el compañero MUST ver que la solicitud viene derivada.
- **FR-019**: La cooperativa del viaje MUST fijarse al pedir; cambios posteriores de membresía no
  la alteran.
- **FR-020**: Un viaje derivado MUST liquidarse igual que uno directo: 100 % de la tarifa acordada
  para el conductor que lo realiza y comisión 0 (RN-KYQ-001).
- **FR-021**: El pasajero MUST poder cancelar en cualquier momento antes de IN_PROGRESS, también
  durante una derivación, sin cargo.

**Canal de grupo**

- **FR-022**: Cada cooperativa activa MUST tener un canal de voz de grupo al que solo pueden
  entrar sus miembros activos.
- **FR-023**: El canal MUST tener un único turno de palabra para todo el grupo, con la misma
  duración máxima y liberación que el canal del viaje de 001.
- **FR-024**: Al salir o ser retirado un miembro, o al suspenderse la cooperativa, MUST perder el
  acceso al canal y ser desconectado.
- **FR-025**: La voz del canal de grupo MUST NOT almacenarse (como en 001).

### Key Entities

- **Cooperativa**: nombre, ciudad, NIT, estado (activa, suspendida), quién la creó y cuándo.
- **Membresía**: conductor, cooperativa, rol (miembro, coordinador), estado (pendiente, activa,
  rechazada, retirada, salió, retirado), motivo de rechazo, quién decidió y cuándo.
- **Viaje (cambios)**: modo de despacho (conductor elegido o cooperativa), conductor pedido,
  cooperativa, consentimiento de delegación, número de pasos a compañeros.
- **Oferta del viaje**: a qué conductor se ofertó y cuándo, y si fue por derivación.
- **Canal de grupo**: cooperativa, tipo `COOP_GROUP`, sala de voz, quién tiene el turno y hasta
  cuándo.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Con el Conductor Elegido ocupado y compañeros libres cerca, el 95 % de las
  solicitudes con consentimiento llegan a un compañero en menos de 2 segundos.
- **SC-002**: Ninguna solicitud llega a dos conductores a la vez ni a un conductor fuera de la
  cooperativa del viaje (0 casos en las pruebas).
- **SC-003**: Ningún viaje derivado cobra comisión (0 casos en pruebas y auditoría).
- **SC-004**: El pasajero sabe en todo momento quién lo atenderá: en una prueba con 5 pasajeros,
  todos identifican que su solicitud fue derivada y el nombre del compañero que aceptó.
- **SC-005**: Un administrador crea una cooperativa y aprueba 5 solicitudes en menos de 3
  minutos.
- **SC-006**: Un miembro retirado pierde el acceso al canal de grupo en menos de 5 segundos.

## Assumptions

- **Opción 3 fuera de alcance**: "Autónomo libre más cercano" (bolsa zonal) no se construye en
  esta etapa; se muestra deshabilitada con "Próximamente" y queda para una etapa posterior.
- **Consentimiento previo**: el pasajero consiente la delegación al pedir (casilla marcada por
  defecto cuando el conductor tiene cooperativa); no se le pregunta de nuevo en cada paso. Puede
  cancelar en cualquier momento.
- **Quién es candidato**: miembros activos libres de la misma cooperativa con ubicación de los
  últimos 5 minutos y a ≤ 10 km en línea recta de la recogida; distancia en línea recta (no por
  carretera) para no gastar una consulta de ruta por candidato (RN-KYQ-004, coste medido).
- **Máximo de pasos**: hasta 3 compañeros por solicitud (25 s cada uno, ~75 s más la oferta al
  elegido); después se cierra para no dejar al pasajero esperando sin fin.
- **Sin afiliación automática**: atender una solicitud derivada no convierte al compañero en
  Conductor Elegido del pasajero.
- **Coordinador**: lo nombra el administrador; puede aprobar y rechazar solicitudes y retirar
  miembros que no sean coordinadores. Puede haber varios.
- **Cualquier conductor puede pedir entrar**, aunque aún no tenga documentos o suscripción al
  día; solo recibe derivaciones cuando puede ponerse ONLINE (estar libre ya lo exige).
- **Solo cooperativas de los Conductores Elegidos**: el pasajero solo puede pedir a la
  cooperativa de un conductor que tiene en su lista.
- **Comisión 0 %**: las cooperativas no cobran ni reparten nada a través de Kyq; cualquier acuerdo
  económico interno queda fuera de la plataforma.
- **Avisos**: las decisiones de membresía se avisan en vivo en la app; no hay SMS ni push en esta
  etapa.
- **Canal de grupo**: sin historial de voz; turno de 60 s como el canal del viaje; la sala se
  crea al primer acceso y LiveKit la elimina cuando queda vacía.
- Android para el conductor y el pasajero, web para el panel; iOS fuera de alcance.
