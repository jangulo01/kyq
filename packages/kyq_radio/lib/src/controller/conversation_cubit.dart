import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_realtime/kyq_realtime.dart';

import '../services.dart';
import 'radio_cubit.dart';

class ConversationState {
  const ConversationState({
    this.detail,
    this.messages = const [],
    this.loading = true,
    this.hasMore = true,
    this.playingId,
    this.speed = 1.0,
    this.sending = false,
    this.notice,
  });

  final RadioConversationDetail? detail;

  /// Historial, el más reciente primero (FR-011).
  final List<RadioMessage> messages;
  final bool loading;
  final bool hasMore;
  final String? playingId;
  final double speed;
  final bool sending;
  final String? notice;

  List<RadioMessage> get unheard => [
    for (final m in messages.reversed)
      if (!m.heard && m.kind == RadioMessageKind.voice && m.hasMedia) m,
  ];

  RadioMessage? get lastVoice => messages.where((m) => m.kind == RadioMessageKind.voice && m.hasMedia).firstOrNull;

  ConversationState copyWith({
    RadioConversationDetail? detail,
    List<RadioMessage>? messages,
    bool? loading,
    bool? hasMore,
    String? Function()? playingId,
    double? speed,
    bool? sending,
    String? Function()? notice,
  }) => ConversationState(
    detail: detail ?? this.detail,
    messages: messages ?? this.messages,
    loading: loading ?? this.loading,
    hasMore: hasMore ?? this.hasMore,
    playingId: playingId != null ? playingId() : this.playingId,
    speed: speed ?? this.speed,
    sending: sending ?? this.sending,
    notice: notice != null ? notice() : this.notice,
  );
}

/// Una conversación abierta (US2, US6): historial con voz, texto, foto, ubicación y alertas en
/// orden; reproducir a 1x, 1,5x o 2x; "Reproducir nuevos" uno tras otro; guardar; enviar.
class ConversationCubit extends Cubit<ConversationState> {
  ConversationCubit({
    required this.api,
    required this.conversationId,
    required this.myUserId,
    required Stream<RealtimeEvent> events,
    required this.player,
    this.radio,
    this.pageSize = 50,
  }) : super(const ConversationState()) {
    _events = events.listen(_onEvent, onError: (Object _) {});
  }

  final RadioApi api;
  final String conversationId;
  final String myUserId;
  final MessagePlayer player;

  /// Para bajar el contador de nuevos de la lista al oír.
  final RadioCubit? radio;
  final int pageSize;
  late final StreamSubscription<RealtimeEvent> _events;
  bool _stopQueue = false;

  Future<void> load() async {
    try {
      final detail = await api.radioConversation(conversationId);
      final page = await api.radioMessages(conversationId, limit: pageSize);
      if (isClosed) return;
      emit(state.copyWith(detail: detail, messages: page, loading: false, hasMore: page.length == pageSize));
      unawaited(_markTextsRead(page));
    } on ApiException catch (e) {
      if (!isClosed) emit(state.copyWith(loading: false, notice: () => radioErrorText(e)));
    }
  }

  /// Página anterior del historial.
  Future<void> loadMore() async {
    if (!state.hasMore || state.messages.isEmpty) return;
    try {
      final page = await api.radioMessages(conversationId, before: state.messages.last.id, limit: pageSize);
      if (isClosed) return;
      emit(state.copyWith(messages: [...state.messages, ...page], hasMore: page.length == pageSize));
    } on ApiException catch (e) {
      _notice(radioErrorText(e));
    }
  }

  /// Texto, foto, ubicación y alertas cuentan como leídos al abrir la conversación.
  Future<void> _markTextsRead(List<RadioMessage> page) async {
    for (final m in page) {
      if (!m.heard && m.kind != RadioMessageKind.voice) await _heard(m);
    }
  }

  Future<void> _heard(RadioMessage m) async {
    if (m.heard) return;
    try {
      await api.setRadioReceipt(m.id, heard: true);
    } on ApiException {
      return;
    }
    _replace(m.id, (x) => x.copyWith(heard: true));
    radio?.markRead(conversationId);
  }

  void _replace(String id, RadioMessage Function(RadioMessage) f) {
    if (isClosed) return;
    emit(state.copyWith(messages: [for (final m in state.messages) m.id == id ? f(m) : m]));
  }

  void _notice(String text) {
    if (!isClosed) emit(state.copyWith(notice: () => text));
  }

  void clearNotice() => emit(state.copyWith(notice: () => null));

  /// Reproduce un mensaje a la velocidad elegida y lo marca oído (FR-011).
  Future<void> play(RadioMessage m) async {
    if (!m.hasMedia) return;
    emit(state.copyWith(playingId: () => m.id));
    try {
      final url = await api.radioMediaUrl(m.id);
      await player.play(url, speed: state.speed);
      await _heard(m);
    } on ApiException catch (e) {
      _notice(radioErrorText(e));
    } finally {
      if (!isClosed && state.playingId == m.id) emit(state.copyWith(playingId: () => null));
    }
  }

