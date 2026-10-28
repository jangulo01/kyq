# Feature Specification: Botón SOS, viaje compartido y consola de emergencias

**Feature Branch**: `003-sos-emergency-console`

**Created**: 2026-10-27

**Status**: Draft

**Input**: User description: "Toolkit de seguridad (RN-KYQ-015): botón SOS en Kyq Pasajero y Kyq Conductor durante un viaje que abre en la consola del Panel Administrativo la ubicación GPS a 1 Hz y un canal de voz PTT en vivo entre la persona en riesgo y el operador; enlace web para compartir el viaje en vivo con un contacto de confianza; consola de emergencias en el panel con cola de alertas, mapa, escucha e intervención por voz, notas y cierre del caso; contactos de emergencia avisados por SMS."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Pedir ayuda con el botón SOS (Priority: P1)

Durante un viaje, el pasajero o el conductor mantiene pulsado el botón SOS 2 segundos. La app
confirma "Alerta enviada", empieza a enviar su ubicación cada segundo y abre un canal de voz
directo con un operador de Kyq, sin pasos extra. Sus contactos de emergencia reciben un SMS con
el enlace del viaje en vivo.

**Why this priority**: es la garantía de seguridad que exige un servicio de transporte; sin ella
no se puede abrir a pasajeros desconocidos ni a la operación nocturna.

**Independent Test**: en un viaje en curso, el pasajero pulsa SOS; en menos de 5 segundos la
alerta aparece en la consola con su ubicación moviéndose y el operador le habla por voz.

**Acceptance Scenarios**:

1. **Given** un viaje ACCEPTED, ARRIVED o IN_PROGRESS, **When** el pasajero mantiene SOS 2 s,
   **Then** se crea una alerta, su ubicación se envía cada segundo y la app muestra "Ayuda en
   camino: un operador te escucha".
2. **Given** una pulsación corta del SOS, **When** se suelta antes de 2 s, **Then** no se envía
   nada y se indica "Mantén pulsado para pedir ayuda".
3. **Given** una alerta activa, **When** el operador habla, **Then** la voz suena en el teléfono
   de quien pidió ayuda en altavoz, aunque la app esté en segundo plano (conductor).
4. **Given** una alerta activa, **When** la persona pulsa "Estoy bien" e introduce su PIN de
   seguridad, **Then** la alerta pasa a "cancelada por el usuario" y el operador lo ve; sin PIN
   (posible coacción) la alerta sigue abierta y se marca "cancelación sin PIN".
5. **Given** el conductor en un viaje, **When** pulsa SOS, **Then** ocurre lo mismo para él; el
   pasajero no ve que se activó una alerta.

---

### User Story 2 - Consola de emergencias del operador (Priority: P1)

El operador de Kyq ve en el panel una cola de alertas abiertas con sonido de aviso. Al abrir una
ve el mapa con la ubicación en vivo y el recorrido, los datos del viaje (pasajero, conductor,
placa, origen y destino), escucha el canal de voz y puede hablar. Anota lo que hace (llamó a la
policía, contactó a la familia) y cierra el caso con un desenlace.

**Why this priority**: sin alguien que atienda, el SOS no ayuda; la consola es la otra mitad de
la historia 1.

**Independent Test**: un operador atiende una alerta de prueba: la toma, habla, deja dos notas y
la cierra como "falsa alarma"; la alerta queda en el historial con todo el registro.

**Acceptance Scenarios**:

1. **Given** una alerta nueva, **When** llega a la consola, **Then** suena un aviso, aparece
   arriba en la cola y se muestra el tiempo de espera.
2. **Given** dos operadores en línea, **When** uno toma la alerta, **Then** al otro le aparece
   tomada por él; ambos pueden escuchar, pero solo quien la tomó habla, salvo que la libere.
3. **Given** una alerta tomada, **When** el operador abre el detalle, **Then** ve la ubicación
   actualizada cada segundo, el recorrido desde el SOS, los datos del viaje y del vehículo, y un
   botón para copiar la ubicación para la policía.
4. **Given** una alerta, **When** el operador cierra el caso, **Then** debe elegir un desenlace
   (falsa alarma, resuelto, derivado a autoridades, sin respuesta) y la persona deja de enviar
   su ubicación cada segundo.
