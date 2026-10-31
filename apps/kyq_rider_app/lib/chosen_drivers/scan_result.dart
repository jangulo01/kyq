import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'scan_cubit.dart';

/// Panel con el resultado del escaneo. [onDone] cierra el escáner tras un éxito.
class ScanResult extends StatelessWidget {
  const ScanResult({super.key, required this.onDone, this.fromLink = false});

  final VoidCallback onDone;

  /// 008: el resultado viene del enlace del conductor, no de la cámara.
  final bool fromLink;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScanCubit, ScanState>(
      builder: (context, state) {
        final (icon, title, detail, action) = switch (state) {
          ScanWaiting() => (null, null, 'Apunta al código QR del conductor', null),
          ScanProcessing() => (null, null, 'Guardando…', null),
          ScanSucceeded(:final driver, :final alreadyChosen) => (
            Icons.check_circle,
            alreadyChosen ? '${driver.displayName} ya está en tu lista' : '${driver.displayName} guardado',
            driver.vehicleDescription,
            FilledButton(onPressed: onDone, child: const Text('Listo')),
          ),
          ScanInvalid() when fromLink => (
            Icons.error,
            'Enlace no válido',
            'Este enlace no corresponde a un conductor Kyq disponible.',
            OutlinedButton(onPressed: onDone, child: const Text('Volver')),
          ),
          ScanInvalid() => (
            Icons.error,
            'Código no válido',
            'Este código no es de un conductor Kyq.',
            OutlinedButton(onPressed: context.read<ScanCubit>().retry, child: const Text('Escanear otro')),
          ),
          ScanFailed(:final message) => (
            Icons.wifi_off,
            'No se pudo guardar',
            message,
            OutlinedButton(onPressed: context.read<ScanCubit>().retry, child: const Text('Reintentar')),
          ),
        };
        return Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) Icon(icon, size: 40),
                if (state is ScanProcessing) const CircularProgressIndicator(),
                if (title != null)
                  Text(title, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(detail, textAlign: TextAlign.center),
                if (action != null) ...[const SizedBox(height: 12), action],
              ],
            ),
          ),
        );
      },
    );
  }
}
