/// Contenido del QR personal del conductor (FR-005): `kyq://driver/{qr_token}`.
String driverQrPayload(String qrToken) => 'kyq://driver/$qrToken';

final _driverQr = RegExp(r'^kyq://driver/([A-Za-z0-9_-]{16,64})$');

/// Devuelve el token de un QR de conductor Kyq, o null si el código no lo es.
String? parseDriverQr(String raw) => _driverQr.firstMatch(raw.trim())?.group(1);
