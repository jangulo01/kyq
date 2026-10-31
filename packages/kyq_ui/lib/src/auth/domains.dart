import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kyq_api/kyq_api.dart';

/// Guarda la lista de dominios válida y el dominio en uso en el almacenamiento seguro (009).
class SecureDomainStore implements DomainStore {
  SecureDomainStore([FlutterSecureStorage? storage]) : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'kyq_domains';
  final FlutterSecureStorage _storage;

  @override
  Future<String?> read() => _storage.read(key: _key);

  @override
  Future<void> write(String value) => _storage.write(key: _key, value: value);
}

/// Clave pública de Kyq para verificar la lista de dominios (`--dart-define`); vacía, sin espejos.
const domainsPublicKey = String.fromEnvironment('KYQ_DOMAINS_PUBLIC_KEY');

/// Lista inicial firmada (`go run ./cmd/domainsign …`) para el primer arranque (FR-022).
const domainsBootstrap = String.fromEnvironment('KYQ_DOMAINS_BOOTSTRAP');

/// Cada cuánto se pide la lista al servidor (FR-020).
const domainsRefresh = Duration(minutes: 10);

/// Carga los dominios espejo si la app trae la clave pública (009, research R8): la lista
/// guardada o, en el primer arranque, la inicial. Sin clave devuelve null y la app usa
/// [fallback]. Se llama antes de crear el cliente y el tiempo real, que toma el dominio en uso.
Future<DomainRotator?> loadDomains({
  required KyqDomain fallback,
  String publicKey = domainsPublicKey,
  String bootstrap = domainsBootstrap,
  DomainStore? store,
}) async {
  if (publicKey.isEmpty) return null;
  SignedDomainList? initial;
  if (bootstrap.isNotEmpty) {
    try {
      initial = SignedDomainList.fromJson(jsonDecode(bootstrap) as Map<String, dynamic>);
    } on Object catch (e) {
      debugPrint('KYQ_DOMAINS_BOOTSTRAP no es una lista firmada: $e');
    }
  }
  final rotator = DomainRotator(
    publicKey: publicKey,
    fallback: fallback,
    bootstrap: initial,
    store: store ?? SecureDomainStore(),
  );
  try {
    await rotator.init();
  } on Object catch (e) {
    debugPrint('No se pudo leer la lista de dominios guardada: $e');
  }
  return rotator;
}

/// Usa [rotator] en [api] y refresca la lista al empezar y cada 10 minutos (FR-020, FR-021).
void useDomains(KyqApiClient api, DomainRotator rotator) {
  api.useDomains(rotator);
  unawaited(api.refreshDomains());
  Timer.periodic(domainsRefresh, (_) => api.refreshDomains());
}
