import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kyq_admin_web/domains/domains_page.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:mocktail/mocktail.dart';

// 009 (US5): dominios espejo con estado, orden y la regla de al menos uno activo.

class _MockApi extends Mock implements KyqApiClient {}

const _a = MirrorDomain(
  id: 'a',
  apiUrl: 'https://api.kyq.co',
  realtimeUrl: 'wss://rt.kyq.co/c',
  position: 1,
  active: true,
  status: 'ok',
  latencyMs: 42,
);
const _b = MirrorDomain(
  id: 'b',
  apiUrl: 'https://espejo.kyq.co',
  realtimeUrl: 'wss://rt2.kyq.co/c',
  position: 2,
  active: true,
  status: 'down',
);

void main() {
  late _MockApi api;

  setUp(() => api = _MockApi());

  testWidgets('estado, orden y el último activo no se apaga', (tester) async {
    tester.view.physicalSize = const Size(2400, 1600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    when(() => api.mirrorDomains()).thenAnswer(
      (_) async => const MirrorDomainListing(version: 3, signingConfigured: true, publicKey: 'PUB', domains: [_a, _b]),
    );
    when(() => api.reorderMirrorDomains(['b', 'a'])).thenAnswer(
      (_) async => const MirrorDomainListing(version: 4, signingConfigured: true, publicKey: 'PUB', domains: [_b, _a]),
    );
    when(
      () => api.updateMirrorDomain('a', apiUrl: _a.apiUrl, realtimeUrl: _a.realtimeUrl, active: false),
    ).thenThrow(const ApiException(409, 'last_active_domain', ''));

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(create: (_) => DomainsCubit(api)..load(), child: const DomainsPage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('wss://rt.kyq.co/c · responde en 42 ms'), findsOneWidget);
    expect(find.text('wss://rt2.kyq.co/c · no responde'), findsOneWidget);
    expect(find.text('PUB'), findsOneWidget);

    await tester.tap(find.byTooltip('Subir').last);
    await tester.pumpAndSettle();
    expect(find.text('1. https://espejo.kyq.co'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('domains.active.a')));
    await tester.pumpAndSettle();
    expect(find.text('Debe quedar al menos un dominio activo.'), findsOneWidget);
  });

  testWidgets('sin clave de firma se avisa', (tester) async {
    when(
      () => api.mirrorDomains(),
    ).thenAnswer((_) async => const MirrorDomainListing(version: 0, signingConfigured: false));
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(create: (_) => DomainsCubit(api)..load(), child: const DomainsPage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('domains.unsigned')), findsOneWidget);
  });
}
