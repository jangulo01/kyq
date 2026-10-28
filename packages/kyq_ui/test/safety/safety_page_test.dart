import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_ui/kyq_ui.dart';

import 'fakes.dart';

void main() {
  test('normalizePhone acepta E.164 y celulares colombianos de 10 dígitos', () {
    expect(normalizePhone('+57 300 111 0001'), '+573001110001');
    expect(normalizePhone('300-111-0001'), '+573001110001');
    expect(normalizePhone('12345'), isNull);
    expect(normalizePhone('+0573001110001'), isNull);
  });

  late FakeSafetyApi api;
  late SafetyCubit cubit;

  setUp(() {
    api = FakeSafetyApi();
    cubit = SafetyCubit(api);
  });

  tearDown(() => cubit.close());

  test('máximo 3 contactos y teléfono válido (FR-016)', () async {
    await cubit.load();
    expect(await cubit.addContact('Mamá', '3001110001'), isTrue);
    expect(api.contacts.single.phoneE164, '+573001110001');
    expect(await cubit.addContact('Papá', '123'), isFalse);
    expect(await cubit.addContact('Papá', '3001110002'), isTrue);
    expect(await cubit.addContact('Tía', '3001110003'), isTrue);
    expect(await cubit.addContact('Primo', '3001110004'), isFalse);
    expect(cubit.state.error, contains('3'));
    expect(api.contacts, hasLength(3));
    expect(await cubit.removeContact(api.contacts.first), isTrue);
    expect(api.contacts.map((c) => c.name), ['Papá', 'Tía']);
  });

  test('cambiar el PIN pide el actual', () async {
    expect(await cubit.setPin('12'), isFalse);
    expect(await cubit.setPin('2468'), isTrue);
    expect(cubit.state.hasPin, isTrue);
    expect(await cubit.setPin('1357', current: '0000'), isFalse);
    expect(cubit.state.error, 'El PIN actual no coincide.');
    expect(await cubit.setPin('1357', current: '2468'), isTrue);
  });

  testWidgets('pantalla Seguridad: añade un contacto y configura el PIN', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(value: cubit..load(), child: const SafetyPage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Aún no tienes PIN'), findsOneWidget);

    await tester.tap(find.byKey(const Key('safety.addContact')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('safety.contactName')), 'Mamá');
    await tester.enterText(find.byKey(const Key('safety.contactPhone')), '300 111 0001');
    await tester.pump();
    await tester.tap(find.byKey(const Key('safety.contactSave')));
    await tester.pumpAndSettle();
    expect(find.text('Mamá'), findsOneWidget);
    expect(find.text('+573001110001'), findsOneWidget);

    await tester.tap(find.byKey(const Key('safety.setPin')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('safety.pinNew')), '2468');
    await tester.enterText(find.byKey(const Key('safety.pinConfirm')), '2468');
    await tester.pump();
    await tester.tap(find.byKey(const Key('safety.pinSave')));
    await tester.pumpAndSettle();
    expect(api.pins.single, ('2468', null));
    expect(find.text('Cambiar PIN'), findsOneWidget);
  });

  testWidgets('el error del servidor se muestra', (tester) async {
    api.failContacts = const ApiException(400, 'invalid_contact', 'inválido');
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(value: cubit..load(), child: const SafetyPage()),
      ),
    );
    await tester.pumpAndSettle();
    await cubit.addContact('Mamá', '3001110001');
    await tester.pumpAndSettle();
    expect(find.text('Revisa el nombre y el teléfono de cada contacto.'), findsOneWidget);
    expect(api.contacts, isEmpty);
    expect(EmergencyContact.fromJson(const {'name': 'A', 'phone_e164': '+1'}).name, 'A');
  });
}
