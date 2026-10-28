# Análisis PHVA: Radio Kyq (011)

Ciclo Planear–Hacer–Verificar–Actuar de la etapa 011. Complementa [spec.md](spec.md): aquí está
el porqué, la referencia funcional de familiaridad, cómo se despliega, cómo se mide y qué se
decide con los resultados.

---

## 1. PLANEAR

### 1.1 Problema

Los conductores autónomos y sus clientes coordinan el día en una app walkie-talkie de terceros.
Kyq solo tiene voz dentro del viaje (001), en una consulta de 2 minutos (005) y en el canal de
cooperativa (006). Mientras la radio diaria siga en otra app:

- el conductor tiene dos apps abiertas al volante (más distracción, más batería);
- la relación con el cliente vive fuera de Kyq (se pierde la fidelización, RN-KYQ-005/006);
- Kyq no puede ofrecer emergencia, moderación ni coste medido sobre esa comunicación.

Riesgo de la migración: si la radio de Kyq se usa distinto, el usuario siente que "perdió su
radio" y vuelve a la app anterior ("trauma de migración").

### 1.2 Objetivos (medibles en la spec, §Success Criteria)

| Objetivo | Indicador | Meta |
|---|---|---|
| Uso sin aprendizaje | SC-001: tareas básicas sin ayuda en la primera sesión | 9 de 10 usuarios, < 2 min por tarea |
| Calidad de voz en vivo | SC-002: latencia boca–oído en 4G | p95 < 250 ms |
| Nada se pierde | SC-003: mensajes a receptores fuera de línea en historial | 100 % |
| Migración sin fricción | SC-004: de abrir el enlace a estar en el canal | < 3 min |
| Escala de invitación | SC-005: carga de 2 000 filas | validación < 1 min, 95 % SMS < 10 min |
| Adopción | SC-007: invitados activos a 30 días | ≥ 70 % |
| Coste | SC-008: coste de Radio por conductor activo | ≤ presupuesto del plan |

### 1.3 Referencia funcional de familiaridad (clean-room, principio I)

Fuente: `Investigacion_Detallada_Zello_WalkieTalkie.xlsx` (hojas 2 y 3, solo descripción funcional
pública). Se toma **qué hace** cada función y **dónde la espera el usuario**; Kyq define su propio
diseño visual, textos, íconos, sonidos y protocolo. No se usa nada del APK descompilado.

| Comportamiento que el usuario ya conoce | Cómo lo cumple Kyq | Requisito |
|---|---|---|
| Lista única de contactos y canales con estado y nuevos | Pestaña "Radio" con contactos, canales y cooperativa en una lista | FR-001 |
| Conversación: cabecera con nombre, estado y duración; botón redondo grande al centro; historial debajo | Mismo orden de pantalla, diseño Kyq | FR-007, FR-009 |
| Mantener para hablar, opcional tocar para hablar | Dos modos, el primero por defecto | FR-007 |
| Un turno a la vez, tono al empezar y al soltar, tono de ocupado | Semidúplex con tonos propios | FR-006 |
| La voz suena al instante con el teléfono bloqueado | Servicio en primer plano "Radio encendida" | FR-026 |
| Historial de cada mensaje, repetir, reproducir más rápido | Historial con 1x / 1,5x / 2x sin cambiar el tono | FR-010, FR-011 |
| Mensajes simultáneos en cola, sin mezclar | Cola por orden de llegada | FR-025 |
| Estados Disponible / Ocupado y horario de silencio | Disponible, Ocupado, Solo escucha, Desconectado | FR-019–FR-021 |
| Alerta para pedir que atiendan | Alerta de llamada con texto opcional | FR-022 |
| Texto, foto y ubicación en la misma conversación | Mismo historial | FR-023 |
| Varios canales escuchándose a la vez | Interruptor "Escuchar" por conversación, hasta 10 | FR-024 |
| Canales con dueño, moderadores, solo escucha; invitación por QR o enlace | Roles y moderación | FR-015, FR-016 |
| Modo para conducir con botones gigantes | Modo auto | FR-029 |
| Botón flotante sobre el navegador y botón Bluetooth | Burbuja y botón de 005 | FR-028 |
| Botón de emergencia | SOS de 003, también sin viaje | FR-030, FR-031 |