5. **Given** una alerta sin tomar 60 s, **When** pasa ese tiempo, **Then** se avisa por SMS a
   los operadores de guardia.

---

### User Story 3 - Compartir el viaje en vivo (Priority: P2)

Desde un viaje, el pasajero o el conductor comparte un enlace web con un contacto de confianza.
Quien lo abre en cualquier navegador, sin instalar nada ni registrarse, ve el mapa con la
posición del vehículo, la placa, el nombre del conductor y el estado del viaje, hasta que
termina.

**Why this priority**: prevención; reduce la necesidad del SOS y da tranquilidad a la familia.

**Independent Test**: el pasajero comparte el viaje; en otro teléfono el enlace muestra el
vehículo moviéndose; al completar el viaje el enlace muestra "Viaje finalizado".

**Acceptance Scenarios**:

1. **Given** un viaje aceptado, **When** el pasajero toca "Compartir viaje", **Then** se abre el
   menú para enviar el enlace por WhatsApp, SMS u otra app.
2. **Given** el enlace abierto, **When** el vehículo se mueve, **Then** la posición se actualiza
   en menos de 5 s.
3. **Given** un viaje completado o cancelado, **When** alguien abre el enlace, **Then** ve
   "Viaje finalizado" sin ubicación; el enlace deja de mostrar datos 15 minutos después.
4. **Given** el enlace, **When** lo ve un tercero, **Then** no aparecen teléfonos ni documentos
   de nadie.

---

### User Story 4 - Contactos de emergencia y PIN de seguridad (Priority: P2)

Pasajero y conductor registran hasta 3 contactos de emergencia (nombre y teléfono) y un PIN de 4
dígitos para cancelar un SOS. Cuando activan el SOS, sus contactos reciben un SMS con el enlace
del viaje en vivo.

**Why this priority**: amplía la red de ayuda más allá del operador; el PIN evita que un agresor
cancele la alerta.

**Independent Test**: un pasajero registra dos contactos y su PIN; al activar SOS ambos reciben
el SMS con el enlace.

**Acceptance Scenarios**:

1. **Given** el perfil de seguridad, **When** el usuario añade un contacto, **Then** se valida el
   teléfono y se guarda (máximo 3).
2. **Given** un SOS activado, **When** se crea la alerta, **Then** cada contacto recibe un SMS con
   el nombre de la persona y el enlace del viaje en vivo.
3. **Given** que el usuario no tiene PIN, **When** intenta activar SOS por primera vez, **Then**
   la alerta se envía igual y después se le pide configurar el PIN.

### Edge Cases

- Sin datos móviles al pulsar SOS: la app reintenta cada pocos segundos y, si tiene señal de
  llamada, ofrece llamar al 123 (línea de emergencias de Colombia).
- GPS sin precisión o apagado: la alerta se crea con la última ubicación conocida y lo indica.
- La app se cierra o el teléfono se bloquea durante la alerta: la ubicación sigue enviándose
  (conductor: servicio en primer plano; pasajero: mientras el sistema lo permita, con aviso de
  no cerrar la app).
- SOS fuera de un viaje: no disponible en esta fase; se ofrece llamar al 123.
- Dos SOS en el mismo viaje (pasajero y conductor): una alerta por persona, ambas enlazadas al
  viaje y visibles juntas.
- Nadie en la consola: tras 60 s se avisa a los operadores de guardia por SMS; la persona ve
  "Seguimos intentando conectar con un operador" y la opción de llamar al 123.
- El viaje termina con la alerta abierta: la alerta sigue hasta que el operador la cierre.
- Abusos (SOS de broma repetidos): se registran por usuario; el operador puede marcar falsa
  alarma y el administrador ve el historial.

## Requirements *(mandatory)*

### Functional Requirements

**SOS**

- **FR-001**: Pasajero y conductor MUST tener un botón SOS visible en la pantalla del viaje desde
  ACCEPTED hasta 15 minutos después de COMPLETED (misma ventana que el canal PTT).
- **FR-002**: La alerta MUST enviarse solo tras mantener pulsado 2 segundos, con respuesta
  táctil y visual.
- **FR-003**: Con una alerta activa, la app MUST enviar la ubicación cada segundo hasta que el
  operador cierre el caso (RN-KYQ-015).
- **FR-004**: La alerta MUST abrir un canal de voz entre la persona y los operadores sin pasos
  extra; la voz del operador suena en altavoz.
