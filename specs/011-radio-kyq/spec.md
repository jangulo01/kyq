# Feature Specification: Radio Kyq: walkie-talkie permanente entre conductores y con sus pasajeros

**Feature Branch**: `011-radio-kyq`

**Created**: 2026-10-28

**Status**: Draft

**Input**: User description: "Radio Kyq: canal walkie-talkie persistente (fuera del viaje) entre
conductores y entre conductor y sus pasajeros. Objetivo: que los conductores y pasajeros que hoy
usan una app walkie-talkie de terceros migren a Kyq sin trauma: la forma de uso debe ser la misma
que ya conocen (referencia funcional clean-room, principio I). Contactos 1 a 1 entre conductores
por invitación; conductor con sus pasajeros (Conductor Elegido); canales de grupo con roles y
moderación; el canal de la cooperativa de 006 como un canal más. Voz primero en vivo y con
registro para reproducir a demanda. Estados, alerta de llamada, texto, foto y ubicación, escucha
de varios canales, modo auto, burbuja y botón Bluetooth de 005, escucha en segundo plano.
Migración por QR o enlace y carga masiva desde el panel con invitaciones por SMS."

## Contexto y alcance

Hoy Kyq solo abre voz dentro de un viaje (001, RN-KYQ-009/014), en la consulta previa de 2
minutos (005, RN-KYQ-010) y en el canal de la cooperativa (006). Muchos conductores autónomos y
sus clientes coordinan su día en una app walkie-talkie de terceros: contactos, canales de grupo,
historial de mensajes y un botón grande para hablar. Para que se pasen a Kyq sin perder esa forma
de trabajar, Radio Kyq ofrece **la misma forma de uso** que ya conocen.

**Familiaridad sin copia (principio I, clean-room)**: se reproduce el *comportamiento* que el
usuario espera (dónde está cada cosa, qué pasa al pulsar, cómo suena un mensaje que llega, cómo se
ve el historial), descrito en `specs/011-radio-kyq/phva.md` §Referencia funcional. La marca, los
íconos, los sonidos, los textos, los colores y el código son propios de Kyq. Ningún requisito de
esta especificación pide igualar un recurso, un nombre o un protocolo de terceros.

**Fuera de alcance**: canales públicos buscables por cualquiera, oyentes anónimos, difusión a
miles de oyentes, prioridad de voz que corta a otro, puentes entre canales, radios físicas
(RoIP), comandos de voz, activación por voz (VOX), llamadas de voz dúplex, iOS (fase 2 de la
constitución) y el megáfono por zonas, que ya cubre 009.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Hablar con un compañero conductor como en la radio de siempre (Priority: P1)

Carlos y Jonathan son conductores de Kyq que se hablaban por otra app. Carlos abre "Radio" en Kyq
Conductor, toca "Agregar contacto" y le muestra su QR a Jonathan, que lo escanea; Jonathan acepta
y ya aparece en la lista de Carlos con un punto verde (Disponible). Carlos toca a Jonathan: se
abre la conversación con su nombre y estado arriba, un botón redondo grande en el centro y el
historial debajo. Carlos mantiene pulsado, oye el tono de "puedes hablar", dice "¿cómo está la
Quinta?" y suelta. A Jonathan, con el teléfono bloqueado en el soporte, le suena la voz por el
altavoz en el acto; mantiene pulsado y responde. Mientras uno habla, el botón del otro muestra
quién tiene el turno y no deja transmitir.

**Why this priority**: es el uso diario que hay que trasladar; si esto no se siente igual, nadie
migra. Sin contactos 1 a 1 no hay Radio.

**Independent Test**: dos conductores con suscripción activa se agregan por QR, se hablan por
turnos con los teléfonos bloqueados y cada uno ve el mensaje del otro en su historial.

**Acceptance Scenarios**:

1. **Given** Carlos y Jonathan conductores activos, **When** Jonathan escanea el QR de Carlos o
   abre su enlace y acepta, **Then** cada uno aparece en la lista del otro con su nombre, foto y
   estado, sin ver el número de teléfono.
2. **Given** una invitación por teléfono a un número que no es conductor de Kyq, **When** Carlos
   la envía, **Then** Kyq no revela si el número existe y envía un SMS con el enlace de
   invitación.
3. **Given** ambos Disponibles, **When** Carlos mantiene pulsado el botón grande, **Then** oye el
   tono de inicio, ve el contador de duración y Jonathan oye la voz en menos de 250 ms (4G).
4. **Given** que Jonathan habla, **When** Carlos intenta hablar, **Then** su botón muestra
   "Jonathan está hablando", no transmite y suena un tono de ocupado.
5. **Given** el modo "Tocar para hablar" activado en ajustes, **When** Carlos toca una vez,
   **Then** el micrófono queda abierto hasta otro toque o hasta 60 s, lo que ocurra antes.
6. **Given** que Carlos suelta el botón, **When** termina el mensaje, **Then** ambos ven en el
   historial una entrada con quién habló, la hora y la duración.
