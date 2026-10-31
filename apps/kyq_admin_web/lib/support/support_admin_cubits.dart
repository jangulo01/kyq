import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_ui/kyq_ui.dart';

/// Filtros de la bandeja (009 FR-008).
@immutable
class InboxFilter {
  const InboxFilter({this.status, this.topic, this.mine = false, this.unanswered = false});

  final SupportStatus? status;
  final SupportTopic? topic;
  final bool mine;
  final bool unanswered;

  InboxFilter copyWith({
    SupportStatus? Function()? status,
    SupportTopic? Function()? topic,
    bool? mine,
    bool? unanswered,
  }) => InboxFilter(
    status: status != null ? status() : this.status,
    topic: topic != null ? topic() : this.topic,
    mine: mine ?? this.mine,
    unanswered: unanswered ?? this.unanswered,
  );
}

@immutable
class InboxState {
  const InboxState({
    this.filter = const InboxFilter(unanswered: true),
    this.cases = const [],
    this.loading = true,
    this.error,
  });

  final InboxFilter filter;
  final List<SupportCase> cases;
  final bool loading;
  final String? error;
}

/// Bandeja de soporte del panel: del más antiguo sin atender al más reciente; se refresca sola.
class SupportInboxCubit extends Cubit<InboxState> {
  SupportInboxCubit(this._api, {Duration? refreshEvery = const Duration(seconds: 15)}) : super(const InboxState()) {
    if (refreshEvery != null) _timer = Timer.periodic(refreshEvery, (_) => load(quiet: true));
  }

  final KyqApiClient _api;
  Timer? _timer;

  Future<void> load({bool quiet = false}) async {
    final f = state.filter;
    if (!quiet) emit(InboxState(filter: f, cases: state.cases));
    try {
      final cases = await _api.adminSupportCases(
        status: f.status,
        topic: f.topic,
        assignedToMe: f.mine,
        unanswered: f.unanswered,
      );
      if (!isClosed && state.filter == f) emit(InboxState(filter: f, cases: cases, loading: false));
    } on ApiException catch (e) {
      if (!isClosed) emit(InboxState(filter: f, cases: state.cases, loading: false, error: supportErrorMessage(e)));
    }
  }

  Future<void> setFilter(InboxFilter filter) {
    emit(InboxState(filter: filter, cases: state.cases));
    return load();
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}

@immutable
class AdminCaseState {
  const AdminCaseState({this.detail, this.loading = true, this.busy = false, this.error});

  final SupportCaseDetail? detail;
  final bool loading;
  final bool busy;
  final String? error;
}

/// Caso en el panel: responder, notas internas, estado, asignación y resolución del pago de 004.
class SupportAdminCaseCubit extends Cubit<AdminCaseState> {
  SupportAdminCaseCubit(this._api, this.caseId, {Duration? refreshEvery = supportRefresh})
    : super(const AdminCaseState()) {
    if (refreshEvery != null) _timer = Timer.periodic(refreshEvery, (_) => load());
  }

  final KyqApiClient _api;
  final String caseId;
  Timer? _timer;

  Future<void> load() => _run(() => _api.adminSupportCase(caseId), busy: false);

  Future<bool> reply(String body, {bool internal = false}) {
    final text = body.trim();
    if (text.isEmpty) return Future.value(false);
    return _run(() => _api.adminReplySupportCase(caseId, text, internal: internal));
  }

  Future<bool> setStatus(SupportStatus status) => _run(() => _api.setSupportCaseStatus(caseId, status));

  Future<bool> assign(String? adminId) => _run(() => _api.assignSupportCase(caseId, adminId: adminId));

  /// Resuelve el pago del viaje con las reglas de 004 (FR-010).
  Future<bool> resolvePayment({required bool paid, required String note}) =>
      _run(() => _api.resolveSupportPayment(caseId, paid: paid, note: note));

  Future<bool> _run(Future<SupportCaseDetail> Function() action, {bool busy = true}) async {
    if (busy) {
      if (state.busy) return false;
      emit(AdminCaseState(detail: state.detail, loading: false, busy: true));
    }
    try {
      final detail = await action();
      if (!isClosed) emit(AdminCaseState(detail: detail, loading: false));
      return true;
    } on ApiException catch (e) {
      if (!isClosed) emit(AdminCaseState(detail: state.detail, loading: false, error: _message(e)));
      return false;
    }
  }

  static String _message(ApiException e) => switch (e.code) {
    'note_required' => 'Escribe una nota de hasta 200 caracteres.',
    'invalid_state' => 'El pago ya cambió de estado; recarga el caso.',
    'not_payment_case' => 'Este caso no está vinculado a un pago.',
    _ => supportErrorMessage(e),
  };

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
