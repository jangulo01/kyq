import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_ptt/kyq_ptt.dart';
import 'package:kyq_realtime/kyq_realtime.dart';

import '../services.dart';
import 'playback_queue.dart';

/// Estado del botón grande (FR-006, FR-007).
enum TalkStatus { idle, requesting, talking, busy, listenOnly, denied, error }

/// Alerta de llamada o emergencia que está sonando (FR-022, FR-031).
class RingingAlert {
  const RingingAlert({required this.message, required this.emergency});

  final RadioMessage message;
  final bool emergency;
}

class RadioState {
  const RadioState({
    this.me,
    this.conversations = const [],
    this.loading = true,
    this.error,
    this.selectedId,
    this.talk = TalkStatus.idle,
    this.talkingIn,
    this.talkStartedAt,
    this.busyHolder,
    this.live,
    this.playingFrom,
    this.waiting = 0,
    this.holders = const {},
    this.alert,
    this.notice,
    this.speakerOn = true,
  });

  final RadioMe? me;
  final List<RadioConversation> conversations;
  final bool loading;
  final String? error;

  /// Conversación seleccionada: la del botón grande, la burbuja y el botón Bluetooth (FR-028).
  final String? selectedId;
  final TalkStatus talk;
  final String? talkingIn;
  final DateTime? talkStartedAt;

  /// Quién tiene el turno cuando me lo negaron: "Jonathan está hablando".
  final String? busyHolder;

  /// Quién suena en vivo ahora (cola, FR-025).
  final LiveSpeaker? live;

  /// El mensaje del registro que suena ahora (de la cola).
  final Queued? playingFrom;
  final int waiting;

  /// Conversación → nombre de quien tiene el turno ahora, según los datos de cada sala.
  final Map<String, String> holders;
  final RingingAlert? alert;

  /// Aviso de una vez para la pantalla (no se puede hablar, cambió la configuración…).
  final String? notice;
  final bool speakerOn;

  RadioConversation? get selected => conversations.where((c) => c.id == selectedId).firstOrNull;

  RadioConversation? byId(String id) => conversations.where((c) => c.id == id).firstOrNull;

  int get listening => conversations.where((c) => c.listening).length;

  RadioState copyWith({
    RadioMe? me,
    List<RadioConversation>? conversations,
    bool? loading,
    String? Function()? error,
    String? Function()? selectedId,
    TalkStatus? talk,
    String? Function()? talkingIn,
    DateTime? Function()? talkStartedAt,
    String? Function()? busyHolder,
    LiveSpeaker? Function()? live,
    Queued? Function()? playingFrom,
    int? waiting,
    Map<String, String>? holders,
    RingingAlert? Function()? alert,
    String? Function()? notice,
    bool? speakerOn,
  }) => RadioState(
    me: me ?? this.me,
    conversations: conversations ?? this.conversations,
    loading: loading ?? this.loading,
    error: error != null ? error() : this.error,
    selectedId: selectedId != null ? selectedId() : this.selectedId,
    talk: talk ?? this.talk,
    talkingIn: talkingIn != null ? talkingIn() : this.talkingIn,
    talkStartedAt: talkStartedAt != null ? talkStartedAt() : this.talkStartedAt,
    busyHolder: busyHolder != null ? busyHolder() : this.busyHolder,
    live: live != null ? live() : this.live,
    playingFrom: playingFrom != null ? playingFrom() : this.playingFrom,
    waiting: waiting ?? this.waiting,
    holders: holders ?? this.holders,
    alert: alert != null ? alert() : this.alert,
    notice: notice != null ? notice() : this.notice,
    speakerOn: speakerOn ?? this.speakerOn,
  );
}

/// Crea una sala de Radio; las pruebas pasan falsas.
typedef ListeningRoomFactory = ListeningRoom Function();

/// Máximo de conversaciones escuchadas a la vez (FR-024).
const maxListening = 10;

