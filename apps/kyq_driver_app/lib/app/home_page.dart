import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_ui/kyq_ui.dart';

import '../presence/presence_cubit.dart';
import 'online_switch_card.dart';

/// Inicio del conductor: interruptor ONLINE, estado de la cuenta y accesos a su QR y su cartera.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kyq Conductor'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthCubit>().signOut(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: context.read<PresenceCubit>().load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            BlocBuilder<PresenceCubit, PresenceState>(
              builder: (context, state) {
                final me = state.me;
                if (me == null) {
                  if (state.loadFailed) {
                    return const Card(
                      child: ListTile(title: Text('No pudimos cargar tu cuenta. Desliza para reintentar.')),
                    );
                  }
                  return const Center(child: CircularProgressIndicator());
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    OnlineSwitchCard(state: state),
                    const SizedBox(height: 8),
                    _AccountStatusCard(me: me),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.qr_code_2),
                title: const Text('Mi código QR'),
                subtitle: const Text('Tus clientes lo escanean para guardarte como su conductor'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/qr'),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.groups),
                title: const Text('Mis clientes'),
                subtitle: const Text('Pasajeros que te guardaron'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/clients'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountStatusCard extends StatelessWidget {
  const _AccountStatusCard({required this.me});

  final DriverMe me;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (icon, color, title, detail) = me.canGoOnline
        ? (
            Icons.check_circle,
            Colors.green,
            'Puedes trabajar',
            me.subscriptionStatus == SubscriptionStatus.gracePeriod
                ? 'Tu suscripción está en periodo de gracia. Renuévala pronto.'
                : 'Suscripción y documentos al día.',
          )
        : switch (me.blockReason) {
            'subscription_suspended' => (
              Icons.block,
              scheme.error,
              'Suscripción suspendida',
              'Paga tu mensualidad para volver a recibir viajes.',
            ),
            _ => (
              Icons.description,
              scheme.error,
              'Documentos pendientes',
              'Algún documento obligatorio falta o venció. Contacta a Kyq.',
            ),
          };
    return Card(
      child: ListTile(
        leading: Icon(icon, color: color, size: 32),
        title: Text(title),
        subtitle: Text(detail),
      ),
    );
  }
}