7. **Given** que Carlos borra a Jonathan de sus contactos, **When** Jonathan intenta hablarle,
   **Then** no puede y la conversación desaparece de la lista de Carlos.

---

### User Story 2 - No perder ningún mensaje: historial y reproducción a demanda (Priority: P1)

Jonathan entra a un túnel y pierde señal mientras Carlos le habla. Al recuperar la señal ve
"1 mensaje nuevo" en la conversación; toca la entrada y la oye. Más tarde, en un semáforo, toca
"Repetir" para oír de nuevo el último mensaje y sube la velocidad a 1,5x para escuchar rápido
tres mensajes del canal de su cooperativa que llegaron mientras estaba en Ocupado. Un mensaje con
una dirección importante lo marca con "Guardar" para que no se borre.

**Why this priority**: la decisión del producto es "primero en vivo pero con registro para
reproducir a demanda"; la gente que migra está acostumbrada a no perder mensajes.

**Independent Test**: un receptor sin conexión recibe tres mensajes; al reconectar los ve como
nuevos, los reproduce en orden a 1x, 1,5x y 2x, guarda uno y comprueba que sigue tras la
retención.

**Acceptance Scenarios**:

1. **Given** un receptor Disponible y conectado, **When** llega voz, **Then** suena en vivo y
   además queda en el historial como escuchada.
2. **Given** un receptor desconectado, Ocupado o en otra transmisión, **When** llega voz,
   **Then** no suena y queda en el historial como nueva, con un contador en la lista.
3. **Given** mensajes nuevos, **When** el receptor toca "Reproducir nuevos", **Then** suenan en
   orden de llegada uno tras otro y cada uno pasa a escuchado.
4. **Given** cualquier mensaje del historial, **When** el receptor toca "Repetir" o la entrada,
   **Then** se reproduce a la velocidad elegida (1x, 1,5x o 2x) sin cambiar el tono de la voz.
5. **Given** un mensaje de voz, foto o texto, **When** el receptor toca "Guardar", **Then** queda
   fuera de la retención ordinaria hasta que lo quite o hasta el límite de guardados.
6. **Given** un mensaje no guardado, **When** vence la retención, **Then** desaparece del
   historial de todos y del almacenamiento.

---

### User Story 3 - Hablar con mis clientes por la radio (Priority: P1)

Carlos activa "Radio con mis clientes". Ana, que lo tiene como Conductor Elegido, ve a Carlos en
la pestaña "Radio" de Kyq Pasajero con su estado y le deja un mensaje: "mañana a las 6 en la
portería". Carlos lo oye en vivo si está Disponible, o lo encuentra en su historial. Desde la
conversación Ana puede tocar "Pedir viaje" a Carlos. Si un cliente insiste demasiado, Carlos lo
silencia (sus mensajes quedan en el historial pero no suenan) o lo bloquea (ya no le puede
escribir ni hablar).

**Why this priority**: es la relación directa conductor–cliente, el diferencial del modelo Kyq
(RN-KYQ-005/006); extiende la consulta previa de 005 a un canal permanente.

**Independent Test**: con la opción activa, Ana deja un mensaje de voz a Carlos; Carlos responde;
Carlos silencia a Ana y sus mensajes ya no suenan; la bloquea y Ana ya no puede enviar.

**Acceptance Scenarios**:

1. **Given** "Radio con mis clientes" desactivada (por defecto), **When** Ana abre Radio, **Then**
   no ve a Carlos como contacto de radio.
2. **Given** la opción activa, **When** Ana es cliente de Carlos (Conductor Elegido activo),
   **Then** lo ve en su lista; un pasajero que no es su cliente no puede encontrarlo.
3. **Given** Ana silenciada, **When** habla, **Then** el mensaje queda en el historial de Carlos
   sin sonar ni avisar.
4. **Given** Ana bloqueada, **When** intenta hablar o escribir, **Then** ve "No puedes enviar
   mensajes a este conductor" y no se guarda nada.
5. **Given** que Ana deja de tener a Carlos como Conductor Elegido, **When** abre Radio, **Then**
   la conversación desaparece para ambos.
6. **Given** la conversación abierta, **When** Ana toca "Pedir viaje", **Then** se abre la
   solicitud a Carlos de 001 con él ya elegido.
7. **Given** un pasajero que envía más de 20 mensajes en una hora al mismo conductor, **When**
   intenta otro, **Then** recibe "Espera un momento antes de enviar otro mensaje".

---

### User Story 4 - Canales de grupo y el canal de mi cooperativa (Priority: P1)

Jonathan administra el grupo "Taxistas Norte" que hoy tiene en otra app. En Kyq toca "Crear
canal", le pone nombre, elige "Con aprobación" y comparte el QR en el grupo de mensajería. Cada
compañero que lo escanea pide entrar y Jonathan lo aprueba. Nombra a Carlos moderador. En la
lista de canales de cada miembro aparece "Taxistas Norte" con el número de conectados, igual que
"Cooperativa Andina" (de 006). Cuando alguien habla, todos los conectados del canal lo oyen y
solo uno habla a la vez. Un miembro que pone música en el canal es silenciado por Carlos y, si
reincide, expulsado.

