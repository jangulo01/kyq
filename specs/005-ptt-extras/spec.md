# Feature Specification: PTT extra — pre-consulta de clientes frecuentes, botón físico y burbuja flotante

**Feature Branch**: `005-ptt-extras`

**Created**: 2026-10-27

**Status**: Draft

**Input**: User description: "RN-KYQ-010 Pre-consulta PTT de clientes frecuentes: el conductor autoriza a sus clientes frecuentes (pasajeros que lo tienen como Conductor Elegido) a enviarle un mensaje de voz PTT corto ANTES de pedir el viaje (p. ej. '¿estás cerca de Unicentro?') y él puede responder por voz. Decidir límites (duración ≤ 15 s, límites de frecuencia, permiso global y por cliente, solo con el conductor ONLINE y libre, retención, cómo lo oye mientras conduce reutilizando la atenuación). RN-KYQ-012 Botón físico Bluetooth y burbuja flotante: el conductor habla con el pasajero pulsando un botón multimedia de su auricular, manos libres o volante, o una burbuja flotante sobre Waze o Google Maps, con el walkie-talkie existente."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Preguntar por voz al conductor antes de pedir el viaje (Priority: P1)

Ana tiene a Carlos como Conductor Elegido. Antes de pedir el viaje quiere saber si está cerca:
en su lista toca "Preguntar por voz" junto a Carlos (solo aparece si Carlos recibe consultas y
está libre). La app avisa "Llamando a Carlos…"; en cuanto la app de Carlos se conecta, Ana
mantiene pulsado y dice "¿estás cerca de Unicentro?" (máximo 15 s por turno). Carlos, que va
conduciendo con Waze, oye la voz de Ana por el altavoz con la navegación atenuada y le responde
"sí, en 5 minutos estoy" con el botón de su volante. Ana pide el viaje desde la misma pantalla.

**Why this priority**: es la regla RN-KYQ-010 y refuerza la fidelización directa conductor–
cliente, el diferencial de Kyq frente a las plataformas de despacho.

**Independent Test**: con Carlos ONLINE y libre y la pre-consulta activada, Ana abre una consulta,
habla 10 s, Carlos responde por voz y Ana pulsa "Pedir viaje" sin salir del flujo.

**Acceptance Scenarios**:

1. **Given** Carlos ONLINE, libre y con las consultas de voz activadas, **When** Ana toca
   "Preguntar por voz", **Then** se abre una consulta, la app de Carlos se une sola en menos de
   5 s con un tono de aviso y Ana ve "Carlos te escucha: mantén pulsado para hablar".
2. **Given** una consulta abierta y Carlos conectado, **When** Ana mantiene pulsado más de 15 s,
   **Then** su turno termina solo a los 15 s y Carlos puede responder.
3. **Given** que Ana habla, **When** Carlos tiene Waze dando indicaciones, **Then** la voz de Ana
   suena en altavoz con la navegación atenuada y la navegación recupera su volumen al terminar.
4. **Given** una consulta abierta, **When** pasan 2 minutos desde que se abrió o cualquiera de
   los dos toca "Terminar", **Then** el canal se cierra para ambos y se ve el motivo.
5. **Given** que la app de Carlos no se une en 30 s, **When** vence ese plazo, **Then** la consulta
   se cierra como "sin respuesta" para Ana, que puede pedir el viaje igualmente, y Carlos la ve
   como perdida en su bandeja.
6. **Given** Carlos desconectado, ocupado en un viaje o con las consultas desactivadas, **When**
   Ana mira su lista, **Then** no ve "Preguntar por voz" junto a él; si lo intenta (versión
   antigua o carrera), recibe un mensaje claro y no se abre nada.

---

### User Story 2 - El conductor decide quién le puede consultar (Priority: P1)

Carlos activa o desactiva "Recibir consultas de voz de mis clientes" en sus ajustes. Con el
interruptor activo, cualquiera de sus clientes puede consultarle; puede silenciar a un cliente
concreto que abusa sin quitarlo de su cartera. En su bandeja ve las consultas de las últimas 24
horas: abiertas, respondidas, escuchadas sin respuesta y perdidas.

**Why this priority**: sin control del conductor la pre-consulta sería una distracción al
volante; es la condición de "el autónomo puede autorizar" de la regla.

**Independent Test**: Carlos desactiva el interruptor; Ana ya no ve la opción. Lo reactiva y
silencia a Ana; Ana tampoco la ve, pero Pedro (otro cliente) sí.

**Acceptance Scenarios**:

1. **Given** un conductor nuevo, **When** abre los ajustes, **Then** las consultas de voz están
   desactivadas por defecto.
2. **Given** las consultas activadas, **When** Carlos silencia a Ana, **Then** Ana no puede abrir
   consultas con él y no se le informa de que fue silenciada (solo ve que no recibe consultas).
3. **Given** una consulta abierta con Ana, **When** Carlos desactiva las consultas o la silencia,
   **Then** esa consulta se cierra en el acto.
