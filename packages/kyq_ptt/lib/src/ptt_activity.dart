import 'package:flutter/foundation.dart';

/// Voz en curso en algún canal PTT de la app (viaje, pre-consulta o grupo). El comunicado del
/// megáfono (009, FR-015) espera a que termine el turno para no pisar al pasajero.
class PttActivity extends ChangeNotifier {
  PttActivity();

  /// Instancia de la app; los controladores PTT la actualizan solos.
  static final instance = PttActivity();

  final _busy = <Object>{};

  /// Alguien habla o se está pidiendo el turno.
  bool get busy => _busy.isNotEmpty;

  /// [owner] informa si tiene voz en curso.
  void report(Object owner, {required bool busy}) {
    final changed = busy ? _busy.add(owner) : _busy.remove(owner);
    if (changed) notifyListeners();
  }
}