**Why this priority**: los grupos son la razón por la que los conductores usan walkie-talkie;
migrar un grupo completo es el caso de negocio de la migración.

**Independent Test**: un conductor crea un canal con aprobación, tres compañeros entran por QR,
se habla por turnos, un moderador silencia y expulsa a uno, y el canal de cooperativa aparece en
la misma lista.

**Acceptance Scenarios**:

1. **Given** un conductor activo, **When** crea un canal, **Then** queda como dueño y elige
   "Abierto con enlace" o "Con aprobación"; el nombre no se repite entre canales activos.
2. **Given** un canal "Con aprobación", **When** alguien abre el enlace, **Then** queda pendiente
   hasta que un dueño o moderador lo apruebe o rechace.
3. **Given** un canal con miembros conectados, **When** uno habla, **Then** lo oyen en vivo todos
   los conectados y Disponibles, y solo uno tiene el turno a la vez (60 s como máximo).
4. **Given** un miembro con rol "Solo escucha", **When** mira el canal, **Then** oye y lee pero
   su botón está desactivado y no puede enviar texto, foto ni ubicación.
5. **Given** un moderador, **When** silencia a un miembro, **Then** ese miembro no puede
   transmitir en el canal hasta que lo reactiven; **When** lo expulsa, **Then** sale en el acto
   y pierde el historial; **When** lo bloquea, **Then** tampoco puede volver a pedir entrada.
6. **Given** el canal de la cooperativa de 006, **When** el conductor abre Radio, **Then** lo ve
   como un canal más, sin poder salir ni borrarlo desde Radio (la membresía la manda 006).
7. **Given** que el dueño borra el canal, **When** confirma, **Then** desaparece para todos y su
   historial se elimina.

---

### User Story 5 - Estados, horario de silencio y alerta de llamada (Priority: P2)

Carlos va a dejar a su hija en el colegio y se pone en "Ocupado": los mensajes le llegan al
historial sin sonar. Tiene programado un horario de silencio de 22:00 a 6:00 que lo pone en
Ocupado solo. Jonathan necesita que Carlos le responda y le manda una "Alerta" con el texto
"llámame cuando puedas": a Carlos le suena un timbre y vibra hasta que la abre.

**Why this priority**: los estados son cómo el usuario controla las interrupciones; sin ellos la
radio molesta y la desinstalan. La alerta es el "tocar la puerta" que ya usan.

**Independent Test**: un conductor en Ocupado recibe voz que no suena y queda como nueva; con el
horario de silencio activo pasa a Ocupado a la hora; una alerta suena aun en Ocupado y para al
abrirla.

**Acceptance Scenarios**:

1. **Given** el estado Disponible, **When** llega voz, **Then** suena en vivo.
2. **Given** el estado Ocupado, **When** llega voz o texto, **Then** no suena (solo un aviso
   silencioso) y queda como nuevo.
3. **Given** el estado "Solo escucha", **When** llega voz, **Then** suena en vivo, pero el botón
   no transmite (evita hablar por error) hasta volver a Disponible.
4. **Given** un horario de silencio, **When** llega la hora de inicio o fin, **Then** el estado
   cambia solo y el usuario lo ve en la barra superior.
5. **Given** una alerta de llamada recibida, **When** el receptor está Disponible u Ocupado,
   **Then** suena y vibra con el texto hasta que la abre o hasta 60 s; queda en el historial.
6. **Given** que alguien envía más de 3 alertas en 10 minutos al mismo contacto, **When** intenta
   otra, **Then** se rechaza con un mensaje claro.
7. **Given** cada contacto, **When** otro lo mira, **Then** ve su estado actual: Disponible
   (verde), Ocupado (ámbar), Solo escucha o Desconectado, con colores y formas de Kyq.

---

### User Story 6 - Texto, foto y ubicación en la misma conversación (Priority: P2)

En un trancón Carlos no puede hablar; escribe "voy tarde 10 min" en la conversación del canal.
Jonathan manda una foto de un accidente y su ubicación para que los demás lo eviten. Todo aparece
en el mismo historial, mezclado con los mensajes de voz en orden.

**Why this priority**: completa la conversación cuando no se puede hablar; los usuarios que
migran lo usan a diario.

**Independent Test**: en un contacto y un canal se envían texto, foto y ubicación; el receptor
los ve en orden con la voz y abre la ubicación en el mapa o en la app de navegación.

**Acceptance Scenarios**:

1. **Given** una conversación, **When** el usuario envía un texto (hasta 500 caracteres), **Then**
   aparece en el historial de todos con hora y autor.
2. **Given** una foto de la cámara o la galería, **When** la envía, **Then** se comprime, se
   muestra en miniatura y se abre a pantalla completa; sin metadatos de ubicación.
3. **Given** "Enviar ubicación", **When** la comparte, **Then** el receptor ve un mapa con el
   punto y puede abrirlo en Waze o Google Maps.
4. **Given** Ocupado, **When** llega texto, foto o ubicación, **Then** no suena y queda como nuevo.

