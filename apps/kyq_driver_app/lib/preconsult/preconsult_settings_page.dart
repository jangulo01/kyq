import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../handsfree/hands_free_settings_cubit.dart';
import 'preconsult_settings_cubit.dart';

/// Ajustes de voz del conductor: consultas de sus clientes (RN-KYQ-010) y manos libres
/// (RN-KYQ-012).
class PreconsultSettingsPage extends StatelessWidget {
  const PreconsultSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes de voz')),
      body: BlocConsumer<PreconsultSettingsCubit, PreconsultSettingsState>(
        listenWhen: (a, b) => b.error != null && a.error != b.error,
        listener: (context, s) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.error!))),
        builder: (context, state) {
          final cubit = context.read<PreconsultSettingsCubit>();
          return ListView(
            children: [
              const _Header('Consultas de tus clientes'),
              SwitchListTile(
                key: const Key('preconsult.accepts'),
                title: const Text('Recibir consultas de voz'),
                subtitle: const Text(
                  'Tus clientes podrán preguntarte por voz antes de pedir el viaje (máx. 15 s por turno, '
                  '2 minutos por consulta) solo cuando estés conectado y libre.',
                ),
                value: state.accepts,
                onChanged: state.loading ? null : cubit.setAccepts,
              ),
              if (state.accepts && state.clients.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Text('Desactiva a un cliente para silenciarlo; no se le avisa.'),
                ),
                for (final c in state.clients)
                  SwitchListTile(
                    key: Key('preconsult.client.${c.passengerId}'),
                    secondary: CircleAvatar(child: Text(c.displayName.characters.first.toUpperCase())),
                    title: Text(c.displayName),
                    value: !state.blocked.contains(c.passengerId),
                    onChanged: (allowed) => cubit.setClientAllowed(c.passengerId, allowed),
                  ),
              ],
              const Divider(),
              const _Header('Manos libres'),
              const _HandsFreeSettings(),
            ],
          );
        },
      ),
    );
  }
}

class _HandsFreeSettings extends StatelessWidget {
  const _HandsFreeSettings();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HandsFreeSettingsCubit, HandsFreeSettingsState>(
      builder: (context, state) {
        final cubit = context.read<HandsFreeSettingsCubit>();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SwitchListTile(
              key: const Key('handsfree.button'),
              title: const Text('Hablar con el botón del auricular o del volante'),
              subtitle: const Text(
                'Con un viaje o una consulta abiertos: un clic abre el micrófono y otro lo cierra; '
                'si lo mantienes pulsado, hablas mientras lo mantienes. Si suena música en otra app, '
                'el botón puede ir a esa app.',
              ),
              value: state.mediaButton,
              onChanged: cubit.setMediaButton,
            ),
            SwitchListTile(
              key: const Key('handsfree.bubble'),
              title: const Text('Burbuja sobre Waze o Google Maps'),
              subtitle: Text(
                state.bubble && !state.overlayGranted
                    ? 'Falta el permiso "Mostrar sobre otras apps". Actívalo para ver la burbuja.'
                    : 'Mantén pulsada la burbuja para hablar sin volver a Kyq. Puedes arrastrarla.',
              ),
              value: state.bubbleActive,
              onChanged: cubit.setBubble,
            ),
          ],
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
    child: Text(text, style: Theme.of(context).textTheme.titleSmall),
  );
}
