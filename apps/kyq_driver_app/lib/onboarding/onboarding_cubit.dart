import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kyq_api/kyq_api.dart';

class OnboardingState {
  const OnboardingState({this.onboarding, this.loading = false, this.loadFailed = false});

  final Onboarding? onboarding;
  final bool loading;
  final bool loadFailed;

  OnboardingStatus? get status => onboarding?.status;

  /// Documentos en el orden del contrato; los tipos que el backend no devuelva salen vacíos.
  List<OnboardingDocument> get documents {
    final byType = {for (final d in onboarding?.documents ?? const <OnboardingDocument>[]) d.docType: d};
    return [for (final t in DocType.values) byType[t] ?? OnboardingDocument(docType: t)];
  }
}

/// Estado de alta del conductor (vehículo y documentos). Lo usa el router para llevarlo a
/// completar el alta (T018) y el inicio para explicar por qué no puede conectarse.
class OnboardingCubit extends Cubit<OnboardingState> {
  OnboardingCubit(this._api) : super(const OnboardingState());

  final KyqApiClient _api;

  Future<void> load() async {
    emit(OnboardingState(onboarding: state.onboarding, loading: true));
    try {
      final onboarding = await _api.driverOnboarding();
      if (!isClosed) emit(OnboardingState(onboarding: onboarding));
    } on ApiException {
      // Sin el estado de alta la app funciona como en 001: el backend sigue bloqueando el ONLINE.
      if (!isClosed) emit(OnboardingState(onboarding: state.onboarding, loadFailed: true));
    }
  }

  /// Al cerrar sesión.
  void reset() => emit(const OnboardingState());
}
