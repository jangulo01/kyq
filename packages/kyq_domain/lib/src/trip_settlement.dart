/// Liquidación de un viaje, en unidades mínimas de moneda (centavos).
class TripSettlement {
  const TripSettlement._({
    required this.fareMinorUnits,
    required this.driverMinorUnits,
    required this.platformCommissionMinorUnits,
  });

  /// RN-KYQ-001: 0 % de comisión; el conductor recibe el 100 % de la tarifa.
  factory TripSettlement.forFare(int fareMinorUnits) {
    if (fareMinorUnits < 0) {
      throw ArgumentError.value(fareMinorUnits, 'fareMinorUnits', 'no puede ser negativa');
    }
    return TripSettlement._(
      fareMinorUnits: fareMinorUnits,
      driverMinorUnits: fareMinorUnits,
      platformCommissionMinorUnits: 0,
    );
  }

  final int fareMinorUnits;
  final int driverMinorUnits;
  final int platformCommissionMinorUnits;
}
