import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_ui/kyq_ui.dart';

/// Inicio del conductor: estado de la cuenta y accesos a su QR y su cartera.
/// El interruptor ONLINE llega con US2.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<DriverMe> _me = context.read<KyqApiClient>().driverMe();

  Future<void> _reload() async {
    setState(() => _me = context.read<KyqApiClient>().driverMe());
    await _me;
  }

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
        onRefresh: _reload,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            FutureBuilder<DriverMe>(
              future: _me,
              builder: (context, snap) {
                if (snap.hasError) {
                  return const Card(
                    child: ListTile(title: Text('No pudimos cargar tu cuenta. Desliza para reintentar.')),
                  );
                }
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                return _AccountStatusCard(me: snap.data!);
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