---

### User Story 7 - Escuchar varios canales a la vez sin que se mezclen (Priority: P2)

Carlos tiene encendidos "Cooperativa Andina", "Taxistas Norte" y su contacto Jonathan. Mientras
oye a alguien de Taxistas Norte, Jonathan le habla: Kyq no mezcla las voces; termina el mensaje
en curso y reproduce el de Jonathan justo después, mostrando de quién es cada uno.

**Why this priority**: escuchar varios grupos sin cambiar de pantalla es como trabajan los
conductores con radio; mezclar audios haría la radio inútil.

**Independent Test**: con tres conversaciones encendidas, dos mensajes llegan a la vez; se oyen
uno tras otro en orden de llegada y ambos quedan en sus historiales.

**Acceptance Scenarios**:

1. **Given** una conversación con el interruptor "Escuchar" encendido, **When** llega voz, **Then**
   suena aunque el usuario esté en otra pantalla o en otra conversación.
2. **Given** el interruptor apagado, **When** llega voz, **Then** no suena y queda como nueva.
3. **Given** dos mensajes simultáneos, **When** llegan, **Then** se reproducen en cola por orden
   de llegada, sin mezclarse, con el nombre del que habla y de la conversación en pantalla.
4. **Given** voz del canal del viaje en curso (001) o de un SOS, **When** hay radio en cola,
   **Then** el viaje y el SOS suenan primero y la radio espera.
5. **Given** que el usuario mantiene pulsado para hablar, **When** hay mensajes en cola, **Then**
   la cola se pausa y quedan como nuevos los que no alcanzó a oír.
6. **Given** un máximo de 10 conversaciones encendidas, **When** intenta encender otra, **Then**
   se le pide apagar alguna.

---

### User Story 8 - Radio mientras conduzco: segundo plano, modo auto, burbuja y botón (Priority: P2)

Carlos navega con Waze. Kyq queda en segundo plano con un aviso fijo "Radio encendida"; la voz
entrante suena en altavoz bajando la navegación (RN-KYQ-011). Con la burbuja flotante de 005 o
el botón Bluetooth del volante habla con la conversación seleccionada sin abrir Kyq. Al tocar
"Modo auto" la pantalla muestra solo el nombre de la conversación, su estado, un botón gigante y
flechas grandes para cambiar de conversación.

**Why this priority**: el conductor usa la radio con las manos ocupadas; sin segundo plano la
radio no sirve en ruta.

**Independent Test**: con la pantalla bloqueada y Waze delante, llega voz y suena; el conductor
responde con el botón Bluetooth; en modo auto cambia de conversación con las flechas.

**Acceptance Scenarios**:

1. **Given** "Radio encendida", **When** la app pasa a segundo plano o se bloquea la pantalla,
   **Then** sigue recibiendo voz en vivo con un aviso fijo y un botón para apagar la radio.
2. **Given** voz entrante con navegación activa, **When** suena, **Then** la navegación baja de
   volumen y lo recupera al terminar.
3. **Given** un viaje en curso, **When** el conductor pulsa la burbuja o el botón Bluetooth,
   **Then** habla en el canal del viaje (001/005); sin viaje, en la conversación de radio
   seleccionada.
4. **Given** el modo auto, **When** el conductor lo abre, **Then** ve botones de al menos 1/3 del
   ancho, alto contraste y sin teclado; texto, foto y ajustes no aparecen.
5. **Given** "Apagar radio", **When** lo toca, **Then** deja de recibir en vivo, pasa a
   Desconectado para los demás y todo llega al historial.

---

### User Story 9 - Emergencia desde la radio (Priority: P2)

En una conversación de radio, sin viaje, Carlos ve una situación de peligro y mantiene pulsado
"Emergencia". Kyq abre una alerta SOS en la consola de emergencias de 003 con su ubicación y su
voz en vivo, y avisa a la conversación abierta y a su canal de cooperativa con un aviso de
emergencia que suena aunque estén en Ocupado.

**Why this priority**: la radio es lo primero que el conductor tiene a mano en un problema; el
botón de emergencia debe estar ahí y usar la misma consola de 003.

**Independent Test**: sin viaje, un conductor activa Emergencia en un canal; el operador ve la
alerta con ubicación y voz, y los miembros conectados del canal reciben el aviso aun en Ocupado.

**Acceptance Scenarios**:

1. **Given** un viaje en curso, **When** pulsa Emergencia en Radio, **Then** se abre el SOS del
   viaje de 003 (mismo flujo, mismo PIN de cancelación).
2. **Given** sin viaje, **When** mantiene pulsado Emergencia 2 s, **Then** se crea una alerta SOS
   sin viaje en la consola, con ubicación cada segundo y voz en vivo para el operador.
3. **Given** la alerta creada, **When** se emite, **Then** la conversación abierta y el canal de
   cooperativa reciben un aviso de emergencia con su nombre y ubicación, que suena en Ocupado.
4. **Given** una alerta sin viaje, **When** el operador la cierra, **Then** el conductor ve el
   cierre como en 003.

