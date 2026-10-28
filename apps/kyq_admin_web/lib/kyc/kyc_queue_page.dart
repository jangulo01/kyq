import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kyq_ui/kyq_ui.dart';

import 'kyc_cubits.dart';

/// Cola de validación de documentos, del envío más antiguo al más reciente (T023).
class KycQueuePage extends StatelessWidget {
  const KycQueuePage({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<KycQueueCubit>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Validación de documentos'),
        actions: [IconButton(tooltip: 'Recargar', icon: const Icon(Icons.refresh), onPressed: cubit.load)],
      ),
      body: BlocBuilder<KycQueueCubit, KycQueueState>(
        builder: (context, state) {
          if (state.loading && state.entries.isEmpty) return const Center(child: CircularProgressIndicator());
          if (state.error != null && state.entries.isEmpty) return Center(child: Text(state.error!));
          if (state.entries.isEmpty) return const Center(child: Text('No hay documentos por revisar.'));
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: state.entries.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final e = state.entries[i];
              final since = e.oldestSubmittedAt;
              return ListTile(
                key: Key('kyc.queue.${e.driverId}'),
                leading: CircleAvatar(child: Text('${i + 1}')),
                title: Text([e.displayName, ?e.vehiclePlate].join(' · ')),
                subtitle: Text(
                  '${e.pendingCount} ${e.pendingCount == 1 ? 'documento' : 'documentos'} por revisar'
                  '${since == null ? '' : ' · enviado el ${formatDate(since)}'}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  await context.push('/kyc/drivers/${e.driverId}');
                  await cubit.load();
                },
              );
            },
          );
        },
      ),
    );
  }
}
