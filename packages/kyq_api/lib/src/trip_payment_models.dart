// Modelos de specs/004-trip-payment-cash/contracts/api.yaml: pago del viaje con Bold o en
// efectivo, medios aceptados, libro de liquidación y giros.
import 'package:freezed_annotation/freezed_annotation.dart';

part 'trip_payment_models.freezed.dart';
part 'trip_payment_models.g.dart';

enum TripPaymentStatus {
  pending,
  @JsonValue('bold_in_progress')
  boldInProgress,
  @JsonValue('cash_reported')
  cashReported,
  paid,
  unpaid,
  disputed,
  @JsonValue('needs_review')
  needsReview,
  voided,
}

/// Viaje aún por pagar: pendiente, no pagado o con un pago de Bold en curso.
extension TripPaymentStatusX on TripPaymentStatus {
  bool get open =>
      this == TripPaymentStatus.pending || this == TripPaymentStatus.unpaid || this == TripPaymentStatus.boldInProgress;

  /// No pagado, en disputa o en revisión: lo revisa un administrador.
  bool get issue =>
      this == TripPaymentStatus.unpaid || this == TripPaymentStatus.disputed || this == TripPaymentStatus.needsReview;
}

enum TripPaymentMethod { bold, cash }

/// Pago de un viaje completado (`GET /v1/trips/{id}/payment`). En el panel trae además las notas
/// de revisión, resolución y anulación.
@freezed
abstract class TripPayment with _$TripPayment {
  const factory TripPayment({
    required String id,
    required String tripId,
    required String driverId,
    required String passengerId,
    @Default('') String driverName,
    @Default('') String passengerName,

    /// Tarifa acordada.
    required int amountMinor,
    required String currency,

    /// Siempre igual a [amountMinor] (RN-KYQ-001).
    required int driverAmountMinor,
    @Default(0) int platformCommissionMinor,
    required TripPaymentStatus status,
    TripPaymentMethod? method,

    /// Medios que el pasajero puede usar.
    @Default(<TripPaymentMethod>[]) List<TripPaymentMethod> acceptedMethods,

    /// Solo con un pago de Bold en curso.
    String? checkoutUrl,
    String? paymentMethodDetail,
    DateTime? cashReportedAt,
    DateTime? cashConfirmedAt,
    DateTime? disputedAt,
    DateTime? unpaidMarkedAt,
    DateTime? paidAt,
    DateTime? voidedAt,
    required DateTime createdAt,

    /// Solo en el panel.
    String? reviewNote,
    String? resolutionNote,
    DateTime? resolvedAt,
    String? voidReason,
  }) = _TripPayment;

  factory TripPayment.fromJson(Map<String, dynamic> json) => _$TripPaymentFromJson(json);
}

/// Medios de pago que acepta el conductor (`/v1/driver/payment-methods`).
@freezed
abstract class PaymentMethods with _$PaymentMethods {
  const factory PaymentMethods({
    required bool acceptsCash,
    required bool acceptsBold,

    /// Bold está configurado en Kyq.
    @Default(false) bool boldAvailable,
  }) = _PaymentMethods;

  factory PaymentMethods.fromJson(Map<String, dynamic> json) => _$PaymentMethodsFromJson(json);
}

/// Tipos de movimiento del libro del conductor.
abstract final class LedgerKinds {
  static const tripCredit = 'trip_credit';
  static const voidDebit = 'void_debit';
  static const payout = 'payout';
}

/// Movimiento del libro: abono > 0; débito por anulación y giro < 0.
@freezed
abstract class LedgerEntry with _$LedgerEntry {
  const factory LedgerEntry({
    required String id,
    required String kind,
    required int amountMinor,
    required String currency,
    String? tripPaymentId,
    String? tripId,
    String? payoutId,

    /// Referencia del giro.
    String? reference,
    required DateTime createdAt,
  }) = _LedgerEntry;

  factory LedgerEntry.fromJson(Map<String, dynamic> json) => _$LedgerEntryFromJson(json);
}

/// Saldo por girar de un conductor en una moneda: abonado − debitado − girado.
@freezed
abstract class SettlementBalance with _$SettlementBalance {
  const factory SettlementBalance({
    required String currency,
    @Default(0) int creditedMinor,
    @Default(0) int debitedMinor,
    @Default(0) int paidOutMinor,
    @Default(0) int balanceMinor,
  }) = _SettlementBalance;

  factory SettlementBalance.fromJson(Map<String, dynamic> json) => _$SettlementBalanceFromJson(json);
}

/// `GET /v1/driver/settlement` y el libro de un conductor en el panel.
@freezed
abstract class DriverSettlement with _$DriverSettlement {
  const factory DriverSettlement({
    @Default(<SettlementBalance>[]) List<SettlementBalance> balances,
    @Default(<LedgerEntry>[]) List<LedgerEntry> entries,
    @Default(<TripPayment>[]) List<TripPayment> payments,
  }) = _DriverSettlement;

  factory DriverSettlement.fromJson(Map<String, dynamic> json) => _$DriverSettlementFromJson(json);
}

/// Fila de `GET /v1/admin/settlements`: un conductor en una moneda.
@freezed
abstract class SettlementRow with _$SettlementRow {
  const factory SettlementRow({
    required String driverId,
    required String displayName,
    String? phoneE164,
    String? vehiclePlate,
    required String currency,
    @Default(0) int creditedMinor,
    @Default(0) int debitedMinor,
    @Default(0) int paidOutMinor,
    @Default(0) int balanceMinor,
    DateTime? lastPayoutAt,
  }) = _SettlementRow;

  factory SettlementRow.fromJson(Map<String, dynamic> json) => _$SettlementRowFromJson(json);
}