  /// "Reproducir nuevos": en orden de llegada, uno tras otro (US2-3).
  Future<void> playNew() async {
    _stopQueue = false;
    for (final m in state.unheard) {
      if (_stopQueue || isClosed) break;
      await play(m);
    }
  }

  /// "Repetir último" (FR-009).
  Future<void> repeatLast() async {
    final last = state.lastVoice;
    if (last != null) await play(last);
  }

  Future<void> stop() async {
    _stopQueue = true;
    await player.stop();
    if (!isClosed) emit(state.copyWith(playingId: () => null));
  }

  /// 1x → 1,5x → 2x → 1x, sin cambiar el tono de la voz.
  Future<void> cycleSpeed() async {
    final i = radioSpeeds.indexOf(state.speed);
    final next = radioSpeeds[(i + 1) % radioSpeeds.length];
    emit(state.copyWith(speed: next));
    await player.setSpeed(next);
  }

  /// Guardar o quitar de guardados (FR-012).
  Future<void> setSaved(RadioMessage m, bool saved) async {
    try {
      await api.setRadioReceipt(m.id, saved: saved);
      _replace(m.id, (x) => x.copyWith(saved: saved));
    } on ApiException catch (e) {
      _notice(radioErrorText(e));
    }
  }

  Future<bool> _send(Future<RadioMessage> Function() send) async {
    emit(state.copyWith(sending: true));
    try {
      final m = await send();
      if (!isClosed) emit(state.copyWith(sending: false, messages: [m, ...state.messages]));
      return true;
    } on ApiException catch (e) {
      if (!isClosed) emit(state.copyWith(sending: false, notice: () => radioErrorText(e)));
      return false;
    }
  }

  Future<bool> sendText(String text) {
    final t = text.trim();
    if (t.isEmpty || t.length > 500) return Future.value(false);
    return _send(() => api.sendRadioText(conversationId, t));
  }

  Future<bool> sendLocation(RadioPoint p) => _send(() => api.sendRadioLocation(conversationId, p.lat, p.lng));

  /// Alerta de llamada con texto opcional (≤ 80, FR-022).
  Future<bool> sendAlert({String? text}) {
    final t = text?.trim();
    return _send(() => api.sendRadioAlert(conversationId, body: t == null || t.isEmpty ? null : t));
  }

  /// Foto ya comprimida: reserva el mensaje, sube a la URL firmada y confirma (R6).
  Future<bool> sendPhoto(Uint8List jpeg) async {
    emit(state.copyWith(sending: true));
    try {
      final up = await api.reserveRadioPhoto(conversationId);
      await api.uploadRadioPhoto(up.uploadUrl, jpeg);
      await api.confirmRadioPhoto(up.messageId);
      if (isClosed) return true;
      emit(state.copyWith(sending: false));
      await _refreshHead();
      return true;
    } on ApiException catch (e) {
      if (!isClosed) emit(state.copyWith(sending: false, notice: () => radioErrorText(e)));
      return false;
    }
  }

  Future<void> report(RadioMessage m, String reason) async {
    try {
      await api.reportRadioMessage(m.id, reason: reason);
      _notice('Gracias. Kyq revisará este mensaje.');
    } on ApiException catch (e) {
      _notice(radioErrorText(e));
    }
  }

  /// Trae los mensajes nuevos de arriba del historial.
  Future<void> _refreshHead() async {
    try {
      final page = await api.radioMessages(conversationId, limit: pageSize);
      if (isClosed) return;
      final known = {for (final m in state.messages) m.id};
      final fresh = [
        for (final m in page)
          if (!known.contains(m.id)) m,
      ];
      emit(state.copyWith(messages: [...fresh, ...state.messages]..sort((a, b) => b.createdAt.compareTo(a.createdAt))));
    } on ApiException {
      // Llegará con el siguiente evento.
    }
  }

  Future<void> _onEvent(RealtimeEvent e) async {
    switch (e) {
      case RadioMessageEvent(:final message) when message['conversation_id'] == conversationId:
        final m = RadioMessage.fromJson(message);
        if (state.messages.any((x) => x.id == m.id)) {
          _replace(m.id, (_) => m);
        } else if (!isClosed) {
          emit(state.copyWith(messages: [m, ...state.messages]));
        }
        // Abierta y en pantalla: texto y ubicación se leen al llegar; la voz, al oírla.
        if (m.kind != RadioMessageKind.voice && m.authorId != myUserId) await _heard(m);
      case RadioMemberChanged(:final conversationId) when conversationId == this.conversationId:
        await load();
      default:
    }
  }

  @override
  Future<void> close() async {
    await _events.cancel();
    await player.stop();
    return super.close();
  }
}
