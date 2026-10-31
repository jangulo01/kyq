# Data Model: Radio Kyq

Migración `backend/migrations/00016_radio.sql`. Todas las tablas nuevas usan `uuid` v7 como las
anteriores y `timestamptz`.

## Enums

```sql
CREATE TYPE radio_conversation_kind AS ENUM ('direct', 'client', 'channel', 'cooperative');
CREATE TYPE radio_conversation_status AS ENUM ('active', 'suspended', 'deleted');
CREATE TYPE radio_join_mode AS ENUM ('open_link', 'approval');
CREATE TYPE radio_role AS ENUM ('owner', 'moderator', 'member', 'listener');
CREATE TYPE radio_member_status AS ENUM ('pending', 'active', 'muted', 'removed', 'blocked', 'rejected');
CREATE TYPE radio_message_kind AS ENUM ('voice', 'text', 'photo', 'location', 'alert', 'emergency');
CREATE TYPE radio_message_status AS ENUM ('recording', 'ready', 'discarded', 'deleted');
CREATE TYPE radio_presence_status AS ENUM ('available', 'busy', 'listen_only');
CREATE TYPE radio_trial_policy AS ENUM ('trial', 'subscription_only', 'listen_only');
CREATE TYPE radio_passenger_policy AS ENUM ('none', 'listen_only', 'all_roles');
CREATE TYPE radio_invite_status AS ENUM ('pending', 'sent', 'failed', 'accepted', 'already_member', 'expired');
```

## Tablas

### radio_conversations

| Columna | Tipo | Notas |
|---|---|---|
| id | uuid PK | |
| kind | radio_conversation_kind | `direct` conductor–conductor, `client` conductor–pasajero, `channel`, `cooperative` (006) |
| name | text NULL | solo canales; único entre canales `active` (índice parcial sobre `lower(name)`) |
| description, photo_key | text NULL | canales |
| join_mode | radio_join_mode NULL | canales |
| passenger_role_max | radio_role NULL | lo que el dueño permite a pasajeros dentro de `radio_settings` |
| cooperative_id | uuid NULL UNIQUE → cooperatives | `kind = cooperative` |
| room_name | text NOT NULL | `radio-{id}-{hex}`; rota al expulsar, salir o bloquear |
| status | radio_conversation_status | |
| created_by | uuid → users | |
| created_at, suspended_at, deleted_at | timestamptz | |

Reglas: un `direct`/`client` tiene exactamente 2 miembros; máx. 10 canales con `owner` por
conductor; máx. 200 miembros activos por canal.

### radio_members

| Columna | Tipo | Notas |
|---|---|---|
| conversation_id, user_id | uuid PK compuesta | |
| role | radio_role | `direct`/`client`: `member` para ambos |
| status | radio_member_status | |
| listening | bool | interruptor "Escuchar" (máx. 10 `true` por usuario) |
| muted_by_peer, blocked_by_peer | bool | en `client`, lo fija el conductor |
| joined_at, updated_at | timestamptz | |
| last_read_message_id | uuid NULL | contador de nuevos |

Para `cooperative`, las filas se sincronizan desde las membresías de 006 (alta, baja, suspensión);
desde Radio no se puede salir.

### radio_floors

Una fila por conversación con turno: `conversation_id` PK, `holder_id`, `message_id`,
`granted_at`, `expires_at` (`granted_at + 60s`). Barrido cada 1 s libera vencidos o sin audio por
3 s (dato de la sala).

### radio_messages

| Columna | Tipo | Notas |
|---|---|---|
| id | uuid PK | |
| conversation_id | uuid → radio_conversations | índice (conversation_id, created_at) |
| author_id | uuid NULL → users | NULL = usuario eliminado |
| kind | radio_message_kind | |
| status | radio_message_status | `recording` solo para voz |
| body | text NULL | texto ≤ 500, texto de alerta ≤ 80 |
| lat, lng | double NULL | ubicación y emergencia |
| object_key | text NULL | voz `radio/{conv}/{id}.ogg`, foto `radio/{conv}/{id}.jpg` |
| duration_ms | int NULL | voz |
| egress_id | text NULL | |
| sos_alert_id | uuid NULL → sos_alerts | `emergency` |
| expires_at | timestamptz | `created_at + retention_days` vigente |
| reported | bool | |
| created_at | timestamptz | |

