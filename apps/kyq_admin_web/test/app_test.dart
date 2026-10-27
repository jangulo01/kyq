import 'package:flutter_test/flutter_test.dart';
import 'package:kyq_admin_web/main.dart';

void main() {
  testWidgets('arranca y muestra el nombre de la app', (tester) async {
    await tester.pumpWidget(const KyqAdminApp());
    expect(find.text('Kyq Admin'), findsOneWidget);
  });
}
