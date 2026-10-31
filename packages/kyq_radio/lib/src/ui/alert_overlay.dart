import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../controller/radio_cubit.dart';
import '../deps.dart';
import '../mount.dart';
import 'history.dart';

/// Aviso en pantalla de una alerta de llamada o de una emergencia que llega por Radio (FR-022,
/// FR-031), sobre cualquier pantalla de la app: suena hasta abrirla o descartarla. La app lo pone
/// en el `builder` de su `MaterialApp`.
class RadioAlertOverlay extends StatelessWidget {
  const RadioAlertOverlay({super.key, required this.mount, required this.open, required this.child});

  final RadioMount mount;

  /// Abre una ruta de Radio (la conversación de la alerta).
  final void Function(String location) open;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        ValueListenableBuilder(
          valueListenable: mount.scope,
          builder: (context, scope, _) => scope == null
              ? const SizedBox.shrink()
              : BlocBuilder<RadioCubit, RadioState>(
                  bloc: scope.cubit,
                  buildWhen: (a, b) => a.alert != b.alert,
                  builder: (context, s) {
                    final alert = s.alert;
                    if (alert == null) return const SizedBox.shrink();
                    return Positioned(
                      left: 12,
                      right: 12,
                      top: MediaQuery.paddingOf(context).top + 8,
                      child: _AlertCard(alert: alert, cubit: scope.cubit, deps: scope.deps, open: open),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.alert, required this.cubit, required this.deps, required this.open});

  final RingingAlert alert;
  final RadioCubit cubit;
  final RadioDeps deps;
  final void Function(String location) open;

  @override
  Widget build(BuildContext context) {
    final m = alert.message;
    final emergency = alert.emergency;
    final bg = emergency ? const Color(0xFFB3261E) : const Color(0xFFE0A019);
    final fg = emergency ? Colors.white : Colors.black;
    final title = emergency ? 'Emergencia: ${m.authorName} pidió ayuda' : '${m.authorName} te está llamando';
    final where = cubit.state.byId(m.conversationId)?.title;
    return Material(
      key: Key(emergency ? 'radio.alert.emergency' : 'radio.alert.call'),
      color: bg,
      elevation: 8,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
        child: DefaultTextStyle(
          style: TextStyle(color: fg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(emergency ? Icons.emergency : Icons.notifications_active, color: fg, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(color: fg, fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              if ((m.body ?? '').isNotEmpty && !emergency)
                Padding(padding: const EdgeInsets.only(top: 6, left: 40), child: Text(m.body!)),
              if (where != null && where != m.authorName)
                Padding(padding: const EdgeInsets.only(top: 4, left: 40), child: Text('En $where')),
              if (emergency)
                const Padding(
                  padding: EdgeInsets.only(top: 6, left: 40),
                  child: Text(
                    'Kyq ya avisó a su equipo de emergencias. Si puedes ayudar, ve con cuidado o llama al 123.',
                  ),
                ),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 4,
                children: [
                  TextButton(
                    key: const Key('radio.alert.dismiss'),
                    style: TextButton.styleFrom(foregroundColor: fg),
                    onPressed: cubit.dismissAlert,
                    child: const Text('Ahora no'),
                  ),
                  if (m.lat != null && m.lng != null)
                    TextButton(
                      key: const Key('radio.alert.map'),
                      style: TextButton.styleFrom(foregroundColor: fg),
                      onPressed: () {
                        cubit.dismissAlert();
                        openInNavigation(m.lat!, m.lng!, waze: false);
                      },
                      child: const Text('Ver ubicación'),
                    ),
                  FilledButton(
                    key: const Key('radio.alert.open'),
                    style: FilledButton.styleFrom(backgroundColor: fg, foregroundColor: bg),
                    onPressed: () {
                      cubit.dismissAlert();
                      open(RadioRoutes.conversation(m.conversationId));
                    },
                    child: const Text('Abrir'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