---

### User Story 10 - Migrar mi grupo: QR, enlace y carga masiva desde el panel (Priority: P1)

Jonathan recrea "Taxistas Norte" en Kyq y comparte el enlace en el grupo de mensajería de
siempre. Pedro no tiene Kyq: abre el enlace, instala la app, se registra con su teléfono y entra
directo al canal sin buscarlo. Para una cooperativa grande, el administrador de Kyq sube desde el
panel una lista con nombre, teléfono, tipo (conductor o pasajero) y canal; Kyq envía a cada uno
un SMS con su enlace y el panel muestra cuántos se enviaron, fallaron y ya entraron.

**Why this priority**: sin una migración sin fricción, la familiaridad de la radio no se aprovecha;
es el objetivo de negocio de la etapa.

**Independent Test**: un usuario sin cuenta abre el enlace de un canal, se registra y queda
dentro en una sola pasada; una carga de 50 filas desde el panel envía los SMS y el reporte se
actualiza al entrar cada invitado.

**Acceptance Scenarios**:

1. **Given** un enlace de canal o de contacto, **When** lo abre alguien con Kyq instalado y
   sesión iniciada, **Then** cae directo en la pantalla de unirse a ese canal o aceptar ese
   contacto.
2. **Given** alguien sin Kyq, **When** abre el enlace, **Then** se le lleva a instalar la app
   correcta; al registrarse con su teléfono, la invitación se aplica sola sin volver a abrir el
   enlace.
3. **Given** un conductor nuevo que entra por invitación, **When** aún no completa registro, KYC
   y suscripción de 002, **Then** se le aplica la regla de acceso de FR-005 y ve qué le falta.
4. **Given** un archivo con hasta 2 000 filas, **When** el administrador lo sube, **Then** el
   panel valida cada fila (teléfono colombiano, tipo, canal existente o a crear) y muestra los
   errores antes de enviar nada.
5. **Given** la carga confirmada, **When** se envían los SMS, **Then** cada fila queda como
   enviada, fallida, aceptada o vencida, y el administrador puede reenviar las fallidas.
6. **Given** un teléfono repetido o ya miembro del canal, **When** se procesa, **Then** no se le
   envía SMS de nuevo y se marca como "ya estaba".
7. **Given** una invitación sin usar, **When** pasan 14 días, **Then** vence.

---

### User Story 11 - El panel cuida la radio: moderación, reportes y coste (Priority: P3)

Un usuario reporta un mensaje ofensivo de un canal. El administrador lo ve en la cola de
moderación de 007 con el audio o la foto reportados, escucha solo eso, y puede borrar el mensaje,
suspender el canal o suspender al usuario. En economía unitaria ve los minutos de radio y el
almacenamiento por conductor.

**Why this priority**: necesario para operar, pero no bloquea el uso diario de los primeros
grupos migrados.

**Independent Test**: un mensaje reportado aparece en la cola; el administrador lo escucha, lo
borra y suspende el canal; los minutos y el almacenamiento aparecen en el panel.

**Acceptance Scenarios**:

1. **Given** un mensaje reportado, **When** el administrador abre el reporte, **Then** ve y oye
   solo ese mensaje y su contexto mínimo (autor, conversación, hora), no el resto del historial.
2. **Given** un canal suspendido por el administrador, **When** sus miembros abren Radio, **Then**
   lo ven como suspendido y no pueden transmitir.
3. **Given** el panel de economía unitaria (007), **When** se consulta, **Then** muestra por
   conductor los minutos de voz de radio, los mensajes guardados y el almacenamiento.
4. **Given** la página "Configuración de Radio", **When** el administrador cambia la política de
   acceso a "Solo escucha", **Then** los conductores sin suscripción dejan de poder transmitir en
   el acto y lo ven explicado; el cambio queda en la bitácora.
5. **Given** la retención en 30 días, **When** el administrador elige 7, **Then** ve el coste
   estimado de cada opción antes de confirmar y los usuarios reciben aviso del nuevo plazo.

---

### Edge Cases

- Dos personas pulsan a la vez en el mismo canal: gana la primera que el servidor registra; la
  otra oye el tono de ocupado y no transmite.
- El que tiene el turno pierde la señal: el turno se libera a los 3 s sin audio o a los 60 s,
  lo que ocurra antes; lo grabado hasta ese momento queda en el historial.
- Mensajes de menos de 0,5 s (pulsación accidental): no se envían ni se guardan.
- Un conductor pierde la suscripción o queda suspendido (007) con mensajes en el historial:
  aplica FR-005; sus canales como dueño pasan al moderador más antiguo o se congelan.
- Un conductor sale de la cooperativa (006): el canal de cooperativa desaparece de su Radio al
  instante, como ya ocurre con el canal de grupo de 006.
- Llamada telefónica entrante: la radio se pausa, lo que llegue queda como nuevo y se reanuda al
  colgar.
- Sin permiso de micrófono o de notificaciones: la radio explica qué falta y abre el ajuste; sin
  micrófono se puede escuchar y escribir.
