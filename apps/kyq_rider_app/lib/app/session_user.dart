import 'dart:convert';

/// Id del usuario según el claim `sub` del token de acceso (JWT). No hay `/me` para pasajeros.
///
/// Devuelve null si el token no es un JWT legible; no verifica la firma (eso lo hace el backend).
String? userIdFromAccessToken(String accessToken) {
  final parts = accessToken.split('.');
  if (parts.length != 3) return null;
  try {
    final payload = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
    final sub = payload is Map ? payload['sub'] : null;
    return sub is String && sub.isNotEmpty ? sub : null;
  } on FormatException {
    return null;
  }
}
