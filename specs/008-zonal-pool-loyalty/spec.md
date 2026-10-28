# Feature Specification: Bolsa zonal y fidelización ampliada

**Feature Branch**: `008-zonal-pool-loyalty`

**Created**: 2026-10-28

**Status**: Draft

**Input**: User description: "Opción 3 del selector triple de despacho (SDD §1, §4
`kyq_rider.confirmation_fare`, CHK-PAS-06; modo `OPEN_H3`): 'Autónomo libre más cercano' (bolsa
zonal H3), también desde el inicio para pasajeros sin Conductores Elegidos, solo hacia conductores
que activen recibir solicitudes de la bolsa. Además, del SDD: etiqueta 'Cliente de tu cartera'
(Prioridad Oro) en la oferta (CHK-DRV-04, `kyq_driver.dispatch_ramen`), tarifa preferencial para
clientes de cartera (RN-KYQ-013) y afiliación sin QR: después del viaje y por enlace
(`driver_loyal_clients.affiliation_source` = QR_SCAN / POST_TRIP / LINK). Comisión 0 %
(RN-KYQ-001)."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - El pasajero pide al conductor libre más cercano de la bolsa zonal (Priority: P1)

Un pasajero necesita un viaje y su Conductor Elegido no puede (o aún no tiene ninguno). Elige
"Conductor libre más cercano": marca recogida y destino, ve la tarifa sugerida y pide. La solicitud
va al conductor libre más cercano a la recogida entre los que aceptan solicitudes de la bolsa
zonal; ese conductor tiene la oferta en exclusiva 25 s, como en 001. Si la rechaza o la deja
vencer, pasa al siguiente más cercano, hasta tres conductores. El pasajero ve "Buscando un
conductor cercano" y, cuando uno acepta, su nombre, vehículo y placa; desde ahí el viaje es igual
que en 001 (walkie-talkie, ciclo del viaje, pago de 004 y 100 % para el conductor).

La opción está en dos sitios: como tercera opción del selector al pedir a un Conductor Elegido
(antes "Próximamente") y en el inicio de la app como "Pedir un viaje a un conductor cercano",
también para quien no tiene Conductores Elegidos.

**Why this priority**: completa el despacho híbrido triple del SDD y evita que el pasajero se
quede sin servicio cuando su conductor y su cooperativa no pueden; también abre la puerta a
pasajeros nuevos.

**Independent Test**: con dos conductores con la bolsa activada a 1 km y 3 km de la recogida y
uno sin activarla a 500 m, un pasajero sin Conductores Elegidos pide desde el inicio; la oferta
llega al de 1 km; este la rechaza; llega al de 3 km, que acepta; el de 500 m nunca la recibe.

**Acceptance Scenarios**:

1. **Given** un pasajero sin Conductores Elegidos, **When** abre la app, **Then** ve "Pedir un
   viaje a un conductor cercano" además de la opción de escanear un QR.
2. **Given** conductores de la bolsa libres cerca, **When** el pasajero pide a la bolsa, **Then**
   la oferta llega en exclusiva al más cercano a la recogida durante 25 s.
3. **Given** que el conductor de la bolsa rechaza o deja vencer la oferta, **When** pasa el
   plazo, **Then** la oferta va al siguiente más cercano no ofertado, hasta tres conductores.
4. **Given** que no hay conductores de la bolsa libres cerca, **When** el pasajero pide, **Then**
   se le dice "No hay conductores libres cerca ahora" y no se crea ninguna oferta.
5. **Given** la pantalla de solicitud a un Conductor Elegido, **When** el pasajero abre el
   selector, **Then** la tercera opción "Conductor libre más cercano" se puede elegir.
6. **Given** un viaje de la bolsa aceptado, **When** se completa, **Then** el conductor recibe
   el 100 % de la tarifa acordada y la comisión es 0 (RN-KYQ-001).
7. **Given** un conductor que no activó la bolsa, **When** hay solicitudes de la bolsa cerca,
   **Then** no recibe ninguna.

---

### User Story 2 - El conductor decide si recibe solicitudes de la bolsa zonal (Priority: P1)

El conductor activa o desactiva en su app "Recibir solicitudes de la bolsa zonal". Por defecto
está desactivado: su prioridad son sus clientes. Con la bolsa activa y estando libre puede
recibir ofertas de pasajeros que no son de su cartera; la tarjeta de la oferta lo indica con
"Bolsa zonal" y muestra la distancia a la recogida.

