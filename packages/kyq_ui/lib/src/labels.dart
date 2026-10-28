import 'package:kyq_api/kyq_api.dart';

/// Nombre del documento como lo conoce el conductor en Colombia.
String docTypeLabel(DocType type) => switch (type) {
  DocType.nationalId => 'Cédula',
  DocType.license => 'Licencia de conducción',
  DocType.mandatoryInsurance => 'SOAT',
  DocType.technicalInspection => 'Revisión técnico-mecánica',
  DocType.vehicleRegistration => 'Tarjeta de propiedad',
};

String billingStatusLabel(BillingStatus status) => switch (status) {
  BillingStatus.active => 'Activa',
  BillingStatus.grace => 'En gracia',
  BillingStatus.suspended => 'Suspendida',
  BillingStatus.unpaid => 'Sin pagar',
};

String paymentStatusLabel(PaymentStatus status) => switch (status) {
  PaymentStatus.created || PaymentStatus.processing => 'En proceso',
  PaymentStatus.approved => 'Aprobado',
  PaymentStatus.rejected => 'Rechazado',
  PaymentStatus.expired => 'Vencido sin pagar',
  PaymentStatus.voided => 'Anulado',
  PaymentStatus.needsReview => 'En revisión',
};

/// Medio de pago: el detalle de Bold (PSE, Nequi…) o el que anotó el administrador.
String paymentMethodLabel(Payment p) {
  final detail = p.paymentMethodDetail;
  if (detail != null && detail.isNotEmpty) {
    return switch (detail.toUpperCase()) {
      'CREDIT_CARD' || 'CARD' => 'Tarjeta',
      'PSE' => 'PSE',
      'NEQUI' => 'Nequi',
      'BOTON_BANCOLOMBIA' => 'Botón Bancolombia',
      _ => detail,
    };
  }
  return p.method == PaymentMethod.bold ? 'Bold' : 'Manual';
}

String costConceptLabel(String concept) => switch (concept) {
  CostConcepts.voiceMinute => 'Voz del walkie-talkie',
  CostConcepts.realtimeEvent => 'Tiempo real',
  CostConcepts.routeRequest => 'Rutas del mapa',
  CostConcepts.fixedMonthly => 'Mapa base y mantenimiento',
  _ => concept,
};

/// Unidad del uso de cada concepto, para "120 minutos", "3 000 eventos"…
String costUsageUnit(String concept) => switch (concept) {
  CostConcepts.voiceMinute => 'minutos',
  CostConcepts.realtimeEvent => 'eventos',
  CostConcepts.routeRequest => 'rutas',
  _ => '',
};

/// Fecha corta local: 27/10/2026.
String formatDate(DateTime d) {
  final l = d.isUtc ? d.toLocal() : d;
  return '${l.day.toString().padLeft(2, '0')}/${l.month.toString().padLeft(2, '0')}/${l.year}';
}

const _months = [
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre',
];

/// Mes en palabras: "octubre de 2026".
String formatMonth(DateTime d) => '${_months[d.month - 1]} de ${d.year}';

/// Agrupa miles con punto: 3000 → "3.000".
String formatCount(num n) {
  final digits = n.round().abs().toString();
  final buf = StringBuffer(n < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write('.');
    buf.write(digits[i]);
  }
  return buf.toString();
}

/// Como `formatMoney` pero admite importes negativos y fraccionarios (costos y márgenes).
String formatSignedMoney(num minorUnits, String currency) {
  final units = (minorUnits / 100).round();
  final text = formatCount(units.abs());
  final amount = currency == 'COP' || currency == 'PEN' ? '\$ $text' : '$text $currency';
  return units < 0 ? '-$amount' : amount;
}
