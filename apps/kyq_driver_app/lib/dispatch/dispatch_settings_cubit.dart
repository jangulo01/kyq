import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kyq_api/kyq_api.dart';

@immutable
class DispatchSettingsState {
  const DispatchSettingsState({
    this.saved = const DispatchSettings(),
    this.acceptsZonePool = false,
    this.discountPct = 0,
    this.loading = true,
    this.saving = false,
    this.error,
  });

  /// Lo guardado en el servidor; [acceptsZonePool] y [discountPct] son el borrador en pantalla.
  final DispatchSettings saved;
  final bool acceptsZonePool;
  final int discountPct;
  final bool loading;
  final bool saving;
  final String? error;

  bool get dirty => acceptsZonePool != saved.acceptsZonePool || discountPct != saved.preferentialDiscountPct;

  DispatchSettingsState copyWith({
    DispatchSettings? saved,
    bool? acceptsZonePool,
    int? discountPct,
    bool? loading,
    bool? saving,
    String? error,
  }) => DispatchSettingsState(
    saved: saved ?? this.saved,
    acceptsZonePool: acceptsZonePool ?? this.acceptsZonePool,
    discountPct: discountPct ?? this.discountPct,
    loading: loading ?? this.loading,
    saving: saving ?? this.saving,
    error: error,
  );
}

/// 008: bolsa zonal (FR-008), tarifa preferencial para su cartera (RN-KYQ-013, 0–30 %) y el enlace
/// que comparte para ganar clientes (FR-015).
class DispatchSettingsCubit extends Cubit<DispatchSettingsState> {
  DispatchSettingsCubit(this._api) : super(const DispatchSettingsState());

  final KyqApiClient _api;

  /// Tope del descuento preferencial (RN-KYQ-013).
  static const maxDiscountPct = 30;

  Future<void> load() async {
    emit(state.copyWith(loading: true));
    try {
      final s = await _api.dispatchSettings();
      if (!isClosed) _show(s);
    } on ApiException {
      if (!isClosed) emit(state.copyWith(loading: false, error: 'No pudimos cargar tus preferencias.'));
    }
  }

  void setAcceptsZonePool(bool on) => emit(state.copyWith(acceptsZonePool: on));

  void setDiscount(int pct) => emit(state.copyWith(discountPct: pct.clamp(0, maxDiscountPct)));

  Future<void> save() async {
    if (state.saving || !state.dirty) return;
    emit(state.copyWith(saving: true));
    try {
      final s = await _api.setDispatchSettings(
        acceptsZonePool: state.acceptsZonePool,
        preferentialDiscountPct: state.discountPct,
      );
      if (!isClosed) _show(s);
    } on ApiException catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          saving: false,
          error: e.code == 'network' ? 'Sin conexión. Inténtalo de nuevo.' : 'No pudimos guardar tus preferencias.',
        ),
      );
    }
  }

  void _show(DispatchSettings s) => emit(
    state.copyWith(
      saved: s,
      acceptsZonePool: s.acceptsZonePool,
      discountPct: s.preferentialDiscountPct,
      loading: false,
      saving: false,
    ),
  );
}