**Why this priority**: sin conductores en la bolsa la historia 1 no funciona; y el conductor
debe controlar si atiende a desconocidos.

**Independent Test**: un conductor activa la bolsa, se pone ONLINE y recibe una oferta de la
bolsa con la etiqueta "Bolsa zonal"; la desactiva y deja de recibirlas.

**Acceptance Scenarios**:

1. **Given** un conductor nuevo, **When** abre los ajustes de despacho, **Then** la bolsa zonal
   está desactivada.
2. **Given** la bolsa activada y el conductor libre, **When** llega una solicitud de la bolsa,
   **Then** la tarjeta dice "Bolsa zonal" y muestra la distancia a la recogida.
3. **Given** la bolsa desactivada con una oferta de la bolsa abierta, **When** la desactiva,
   **Then** la oferta abierta sigue su curso y no le llegan más.

---

### User Story 3 - El conductor distingue a sus clientes (Prioridad Oro) (Priority: P2)

Cuando un cliente de su cartera le pide un viaje directamente, la tarjeta de la oferta muestra
"⭐ Cliente de tu cartera" con el número de viajes que han hecho juntos. Las ofertas que llegan
de la cooperativa o de la bolsa muestran su origen ("De tu cooperativa", "Bolsa zonal").

**Why this priority**: refuerza la fidelización (RN-KYQ-005, RN-KYQ-007) y ayuda al conductor a
decidir rápido.

**Independent Test**: un cliente con 3 viajes previos pide al conductor; la oferta muestra la
etiqueta y "3 viajes juntos".

**Acceptance Scenarios**:

1. **Given** un cliente de la cartera, **When** pide al conductor, **Then** la oferta muestra
   "⭐ Cliente de tu cartera" y los viajes completados juntos.
2. **Given** una oferta de la bolsa, **When** el conductor la ve, **Then** muestra "Bolsa zonal"
   y no la etiqueta de cartera.

---

### User Story 4 - Tarifa preferencial para clientes de la cartera (Priority: P2)

El conductor puede definir un descuento preferencial para los clientes de su cartera (0 % a
30 %). Cuando uno de sus clientes le pide un viaje directamente, la tarifa sugerida ya incluye el
descuento y el pasajero lo ve ("Tarifa preferencial de Carlos: −10 %"). No aplica a viajes de la
bolsa ni a los derivados a compañeros. La negociación de 001 sigue disponible sobre esa tarifa.

**Why this priority**: RN-KYQ-013 (acuerdos directos) y fidelización; el conductor premia a sus
clientes sin intermediarios.

**Independent Test**: el conductor fija 10 %; su cliente cotiza un viaje de 20 000 COP sugeridos y
ve 18 000 con el aviso; un pasajero de la bolsa ve 20 000.

**Acceptance Scenarios**:

1. **Given** un descuento del 10 %, **When** un cliente de la cartera cotiza un viaje con ese
   conductor, **Then** ve la tarifa con el descuento aplicado y el aviso de tarifa preferencial.
2. **Given** el mismo conductor, **When** recibe un viaje de la bolsa, **Then** la tarifa es la
   sugerida sin descuento.
3. **Given** un valor fuera de 0–30 %, **When** el conductor lo guarda, **Then** se rechaza con
   un mensaje claro.
4. **Given** un viaje con tarifa preferencial completado, **When** se liquida, **Then** el
   conductor recibe el 100 % de la tarifa acordada (RN-KYQ-001).

---

### User Story 5 - Afiliarse sin escanear el QR: después del viaje o por enlace (Priority: P2)

Al terminar un viaje con un conductor que no es su Conductor Elegido (de la bolsa o de una
cooperativa), el pasajero ve "Guardar a Diana como Conductor Elegido" y con un toque la añade.
Además, el conductor puede compartir un enlace personal (por WhatsApp, por ejemplo); al abrirlo,
el pasajero entra a la app y confirma la afiliación igual que con el QR. Cada afiliación registra
su origen (QR, después del viaje o enlace) y el panel de fidelización de 007 lo desglosa.

**Why this priority**: RN-KYQ-005; la bolsa y las cooperativas acercan pasajeros nuevos al
conductor y esta historia los convierte en cartera.

**Independent Test**: un pasajero completa un viaje de la bolsa con Diana y la guarda; Diana ve
al pasajero en "Mis clientes" con origen "Después del viaje". Otro pasajero abre el enlace de
Diana y queda afiliado con origen "Enlace".

