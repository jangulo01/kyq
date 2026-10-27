import 'package:flutter_test/flutter_test.dart';
import 'package:kyq_driver_app/main.dart';

void main() {
  testWidgets('arranca y muestra el nombre de la app', (tester) async {
    await tester.pumpWidget(const KyqDriverApp());
    expect(find.text('Kyq Conductor'), findsOneWidget);
  });
}
