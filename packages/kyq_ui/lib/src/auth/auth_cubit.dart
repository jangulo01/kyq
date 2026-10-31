import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kyq_api/kyq_api.dart';

/// Estado del inicio de sesión.
sealed class AuthState {
  const AuthState();
}

/// Aún no se ha leído la sesión guardada.
final class AuthUnknown extends AuthState {
  const AuthUnknown();
}

/// Sin sesión: se pide el teléfono.
final class AuthSignedOut extends AuthState {
  const AuthSignedOut({this.busy = false, this.error});

  final bool busy;
  final String? error;
}

/// Código enviado: se pide el código y, si el teléfono es nuevo, el nombre.
final class AuthCodeSent extends AuthState {
  const AuthCodeSent({required this.phone, this.needsName = false, this.busy = false, this.error});

  final String phone;
  final bool needsName;
  final bool busy;
  final String? error;

  AuthCodeSent copyWith({bool? needsName, bool? busy, String? error}) =>
      AuthCodeSent(phone: phone, needsName: needsName ?? this.needsName, busy: busy ?? this.busy, error: error);
}

final class AuthSignedIn extends AuthState {
  const AuthSignedIn(this.role, {this.radioInvitesApplied = const []});

  final UserRole role;

  /// 011: conversaciones de Radio a las que llevaron invitaciones por teléfono al registrarse;
  /// solo justo después de verificar el código.
  final List<String> radioInvitesApplied;
}

/// 009: cuenta suspendida; la sesión solo abre el centro de soporte (FR-011).
final class AuthSupportOnly extends AuthState {
  const AuthSupportOnly(this.role);

  final UserRole role;
}

/// Login por OTP. Solo acepta sesiones de [allowedRoles]: cada app es para un tipo de usuario.
class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._api, {required this.allowedRoles, required this.wrongRoleMessage, this.signUpRole})
    : super(const AuthUnknown());

  final KyqApiClient _api;
  final Set<UserRole> allowedRoles;
  final String wrongRoleMessage;

  /// Rol con el que se crea la cuenta si el teléfono es nuevo (la app del conductor usa
  /// [UserRole.driver]); null deja el de por defecto del backend, pasajero.
  final UserRole? signUpRole;

  Future<void> start() async {
    final session = await _api.currentSession();
    if (session != null && allowedRoles.contains(session.role)) {
      emit(session.supportOnly ? AuthSupportOnly(session.role) : AuthSignedIn(session.role));
    } else {
      emit(const AuthSignedOut());
    }
  }

  Future<void> requestCode(String phone) async {
    emit(const AuthSignedOut(busy: true));
    try {
      await _api.requestOtp(phone);
      emit(AuthCodeSent(phone: phone));
    } on ApiException catch (e) {
      emit(AuthSignedOut(error: _message(e)));
    }
  }

  Future<void> verify(String code, {String? displayName}) async {
    final current = state;
    if (current is! AuthCodeSent) return;
    emit(current.copyWith(busy: true));
    try {
      final tokens = await _api.verifyOtp(current.phone, code, displayName: displayName, role: signUpRole);
      if (!allowedRoles.contains(tokens.role)) {
        await _api.logout();
        emit(AuthSignedOut(error: wrongRoleMessage));
        return;
      }
      emit(
        tokens.supportOnly
            ? AuthSupportOnly(tokens.role)
            : AuthSignedIn(tokens.role, radioInvitesApplied: tokens.radioInvitesApplied),
      );
    } on ApiException catch (e) {
      if (e.code == 'display_name_required') {
        emit(current.copyWith(needsName: true));
      } else {
        emit(current.copyWith(error: _message(e)));
      }
    }
  }

  /// Vuelve a pedir el teléfono.
  void changePhone() => emit(const AuthSignedOut());

  Future<void> signOut() async {
    await _api.logout();
    emit(const AuthSignedOut());
  }

  /// Llamar desde `KyqApiClient.onSupportOnly`: la cuenta se suspendió con la sesión abierta.
  Future<void> supportOnly() async {
    final session = await _api.currentSession();
    if (session != null && session.supportOnly) emit(AuthSupportOnly(session.role));
  }

  /// Llamar desde `KyqApiClient.onSessionExpired`.
  void sessionExpired() => emit(const AuthSignedOut(error: 'Tu sesión caducó. Vuelve a entrar.'));

  static String _message(ApiException e) => switch (e.code) {
    'invalid_phone' => 'Revisa el número de teléfono.',
    'rate_limited' => 'Pediste demasiados códigos. Espera una hora.',
    'invalid_code' => 'Código incorrecto o caducado.',
    'phone_has_other_role' =>
      'Este número ya tiene una cuenta de pasajero o de administrador en Kyq. Para registrarte como conductor usa otro número.',
    'network' => 'Sin conexión. Revisa tu internet.',
    'account_suspended' => 'Tu cuenta está suspendida; comunícate con el soporte de Kyq.',
    _ => 'Algo salió mal. Inténtalo de nuevo.',
  };
}