**Acceptance Scenarios**:

1. **Given** un viaje completado con un conductor que no es su elegido, **When** el pasajero ve
   el resumen, **Then** se le ofrece guardarlo como Conductor Elegido.
2. **Given** un viaje con su propio Conductor Elegido, **When** ve el resumen, **Then** no se le
   ofrece (ya lo tiene).
3. **Given** el enlace de un conductor, **When** el pasajero lo abre con la app instalada,
   **Then** ve el conductor y confirma la afiliación.
4. **Given** el enlace de un conductor, **When** se abre sin la app, **Then** una página explica
   cómo instalar Kyq Pasajero, sin datos personales del conductor más allá de su nombre.
5. **Given** afiliaciones de los tres orígenes, **When** el administrador abre Fidelización,
   **Then** ve cuántas nuevas hubo por origen en el periodo.

### Edge Cases

- Dos solicitudes de la bolsa a la vez: un conductor no puede quedar reservado por las dos; la
  segunda toma al siguiente.
- Un conductor de la bolsa sin ubicación reciente (más de 5 minutos) o a más de 5 km de la
  recogida no recibe ofertas de la bolsa.
- El pasajero pide a la bolsa y el más cercano es uno de sus Conductores Elegidos con la bolsa
  activa: la recibe como cualquiera, pero la tarjeta muestra la etiqueta de cartera y aplica su
  tarifa preferencial (es su cliente).
- El pasajero cancela mientras se busca conductor: se cierra para todos sin cargo.
- Un conductor suspendido (007) o sin suscripción o documentos al día no recibe ofertas de la
  bolsa aunque la tenga activada.
- Un pasajero suspendido no puede pedir a la bolsa.
- El conductor cambia su descuento mientras un cliente arma su solicitud: al pedir se aplica el
  descuento vigente y queda fijo en ese viaje; los cambios posteriores aplican a los siguientes.
- El pasajero abre el enlace de un conductor que ya es su elegido: se le dice que ya lo tiene.
- El enlace de un conductor sin alta completa o suspendido: "Este conductor no está disponible".
- Pasajero con una solicitud o viaje activo: no puede pedir otro, tampoco a la bolsa (como 001).

## Requirements *(mandatory)*

### Functional Requirements

**Bolsa zonal**

- **FR-001**: El pasajero MUST poder pedir un viaje a la bolsa zonal desde el inicio de la app
  (tenga o no Conductores Elegidos) y como tercera opción del selector de despacho de 006.
- **FR-002**: Una solicitud de la bolsa MUST ofrecerse al conductor elegible más cercano a la
  recogida: con la bolsa activada, libre (ONLINE sin viaje ni oferta), habilitado para estar
  ONLINE (RN-KYQ-002, RN-KYQ-003, RN-KYQ-016), no suspendido, con ubicación de los últimos
  5 minutos y a no más de 5 km en línea recta; a igual distancia, uno estable.
- **FR-003**: Cada oferta de la bolsa MUST seguir las reglas de 001: exclusiva, 25 s para
  responder y el conductor reservado mientras la tiene (RN-KYQ-007).
- **FR-004**: Si el conductor rechaza o deja vencer la oferta, MUST pasar al siguiente elegible
  no ofertado; como máximo tres conductores por solicitud; agotados o sin candidatos, se cierra
  con "sin conductores disponibles".
- **FR-005**: La tarifa de un viaje de la bolsa MUST calcularse con la tabla de la ciudad
  (RN-KYQ-013) y admitir la negociación de 001.
- **FR-006**: El pasajero MUST ver el estado de la búsqueda y, al aceptar un conductor, su nombre,
  vehículo y placa; nunca su teléfono.
- **FR-007**: Un viaje de la bolsa MUST seguir el ciclo, el walkie-talkie (RN-KYQ-009,
  RN-KYQ-014), la seguridad (003) y el pago (004) de cualquier viaje, con 100 % para el conductor
  y comisión 0 (RN-KYQ-001).
- **FR-008**: El conductor MUST poder activar y desactivar la recepción de solicitudes de la
  bolsa; por defecto desactivada; desactivarla no retira una oferta ya abierta.
- **FR-009**: Un conductor sin la bolsa activada MUST NOT recibir solicitudes de la bolsa.

**Origen de la oferta y Prioridad Oro**

