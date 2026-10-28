import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';

import 'dispatch_settings_cubit.dart';

/// Comparte un texto con las apps del teléfono; las pruebas pasan un falso.
typedef ShareText = Future<void> Function(String text);

Future<void> shareWithPlatform(String text) => SharePlus.instance.share(ShareParams(text: text));

/// Texto con el que el conductor invita a un pasajero a guardarlo (FR-015).
String affiliateInvitation(String link) => 'Guárdame como tu conductor de confianza en Kyq: $link';

/// 008: "Despacho y tarifas": bolsa zonal, tarifa preferencial y enlace para compartir.
class DispatchSettingsPage extends StatelessWidget {
  const DispatchSettingsPage({super.key, this.share = shareWithPlatform});

  final ShareText share;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DispatchSettingsCubit>();
    return Scaffold(
      appBar: AppBar(title: const Text('Despacho y tarifas')),
      body: BlocConsumer<DispatchSettingsCubit, DispatchSettingsState>(
        listenWhen: (a, b) => b.error != null && a.error != b.error,
        listener: (context, s) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.error!))),
        builder: (context, s) {
          if (s.loading) return const Center(child: CircularProgressIndicator());
          final theme = Theme.of(context);
          final link = s.saved.affiliateLink;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: SwitchListTile(
                  key: const Key('dispatch.zonePool'),
                  value: s.acceptsZonePool,
                  onChanged: cubit.setAcceptsZonePool,
                  title: const Text('Recibir solicitudes de la bolsa zonal'),
                  subtitle: const Text(
                    'Pasajeros cercanos que no te tienen como Conductor Elegido. Te llegan solo cuando '
                    'estás libre y pagan la tarifa sugerida completa.',
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Tarifa preferencial para tu cartera', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 4),
                      const Text(
                        'Descuento sobre la tarifa sugerida para quienes te tienen como Conductor Elegido. '
                        'No aplica a la bolsa zonal ni a solicitudes de tu cooperativa.',
                      ),
                      Slider(
                        key: const Key('dispatch.discount'),
                        value: s.discountPct.toDouble(),
                        max: DispatchSettingsCubit.maxDiscountPct.toDouble(),
                        divisions: DispatchSettingsCubit.maxDiscountPct,
                        label: '${s.discountPct} %',
                        onChanged: (v) => cubit.setDiscount(v.round()),
                      ),
                      Text(
                        s.discountPct == 0 ? 'Sin descuento' : '${s.discountPct} % de descuento',
                        key: const Key('dispatch.discountLabel'),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                key: const Key('dispatch.save'),
                onPressed: s.dirty && !s.saving ? cubit.save : null,
                child: s.saving
                    ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Guardar'),
              ),
              if (link.isNotEmpty) ...[
                const SizedBox(height: 24),
                Card(
                  child: ListTile(
                    key: const Key('dispatch.shareLink'),
                    leading: const Icon(Icons.share),
                    title: const Text('Compartir mi enlace'),
                    subtitle: Text(link),
                    onTap: () => share(affiliateInvitation(link)),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
