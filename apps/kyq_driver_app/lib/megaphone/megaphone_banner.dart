import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'megaphone_cubit.dart';

/// Aviso "Comunicado de Kyq" sobre cualquier pantalla (009, FR-015): mientras suena y, después,
/// hasta que el conductor lo cierra.
class MegaphoneBanner extends StatelessWidget {
  const MegaphoneBanner({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MegaphoneCubit, MegaphoneState>(
      builder: (context, state) {
        final last = state.lastAt;
        final text = state.playing
            ? 'Comunicado de Kyq en curso'
            : last != null
            ? 'Comunicado de Kyq a las ${last.hour.toString().padLeft(2, '0')}:${last.minute.toString().padLeft(2, '0')}'
            : null;
        if (text == null) return child;
        final theme = Theme.of(context);
        return Column(
          children: [
            Material(
              color: theme.colorScheme.tertiaryContainer,
              child: SafeArea(
                bottom: false,
                child: ListTile(
                  key: const Key('megaphone.banner'),
                  dense: true,
                  leading: Icon(state.playing ? Icons.campaign : Icons.campaign_outlined),
                  title: Text(text),
                  subtitle: state.waiting > 0 ? Text('${state.waiting} más en espera') : null,
                  trailing: state.playing
                      ? null
                      : IconButton(
                          key: const Key('megaphone.dismiss'),
                          tooltip: 'Cerrar',
                          icon: const Icon(Icons.close),
                          onPressed: context.read<MegaphoneCubit>().dismiss,
                        ),
                ),
              ),
            ),
            Expanded(
              child: MediaQuery.removePadding(context: context, removeTop: true, child: child),
            ),
          ],
        );
      },
    );
  }
}
