import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kyq_domain/kyq_domain.dart';

import 'scan_result.dart';

/// 008: guarda como Conductor Elegido al conductor del enlace que compartió (FR-015).
class AffiliateLinkPage extends StatelessWidget {
  const AffiliateLinkPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Conductor Elegido')),
      body: Center(child: ScanResult(fromLink: true, onDone: () => context.go('/'))),
    );
  }
}

/// Ruta interna del enlace de un conductor.
String affiliateLinkLocation(String token) => '/affiliate/$token';

/// Lleva `kyq://affiliate/{token}` (o la página pública `…/a/{token}`) a su ruta en la app; null si
/// [uri] no es un enlace de conductor.
String? affiliateLinkRedirect(Uri uri) {
  final isLink = (uri.scheme == 'kyq' && uri.host == 'affiliate') || uri.path.startsWith('/a/');
  if (!isLink) return null;
  final token = parseAffiliateLink(uri.scheme == 'kyq' ? 'kyq://affiliate${uri.path}' : 'https://kyq${uri.path}');
  return token == null ? '/' : affiliateLinkLocation(token);
}