**Lo que se diferencia a propósito**: canales públicos abiertos a cualquiera, oyentes anónimos,
prioridad que corta al que habla, VOX y comandos de voz quedan fuera (spec §Contexto y alcance):
más riesgo de acoso o de distracción que valor para el conductor autónomo.

### 1.4 Análisis de la situación actual (lo que se reutiliza)

| Pieza existente | Etapa | Uso en Radio |
|---|---|---|
| Voz semidúplex con turno y tonos | 001, 005, 006 | Mismo motor de turno, ahora por conversación persistente |
| Canal de grupo con rotación de sala y miembros | 006 | Base de los canales; la cooperativa aparece como canal |
| Botón Bluetooth, burbuja, atenuación de navegación | 005 | Hablar en Radio cuando no hay viaje |
| Consola SOS y alertas con ubicación 1 Hz | 003 | Emergencia desde Radio, también sin viaje |
| Moderación, bitácora de auditoría, economía unitaria | 007 | Reportes de mensajes, cambios de configuración, coste |
| Almacenamiento de objetos (KYC, grabaciones SOS) | 002, 003 | Audios y fotos de Radio con vencimiento |
| SMS (OTP, contactos de emergencia) | 001, 003 | Invitaciones de migración |

### 1.5 Riesgos y respuesta

| Riesgo | Prob. | Impacto | Respuesta planeada |
|---|---|---|---|
| La forma de uso se siente distinta y no migran | Media | Alto | Referencia funcional §1.3; prueba de usabilidad SC-001 antes del piloto |
| Latencia o cortes en 4G | Media | Alto | Mismo motor de voz probado en 001; medir p95 por ciudad |
| Grabar la voz expone datos personales | Media | Alto | Aviso y aceptación (FR-013), retención corta, acceso del personal solo por reporte o SOS con auditoría (FR-037), borrado por habeas data |
| Coste de almacenamiento crece sin control | Baja | Medio | Retención configurable con coste visible (FR-012), límite de guardados, medición por conductor (FR-038) |
| Acoso o spam de pasajeros | Media | Medio | Radio con clientes desactivada por defecto, silenciar y bloquear, límite de 20 mensajes/hora, pasajeros fuera de canales por defecto |
| Distracción al volante | Media | Alto | Modo auto, botón físico y burbuja, nada de teclado en modo auto |
| Batería por el servicio en primer plano | Media | Medio | Apagar radio con un toque; medir consumo en el piloto |
| Conductores invitados sin suscripción no se quedan | Alta | Medio | Política de acceso configurable (prueba / solo con suscripción / solo escucha) para probar en el mercado |
| SMS masivos marcados como spam | Media | Medio | Texto con quién invita y cómo darse de baja, envío escalonado, vencimiento a 14 días |
| Riesgo legal por parecido con la app de terceros | Baja | Alto | Principio I: diseño, sonidos, íconos y textos propios; revisión explícita en el code review |

### 1.6 Recursos y coste estimado (se confirma en el plan)

- Voz en vivo: mismo servidor de voz actual; el coste crece con minutos de participante.
- Registro de voz: unos 2 KB por segundo de voz comprimida. Un conductor que transmite 30
  min/día genera ~3,6 MB/día; con retención de 30 días son ~110 MB almacenados por conductor
  activo (con 7 días, ~25 MB; con 90 días, ~330 MB). Se guarda una vez por mensaje, no por
  receptor.
- Fotos: comprimidas a ~200 KB; mismo vencimiento.
- SMS de migración: costo por SMS del proveedor actual × filas válidas.

---

## 2. HACER

Despliegue por incrementos; cada uno se puede probar y entregar solo (historias de la spec).

