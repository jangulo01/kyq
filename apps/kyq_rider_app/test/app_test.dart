import 'package:flutter_test/flutter_test.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_rider_app/app/app.dart';

void main() {
  testWidgets('sin sesión muestra el login', (tester) async {
    final deps = bootstrap(tokenStore: InMemoryTokenStore());
    await tester.pumpWidget(KyqRiderApp(api: deps.api, auth: deps.auth));
    await tester.pumpAndSettle();
    expect(find.text('Kyq Pasajero'), findsWidgets);
    expect(find.text('Enviarme un código'), findsOneWidget);
  });

  testWidgets('con sesión del rol correcto muestra el inicio', (tester) async {
    final deps = bootstrap(
      tokenStore: InMemoryTokenStore(const Tokens(accessToken: 'a', refreshToken: 'r', role: UserRole.passenger)),
    );
    await tester.pumpWidget(KyqRiderApp(api: deps.api, auth: deps.auth));
    await tester.pumpAndSettle();
    expect(find.text('Sesión iniciada'), findsOneWidget);
  });
}