4. **Given** consultas de las últimas 24 h, **When** Carlos abre su bandeja, **Then** ve nombre del
   cliente, hora y estado (abierta, respondida, sin respuesta, perdida), la más reciente primero.

---

### User Story 3 - Hablar con el botón del volante o del auricular (Priority: P1)

Durante un viaje o una consulta, Carlos habla sin tocar el teléfono: pulsa el botón multimedia
de su auricular Bluetooth, de su manos libres o del volante. Si su botón solo hace "clic", un
clic abre el micrófono y otro lo cierra; si lo mantiene pulsado, habla mientras lo mantiene.

**Why this priority**: es la regla RN-KYQ-012 y la forma segura de usar el walkie-talkie al
volante.

**Independent Test**: con un auricular Bluetooth emparejado y un viaje aceptado, un clic del
botón multimedia abre el turno (tono de inicio), el pasajero oye al conductor y otro clic lo
cierra (tono de fin).

**Acceptance Scenarios**:

1. **Given** un viaje aceptado o una consulta abierta, **When** el conductor hace un clic en el
   botón multimedia, **Then** se pide el turno y, concedido, se abre el micrófono hasta el
   siguiente clic o hasta que el turno caduque.
2. **Given** un botón que informa la pulsación mantenida, **When** el conductor lo mantiene más de
   medio segundo y lo suelta, **Then** habla mientras lo mantiene y se cierra al soltar.
3. **Given** que no hay viaje ni consulta con canal abierto, **When** se pulsa el botón, **Then**
   Kyq no lo captura (lo recibe la app de música que corresponda).
4. **Given** el botón desactivado en los ajustes, **When** se pulsa, **Then** Kyq no lo captura.

---

### User Story 4 - Burbuja flotante sobre Waze o Google Maps (Priority: P2)

Con la navegación abierta en Waze o Google Maps, Carlos ve una burbuja de Kyq flotando sobre el
mapa mientras haya un canal de voz abierto. Mantiene pulsada la burbuja para hablar; su color
indica si está libre, si él habla o si habla el pasajero. Puede arrastrarla a otro sitio.

**Why this priority**: complementa el botón físico para quien no tiene uno; la navegación en el
MVP es externa (constitución) y sin burbuja habría que volver a Kyq para hablar.

**Independent Test**: con el permiso de "mostrar sobre otras apps" concedido, el conductor abre
Waze durante un viaje; aparece la burbuja; mantenerla pulsada transmite y soltarla cierra.

**Acceptance Scenarios**:

1. **Given** el permiso concedido y un canal abierto, **When** Kyq pasa a segundo plano, **Then**
   aparece la burbuja; **When** Kyq vuelve al frente o el canal se cierra, **Then** desaparece.
2. **Given** la burbuja visible, **When** el conductor la mantiene pulsada, **Then** se pide el
   turno y habla hasta soltarla (o hasta que el turno caduque).
3. **Given** la burbuja visible, **When** el conductor la arrastra, **Then** se mueve y, si estaba
   hablando, el turno se suelta.
4. **Given** el permiso no concedido, **When** el conductor activa la burbuja en ajustes,
   **Then** se le lleva a la pantalla del sistema para concederlo y se explica para qué es.

### Edge Cases

- Ana ya tiene una consulta abierta con Carlos y vuelve a tocar "Preguntar por voz": se retoma la
  misma consulta, no se abre otra.
- Ana intenta consultar a Pedro con una consulta abierta con Carlos: se le pide terminar primero.
- Carlos atiende otra consulta: Ana recibe "Carlos está atendiendo otra consulta, inténtalo en un
  momento".
- Ana abre consultas en ráfaga: máximo 3 por hora al mismo conductor y 6 al día en total; al
  superar el límite se le indica cuándo puede volver a intentarlo de forma genérica.
- Carlos acepta un viaje de otro cliente durante la consulta (pasa a ocupado) o se desconecta:
  la consulta se cierra con "Carlos ya no está disponible".
- Ana pide el viaje a Carlos durante la consulta: la consulta sigue hasta su cierre normal; al
  aceptar Carlos el viaje pasa a ocupado y la consulta se cierra; la conversación sigue en el
  canal del viaje.
- Ambos pulsan a la vez: el turno es exclusivo como en el viaje; el segundo oye el tono de
  ocupado.
- Falla el servidor de voz al conceder o retirar el turno: se aplica el control de turno a prueba
  de fallos del canal del viaje (nadie habla sin turno; un turno sin retirar caduca y se retira).
- El conductor usa música (Spotify) con el teléfono: Android entrega el botón multimedia a la
  última app que reprodujo audio; mientras suena música, el botón puede ir a esa app. Se informa
  en ajustes.
- Kyq cerrado por el sistema: la burbuja y el botón dejan de funcionar con la app; el servicio en
  primer plano de ONLINE reduce ese riesgo.
- Sin permiso de micrófono: el primer uso del botón o la burbuja abre la app para pedirlo.

## Requirements *(mandatory)*

### Functional Requirements

**Pre-consulta (RN-KYQ-010)**

