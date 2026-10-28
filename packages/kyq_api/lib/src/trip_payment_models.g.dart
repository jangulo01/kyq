// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trip_payment_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TripPayment _$TripPaymentFromJson(Map<String, dynamic> json) => _TripPayment(
  id: json['id'] as String,
  tripId: json['trip_id'] as String,
  driverId: json['driver_id'] as String,
  passengerId: json['passenger_id'] as String,
  driverName: json['driver_name'] as String? ?? '',
  passengerName: json['passenger_name'] as String? ?? '',
  amountMinor: (json['amount_minor'] as num).toInt(),
  currency: json['currency'] as String,
  driverAmountMinor: (json['driver_amount_minor'] as num).toInt(),
  platformCommissionMinor: (json['platform_commission_minor'] as num?)?.toInt() ?? 0,
  status: $enumDecode(_$TripPaymentStatusEnumMap, json['status']),
  method: $enumDecodeNullable(_$TripPaymentMethodEnumMap, json['method']),
  acceptedMethods:
      (json['accepted_methods'] as List<dynamic>?)?.map((e) => $enumDecode(_$TripPaymentMethodEnumMap, e)).toList() ??
      const <TripPaymentMethod>[],
  checkoutUrl: json['checkout_url'] as String?,
  paymentMethodDetail: json['payment_method_detail'] as String?,
  cashReportedAt: json['cash_reported_at'] == null ? null : DateTime.parse(json['cash_reported_at'] as String),
  cashConfirmedAt: json['cash_confirmed_at'] == null ? null : DateTime.parse(json['cash_confirmed_at'] as String),
  disputedAt: json['disputed_at'] == null ? null : DateTime.parse(json['disputed_at'] as String),
  unpaidMarkedAt: json['unpaid_marked_at'] == null ? null : DateTime.parse(json['unpaid_marked_at'] as String),
  paidAt: json['paid_at'] == null ? null : DateTime.parse(json['paid_at'] as String),
  voidedAt: json['voided_at'] == null ? null : DateTime.parse(json['voided_at'] as String),
  createdAt: DateTime.parse(json['created_at'] as String),
  reviewNote: json['review_note'] as String?,
  resolutionNote: json['resolution_note'] as String?,
  resolvedAt: json['resolved_at'] == null ? null : DateTime.parse(json['resolved_at'] as String),
  voidReason: json['void_reason'] as String?,
);

Map<String, dynamic> _$TripPaymentToJson(_TripPayment instance) => <String, dynamic>{
  'id': instance.id,
  'trip_id': instance.tripId,
  'driver_id': instance.driverId,
  'passenger_id': instance.passengerId,
  'driver_name': instance.driverName,
  'passenger_name': instance.passengerName,
  'amount_minor': instance.amountMinor,
  'currency': instance.currency,
  'driver_amount_minor': instance.driverAmountMinor,
  'platform_commission_minor': instance.platformCommissionMinor,
  'status': _$TripPaymentStatusEnumMap[instance.status]!,
  'method': _$TripPaymentMethodEnumMap[instance.method],
  'accepted_methods': instance.acceptedMethods.map((e) => _$TripPaymentMethodEnumMap[e]!).toList(),
  'checkout_url': instance.checkoutUrl,
  'payment_method_detail': instance.paymentMethodDetail,
  'cash_reported_at': instance.cashReportedAt?.toIso8601String(),
  'cash_confirmed_at': instance.cashConfirmedAt?.toIso8601String(),
  'disputed_at': instance.disputedAt?.toIso8601String(),
  'unpaid_marked_at': instance.unpaidMarkedAt?.toIso8601String(),
  'paid_at': instance.paidAt?.toIso8601String(),
  'voided_at': instance.voidedAt?.toIso8601String(),
  'created_at': instance.createdAt.toIso8601String(),
  'review_note': instance.reviewNote,
  'resolution_note': instance.resolutionNote,
  'resolved_at': instance.resolvedAt?.toIso8601String(),
  'void_reason': instance.voidReason,
};

const _$TripPaymentStatusEnumMap = {
  TripPaymentStatus.pending: 'pending',
  TripPaymentStatus.boldInProgress: 'bold_in_progress',
  TripPaymentStatus.cashReported: 'cash_reported',
  TripPaymentStatus.paid: 'paid',
  TripPaymentStatus.unpaid: 'unpaid',
  TripPaymentStatus.disputed: 'disputed',
  TripPaymentStatus.needsReview: 'needs_review',
  TripPaymentStatus.voided: 'voided',
};

const _$TripPaymentMethodEnumMap = {TripPaymentMethod.bold: 'bold', TripPaymentMethod.cash: 'cash'};

