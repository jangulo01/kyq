import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_ui/kyq_ui.dart';
import 'package:mocktail/mocktail.dart';

class _MockApi extends Mock implements KyqApiClient {}

const _passenger = Tokens(accessToken: 'a', refreshToken: 'r', role: UserRole.passenger);
const _driver = Tokens(accessToken: 'a', refreshToken: 'r', role: UserRole.driver);

void main() {
  late _MockApi api;
  late AuthCubit cubit;

  setUp(() {
    api = _MockApi();
    cubit = AuthCubit(api, allowedRoles: {UserRole.passenger}, wrongRoleMessage: 'Esta app es para pasajeros.');
    when(() => api.currentSession()).thenAnswer((_) async => null);
    when(() => api.requestOtp(any())).thenAnswer((_) async {});
    when(() => api.logout()).thenAnswer((_) async {});
  });

  Future<void> pump(WidgetTester tester) async {
    await cubit.start();
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: cubit,
          child: const LoginPage(title: 'Kyq Pasajero'),
        ),
      ),
    );
  }

  testWidgets('teléfono → código → nombre en el primer registro', (tester) async {
    when(
      () => api.verifyOtp('+573001234567', '123456'),
    ).thenThrow(const ApiException(400, 'display_name_required', ''));
    when(() => api.verifyOtp('+573001234567', '123456', displayName: 'Ana')).thenAnswer((_) async => _passenger);
    await pump(tester);

    await tester.enterText(find.byKey(const Key('login.phone')), '300 123 4567');
    await tester.tap(find.byKey(const Key('login.sendCode')));
    await tester.pumpAndSettle();
    verify(() => api.requestOtp('+573001234567')).called(1);
    expect(find.textContaining('+573001234567'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('login.code')), '123456');
    await tester.tap(find.byKey(const Key('login.verify')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('login.name')), findsOneWidget);

    await tester.enterText(find.byKey(const Key('login.name')), 'Ana');
    await tester.tap(find.byKey(const Key('login.verify')));
    // Con sesión la página muestra un indicador hasta que el router redirige: no se asienta.
    await tester.pump();
    expect(cubit.state, isA<AuthSignedIn>());
  });

  testWidgets('muestra el error de código incorrecto', (tester) async {
    when(
      () => api.verifyOtp(any(), any(), displayName: any(named: 'displayName')),
    ).thenThrow(const ApiException(401, 'invalid_code', ''));
    await pump(tester);

    await tester.enterText(find.byKey(const Key('login.phone')), '3001234567');
    await tester.tap(find.byKey(const Key('login.sendCode')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('login.code')), '000000');
    await tester.tap(find.byKey(const Key('login.verify')));
    await tester.pumpAndSettle();

    expect(find.text('Código incorrecto o caducado.'), findsOneWidget);
  });

  test('rechaza una sesión de otro rol y la cierra', () async {
    when(() => api.verifyOtp(any(), any(), displayName: any(named: 'displayName'))).thenAnswer((_) async => _driver);
    await cubit.start();
    await cubit.requestCode('+573001234567');
    await cubit.verify('123456');

    expect(cubit.state, isA<AuthSignedOut>().having((s) => s.error, 'error', 'Esta app es para pasajeros.'));
    verify(() => api.logout()).called(1);
  });

  group('alta como conductor', () {
    late AuthCubit driverAuth;

    setUp(() {
      driverAuth = AuthCubit(
        api,
        allowedRoles: {UserRole.driver},
        wrongRoleMessage: 'Esta app es para conductores.',
        signUpRole: UserRole.driver,
      );
    });

    test('verifica con role driver', () async {
      when(
        () => api.verifyOtp(
          any(),
          any(),
          displayName: any(named: 'displayName'),
          role: UserRole.driver,
        ),
      ).thenAnswer((_) async => _driver);
      await driverAuth.start();
      await driverAuth.requestCode('+573001234567');
      await driverAuth.verify('123456', displayName: 'Carlos');

      expect(driverAuth.state, isA<AuthSignedIn>());
      verify(() => api.verifyOtp('+573001234567', '123456', displayName: 'Carlos', role: UserRole.driver)).called(1);
    });

    testWidgets('teléfono de pasajero: mensaje claro para usar otro número', (tester) async {
      when(
        () => api.verifyOtp(
          any(),
          any(),
          displayName: any(named: 'displayName'),
          role: any(named: 'role'),
        ),
      ).thenThrow(const ApiException(409, 'phone_has_other_role', 'phone already registered'));
      await driverAuth.start();
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: driverAuth,
            child: const LoginPage(title: 'Kyq Conductor', subtitle: 'Soy conductor'),
          ),
        ),
      );
      expect(find.text('Soy conductor'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('login.phone')), '3001234567');
      await tester.tap(find.byKey(const Key('login.sendCode')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('login.code')), '123456');
      await tester.tap(find.byKey(const Key('login.verify')));
      await tester.pumpAndSettle();

      expect(find.textContaining('ya tiene una cuenta de pasajero'), findsOneWidget);
      expect(find.textContaining('usa otro número'), findsOneWidget);
    });
  });

  test('restaura la sesión guardada del rol correcto', () async {
    when(() => api.currentSession()).thenAnswer((_) async => _passenger);
    await cubit.start();
    expect(cubit.state, isA<AuthSignedIn>());
  });
}
