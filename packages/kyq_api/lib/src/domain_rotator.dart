import 'dart:async';
import 'dart:convert';

import 'package:cryptography/cryptography.dart';

import 'ops_models.dart';

/// Dominio de la API y del tiempo real (009, FR-019).
class KyqDomain {
  const KyqDomain({required this.apiUrl, required this.realtimeUrl});

  final String apiUrl;
  final String realtimeUrl;

  @override
  bool operator ==(Object other) => other is KyqDomain && other.apiUrl == apiUrl && other.realtimeUrl == realtimeUrl;

  @override
  int get hashCode => Object.hash(apiUrl, realtimeUrl);

  @override
  String toString() => 'KyqDomain($apiUrl)';
}

/// Dónde guarda la app la última lista válida y el dominio en uso.
abstract interface class DomainStore {
  Future<String?> read();

  Future<void> write(String value);
}

class InMemoryDomainStore implements DomainStore {
  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String value) async => this.value = value;
}

/// Lista firmada ya verificada.
class _List {
  const _List(this.version, this.domains, this.signed);

  final int version;
  final List<KyqDomain> domains;
  final SignedDomainList signed;
}

/// Dominios espejo en las apps (009, research R8): verifica con la clave pública de Kyq la lista
/// firmada, la guarda, y pasa al siguiente dominio tras [failuresToRotate] fallos de red
/// seguidos, recordándolo. Una lista sin firma válida, vacía o más antigua no cambia nada
/// (SC-006).
class DomainRotator {
  DomainRotator({
    required String publicKey,
    required KyqDomain fallback,
    SignedDomainList? bootstrap,
    DomainStore? store,
    this.failuresToRotate = 3,
  }) : _publicKey = base64.decode(publicKey),
       _bootstrapList = bootstrap,
       _store = store ?? InMemoryDomainStore(),
       _domains = [fallback];

  final List<int> _publicKey;
  final SignedDomainList? _bootstrapList;
  final DomainStore _store;
  final int failuresToRotate;

  List<KyqDomain> _domains;
  int _index = 0;
  int _version = -1;
  int _failures = 0;
  SignedDomainList? _signed;
  final _changes = StreamController<KyqDomain>.broadcast();

  /// Dominio en uso.
  KyqDomain get current => _domains[_index];

  List<KyqDomain> get domains => List.unmodifiable(_domains);

  /// Versión de la lista vigente (-1 sin lista firmada).
  int get version => _version;

  /// Avisa cada vez que cambia el dominio en uso.
  Stream<KyqDomain> get changes => _changes.stream;

  /// Carga la lista guardada o, en el primer arranque, la inicial de la app (FR-022).
  Future<void> init() async {
    final saved = await _store.read();
    if (saved != null) {
      try {
        final json = jsonDecode(saved) as Map<String, dynamic>;
        final list = await _verify(SignedDomainList.fromJson((json['list'] as Map).cast<String, dynamic>()));
        if (list != null) {
          _apply(list, keep: null);
          final index = json['index'];
          if (index is int && index >= 0 && index < _domains.length) _index = index;
          return;
        }
      } on Object {
        // Guardado corrupto: se usa la lista inicial.
      }
    }
    final bootstrap = _bootstrapList;
    if (bootstrap != null) {
      final list = await _verify(bootstrap);
      if (list != null) _apply(list, keep: null);
    }
  }

  /// Acepta una lista del servidor si está firmada por Kyq, no está vacía y es más nueva
  /// (FR-020). Conserva el dominio en uso si sigue en la lista. Devuelve si la aplicó.
  Future<bool> accept(SignedDomainList signed) async {
    final list = await _verify(signed);
    if (list == null || list.version <= _version) return false;
    final before = current;
    _apply(list, keep: before);
    await _save();
    if (current != before) _changes.add(current);
    return true;
  }

  /// Respuesta correcta: el dominio funciona.
  void reportSuccess() => _failures = 0;

  /// Fallo de red. Al llegar a [failuresToRotate] seguidos pasa al siguiente dominio y
  /// devuelve true (FR-021).
  Future<bool> reportFailure() async {
    _failures++;
    if (_failures < failuresToRotate || _domains.length < 2) return false;
    _failures = 0;
    _index = (_index + 1) % _domains.length;
    await _save();
    _changes.add(current);
    return true;
  }

  Future<_List?> _verify(SignedDomainList signed) async {
    try {
      final ok = await Ed25519().verify(
        utf8.encode(signed.payload),
        signature: Signature(
          base64.decode(signed.signature),
          publicKey: SimplePublicKey(_publicKey, type: KeyPairType.ed25519),
        ),
      );
      if (!ok) return null;
      final json = jsonDecode(signed.payload) as Map<String, dynamic>;
      final domains = [
        for (final d in json['domains'] as List)
          KyqDomain(apiUrl: (d as Map)['api_url'] as String, realtimeUrl: d['realtime_url'] as String),
      ];
      if (domains.isEmpty) return null;
      return _List((json['version'] as num).toInt(), domains, signed);
    } on Object {
      return null;
    }
  }

  void _apply(_List list, {required KyqDomain? keep}) {
    _domains = list.domains;
    _version = list.version;
    _signed = list.signed;
    _failures = 0;
    final kept = keep == null ? -1 : _domains.indexWhere((d) => d.apiUrl == keep.apiUrl);
    _index = kept >= 0 ? kept : 0;
  }

  Future<void> _save() async {
    final signed = _signed;
    if (signed == null) return;
    await _store.write(jsonEncode({'list': signed.toJson(), 'index': _index}));
  }

  Future<void> close() => _changes.close();
}
