import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_domain/kyq_domain.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';

const _invitation = 'Escanéame con Kyq Pasajero y guárdame como tu conductor de confianza';

/// QR personal del conductor (FR-005), en pantalla y en PDF para imprimir.
class MyQrPage extends StatefulWidget {
  const MyQrPage({super.key});

  @override
  State<MyQrPage> createState() => _MyQrPageState();
}

class _MyQrPageState extends State<MyQrPage> {
  late final Future<DriverMe> _me = context.read<KyqApiClient>().driverMe();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi código QR')),
      body: FutureBuilder<DriverMe>(
        future: _me,
        builder: (context, snap) {
          if (snap.hasError) return const Center(child: Text('No pudimos cargar tu código.'));
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final payload = driverQrPayload(snap.data!.qrToken);
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: QrImageView(
                  data: payload,
                  size: 260,
                  backgroundColor: Colors.white,
                  semanticsLabel: 'Código QR del conductor',
                ),
              ),
              const SizedBox(height: 16),
              const Text(_invitation, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () async => Printing.sharePdf(
                  bytes: await buildQrPdf(payload, font: await _unicodeFont()),
                  filename: 'kyq-mi-qr.pdf',
                ),
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Descargar PDF para imprimir'),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Fuente con tildes y ñ. Se descarga una vez y queda en caché; sin red se usa la base.
Future<pw.Font?> _unicodeFont() async {
  try {
    return await PdfGoogleFonts.notoSansRegular();
  } on Object {
    return null;
  }
}

/// PDF A6 con el QR, para pegar en el vehículo. [font] debe cubrir tildes y ñ.
Future<Uint8List> buildQrPdf(String payload, {pw.Font? font}) {
  final doc = pw.Document(
    title: 'Código QR Kyq',
    theme: font == null ? null : pw.ThemeData.withFont(base: font, bold: font),
  );
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a6,
      build: (_) => pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Text('Kyq', style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 12),
          pw.BarcodeWidget(barcode: pw.Barcode.qrCode(), data: payload, width: 200, height: 200),
          pw.SizedBox(height: 12),
          pw.Text(_invitation, textAlign: pw.TextAlign.center),
        ],
      ),
    ),
  );
  return doc.save();
}