- Teléfono sin Google Play Services (Huawei): los avisos y la ubicación funcionan con la
  alternativa de la constitución.
- La retención cambia: los mensajes ya guardados por el usuario se respetan.
- Un pasajero o conductor borra su cuenta: sus mensajes quedan como "Usuario eliminado" y su
  audio se borra con la retención o en el acto si lo pide (habeas data).
- Un canal llega al máximo de miembros: nuevas solicitudes se rechazan con un mensaje claro.

## Requirements *(mandatory)*

### Functional Requirements

**Conversaciones y acceso**

- **FR-001**: Kyq Conductor y Kyq Pasajero MUST tener una sección "Radio" con una lista única de
  conversaciones: contactos 1 a 1 y canales (incluido el de cooperativa de 006), cada una con
  nombre, foto, estado o número de conectados, mensajes nuevos y el interruptor "Escuchar".
- **FR-002**: Un conductor MUST poder invitar a otro conductor por QR, enlace o número de
  teléfono; el contacto existe solo cuando el invitado acepta, y cualquiera de los dos MUST
  poder borrarlo.
- **FR-003**: Un pasajero MUST poder tener como contacto de radio solo a conductores que lo
  tienen en su cartera (Conductor Elegido activo, RN-KYQ-005) y que activaron "Radio con mis
  clientes" (desactivada por defecto); el conductor MUST poder silenciarlo o bloquearlo.
- **FR-004**: Ninguna pantalla de Radio ni ningún enlace MUST mostrar el teléfono de otro
  usuario (se mantiene la privacidad de 001).
- **FR-005**: Un conductor con cuenta no suspendida (007) y suscripción ACTIVE o GRACE_PERIOD
  (RN-KYQ-002/003) MUST poder usar Radio completa. Para el conductor sin KYC o sin suscripción,
  el administrador MUST poder elegir en el panel una de tres políticas de acceso, para probar
  cuál funciona mejor en el mercado: (a) "Prueba": Radio completa durante N días desde su
  registro (14 por defecto, configurable), luego aplica (b); (b) "Solo con suscripción": no puede
  usar Radio; (c) "Solo escucha": oye y lee sus conversaciones pero no transmite. La política por
  defecto es (a). En ningún caso recibe viajes sin cumplir 002. El conductor MUST ver qué le
  falta y cuántos días de prueba le quedan. Un pasajero MUST poder usar Radio mientras su cuenta
  no esté suspendida.

**Voz en vivo**

- **FR-006**: La voz MUST ser semidúplex: una sola persona con turno por conversación, turno
  máximo de 60 s, tono de inicio, tono de fin y tono de ocupado propios de Kyq.
- **FR-007**: El botón para hablar MUST ser un botón redondo grande en el centro de la
  conversación, con dos modos elegibles: "Mantener para hablar" (por defecto) y "Tocar para
  hablar"; mientras otro habla MUST mostrar quién tiene el turno.
- **FR-008**: La voz MUST llegar en vivo a los receptores conectados, con "Escuchar" encendido y
  en estado Disponible o Solo escucha, con latencia de boca a oído < 250 ms en 4G.
- **FR-009**: La conversación MUST mostrar arriba el nombre y el estado del otro (o del canal),
  la duración del mensaje en curso, "Repetir último", el botón de Emergencia y la salida de audio
  (altavoz o auricular).

**Registro y reproducción**

- **FR-010**: Cada mensaje de voz de Radio MUST quedar registrado con autor, conversación, hora y
  duración, y su audio MUST poder reproducirse a demanda por los participantes con acceso a esa
  conversación, aunque no estuvieran conectados.
- **FR-011**: El historial MUST mostrar voz, texto, foto, ubicación y alertas en orden
  cronológico, marcar nuevos y escuchados, y permitir reproducir nuevos en cola, repetir y elegir
  velocidad 1x, 1,5x o 2x sin cambiar el tono de la voz.
- **FR-012**: Los mensajes MUST borrarse al vencer la retención, que el administrador configura
  en el panel entre 7, 30 o 90 días (30 por defecto), viendo el coste estimado de cada opción; el
  receptor MUST poder "Guardar" un mensaje para excluirlo de la retención, hasta 200 guardados por
  usuario y como máximo 1 año. Un cambio de retención aplica a los mensajes nuevos y a los
  existentes no guardados, nunca borra antes de lo anunciado al usuario.
- **FR-013**: Antes de su primer uso, Radio MUST informar que los mensajes quedan registrados
  y por cuánto tiempo, y pedir aceptación. El canal del viaje (001 FR-021) y la consulta previa
  (005 FR-008) siguen sin grabarse.
- **FR-014**: Un participante expulsado o que sale de un canal, o un contacto borrado, MUST
  perder el acceso al historial de esa conversación en el acto.

**Canales**

- **FR-015**: Un conductor MUST poder crear canales de grupo con nombre único entre canales
  activos, tipo "Abierto con enlace" o "Con aprobación", foto y descripción opcionales; hasta 10
  canales propios por conductor y 200 miembros por canal.
