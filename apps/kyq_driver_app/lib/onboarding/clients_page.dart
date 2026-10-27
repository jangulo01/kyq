import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kyq_api/kyq_api.dart';

/// Cartera de pasajeros que guardaron al conductor (FR-007, RN-KYQ-005).
class ClientsPage extends StatefulWidget {
  const ClientsPage({super.key});

  @override
  State<ClientsPage> createState() => _ClientsPageState();
}

class _ClientsPageState extends State<ClientsPage> {
  late Future<List<DriverClient>> _clients = context.read<KyqApiClient>().driverClients();

  Future<void> _reload() async {
    setState(() => _clients = context.read<KyqApiClient>().driverClients());
    await _clients;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis clientes')),
      body: FutureBuilder<List<DriverClient>>(
        future: _clients,
        builder: (context, snap) {
          if (snap.hasError) return const Center(child: Text('No pudimos cargar tus clientes.'));
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final clients = snap.data!;
          return RefreshIndicator(
            onRefresh: _reload,
            child: clients.isEmpty
                ? ListView(
                    padding: const EdgeInsets.all(32),
                    children: const [
                      Text(
                        'Aún nadie te ha guardado. Muestra tu código QR a tus pasajeros.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  )
                : ListView.separated(
                    itemCount: clients.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final c = clients[i];
                      final d = c.affiliatedAt.toLocal();
                      return ListTile(
                        leading: CircleAvatar(child: Text(c.displayName.characters.first.toUpperCase())),
                        title: Text(c.displayName),
                        subtitle: Text('Te guardó el ${d.day}/${d.month}/${d.year}'),
                      );
                    },
                  ),
          );
        },
      ),
    );
  }
}
