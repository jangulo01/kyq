import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kyq_api/kyq_api.dart';

String adminErrorMessage(ApiException e) => switch (e.code) {
  'network' => 'Sin conexión con el servidor.',
  'reason_required' => 'Escribe o elige el motivo del rechazo.',
  'invalid_state' => 'Ese documento ya fue revisado. Recarga el expediente.',
  _ => e.message.isEmpty ? 'Algo salió mal (${e.code}).' : e.message,
};

class KycQueueState {
  const KycQueueState({this.entries = const [], this.loading = false, this.error});

  final List<KycQueueEntry> entries;
  final bool loading;
  final String? error;
}

/// Cola de revisión KYC (T023, FR-008): del envío más antiguo al más reciente.
class KycQueueCubit extends Cubit<KycQueueState> {
  KycQueueCubit(this._api) : super(const KycQueueState());

  final KyqApiClient _api;

  Future<void> load() async {
    emit(KycQueueState(entries: state.entries, loading: true));
    try {
      final entries = await _api.adminKycQueue();
      // El backend ya ordena; se asegura aquí porque es la regla de la cola.
      final far = DateTime.utc(9999);
      entries.sort((a, b) => (a.oldestSubmittedAt ?? far).compareTo(b.oldestSubmittedAt ?? far));
      emit(KycQueueState(entries: entries));
    } on ApiException catch (e) {
      emit(KycQueueState(entries: state.entries, error: adminErrorMessage(e)));
    }
  }
}

class KycDriverState {
  const KycDriverState({this.file, this.loading = false, this.busy = false, this.error});

  final KycDriverFile? file;
  final bool loading;

  /// Revisión en curso.
  final bool busy;
  final String? error;
}

/// Expediente de un conductor: aprobar (con correcciones) o rechazar con motivo (FR-008, FR-009).
class KycDriverCubit extends Cubit<KycDriverState> {
  KycDriverCubit(this._api, this.driverId) : super(const KycDriverState());

  final KyqApiClient _api;
  final String driverId;

  Future<void> load() async {
    emit(KycDriverState(file: state.file, loading: true));
    try {
      emit(KycDriverState(file: await _api.adminKycDriver(driverId)));
    } on ApiException catch (e) {
      emit(KycDriverState(file: state.file, error: adminErrorMessage(e)));
    }
  }

  /// Envía solo las correcciones que cambian lo declarado. Devuelve false si falla.
  Future<bool> approve(KycDocument doc, {String? number, DateTime? expiresAt, DateTime? exemptUntil}) => _review(
    () => _api.adminReviewDocument(
      doc.id,
      approve: true,
      number: number != null && number.trim().isNotEmpty && number.trim() != doc.number ? number.trim() : null,
      expiresAt: expiresAt != null && !_sameDay(expiresAt, doc.expiresAt) ? expiresAt : null,
      exemptUntil: exemptUntil,
    ),
  );

  Future<bool> reject(KycDocument doc, String reason) =>
      _review(() => _api.adminReviewDocument(doc.id, approve: false, reason: reason.trim()));

  Future<bool> _review(Future<void> Function() action) async {
    emit(KycDriverState(file: state.file, busy: true));
    try {
      await action();
      emit(KycDriverState(file: await _api.adminKycDriver(driverId)));
      return true;
    } on ApiException catch (e) {
      emit(KycDriverState(file: state.file, error: adminErrorMessage(e)));
      return false;
    }
  }

  static bool _sameDay(DateTime a, DateTime? b) =>
      b != null && a.year == b.year && a.month == b.month && a.day == b.day;
}
