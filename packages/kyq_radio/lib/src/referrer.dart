import 'package:flutter/foundation.dart';
import 'package:play_install_referrer/play_install_referrer.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Código de invitación con el que se instaló la app (R9): la página `/r/{code}` manda a la tienda
/// con `referrer=radio%3D{code}`, así quien instala desde el enlace llega a la invitación tras
/// registrarse (SC-004).
abstract interface class RadioReferrer {
  /// El código una sola vez por instalación; null si no hay o ya se usó.
  Future<String?> take();
}

/// Sin referrer (pruebas, iOS y equipos sin Google Play: ahí está el portapapeles).
class NoRadioReferrer implements RadioReferrer {
  const NoRadioReferrer();

  @override
  Future<String?> take() async => null;
}

/// Lee el `referrer` de la instalación desde Google Play (Play Install Referrer).
class PlayRadioReferrer implements RadioReferrer {
  const PlayRadioReferrer();

  static const _usedKey = 'radio.referrer.used';

  @override
  Future<String?> take() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_usedKey) ?? false) return null;
      await prefs.setBool(_usedKey, true);
      final details = await PlayInstallReferrer.installReferrer;
      return radioReferrerCode(details.installReferrer);
    } on Object {
      // Sin Google Play o el servicio no respondió: queda el enlace o el portapapeles.
      return null;
    }
  }
}

final _referrerCode = RegExp(r'(?:^|&)radio=([0-9A-Za-z]{10})(?:&|$)');

/// Código de `radio={code}` dentro del referrer de la instalación (ya decodificado por Play).
String? radioReferrerCode(String? referrer) {
  if (referrer == null) return null;
  return _referrerCode.firstMatch(Uri.decodeComponent(referrer))?.group(1);
}
