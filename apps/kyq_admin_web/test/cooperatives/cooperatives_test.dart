import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kyq_admin_web/cooperatives/cooperative_detail_page.dart';
import 'package:kyq_admin_web/cooperatives/cooperatives_cubits.dart';
import 'package:kyq_admin_web/cooperatives/cooperatives_page.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:mocktail/mocktail.dart';

// Panel de cooperativas (006, T008–T009).

class _MockApi extends Mock implements KyqApiClient {}

const _andina = Cooperative(
  id: 'c1',
  name: 'Cooperativa Andina',
  cityCode: 'bogota',
  status: CooperativeStatus.active,
  membersCount: 2,
  pendingCount: 1,
);

CooperativeDetail _detail({CooperativeStatus status = CooperativeStatus.active, bool coordinator = false}) =>
    CooperativeDetail(
      cooperative: _andina.copyWith(status: status),
      members: [
        CooperativeMember(
          membershipId: 'm1',
          driverId: 'd1',
          displayName: 'Carlos',
          vehiclePlate: 'KYQ001',
          role: coordinator ? CooperativeRole.coordinator : CooperativeRole.member,
          presence: 'free',
        ),
      ],
      requests: [
        MembershipRequest(
          membershipId: 'm2',
          driverId: 'd2',
          displayName: 'Beto',
          vehiclePlate: 'KYQ002',
          requestedAt: DateTime.utc(2026, 10, 27),
        ),
      ],
    );

const _dani = AdminDriver(
  driverId: 'd3',
  phoneE164: '+573100000003',
  displayName: 'Dani',
  qrToken: 'qr',
  vehiclePlate: 'KYQ003',
  vehicleDescription: 'Kia',
  presence: DriverPresence.offline,
  subscriptionStatus: SubscriptionStatus.active,
  canGoOnline: true,
);

Future<void> _wide(WidgetTester tester) async {
  tester.view.physicalSize = const Size(2400, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  late _MockApi api;

  setUp(() => api = _MockApi());

  testWidgets('lista con solicitudes pendientes y alta de una cooperativa', (tester) async {
    await _wide(tester);
    var created = false;
    when(() => api.adminCooperatives()).thenAnswer((_) async => created ? [_andina] : []);
    when(() => api.adminCreateCooperative(name: 'Cooperativa Andina', cityCode: 'bogota', nit: '900123')).thenAnswer((
      _,
    ) async {
      created = true;
      return _andina;
    });
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(create: (_) => CooperativesCubit(api)..load(), child: const CooperativesPage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Aún no hay cooperativas.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('coops.create')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('coops.form.name')), 'Cooperativa Andina');
    await tester.enterText(find.byKey(const Key('coops.form.nit')), '900123');
    await tester.tap(find.byKey(const Key('coops.form.save')));
    await tester.pumpAndSettle();

    expect(find.text('Cooperativa Andina'), findsOneWidget);
    expect(find.text('1 solicitud'), findsOneWidget);
  });

  testWidgets('nombre repetido: el formulario explica el error', (tester) async {
    await _wide(tester);
    when(() => api.adminCooperatives()).thenAnswer((_) async => [_andina]);
    when(
      () => api.adminCreateCooperative(
        name: any(named: 'name'),
        cityCode: any(named: 'cityCode'),
        nit: any(named: 'nit'),
      ),
    ).thenThrow(const ApiException(409, 'cooperative_name_taken', ''));
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(create: (_) => CooperativesCubit(api)..load(), child: const CooperativesPage()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('coops.create')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('coops.form.name')), 'cooperativa andina');
    await tester.tap(find.byKey(const Key('coops.form.save')));
    await tester.pumpAndSettle();
    expect(find.text('Ya existe una cooperativa con ese nombre.'), findsOneWidget);
  });

  testWidgets('detalle: aprobar, rechazar con motivo, coordinador, agregar y suspender', (tester) async {
    await _wide(tester);
    when(() => api.adminCooperative('c1')).thenAnswer((_) async => _detail());
    when(() => api.adminListDrivers()).thenAnswer((_) async => [_dani]);
    when(() => api.adminDecideMembership('m2', approve: true)).thenAnswer((_) async {});
    when(() => api.adminDecideMembership('m2', approve: false, reason: 'Sin referencias')).thenAnswer((_) async {});
    when(() => api.adminSetCooperativeRole('c1', 'd1', CooperativeRole.coordinator)).thenAnswer((_) async {});
    when(() => api.adminAddCooperativeMember('c1', 'd3')).thenAnswer((_) async {});
    when(
      () => api.adminUpdateCooperative('c1', status: CooperativeStatus.suspended),
    ).thenAnswer((_) async => _andina.copyWith(status: CooperativeStatus.suspended));

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (_) => CooperativeDetailCubit(api, 'c1')..load(),
          child: const CooperativeDetailPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Cooperativa Andina'), findsOneWidget);
    expect(find.text('Beto · KYQ002'), findsOneWidget);

    await tester.tap(find.byKey(const Key('coop.approve.m2')));
    await tester.pumpAndSettle();
    verify(() => api.adminDecideMembership('m2', approve: true)).called(1);

    await tester.tap(find.byKey(const Key('coop.reject.m2')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('coop.dialog.text')), 'Sin referencias');
    await tester.tap(find.byKey(const Key('coop.dialog.ok')));
    await tester.pumpAndSettle();
    verify(() => api.adminDecideMembership('m2', approve: false, reason: 'Sin referencias')).called(1);

    await tester.tap(find.byKey(const Key('coop.role.d1')));
    await tester.pumpAndSettle();
    verify(() => api.adminSetCooperativeRole('c1', 'd1', CooperativeRole.coordinator)).called(1);

    await tester.tap(find.byKey(const Key('coop.add')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('coop.add.d3')));
    await tester.pumpAndSettle();
    verify(() => api.adminAddCooperativeMember('c1', 'd3')).called(1);

    await tester.tap(find.byKey(const Key('coop.status')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('coop.confirm')));
    await tester.pumpAndSettle();
    verify(() => api.adminUpdateCooperative('c1', status: CooperativeStatus.suspended)).called(1);
  });

  testWidgets('cooperativa suspendida: aviso y opción de reactivar', (tester) async {
    await _wide(tester);
    when(
      () => api.adminCooperative('c1'),
    ).thenAnswer((_) async => _detail(status: CooperativeStatus.suspended, coordinator: true));
    when(() => api.adminListDrivers()).thenAnswer((_) async => []);
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (_) => CooperativeDetailCubit(api, 'c1')..load(),
          child: const CooperativeDetailPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Suspendida'), findsOneWidget);
    expect(find.text('Reactivar'), findsOneWidget);
    expect(find.text('Quitar coordinador'), findsOneWidget);
  });
}
