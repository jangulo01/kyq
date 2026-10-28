/// Contenido del QR personal del conductor (FR-005): `kyq://driver/{qr_token}`.
String driverQrPayload(String qrToken) => 'kyq://driver/$qrToken';

final _driverQr = RegExp(r'^kyq://driver/([A-Za-z0-9_-]{16,64})$');

/// Devuelve el token de un QR de conductor Kyq, o null si el código no lo es.
String? parseDriverQr(String raw) => _driverQr.firstMatch(raw.trim())?.group(1);

/// 008: enlace que comparte el conductor. Llega a la app como `kyq://affiliate/{token}` desde su
/// página pública, o como esa página (`https://…/a/{token}`) si se pega o se escanea.
final _affiliateLink = RegExp(r'^(?:kyq://affiliate/|https?://[^/\s]+/a/)([A-Za-z0-9_-]{16,64})/?$');

/// Devuelve el token del enlace de un conductor, o null si [raw] no lo es.
String? parseAffiliateLink(String raw) => _affiliateLink.firstMatch(raw.trim())?.group(1);