_PaymentMethods _$PaymentMethodsFromJson(Map<String, dynamic> json) => _PaymentMethods(
  acceptsCash: json['accepts_cash'] as bool,
  acceptsBold: json['accepts_bold'] as bool,
  boldAvailable: json['bold_available'] as bool? ?? false,
);

Map<String, dynamic> _$PaymentMethodsToJson(_PaymentMethods instance) => <String, dynamic>{
  'accepts_cash': instance.acceptsCash,
  'accepts_bold': instance.acceptsBold,
  'bold_available': instance.boldAvailable,
};

_LedgerEntry _$LedgerEntryFromJson(Map<String, dynamic> json) => _LedgerEntry(
  id: json['id'] as String,
  kind: json['kind'] as String,
  amountMinor: (json['amount_minor'] as num).toInt(),
  currency: json['currency'] as String,
  tripPaymentId: json['trip_payment_id'] as String?,
  tripId: json['trip_id'] as String?,
  payoutId: json['payout_id'] as String?,
  reference: json['reference'] as String?,
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$LedgerEntryToJson(_LedgerEntry instance) => <String, dynamic>{
  'id': instance.id,
  'kind': instance.kind,
  'amount_minor': instance.amountMinor,
  'currency': instance.currency,
  'trip_payment_id': instance.tripPaymentId,
  'trip_id': instance.tripId,
  'payout_id': instance.payoutId,
  'reference': instance.reference,
  'created_at': instance.createdAt.toIso8601String(),
};

_SettlementBalance _$SettlementBalanceFromJson(Map<String, dynamic> json) => _SettlementBalance(
  currency: json['currency'] as String,
  creditedMinor: (json['credited_minor'] as num?)?.toInt() ?? 0,
  debitedMinor: (json['debited_minor'] as num?)?.toInt() ?? 0,
  paidOutMinor: (json['paid_out_minor'] as num?)?.toInt() ?? 0,
  balanceMinor: (json['balance_minor'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$SettlementBalanceToJson(_SettlementBalance instance) => <String, dynamic>{
  'currency': instance.currency,
  'credited_minor': instance.creditedMinor,
  'debited_minor': instance.debitedMinor,
  'paid_out_minor': instance.paidOutMinor,
  'balance_minor': instance.balanceMinor,
};

_DriverSettlement _$DriverSettlementFromJson(Map<String, dynamic> json) => _DriverSettlement(
  balances:
      (json['balances'] as List<dynamic>?)
          ?.map((e) => SettlementBalance.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <SettlementBalance>[],
  entries:
      (json['entries'] as List<dynamic>?)?.map((e) => LedgerEntry.fromJson(e as Map<String, dynamic>)).toList() ??
      const <LedgerEntry>[],
  payments:
      (json['payments'] as List<dynamic>?)?.map((e) => TripPayment.fromJson(e as Map<String, dynamic>)).toList() ??
      const <TripPayment>[],
);

Map<String, dynamic> _$DriverSettlementToJson(_DriverSettlement instance) => <String, dynamic>{
  'balances': instance.balances.map((e) => e.toJson()).toList(),
  'entries': instance.entries.map((e) => e.toJson()).toList(),
  'payments': instance.payments.map((e) => e.toJson()).toList(),
};

_SettlementRow _$SettlementRowFromJson(Map<String, dynamic> json) => _SettlementRow(
  driverId: json['driver_id'] as String,
  displayName: json['display_name'] as String,
  phoneE164: json['phone_e164'] as String?,
  vehiclePlate: json['vehicle_plate'] as String?,
  currency: json['currency'] as String,
  creditedMinor: (json['credited_minor'] as num?)?.toInt() ?? 0,
  debitedMinor: (json['debited_minor'] as num?)?.toInt() ?? 0,
  paidOutMinor: (json['paid_out_minor'] as num?)?.toInt() ?? 0,
  balanceMinor: (json['balance_minor'] as num?)?.toInt() ?? 0,
  lastPayoutAt: json['last_payout_at'] == null ? null : DateTime.parse(json['last_payout_at'] as String),
);

Map<String, dynamic> _$SettlementRowToJson(_SettlementRow instance) => <String, dynamic>{
  'driver_id': instance.driverId,
  'display_name': instance.displayName,
  'phone_e164': instance.phoneE164,
  'vehicle_plate': instance.vehiclePlate,
  'currency': instance.currency,
  'credited_minor': instance.creditedMinor,
  'debited_minor': instance.debitedMinor,
  'paid_out_minor': instance.paidOutMinor,
  'balance_minor': instance.balanceMinor,
  'last_payout_at': instance.lastPayoutAt?.toIso8601String(),
};