- **FR-016**: Los roles MUST ser Dueño, Moderador, Miembro y Solo escucha; Dueño y Moderador
  aprueban o rechazan solicitudes, silencian, expulsan, bloquean y cambian roles (solo el Dueño
  nombra moderadores, transfiere o borra el canal).
- **FR-017**: La entrada de pasajeros a canales de grupo MUST ser configurable por el
  administrador en el panel: "No permitida" (por defecto), "Solo escucha" o "Todos los roles".
  Dentro de lo que el panel permite, el dueño de cada canal decide si admite pasajeros y con qué
  rol. Si el administrador restringe la política, los pasajeros ya dentro pasan al rol máximo
  permitido o salen si ya no se permite ninguno, con aviso.
- **FR-018**: El canal de cooperativa de 006 MUST aparecer en Radio con las reglas de membresía,
  turno y cierre de 006; desde Radio no se puede salir ni borrar, y sus mensajes siguen las
  reglas de registro de esta etapa.

**Estados y alertas**

- **FR-019**: Cada usuario MUST tener un estado Disponible, Ocupado, Solo escucha o Desconectado
  (radio apagada o sin conexión), visible para sus contactos y en los miembros de sus canales.
- **FR-020**: En Ocupado, la voz, el texto, la foto y la ubicación MUST NOT sonar; solo quedan
  como nuevos con un aviso silencioso.
- **FR-021**: El usuario MUST poder programar horarios de silencio por días de la semana que lo
  pasan a Ocupado y lo devuelven a su estado anterior.
- **FR-022**: Un usuario MUST poder enviar una alerta de llamada (texto opcional de hasta 80
  caracteres) a un contacto o a un canal donde tenga permiso de hablar; suena y vibra hasta 60 s
  o hasta que el receptor la abre, también en Ocupado; máximo 3 alertas por emisor y destino en
  10 minutos.

**Texto, foto y ubicación**

- **FR-023**: Los participantes con permiso de hablar MUST poder enviar texto (hasta 500
  caracteres), fotos de cámara o galería (comprimidas, sin metadatos de ubicación) y su ubicación
  actual o un punto elegido en el mapa, que el receptor puede abrir en una app de navegación.

**Varias conversaciones a la vez**

- **FR-024**: El usuario MUST poder tener hasta 10 conversaciones con "Escuchar" encendido; la
  voz que llegue de cualquiera MUST sonar aunque esté en otra pantalla.
- **FR-025**: Los mensajes simultáneos MUST reproducirse en cola por orden de llegada, sin
  mezclarse, mostrando autor y conversación; el canal del viaje en curso y los SOS tienen
  prioridad sobre Radio; hablar pausa la cola.

**Manos libres**

- **FR-026**: Con "Radio encendida", la app MUST seguir recibiendo voz en vivo en segundo plano y
  con la pantalla bloqueada, con un aviso fijo que permite apagarla.
- **FR-027**: La voz de Radio MUST sonar en altavoz con la navegación atenuada (RN-KYQ-011).
- **FR-028**: La burbuja flotante y el botón físico de 005 MUST hablar en el canal del viaje si
  hay viaje abierto y, si no, en la conversación de Radio seleccionada (RN-KYQ-012).
- **FR-029**: Un "Modo auto" MUST mostrar solo la conversación seleccionada, su estado, un botón
  gigante y controles grandes para cambiar de conversación, con alto contraste.

**Emergencia**

- **FR-030**: El botón Emergencia de Radio MUST abrir el SOS del viaje de 003 si hay viaje en
  curso; sin viaje MUST crear una alerta SOS sin viaje en la consola de 003, con ubicación cada
  segundo y voz en vivo para el operador (RN-KYQ-015).
- **FR-031**: Una emergencia desde Radio MUST avisar a la conversación abierta y al canal de
  cooperativa del conductor con un aviso que suena también en Ocupado.

**Migración**

- **FR-032**: Los enlaces y QR de contacto y de canal MUST funcionar como enlace profundo: con la
  app y sesión, abren la pantalla de unirse o aceptar; sin la app, llevan a instalar la app
  correcta (conductor o pasajero) y la invitación se aplica sola tras el registro por teléfono.
- **FR-033**: El panel MUST permitir subir una lista (nombre, teléfono, tipo, canal, rol) de hasta
  2 000 filas, validarla y mostrar errores antes de enviar, crear los canales que falten con un
  dueño indicado, y enviar un SMS por fila válida con su enlace personal.
- **FR-034**: El panel MUST mostrar por carga el estado de cada fila (enviada, fallida, aceptada,
  ya estaba, vencida), permitir reenviar las fallidas y no reenviar a quien ya aceptó.
- **FR-035**: Las invitaciones MUST vencer a los 14 días; el SMS MUST decir quién invita, a qué
  canal y cómo dejar de recibir invitaciones.

**Moderación y coste**

- **FR-036**: Cualquier participante MUST poder reportar un mensaje; el reporte MUST llegar a la
  cola de moderación de 007 con solo ese mensaje y su contexto mínimo; el administrador MUST
  poder borrarlo, suspender el canal o suspender al usuario.
