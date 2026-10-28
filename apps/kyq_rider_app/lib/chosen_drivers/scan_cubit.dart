import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_domain/kyq_domain.dart';

sealed class ScanState {
  const ScanState();
}

/// Cámara activa esperando un código.
final class ScanWaiting extends ScanState {
  const ScanWaiting();
}

final class ScanProcessing extends ScanState {
  const ScanProcessing();
}

final class ScanSucceeded extends ScanState {
  const ScanSucceeded(this.driver, {required this.alreadyChosen});

  final ChosenDriver driver;
  final bool alreadyChosen;
}

/// El código leído no es un QR de conductor Kyq, o el conductor no existe.
final class ScanInvalid extends ScanState {
  const ScanInvalid();
}

final class ScanFailed extends ScanState {
  const ScanFailed(this.message);

  final String message;
}

/// Afiliación por QR (FR-006). Ignora lecturas mientras procesa o muestra un resultado.
class ScanCubit extends Cubit<ScanState> {
  ScanCubit(this._api) : super(const ScanWaiting());

  final KyqApiClient _api;

  Future<void> onCode(String raw) async {
    if (state is! ScanWaiting) return;
    // 008: también vale el enlace del conductor mostrado como código.
    final token = parseDriverQr(raw) ?? parseAffiliateLink(raw);
    if (token == null) {
      emit(const ScanInvalid());
      return;
    }
    await _affiliate(token, AffiliationSource.qrScan);
  }

  /// 008: afiliación desde el enlace que compartió el conductor (`kyq://affiliate/{token}`).
  Future<void> fromLink(String token) async {
    _linkToken = token;
    if (state is ScanProcessing) return;
    await _affiliate(token, AffiliationSource.link);
  }

  String? _linkToken;

  Future<void> _affiliate(String token, AffiliationSource source) async {
    emit(const ScanProcessing());
    try {
      final result = await _api.affiliate(token, source: source);
      emit(ScanSucceeded(result.driver, alreadyChosen: !result.created));
    } on ApiException catch (e) {
      emit(
        e.code == 'driver_not_found'
            ? const ScanInvalid()
            : ScanFailed(
                e.code == 'network' ? 'Sin conexión. Inténtalo de nuevo.' : 'No pudimos guardar al conductor.',
              ),
      );
    }
  }

  /// Vuelve a escanear tras un código inválido o un error; con un enlace, lo reintenta.
  void retry() {
    final link = _linkToken;
    if (link != null) {
      _affiliate(link, AffiliationSource.link);
    } else {
      emit(const ScanWaiting());
    }
  }
}