### radio_receipts

`message_id`, `user_id` PK; `heard_at` (escuchado/leído), `saved_at`, `saved_key` (copia en
`kyq-radio-saved/`). Máx. 200 `saved_at` no nulos por usuario; guardado vence al año.

### radio_presence

`user_id` PK, `status` radio_presence_status, `radio_on` bool, `last_seen_at`, `push_mode`
(`hold` | `toggle`), `timezone` (por defecto `America/Bogota`).

### radio_quiet_hours

`id` PK, `user_id`, `weekdays` int2[] (1–7), `starts`, `ends` (time), `enabled`.

### radio_invites

| Columna | Tipo | Notas |
|---|---|---|
| id | uuid PK | |
| code | text UNIQUE | 10 caracteres base62 |
| inviter_id | uuid NULL → users | NULL si viene del panel |
| conversation_id | uuid NULL | invitación a canal |
| contact_of | uuid NULL → users | invitación de contacto 1 a 1 |
| phone_e164 | text NULL | por teléfono o carga masiva |
| invitee_kind | user_role | driver / passenger |
| role | radio_role NULL | rol en el canal |
| bulk_id | uuid NULL → radio_bulk_uploads | |
| status | radio_invite_status | |
| error | text NULL | |
| accepted_by | uuid NULL | |
| created_at, sent_at, expires_at | timestamptz | `expires_at = created_at + 14 días` |

Un `code` de QR/enlace de contacto o canal sin teléfono puede usarse varias veces hasta vencer;
uno con teléfono, una sola vez.

### radio_bulk_uploads

`id`, `admin_id`, `file_name`, `rows_total`, `rows_valid`, `rows_invalid`, `status`
(`validated` | `sending` | `done`), `created_at`, `confirmed_at`. Las filas son `radio_invites`
con `bulk_id`; las inválidas se guardan con `status = failed` y `error`.

### radio_settings y radio_settings_audit

Una fila (`id = 1`): `trial_policy` (`trial`), `trial_days` (14), `passengers_in_channels`
(`none`), `retention_days` (30, CHECK IN (7, 30, 90)), `updated_by`, `updated_at`. Cada cambio
inserta en `radio_settings_audit` (`admin_id`, `before`, `after` jsonb, `at`).

### radio_consents

`user_id` PK, `retention_days_accepted`, `accepted_at`. Cambiar la retención pide aceptar de
nuevo al abrir Radio.

### radio_reports

`id`, `message_id`, `reporter_id`, `reason` (≤ 200), `status` (`open` | `resolved`),
`decision` (`dismissed` | `message_deleted` | `channel_suspended` | `user_suspended`),
`resolved_by`, `resolved_at`. Abrir un reporte en el panel inserta en `radio_report_access`
(`report_id`, `admin_id`, `at`).

## Cambios en tablas existentes

- `sos_alerts`: `trip_id` pasa a NULL; columnas `raised_from` (`trip` | `radio`, por defecto
  `trip`) y `radio_conversation_id uuid NULL`; CHECK `trip_id IS NOT NULL OR raised_from = 'radio'`.
- `cost_concept`: valores `radio_storage`, `sms_invite`.
- `driver_usage_daily`: columnas `radio_voice_seconds`, `radio_messages`, `radio_storage_bytes`.

## Transiciones

- Miembro: `pending → active | rejected`; `active ↔ muted`; `active | muted → removed | blocked`;
  `removed → pending` (volver a pedir); `blocked` es final salvo que un moderador desbloquee.
- Mensaje de voz: `recording → ready | discarded`; cualquiera → `deleted` (moderación, retención
  o cuenta eliminada).
- Invitación: `pending → sent | failed`; `sent | pending → accepted | already_member | expired`;
  `failed → sent` (reenvío).
- Conversación: `active ↔ suspended` (admin); `active → deleted` (dueño o contacto borrado).

## Acceso (FR-005, una sola función)

`radio.Access(user, now, settings) → full | listen | none`:

1. Usuario suspendido (007) → `none`.
2. Pasajero → `full` (limitado por conversación: cliente activo y no bloqueado).
3. Conductor con suscripción ACTIVE o GRACE_PERIOD → `full`.
4. Conductor sin ella: `trial` → `full` si `now < created_at + trial_days`, si no `none`;
   `subscription_only` → `none`; `listen_only` → `listen`.