/// Radio Kyq de la app (research R2, R12): la lista única, el estado propio, una sala conectada
/// solo para escuchar por cada conversación con "Escuchar", el turno de la seleccionada con sus
/// tonos y la cola que reproduce en orden lo que llega mientras otro suena.
class RadioCubit extends Cubit<RadioState> implements QueueEffects {
  RadioCubit({
    required this.api,
    required this.myUserId,
    required Stream<RealtimeEvent> events,
    required this._rooms,
    required this.tones,
    required this.focus,
    required this._player,
    this.output,
    this.heartbeatEvery = const Duration(seconds: 30),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now,
       super(const RadioState()) {
    queue = PlaybackQueue(this, now: _now);
    ringer = AlertRinger(tones);
    _events = events.listen(_onEvent, onError: (Object _) {});
  }

  final RadioApi api;
  final String myUserId;
  final TonePlayer tones;
  final AudioFocus focus;

  /// Altavoz o auricular; null no cambia la salida (pruebas).
  final AudioOutput? output;
  final Duration heartbeatEvery;
  final ListeningRoomFactory _rooms;
  final MessagePlayer _player;
  final DateTime Function() _now;
  late final PlaybackQueue queue;
  late final AlertRinger ringer;
  late final StreamSubscription<RealtimeEvent> _events;

  /// Salas conectadas por conversación y sus suscripciones.
  final _connected = <String, ListeningRoom>{};
  final _roomSubs = <String, StreamSubscription<VoiceRoomEvent>>{};
  Timer? _heartbeat;
  Timer? _tick;
  Timer? _reload;

  /// Datos de la conversación en la que se habla ahora.
  String? _floorMessageId;

  // Carga y estado propio --------------------------------------------------------------------

  Future<void> load() async {
    try {
      final me = await api.radioMe();
      if (isClosed) return;
      emit(state.copyWith(me: me));
      if (me.access == RadioAccess.none) {
        emit(state.copyWith(loading: false, conversations: const [], error: () => null));
        return;
      }
      final list = await api.radioConversations();
      if (isClosed) return;
      emit(state.copyWith(conversations: list, loading: false, error: () => null));
      await _syncRooms();
      _syncHeartbeat();
    } on ApiException catch (e) {
      if (!isClosed) emit(state.copyWith(loading: false, error: () => radioErrorText(e)));
    } on Object {
      // Radio nunca tumba la app: una respuesta inesperada se muestra como error de carga.
      if (!isClosed) {
        emit(state.copyWith(loading: false, error: () => 'No pudimos cargar Radio. Desliza para reintentar.'));
      }
    }
  }

  /// Recarga la lista unos instantes después; varios eventos seguidos piden una sola carga.
  void _reloadSoon() {
    _reload?.cancel();
    _reload = Timer(const Duration(milliseconds: 300), () => unawaited(load()));
  }

  Future<void> acceptConsent() async {
    await api.acceptRadioConsent();
    await load();
  }

  /// Disponible, Ocupado o Solo escucha (FR-019).
  Future<void> setStatus(RadioPresence status) async {
    try {
      final me = await api.updateRadioMe(status: status);
      if (!isClosed) emit(state.copyWith(me: me));
      await _applyStatus();
    } on ApiException catch (e) {
      _notice(radioErrorText(e));
    }
  }

  Future<void> setPushMode(RadioPushMode mode) async {
    try {
      final me = await api.updateRadioMe(pushMode: mode);
      if (!isClosed) emit(state.copyWith(me: me));
    } on ApiException catch (e) {
      _notice(radioErrorText(e));
    }
  }

  /// "Radio encendida" o "Apagar radio" (FR-026, US8-5): apagada no se recibe en vivo, los
  /// demás la ven Desconectada y todo llega al historial.
  Future<void> setRadioOn(bool on) async {
    try {
      final me = await api.updateRadioMe(radioOn: on);
      if (!isClosed) emit(state.copyWith(me: me));
      await _syncRooms();
      _syncHeartbeat();
    } on ApiException catch (e) {
      _notice(radioErrorText(e));
    }
  }

  void _syncHeartbeat() {
    final on = state.me?.radioOn ?? false;
    if (!on) {
      _heartbeat?.cancel();
      _heartbeat = null;
      _tick?.cancel();
      _tick = null;
      return;
    }
    _heartbeat ??= Timer.periodic(heartbeatEvery, (_) => unawaited(api.radioHeartbeat().catchError((Object _) {})));
    _tick ??= Timer.periodic(const Duration(seconds: 5), (_) => unawaited(queue.tick()));
  }

  void select(String? conversationId) {
    emit(state.copyWith(selectedId: () => conversationId));
    unawaited(_syncRooms());
  }

  /// Altavoz (por defecto: el teléfono va en el soporte) o auricular (FR-009).
  Future<void> setSpeaker(bool on) async {
    await output?.setSpeaker(on);
    if (!isClosed) emit(state.copyWith(speakerOn: on));
  }

  /// Siguiente o anterior conversación de la lista (modo auto, FR-029).
  void selectNext({int step = 1}) {
    final list = state.conversations;
    if (list.isEmpty) return;
    final i = list.indexWhere((c) => c.id == state.selectedId);
    final next = list[((i < 0 ? 0 : i + step) % list.length + list.length) % list.length];
    select(next.id);
  }

  /// "Escuchar" (FR-024), con tope de [maxListening].
  Future<void> setListening(String conversationId, bool on) async {
    if (on && state.listening >= maxListening) {
      _notice('Ya escuchas $maxListening conversaciones. Apaga alguna para encender esta.');
      return;
    }
    try {
      await api.setRadioListening(conversationId, on);
      _replace(conversationId, (c) => c.copyWith(listening: on));
      await _syncRooms();
    } on ApiException catch (e) {
      _notice(radioErrorText(e));
    }
  }

  void _replace(String id, RadioConversation Function(RadioConversation) f) {
    emit(state.copyWith(conversations: [for (final c in state.conversations) c.id == id ? f(c) : c]));
  }

  void clearNotice() => emit(state.copyWith(notice: () => null));

  void _notice(String text) {
    if (!isClosed) emit(state.copyWith(notice: () => text));
  }

  // Salas ------------------------------------------------------------------------------------

  /// Conversaciones que deben estar conectadas: las que se escuchan con la radio encendida y la
  /// seleccionada (para poder hablar en ella).
  Set<String> _wanted() {
    final me = state.me;
    if (me == null || me.access == RadioAccess.none || !me.radioOn) {
      return {?state.selectedId};
    }
    return {
      for (final c in state.conversations)
        if (c.listening && !c.suspended && !c.pending) c.id,
      ?state.selectedId,
    };
  }

  /// Suena en vivo: radio encendida, no Ocupado, "Escuchar" y no es un cliente silenciado.
  bool _audible(String conversationId) {
    final me = state.me;
    final c = state.byId(conversationId);
    if (me == null || c == null || !me.radioOn) return false;
    return me.status != RadioPresence.busy && c.listening && !c.peerMuted;
  }

  Future<void> _syncRooms() async {
    final wanted = _wanted();
    for (final id in _connected.keys.toList()) {
      if (!wanted.contains(id)) await _disconnect(id);
    }
    for (final id in wanted) {
      if (!_connected.containsKey(id)) await _connect(id);
    }
  }

  Future<void> _connect(String conversationId) async {
    final room = _rooms();
    _connected[conversationId] = room;
    _roomSubs[conversationId] = room.events.listen((e) => _onRoomEvent(conversationId, e));
    try {
      final cred = await api.radioToken(conversationId);
      await room.setRemoteAudioEnabled(false);
      await room.connect(cred.url, cred.token);
    } on Object {
      await _disconnect(conversationId);
    }
  }

  Future<void> _disconnect(String conversationId) async {
    await _roomSubs.remove(conversationId)?.cancel();
    final room = _connected.remove(conversationId);
    await room?.disconnect();
    if (state.live?.conversationId == conversationId) await queue.floorReleased(conversationId);
  }

  Future<void> _reconnect(String conversationId) async {
    if (!_connected.containsKey(conversationId)) return;
    await _disconnect(conversationId);
    await _connect(conversationId);
  }

  Future<void> _applyStatus() async {
    final live = state.live;
    if (live != null && !_audible(live.conversationId)) await queue.floorReleased(live.conversationId);
  }

  Future<void> _onRoomEvent(String conversationId, VoiceRoomEvent e) async {
    switch (e) {
      case VoiceDataReceived(:final message, :final senderId, :final senderName):
        final user = message['user_id'] as String? ?? senderId ?? '';
        if (user == myUserId) return;
        switch (message['type']) {
          case 'floor.taken':
            final name = senderName ?? state.byId(conversationId)?.title ?? '';
            emit(state.copyWith(holders: {...state.holders, conversationId: name}));
            if (_audible(conversationId)) {
              await queue.floorTaken(conversationId, user, name: name, messageId: message['message_id'] as String?);
            }
          case 'floor.released':
            emit(state.copyWith(holders: {...state.holders}..remove(conversationId)));
            await queue.floorReleased(conversationId, userId: user.isEmpty ? null : user);
        }
      case VoiceRemoteLeft():
        if (state.holders.containsKey(conversationId)) {
          emit(state.copyWith(holders: {...state.holders}..remove(conversationId)));
          await queue.floorReleased(conversationId);
        }
      case VoiceConnectionChanged(:final connection) when connection == VoiceConnection.disconnected:
        // La sala se cayó (token vencido, sala rotada): se vuelve a entrar con un token nuevo.
        if (_connected.containsKey(conversationId)) await _reconnect(conversationId);
      default:
    }
  }

  // Hablar -----------------------------------------------------------------------------------

  /// Pulsar el botón grande: pide el turno en la conversación seleccionada (FR-006).
  Future<void> press([String? conversationId]) async {
    final id = conversationId ?? state.selectedId;
    if (id == null || state.talk == TalkStatus.requesting || state.talk == TalkStatus.talking) return;
    final c = state.byId(id);
    final me = state.me;
    if (me?.access == RadioAccess.listen || me?.status == RadioPresence.listenOnly || (c != null && !c.canTalk)) {
      emit(state.copyWith(talk: TalkStatus.listenOnly));
      return;
    }
    emit(state.copyWith(talk: TalkStatus.requesting, talkingIn: () => id, busyHolder: () => null));
    await queue.setTalking(true);
    if (!_connected.containsKey(id)) await _connect(id);
    final room = _connected[id];
    try {
      final floor = await api.takeRadioFloor(id);
      _floorMessageId = floor.messageId;
      if (isClosed) return;
      if (state.talkingIn != id || state.talk != TalkStatus.requesting) {
        // Soltó antes de que llegara el turno.
        await api.releaseRadioFloor(id);
        return;
      }
      await tones.play(PttTone.start);
      await room?.setMicrophoneEnabled(true);
      await room?.sendData({'type': 'floor.taken', 'user_id': myUserId, 'message_id': floor.messageId});
      emit(state.copyWith(talk: TalkStatus.talking, talkStartedAt: () => _now()));
    } on ApiException catch (e) {
      await queue.setTalking(false);
      if (e.code == 'floor_busy') {
        await tones.play(PttTone.busy);
        final holder = e.message.replaceFirst(RegExp(r' está hablando$'), '');
        emit(state.copyWith(talk: TalkStatus.busy, busyHolder: () => holder, talkingIn: () => null));
        return;
      }
      final status = switch (e.code) {
        'radio_listen_only' => TalkStatus.listenOnly,
        'member_muted' || 'blocked' || 'conversation_suspended' || 'radio_access_denied' => TalkStatus.denied,
        _ => TalkStatus.error,
      };
      emit(state.copyWith(talk: status, talkingIn: () => null, notice: () => radioErrorText(e)));
    }
  }

  /// Soltar el botón: corta el micrófono, avisa en la sala y suelta el turno.
  Future<void> release() async {
    final id = state.talkingIn;
    if (id == null) {
      if (state.talk != TalkStatus.idle) emit(state.copyWith(talk: TalkStatus.idle, busyHolder: () => null));
      return;
    }
    final wasTalking = state.talk == TalkStatus.talking;
    emit(state.copyWith(talk: TalkStatus.idle, talkingIn: () => null, talkStartedAt: () => null));
    final room = _connected[id];
    if (wasTalking) {
      await room?.setMicrophoneEnabled(false);
      await room?.sendData({'type': 'floor.released', 'user_id': myUserId, 'message_id': _floorMessageId});
      await tones.play(PttTone.end);
      try {
        await api.releaseRadioFloor(id);
      } on ApiException {
        // El turno caduca solo a los 60 s.
      }
    }
    _floorMessageId = null;
    await queue.setTalking(false);
    if (!_wanted().contains(id)) await _disconnect(id);
  }

  /// Modo "Tocar para hablar": un toque abre y otro cierra (FR-007).
  Future<void> toggle([String? conversationId]) => state.talk == TalkStatus.talking ? release() : press(conversationId);

  /// El viaje en curso o un SOS suena (FR-025): la radio espera.
  Future<void> setPriority(bool on) => queue.setPriority(on);

  // Eventos en vivo --------------------------------------------------------------------------

  Future<void> _onEvent(RealtimeEvent e) async {
    switch (e) {
      case RadioMessageEvent(:final kind, :final message, :final silent):
        final m = RadioMessage.fromJson(message);
        if (m.authorId == myUserId) return;
        await queue.messageReady(m.id);
        if (kind != RadioEventKind.message && !silent) {
          ringer.start(emergency: kind == RadioEventKind.emergency);
          emit(
            state.copyWith(
              alert: () => RingingAlert(message: m, emergency: kind == RadioEventKind.emergency),
            ),
          );
        }
        _replace(
          m.conversationId,
          (c) => c.copyWith(unreadCount: c.unreadCount + (m.heard ? 0 : 1), lastMessageAt: m.createdAt),
        );
      case RadioPresenceChanged(:final userId, :final status):
        if (userId == myUserId) {
          await load();
          return;
        }
        final presence = RadioPresence.values.firstWhere(
          (p) => (p == RadioPresence.listenOnly ? 'listen_only' : p.name) == status,
          orElse: () => RadioPresence.offline,
        );
        emit(
          state.copyWith(
            conversations: [
              for (final c in state.conversations) c.peerId == userId ? c.copyWith(peerStatus: presence) : c,
            ],
          ),
        );
      case RadioMemberChanged(:final conversationId, :final change):
        if (change == 'room_rotated') {
          await _reconnect(conversationId);
          return;
        }
        _reloadSoon();
      case RadioInviteAccepted():
        _reloadSoon();
      case RadioSettingsChanged():
        _reloadSoon();
      default:
    }
  }

  /// Abrir la alerta para de sonar (FR-022).
  void dismissAlert() {
    ringer.stop();
    emit(state.copyWith(alert: () => null));
  }

  /// El mensaje se oyó o leyó: baja el contador de nuevos.
  void markRead(String conversationId, {int count = 1}) {
    _replace(conversationId, (c) => c.copyWith(unreadCount: (c.unreadCount - count).clamp(0, 1 << 30)));
  }

  // QueueEffects -----------------------------------------------------------------------------

  @override
  Future<void> setLive(String conversationId, bool on) async => _connected[conversationId]?.setRemoteAudioEnabled(on);

  @override
  Future<void> duck() => focus.duck();

  @override
  Future<void> releaseFocus() => focus.release();

  @override
  Future<void> playRecorded(String messageId) async {
    final url = await api.radioMediaUrl(messageId);
    await _player.play(url);
  }

  @override
  Future<void> stopRecorded() => _player.stop();

  @override
  void heard(String messageId) {
    unawaited(api.setRadioReceipt(messageId, heard: true).catchError((Object _) {}));
    final convId = state.live?.messageId == messageId ? state.live?.conversationId : queue.playing?.conversationId;
    if (convId != null) markRead(convId);
  }

  @override
  void changed() {
    if (isClosed) return;
    emit(state.copyWith(live: () => queue.live, playingFrom: () => queue.playing, waiting: queue.waiting));
  }

  /// Detiene latido, sondeo de la cola, recarga pendiente y timbre (al cerrar y en pruebas).
  void cancelTimers() {
    _heartbeat?.cancel();
    _heartbeat = null;
    _tick?.cancel();
    _tick = null;
    _reload?.cancel();
    ringer.stop();
  }

  @override
  Future<void> close() async {
    // Antes de cualquier await: al cerrar la app no debe quedar un temporizador vivo.
    cancelTimers();
    await _events.cancel();
    for (final id in _connected.keys.toList()) {
      await _disconnect(id);
    }
    await _player.dispose();
    return super.close();
  }
}

/// Mensajes en español de los errores de Radio.
String radioErrorText(ApiException e) => switch (e.code) {
  'radio_access_denied' => 'No tienes acceso a Radio. Revisa tu suscripción.',
  'radio_listen_only' => 'Aquí solo puedes escuchar.',
  'radio_consent_required' => 'Acepta el aviso de registro para usar Radio.',
  'member_muted' => 'Un moderador te silenció en este canal.',
  'blocked' => 'No puedes enviar mensajes en esta conversación.',
  'conversation_suspended' => 'Esta conversación está suspendida.',
  'not_owner' => 'Solo el dueño del canal puede hacerlo.',
  'not_moderator' => 'Solo el dueño o un moderador puede hacerlo.',
  'cooperative_channel' => 'El canal de la cooperativa lo administra la cooperativa.',
  'channel_name_taken' => 'Ya existe un canal con ese nombre.',
  'channel_limit' => 'Ya tienes 10 canales.',
  'channel_full' => 'El canal está lleno.',
  'listening_limit' => 'Ya escuchas 10 conversaciones. Apaga alguna.',
  'saved_limit' => 'Ya tienes 200 mensajes guardados. Quita alguno.',
  'rate_limited' => 'Espera un momento antes de enviar otro mensaje.',
  'invite_expired' => 'La invitación venció o ya se usó.',
  'invite_wrong_app' => 'Esta invitación es para la otra app de Kyq.',
  'passengers_not_allowed' => 'Este canal no admite pasajeros.',
  'voice_unavailable' => 'El servidor de voz no responde. Inténtalo de nuevo.',
  'network' => 'Sin conexión. Revisa tu internet.',
  _ => e.message.isEmpty ? 'No pudimos completar la acción.' : e.message,
};

/// Crea el [RadioCubit] de la app cuando se conoce el usuario; las pruebas pasan uno con falsos.
typedef RadioCubitFactory = RadioCubit Function(RadioApi api, String myUserId, Stream<RealtimeEvent> events);

/// [RadioCubit] real: salas LiveKit, tonos sintetizados de Kyq, foco de audio y just_audio.
RadioCubit liveRadioCubit(RadioApi api, String myUserId, Stream<RealtimeEvent> events) => RadioCubit(
  api: api,
  myUserId: myUserId,
  events: events,
  rooms: LiveKitVoiceRoom.new,
  tones: AudioplayersTonePlayer(),
  focus: AudioSessionFocus(),
  player: JustAudioMessagePlayer(),
  output: const LiveKitAudioOutput(),
);