| Incremento | Contenido | Historias | Salida |
|---|---|---|---|
| H1. Radio 1 a 1 | Contactos entre conductores, voz en vivo, registro e historial, segundo plano | US1, US2, US8 (parte) | Dos conductores se hablan con la pantalla bloqueada sin perder mensajes |
| H2. Canales y cooperativa | Canales, roles, moderación, cooperativa como canal, varias conversaciones | US4, US7 | Un grupo completo habla por turnos |
| H3. Clientes | Radio conductor–pasajero con silenciar y bloquear | US3 | Ana deja un mensaje a Carlos y pide el viaje |
| H4. Migración | Enlaces profundos, registro con invitación, carga masiva y SMS, configuración de acceso | US10, FR-040 | Un grupo real recreado y sus miembros dentro |
| H5. Comodidad y control | Estados, horario de silencio, alertas, texto, foto, ubicación, modo auto, emergencia, reportes y coste | US5, US6, US8, US9, US11 | Paridad de uso con la radio anterior |

**Piloto**: un grupo real de 20–50 conductores (idealmente una cooperativa de 006) durante 2
semanas, con la política de acceso en "Prueba" y la retención en 30 días.

**Registro durante la ejecución**: `validation.md` de la etapa, como en 001–010, con fecha,
commit, teléfonos y resultado de cada escenario.

---

## 3. VERIFICAR

| Qué se verifica | Cómo | Cuándo | Criterio |
|---|---|---|---|
| Reglas y contratos | Pruebas automáticas de turno, acceso por política, retención, roles, privacidad y RN-KYQ-017 | CI en cada cambio | Verde (principio VI) |
| Familiaridad | Prueba de usabilidad con 10 usuarios de la app anterior, sin explicación | Antes del piloto | SC-001 |
| Latencia | Medición boca–oído con dos teléfonos en 4G (como SC-005 de 001) | H1 y piloto | p95 < 250 ms |
| No pérdida | Receptor sin red durante 3 mensajes; comparar enviados vs. historial | H1 | 100 % |
| Cola sin mezcla | 1 hora con 3 conversaciones y mensajes simultáneos | H2 | 0 mezclas, 0 pérdidas |
| Migración | Cronometrar enlace → dentro del canal con usuario sin cuenta; carga de 2 000 filas | H4 | SC-004, SC-005 |
| Adopción | Panel: invitados activos en la última semana | Día 30 del piloto | ≥ 70 % |
| Coste | Economía unitaria: minutos, almacenamiento y SMS por conductor | Semanal en el piloto | ≤ presupuesto |
| Privacidad | Revisión de bitácora: todo acceso del personal tiene reporte o SOS | Fin del piloto | 0 accesos sin motivo |
| Batería | Consumo con radio encendida 8 h | Piloto | Dato para decidir en Actuar |

---

## 4. ACTUAR

Reglas de decisión con los resultados del piloto. Las tres decisiones de mercado ya son
configuración del panel, así que actuar no exige otro desarrollo.

| Resultado observado | Acción |
|---|---|
| Invitados se registran pero no pagan al terminar la prueba | Probar "Solo escucha" en otra ciudad o grupo y comparar conversión a suscripción |
| La prueba no cambia la conversión frente a "Solo con suscripción" | Dejar "Solo con suscripción" (menos coste y fraude) |
| Coste de almacenamiento sobre presupuesto | Bajar la retención a 7 días; revisar el límite de guardados |
| Usuarios piden mensajes más antiguos | Subir a 90 días donde el coste lo permita |
| Grupos piden incluir a clientes | Activar pasajeros "Solo escucha" en canales y medir reportes de acoso |
| Reportes de acoso o spam crecen | Volver a "No permitida" o bajar el límite de mensajes por hora |
| SC-001 < 9/10 | Corregir la pantalla que falló siguiendo §1.3 y repetir la prueba antes de ampliar |
| Latencia p95 > 250 ms en una ciudad | Revisar la región del servidor de voz antes de ampliar el despliegue allí |
| Consumo de batería alto | Ajustar el servicio en primer plano o sugerir "Apagar radio" en horarios de silencio |
| Todo dentro de meta | Estandarizar: abrir Radio a todos los conductores y preparar iOS (fase 2) |

Cada decisión se registra en `validation.md` (sección Incidencias y decisiones) y, si cambia un
requisito, se actualiza la spec, la prueba y la trazabilidad en el mismo cambio (principio V).
