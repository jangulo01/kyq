import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kyq_api/kyq_api.dart';

/// Mensaje para el usuario de un error del centro de soporte.
String supportErrorMessage(ApiException e) => switch (e.code) {
  'invalid_text' => 'Escribe de 10 a 2 000 caracteres.',
  'invalid_trip' => 'Ese viaje ya no se puede asociar: elige uno de los últimos 30 días.',
  'case_closed' => 'Este caso está cerrado. Abre uno nuevo si necesitas más ayuda.',
  'case_not_found' => 'No encontramos ese caso.',
  'network' => 'Sin conexión. Revisa tu internet.',
  _ => 'No pudimos completar la acción. Inténtalo de nuevo.',
};

@immutable
class SupportListState {
  const SupportListState({this.cases = const [], this.loading = true, this.error});

  final List<SupportCase> cases;
  final bool loading;
  final String? error;
}

/// Casos del usuario (009 FR-011); se refresca mientras la lista está abierta (FR-009).
class SupportListCubit extends Cubit<SupportListState> {
  SupportListCubit(this._api, {Duration? refreshEvery}) : super(const SupportListState()) {
    if (refreshEvery != null) _timer = Timer.periodic(refreshEvery, (_) => load(quiet: true));
  }

  final KyqApiClient _api;
  Timer? _timer;

  Future<void> load({bool quiet = false}) async {
    if (!quiet) emit(SupportListState(cases: state.cases));
    try {
      final cases = await _api.supportCases();
      if (!isClosed) emit(SupportListState(cases: cases, loading: false));
    } on ApiException catch (e) {
      if (!isClosed) emit(SupportListState(cases: state.cases, loading: false, error: supportErrorMessage(e)));
    }
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}

@immutable
class SupportCaseState {
  const SupportCaseState({this.detail, this.loading = true, this.sending = false, this.error});

  final SupportCaseDetail? detail;
  final bool loading;
  final bool sending;
  final String? error;

  bool get closed => detail?.supportCase.status == SupportStatus.closed;

  SupportCaseState copyWith({SupportCaseDetail? detail, bool? loading, bool? sending, String? Function()? error}) =>
      SupportCaseState(
        detail: detail ?? this.detail,
        loading: loading ?? this.loading,
        sending: sending ?? this.sending,
        error: error != null ? error() : this.error,
      );
}

/// Conversación de un caso. Se vuelve a pedir cada [refreshEvery] para ver las respuestas del
/// soporte en menos de 10 s (SC-003).
class SupportCaseCubit extends Cubit<SupportCaseState> {
  SupportCaseCubit(this._api, this.caseId, {Duration? refreshEvery}) : super(const SupportCaseState()) {
    if (refreshEvery != null) _timer = Timer.periodic(refreshEvery, (_) => load());
  }

  final KyqApiClient _api;
  final String caseId;
  Timer? _timer;

  Future<void> load() async {
    try {
      final detail = await _api.supportCase(caseId);
      if (!isClosed) emit(state.copyWith(detail: detail, loading: false));
    } on ApiException catch (e) {
      if (!isClosed) emit(state.copyWith(loading: false, error: () => supportErrorMessage(e)));
    }
  }

  /// Envía [body]; devuelve si se envió.
  Future<bool> reply(String body) async {
    final text = body.trim();
    if (text.isEmpty || state.sending) return false;
    emit(state.copyWith(sending: true, error: () => null));
    try {
      final detail = await _api.replySupportCase(caseId, text);
      if (!isClosed) emit(state.copyWith(detail: detail, sending: false));
      return true;
    } on ApiException catch (e) {
      if (isClosed) return false;
      emit(state.copyWith(sending: false, error: () => supportErrorMessage(e)));
      if (e.code == 'case_closed') await load();
      return false;
    }
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}

@immutable
class NewCaseState {
  const NewCaseState({
    this.topic,
    this.trips = const [],
    this.tripId,
    this.sending = false,
    this.createdId,
    this.error,
  });

  final SupportTopic? topic;
  final List<SupportTripRef> trips;
  final String? tripId;
  final bool sending;

  /// Caso creado: la página abre su conversación.
  final String? createdId;
  final String? error;

  NewCaseState copyWith({
    SupportTopic? topic,
    List<SupportTripRef>? trips,
    String? Function()? tripId,
    bool? sending,
    String? createdId,
    String? Function()? error,
  }) => NewCaseState(
    topic: topic ?? this.topic,
    trips: trips ?? this.trips,
    tripId: tripId != null ? tripId() : this.tripId,
    sending: sending ?? this.sending,
    createdId: createdId ?? this.createdId,
    error: error != null ? error() : this.error,
  );
}

/// Abrir un caso: tema, viaje opcional de los últimos 30 días y descripción (009 FR-005).
class NewCaseCubit extends Cubit<NewCaseState> {
  NewCaseCubit(this._api) : super(const NewCaseState());

  final KyqApiClient _api;

  Future<void> loadTrips() async {
    try {
      final trips = await _api.supportTrips();
      if (!isClosed) emit(state.copyWith(trips: trips));
    } on ApiException {
      // Sin viajes para elegir se puede abrir el caso igual.
    }
  }

  void setTopic(SupportTopic topic) => emit(state.copyWith(topic: topic));

  void setTrip(String? tripId) => emit(state.copyWith(tripId: () => tripId));

  Future<void> submit(String description) async {
    final topic = state.topic;
    if (topic == null || state.sending) return;
    if (description.trim().length < 10) {
      emit(state.copyWith(error: () => 'Cuéntanos un poco más: al menos 10 caracteres.'));
      return;
    }
    emit(state.copyWith(sending: true, error: () => null));
    try {
      final created = await _api.openSupportCase(topic, description.trim(), tripId: state.tripId);
      if (!isClosed) emit(state.copyWith(sending: false, createdId: created.supportCase.id));
    } on ApiException catch (e) {
      if (!isClosed) emit(state.copyWith(sending: false, error: () => supportErrorMessage(e)));
    }
  }
}
