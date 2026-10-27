import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'scan_cubit.dart';
import 'scan_result.dart';

/// Escáner del QR del conductor. Devuelve true al cerrarse si se guardó un conductor.
class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  final _camera = MobileScannerController(formats: const [BarcodeFormat.qrCode]);

  @override
  void dispose() {
    _camera.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ScanCubit(context.read<KyqApiClient>()),
      child: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Escanear conductor')),
          body: Stack(
            children: [
              MobileScanner(
                controller: _camera,
                onDetect: (capture) {
                  final raw = capture.barcodes.firstOrNull?.rawValue;
                  if (raw != null) context.read<ScanCubit>().onCode(raw);
                },
                errorBuilder: (context, error) => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'No podemos usar la cámara. Revisa el permiso de cámara en los ajustes del teléfono.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                // SafeArea: sin él, el panel queda bajo la barra de navegación del sistema.
                child: SafeArea(child: ScanResult(onDone: () => Navigator.of(context).pop(true))),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
