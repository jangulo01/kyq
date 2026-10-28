import 'dart:async';

/// Mantiene viva la app mientras la radio está encendida (FR-026, US8): servicio en primer plano
/// con el aviso fijo "Radio encendida" y su botón "Apagar radio". Cada app pone el suyo.
abstract interface class RadioKeepAlive {
  /// Muestra u oculta el aviso de la radio; la app decide si comparte servicio con otro motivo.
  Future<void> setRadioOn(bool on);

  /// El usuario tocó "Apagar radio" en el aviso.
  Stream<void> get turnOffRequests;
}

/// Sin servicio (pruebas y web).
class NoRadioKeepAlive implements RadioKeepAlive {
  const NoRadioKeepAlive();

  @override
  Future<void> setRadioOn(bool on) async {}

  @override
  Stream<void> get turnOffRequests => const Stream.empty();
}