- **FR-001**: El conductor MUST poder activar o desactivar la recepción de consultas de voz de
  sus clientes; por defecto desactivada.
- **FR-002**: El conductor MUST poder silenciar y reactivar las consultas de un cliente concreto
  sin quitarlo de su cartera; el cliente no es informado del silencio.
- **FR-003**: Solo un pasajero afiliado (Conductor Elegido activo) y no silenciado MUST poder abrir
  una consulta, y solo si el conductor está ONLINE, libre y con las consultas activadas.
- **FR-004**: Una consulta MUST ser un canal de voz walkie-talkie 1 a 1 con turno exclusivo de
  15 s como máximo por intervención; ambos pueden hablar por turnos.
- **FR-005**: La app del conductor MUST unirse sola a la consulta con un tono de aviso; el
  pasajero MUST NOT poder hablar hasta que el conductor esté conectado.
- **FR-006**: Una consulta MUST cerrarse a los 2 minutos de abrirse, a los 30 s si el conductor no
  se conecta (perdida), cuando cualquiera la termina, cuando el conductor deja de estar libre o
  desactiva/silencia, y ambos MUST ser avisados con el motivo.
- **FR-007**: Límites: una consulta abierta por conductor y una por pasajero a la vez; 3 consultas
  por hora del mismo pasajero al mismo conductor y 6 por día de un pasajero en total.
- **FR-008**: La voz de la consulta MUST NOT almacenarse (como el canal del viaje, FR-021 de 001);
  se guardan solo los datos de la consulta (quién, cuándo, estado) y se borran a los 30 días.
- **FR-009**: La voz entrante MUST sonar en altavoz con la navegación atenuada (RN-KYQ-011), con
  la app en primer plano o en segundo plano.
- **FR-010**: El conductor MUST ver una bandeja con las consultas de las últimas 24 h y su estado.
- **FR-011**: Desde la consulta, el pasajero MUST poder pedir el viaje al conductor sin volver a
  la lista.

**Botón físico y burbuja (RN-KYQ-012)**

- **FR-012**: Con un canal de voz abierto (viaje o consulta), Kyq Conductor MUST capturar los
  botones multimedia (auricular, manos libres, volante) para el walkie-talkie: clic corto alterna
  hablar/soltar; pulsación de ≥ 0,5 s habla mientras se mantiene.
- **FR-013**: Sin canal abierto, Kyq MUST NOT capturar los botones multimedia.
- **FR-014**: Con un canal abierto, el permiso concedido y Kyq en segundo plano, Kyq Conductor
  MUST mostrar una burbuja flotante sobre otras apps: mantener pulsado para hablar, colores por
  estado (libre, hablando, habla la otra parte, ocupado) y arrastrable.
- **FR-015**: El conductor MUST poder desactivar el botón físico y la burbuja por separado.
- **FR-016**: El botón y la burbuja MUST usar el mismo turno y las mismas reglas que el botón de
  la pantalla (turno exclusivo, tonos, permiso de micrófono).

### Key Entities

- **Pre-consulta**: pasajero, conductor, sala de voz, abierta, plazo para conectarse, cierre
  previsto, conectado (conductor), respondida (el conductor habló), cerrada y motivo, turno.
- **Ajuste de consultas del conductor**: recibe consultas sí/no.
- **Silencio por cliente**: en la afiliación pasajero–conductor.
- **Preferencias manos libres** (en el teléfono): botón físico sí/no, burbuja sí/no.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: La app del conductor se une a una consulta en menos de 5 s desde que el pasajero la
  abre, en el 95 % de los casos con 4G.
- **SC-002**: La voz de la consulta tiene la misma latencia que el canal del viaje (< 250 ms
  objetivo de la constitución).
- **SC-003**: Ninguna intervención supera 15 s y ninguna consulta supera 2 min (0 casos en
  pruebas).
- **SC-004**: 0 consultas abiertas a conductores con las consultas desactivadas, ocupados,
  desconectados o con el cliente silenciado (pruebas automáticas).
- **SC-005**: Con un botón multimedia Bluetooth, el turno se abre en menos de 1 s desde el clic.
- **SC-006**: El conductor no necesita volver a Kyq para hablar durante un viaje navegando con
  Waze o Google Maps (burbuja o botón).

## Assumptions

- "Clientes frecuentes" = pasajeros que tienen al conductor como Conductor Elegido (afiliación
  activa de 001); no se mide frecuencia de viajes.
- La consulta es en vivo (walkie-talkie) y no buzón de voz: si el conductor no está conectado, no
  hay mensaje que escuchar después; la bandeja muestra la consulta como perdida.
- Las consultas no tienen coste para el pasajero y sus minutos de voz cuentan en el coste medido
  del conductor (constitución VII).
- Solo Android en esta fase (botón y burbuja); el pasajero puede consultar desde Android.
- Los límites (15 s, 2 min, 30 s, 3/h, 6/día, 30 días) son decisiones de producto iniciales y se
  pueden ajustar con datos del piloto.
