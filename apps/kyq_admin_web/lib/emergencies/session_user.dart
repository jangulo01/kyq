import 'dart:convert';

/// Id del operador según el claim `sub` del token de acceso (JWT): la consola lo usa para saber
/// si la alerta es suya. Copia de la del pasajero; no hay `/me` para administradores.
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