- **FR-010**: La oferta MUST mostrar su origen: "⭐ Cliente de tu cartera" (con viajes completados
  juntos) cuando el pasajero está afiliado al conductor, "De tu cooperativa" cuando viene
  derivada (006) y "Bolsa zonal" (con distancia a la recogida) cuando viene de la bolsa.

**Tarifa preferencial (RN-KYQ-013)**

- **FR-011**: El conductor MUST poder fijar un descuento preferencial de 0 % a 30 % (en pasos de
  1 %) para los pasajeros de su cartera; 0 % lo desactiva.
- **FR-012**: La cotización de un pasajero afiliado al conductor que recibirá la oferta MUST
  aplicar el descuento a la tarifa sugerida y mostrarlo; no aplica a ofertas derivadas a otro
  conductor ni a pasajeros no afiliados.
- **FR-013**: El viaje MUST conservar el descuento aplicado al pedir aunque el conductor lo cambie
  después; la pantalla de confirmación MUST mostrar la tarifa con el descuento vigente.

**Afiliación sin QR (RN-KYQ-005)**

- **FR-014**: Tras completar un viaje con un conductor que no es su Conductor Elegido, el
  pasajero MUST poder añadirlo con un toque desde el resumen.
- **FR-015**: Cada conductor MUST tener un enlace personal para compartir; abrirlo en un teléfono
  con Kyq Pasajero MUST llevar a confirmar la afiliación; sin la app, una página pública muestra
  solo su nombre y cómo instalar Kyq.
- **FR-016**: Cada afiliación MUST registrar su origen (QR, después del viaje o enlace) y el
  informe de fidelización de 007 MUST desglosar las nuevas afiliaciones por origen.
- **FR-017**: El enlace MUST NOT funcionar para conductores sin alta completa o suspendidos, y
  MUST NOT revelar el teléfono del conductor.

### Key Entities

- **Preferencias de despacho del conductor**: recibe solicitudes de la bolsa (sí/no), descuento
  preferencial para su cartera (0–30 %).
- **Viaje (cambios)**: nuevo modo de despacho "bolsa zonal", tarifa preferencial aplicada (sí/no
  y porcentaje).
- **Oferta del viaje (cambios)**: origen de la oferta (cartera, cooperativa, bolsa) y distancia
  a la recogida.
- **Afiliación (cambios)**: origen (QR, después del viaje, enlace).
- **Enlace del conductor**: identificador público para compartir, sin datos de contacto.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Con conductores de la bolsa libres cerca, el 95 % de las solicitudes llegan a un
  conductor en menos de 2 segundos.
- **SC-002**: Ninguna solicitud de la bolsa llega a un conductor sin la bolsa activada, ocupado,
  suspendido o a más de 5 km (0 casos en las pruebas).
- **SC-003**: Ningún viaje de la bolsa ni con tarifa preferencial cobra comisión (0 casos).
- **SC-004**: Un pasajero sin Conductores Elegidos pide su primer viaje en menos de 1 minuto
  desde que abre la app (cuenta ya creada).
- **SC-005**: El 100 % de las afiliaciones nuevas tienen origen registrado y el informe de
  fidelización las suma igual que el total de afiliaciones nuevas.

## Assumptions

- **Radio y frescura**: 5 km en línea recta y ubicación de ≤ 5 minutos (en 006 el radio de
  cooperativa es 10 km; la bolsa es más local porque el conductor no conoce al pasajero).
- **Máximo de pasos**: hasta 3 conductores por solicitud, como en 006.
- **Opt-in**: la bolsa está desactivada por defecto; así lo decidió el responsable de producto
  (solo los conductores que la activen).
- **Disponibilidad**: también desde el inicio para pasajeros sin Conductores Elegidos (decisión
  del responsable de producto).
- **Prioridad**: no se reordena a nadie por estar en la cartera dentro de la bolsa; la Prioridad
  Oro es la oferta exclusiva nominal de 001 (RN-KYQ-007), que no cambia.
- **Descuento**: un porcentaje único para toda la cartera; no hay tarifas por cliente ni cupones.
- **Enlace**: usa el mismo identificador que el QR del conductor; la página pública sin app no
  muestra foto, teléfono ni placa.
- **Fidelización**: la bolsa no afilia automáticamente; solo con el toque del pasajero.
- Android para conductor y pasajero, web para el panel; iOS fuera de alcance (fase 2).
