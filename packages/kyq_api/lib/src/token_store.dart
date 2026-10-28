import 'models.dart';

/// Persistencia de la sesión. Las apps la implementan con almacenamiento seguro.
abstract interface class TokenStore {
  Future<Tokens?> read();
  Future<void> write(Tokens tokens);
  Future<void> clear();
}

/// [TokenStore] en memoria, para pruebas.
class InMemoryTokenStore implements TokenStore {
  InMemoryTokenStore([this._tokens]);

  Tokens? _tokens;

  @override
  Future<Tokens?> read() async => _tokens;

  @override
  Future<void> write(Tokens tokens) async => _tokens = tokens;

  @override
  Future<void> clear() async => _tokens = null;
}
