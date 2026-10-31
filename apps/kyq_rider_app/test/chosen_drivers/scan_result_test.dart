import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_rider_app/chosen_drivers/scan_cubit.dart';
import 'package:kyq_rider_app/chosen_drivers/scan_result.dart';
import 'package:mocktail/mocktail.dart';

class _MockApi extends Mock implements KyqApiClient {}

const _token = 'q3T9xZk2LmN8pR4sV7wY1a';
const _carlos = ChosenDriver(
  driverId: 'd1',
  displayName: 'Carlos',
  vehicleDescription: 'Kia gris',
  presence: DriverPresence.free,
);

void main() {
  setUpAll(() => registerFallbackValue(AffiliationSource.qrScan));

  late _MockApi api;
  late ScanCubit cubit;
  var done = 0;

  setUp(() {
    api = _MockApi();
    cubit = ScanCubit(api);
    done = 0;
  });

  Future<void> pump(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: BlocProvider.value(
          value: cubit,
          child: ScanResult(onDone: () => done++),
        ),
      ),
    ),
  );

  testWidgets('QR válido: confirma el conductor guardado', (tester) async {
    when(
      () => api.affiliate(_token, source: AffiliationSource.qrScan),
    ).thenAnswer((_) async => (driver: _carlos, created: true));
    await pump(tester);

    await cubit.onCode('kyq://driver/$_token');
    await tester.pump();

    expect(find.text('Carlos guardado'), findsOneWidget);
    await tester.tap(find.text('Listo'));
    expect(done, 1);
  });

  testWidgets('QR de un conductor ya elegido lo indica', (tester) async {
    when(
      () => api.affiliate(_token, source: AffiliationSource.qrScan),
    ).thenAnswer((_) async => (driver: _carlos, created: false));
    await pump(tester);

    await cubit.onCode('kyq://driver/$_token');
    await tester.pump();

    expect(find.text('Carlos ya está en tu lista'), findsOneWidget);
  });

  testWidgets('QR que no es de Kyq: error sin llamar a la API', (tester) async {
    await pump(tester);

    await cubit.onCode('https://example.com');
    await tester.pump();

    expect(find.text('Código no válido'), findsOneWidget);
    verifyNever(() => api.affiliate(any(), source: any(named: 'source')));

    await tester.tap(find.text('Escanear otro'));
    await tester.pump();
    expect(cubit.state, isA<ScanWaiting>());
  });

  testWidgets('QR con formato Kyq pero conductor inexistente: error sin vínculo', (tester) async {
    when(
      () => api.affiliate(any(), source: any(named: 'source')),
    ).thenThrow(const ApiException(404, 'driver_not_found', ''));
    await pump(tester);

    await cubit.onCode('kyq://driver/$_token');
    await tester.pump();

    expect(find.text('Código no válido'), findsOneWidget);
  });

  test('ignora lecturas repetidas mientras procesa', () async {
    when(
      () => api.affiliate(_token, source: AffiliationSource.qrScan),
    ).thenAnswer((_) async => (driver: _carlos, created: true));
    await Future.wait([cubit.onCode('kyq://driver/$_token'), cubit.onCode('kyq://driver/$_token')]);
    verify(() => api.affiliate(_token, source: AffiliationSource.qrScan)).called(1);
  });
}