- **FR-037**: El personal de Kyq MUST NOT poder escuchar ni leer conversaciones de Radio salvo
  mensajes reportados y alertas SOS; todo acceso del panel a un mensaje MUST quedar en la
  bitácora de auditoría.
- **FR-038**: Los minutos de voz, el número de mensajes y el almacenamiento de Radio MUST medirse
  por conductor y verse en la economía unitaria del panel (RN-KYQ-004, principio VII).

- **FR-040**: El panel MUST tener una página "Configuración de Radio" con la política de acceso
  de conductores sin suscripción y sus días de prueba (FR-005), la entrada de pasajeros a canales
  (FR-017) y la retención (FR-012); solo administradores pueden cambiarla y cada cambio queda en
  la bitácora de auditoría.

**Familiaridad**

- **FR-039**: La forma de uso MUST seguir la referencia funcional de `phva.md` (ubicación de la
  lista, de la conversación, del botón grande, del historial, de estados y alertas, y el
  comportamiento de cada acción), con marca, íconos, sonidos, colores y textos propios de Kyq.

### Key Entities *(include if feature involves data)*

- **Conversación de radio**: contacto 1 a 1 (entre dos conductores o conductor–cliente) o canal;
  tipo, nombre, foto, estado (activa, suspendida, borrada), creada por.
- **Contacto de radio**: par de usuarios, quién invitó, estado (pendiente, aceptado, borrado),
  silenciado o bloqueado por cada lado.
- **Canal**: nombre, tipo de entrada (abierto con enlace, con aprobación), dueño, límite de
  miembros, origen (propio o cooperativa de 006).
- **Miembro de canal**: usuario, rol (dueño, moderador, miembro, solo escucha), estado
  (pendiente, activo, silenciado, expulsado, bloqueado).
- **Mensaje**: conversación, autor, tipo (voz, texto, foto, ubicación, alerta, emergencia),
  hora, duración y referencia al audio o la foto, vence el, reportado.
- **Estado del mensaje por receptor**: nuevo, escuchado o leído, guardado.
- **Estado de radio del usuario**: estado actual, radio encendida, conversaciones con "Escuchar",
  horarios de silencio, modo de botón.
- **Invitación**: emisor, destino (contacto o canal), enlace, teléfono si aplica, estado,
  vence el; ligada a una carga masiva si viene del panel.
- **Carga masiva**: administrador, archivo, filas con su estado y error, totales.
- **Reporte de mensaje**: mensaje, quién reporta, motivo, decisión del administrador.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: En una prueba con 10 usuarios que hoy usan otra app walkie-talkie, sin explicación
  previa, al menos 9 envían un mensaje de voz, reproducen uno anterior y cambian su estado en su
  primera sesión, en menos de 2 minutos cada tarea.
- **SC-002**: El 95 % de los mensajes de voz en vivo se oye en el receptor menos de 250 ms
  después de pronunciado, en 4G.
- **SC-003**: El 100 % de los mensajes de voz enviados a un receptor desconectado u Ocupado está
  en su historial y se puede reproducir al reconectar.
- **SC-004**: Un usuario sin cuenta que abre un enlace de canal queda dentro del canal, registrado,
  en menos de 3 minutos sin volver a abrir el enlace.
- **SC-005**: Una carga masiva de 2 000 filas se valida en menos de 1 minuto y el 95 % de los SMS
  válidos sale en menos de 10 minutos.
- **SC-006**: En una prueba de 1 hora con 3 conversaciones encendidas y mensajes simultáneos,
  ningún audio se mezcla ni se pierde.
- **SC-007**: A los 30 días de migrar un grupo, al menos el 70 % de los miembros invitados usó
  Radio en la última semana.
- **SC-008**: El coste mensual de Radio por conductor activo se ve en el panel y no supera el
  presupuesto definido en el plan.

## Assumptions

- Tres decisiones de mercado quedan como configuración del panel (FR-005, FR-012, FR-017) con
  valores por defecto prudentes: prueba de 14 días, canales sin pasajeros y retención de 30 días.
  Cada cambio de configuración queda en la bitácora de auditoría con quién y cuándo.
- Los grupos de la app de terceros no se pueden importar automáticamente: se recrean en Kyq y se
  invita a sus miembros (por enlace o por carga masiva).
- Las invitaciones por SMS usan el proveedor de SMS que ya usa Kyq para el OTP y los contactos de
  emergencia de 003.
- La alerta SOS sin viaje amplía 003 sin cambiar su consola: es una alerta con conductor y
  ubicación, sin viaje asociado.
- Un usuario que es pasajero y conductor a la vez usa la Radio de cada app con su rol.
- Radio es una nueva regla de negocio (propuesta RN-KYQ-017: "Radio Kyq permanente con registro
  a demanda") que se agrega a la constitución en el mismo cambio (principio V, enmienda MINOR).
- Solo Android y web del panel en esta etapa; iOS en fase 2 con el framework PushToTalk.
