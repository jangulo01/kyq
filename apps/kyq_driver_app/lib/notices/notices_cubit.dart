import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_realtime/kyq_realtime.dart';

class NoticesState {
  const NoticesState({this.notices = const [], this.loading = false, this.latest});

  /// Recientes primero.
  final List<Notice> notices;
  final bool loading;

  /// Último aviso llegado en vivo, para mostrarlo al momento.
  final Notice? latest;

  int get unread => notices.where((n) => n.readAt == null).length;
}

/// Avisos de documentos y pagos (T024): lista, no leídos para la insignia del inicio y llegada en
/// vivo por `notice.created` en `user:{id}`.
class NoticesCubit extends Cubit<NoticesState> {
  NoticesCubit(this._api, Stream<RealtimeEvent> events, {this.onNotice, DateTime Function()? now})
    : _now = now ?? DateTime.now,
      super(const NoticesState()) {
    _sub = events.listen(_onEvent);
  }

  final KyqApiClient _api;
  final DateTime Function() _now;

  /// Un aviso nuevo suele venir de un cambio de estado (documento aprobado, pago confirmado):
  /// la app recarga lo que muestra.
  final void Function(Notice notice)? onNotice;
  late final StreamSubscription<RealtimeEvent> _sub;

  Future<void> load() async {
    emit(NoticesState(notices: state.notices, loading: true));
    try {
      final notices = await _api.driverNotices();
      if (!isClosed) emit(NoticesState(notices: notices));
    } on ApiException {
      if (!isClosed) emit(NoticesState(notices: state.notices));
    }
  }

  void _onEvent(RealtimeEvent e) {
    if (e is! NoticeCreated || isClosed) return;
    if (state.notices.any((n) => n.id == e.noticeId)) return;
    final notice = Notice(id: e.noticeId, kind: e.kind, title: e.title, body: e.body, createdAt: e.occurredAt);
    emit(NoticesState(notices: [notice, ...state.notices], latest: notice));
    onNotice?.call(notice);
  }

  Future<void> markRead(String id) async {
    final notice = state.notices.where((n) => n.id == id).firstOrNull;
    if (notice == null || notice.readAt != null) return;
    final now = _now();
    emit(NoticesState(notices: [for (final n in state.notices) n.id == id ? n.copyWith(readAt: now) : n]));
    try {
      await _api.markNoticeRead(id);
    } on ApiException {
      // Se vuelve a marcar en la próxima visita; no vale la pena molestar al conductor.
    }
  }

  Future<void> markAllRead() async {
    for (final n in state.notices.where((n) => n.readAt == null).toList()) {
      await markRead(n.id);
    }
  }

  void reset() => emit(const NoticesState());

  @override
  Future<void> close() async {
    await _sub.cancel();
    return super.close();
  }
}
