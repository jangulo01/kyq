import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kyq_api/kyq_api.dart';

class DriversState {
  const DriversState({this.drivers = const [], this.loading = false, this.error});

  final List<AdminDriver> drivers;
  final bool loading;
  final String? error;
}

/// Alta de conductores, registro de pagos y aprobación de documentos (FR-004).
class DriversCubit extends Cubit<DriversState> {
  DriversCubit(this._api) : super(const DriversState());

  final KyqApiClient _api;

  Future<void> load() => _run(() async {});

  Future<bool> create({
    required String phoneE164,
    required String displayName,
    required String vehiclePlate,
    required String vehicleDescription,
  }) => _run(
    () => _api.adminCreateDriver(
      phoneE164: phoneE164,
      displayName: displayName,
      vehiclePlate: vehiclePlate,
      vehicleDescription: vehicleDescription,
    ),
  );

  /// Registra la suscripción pagada hasta el final del día [paidThrough] (hora local).
  Future<bool> setPaidThrough(String driverId, DateTime paidThrough) {
    final endOfDay = DateTime(paidThrough.year, paidThrough.month, paidThrough.day, 23, 59, 59);
    return _run(() => _api.adminSetSubscription(driverId, endOfDay));
  }

  Future<bool> setDocument(String driverId, DocType type, {required DateTime expiresAt, required bool approved}) =>
      _run(() => _api.adminSetDocument(driverId, type, expiresAt: expiresAt, approved: approved));

  /// Ejecuta [action] y recarga la lista. Devuelve false y deja el error en el estado si falla.
  Future<bool> _run(Future<void> Function() action) async {
    emit(DriversState(drivers: state.drivers, loading: true));
    try {
      await action();
      emit(DriversState(drivers: await _api.adminListDrivers()));
      return true;
    } on ApiException catch (e) {
      emit(DriversState(drivers: state.drivers, error: _message(e)));
      return false;
    }
  }

  static String _message(ApiException e) => switch (e.code) {
    'phone_in_use' => 'Ese teléfono ya tiene una cuenta.',
    'invalid_phone' => 'El teléfono debe tener el formato +57XXXXXXXXXX.',
    'invalid_display_name' => 'El nombre debe tener de 2 a 60 caracteres.',
    'invalid_vehicle' => 'Indica placa y descripción del vehículo.',
    'network' => 'Sin conexión con el servidor.',
    _ => e.message.isEmpty ? 'Algo salió mal (${e.code}).' : e.message,
  };
}