- **FR-005**: Cancelar una alerta MUST pedir el PIN de seguridad; una cancelación sin PIN no
  cierra la alerta y se marca para el operador.
- **FR-006**: La otra parte del viaje MUST NOT ser avisada de que se activó un SOS.

**Consola**

- **FR-007**: El panel MUST mostrar una cola de alertas abiertas en tiempo real con aviso sonoro
  y tiempo de espera, y un historial de alertas cerradas filtrable por fecha y desenlace.
- **FR-008**: Un operador MUST poder tomar y liberar una alerta; solo quien la tiene habla, todos
  los operadores pueden escuchar.
- **FR-009**: El detalle MUST mostrar la ubicación en vivo, el recorrido desde el SOS, los datos
  del viaje, del pasajero (nombre) y del conductor (nombre, placa, vehículo).
- **FR-010**: El operador MUST poder añadir notas con hora y cerrar con desenlace: falsa alarma,
  resuelto, derivado a autoridades o sin respuesta.
- **FR-011**: Una alerta sin tomar durante 60 s MUST avisar por SMS a los operadores de guardia.
- **FR-012**: Solo los administradores con el permiso de operador de emergencias MUST acceder a
  la consola; todo acceso y acción queda auditado.

**Viaje compartido**

- **FR-013**: Pasajero y conductor MUST poder generar un enlace del viaje en vivo y compartirlo
  con el menú del sistema.
- **FR-014**: El enlace MUST funcionar en cualquier navegador sin registro, mostrar posición
  (actualizada en < 5 s), placa, nombre del conductor y estado, y dejar de mostrar datos 15
  minutos después de terminar el viaje.
- **FR-015**: El enlace MUST NOT mostrar teléfonos, documentos ni datos de pago, y no debe poder
  adivinarse.

**Contactos y PIN**

- **FR-016**: Cada usuario MUST poder registrar hasta 3 contactos de emergencia y un PIN de 4
  dígitos.
- **FR-017**: Al crearse una alerta, sus contactos MUST recibir un SMS con el enlace del viaje.

**Grabación**

- **FR-018**: El audio del canal SOS MUST grabarse y conservarse 90 días como evidencia,
  accesible solo para operadores; es la única excepción a "la voz no se almacena" (FR-021 de
  001).

### Key Entities

- **Alerta SOS**: viaje, quién la activó (rol), estado (abierta, tomada, cerrada, cancelada por
  el usuario, cancelación sin PIN), operador asignado, creada, tomada, cerrada, desenlace.
- **Punto de ubicación de alerta**: alerta, posición, precisión, momento (1 por segundo).
- **Nota de alerta**: alerta, operador, texto, momento.
- **Enlace de viaje compartido**: viaje, quién lo creó, token no adivinable, vigencia.
- **Contacto de emergencia**: usuario, nombre, teléfono (máximo 3).
- **PIN de seguridad**: usuario, PIN guardado de forma no reversible.
- **Grabación SOS**: alerta, archivo de audio, vigencia de 90 días.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: La alerta aparece en la consola en menos de 5 s desde que se completa la pulsación
  de 2 s, en el 95 % de los casos.
- **SC-002**: El operador oye a la persona en menos de 1 s desde que habla (canal en vivo).
- **SC-003**: La ubicación en la consola tiene un retraso menor a 3 s respecto al teléfono.
- **SC-004**: El 95 % de las alertas se toman en menos de 60 s durante el horario con operador.
- **SC-005**: Los contactos de emergencia reciben el SMS en menos de 30 s.
- **SC-006**: Ningún SOS se cancela sin PIN y ningún enlace compartido expone un teléfono (0 casos
  en pruebas).

## Assumptions

- Kyq tiene operadores propios (rol administrador con permiso de emergencias) en un horario
  definido; fuera de él aplican los avisos por SMS y la opción del 123.
- Kyq no despacha policía ni ambulancias: el operador deriva a las autoridades por teléfono.
- El SOS se limita al viaje (desde ACCEPTED hasta 15 min después de terminar); fuera de un viaje
  se ofrece llamar al 123.
- Solo Android (apps) y web (consola y enlace compartido).
- La grabación del canal SOS se conserva 90 días; es la única voz que Kyq guarda.
