import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_ui/kyq_ui.dart';

import 'onboarding_cubit.dart';
import 'onboarding_texts.dart';

/// Un documento aprobado se puede renovar desde este margen antes de vencer (FR-007).
const renewWindow = Duration(days: 30);

/// Puede enviar (o reenviar) este documento: falta, fue rechazado, venció o vence pronto. Si
/// hay uno en revisión, se espera a que lo revisen.
bool canSubmitDocument(OnboardingDocument d, {DateTime? now}) {
  final latest = d.latest ?? d.current;
  if (latest == null) return true;
  return switch (latest.status) {
    DocumentStatus.submitted => false,
    DocumentStatus.uploading || DocumentStatus.rejected => true,
    DocumentStatus.approved || DocumentStatus.superseded =>
      latest.legacy ||
          latest.expired ||
          switch (latest.expiresAt ?? latest.exemptUntil) {
            final until? => until.difference(now ?? DateTime.now()) < renewWindow,
            null => false,
          },
  };
}

/// Lista de documentos con su estado y motivo de rechazo (T017).
class DocumentsPage extends StatelessWidget {
  const DocumentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OnboardingCubit>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis documentos'),
        actions: [
          if (!context.canPop())
            IconButton(
              tooltip: 'Cerrar sesión',
              icon: const Icon(Icons.logout),
              onPressed: () => context.read<AuthCubit>().signOut(),
            ),
        ],
      ),
      body: BlocBuilder<OnboardingCubit, OnboardingState>(
        builder: (context, state) {
          final onboarding = state.onboarding;
          if (onboarding == null) {
            return state.loadFailed
                ? Center(
                    child: TextButton(onPressed: cubit.load, child: const Text('No pudimos cargar. Reintentar')),
                  )
                : const Center(child: CircularProgressIndicator());
          }
          final vehicle = onboarding.vehicle;
          final message = onboardingBlockMessage(onboarding.status);
          return RefreshIndicator(
            onRefresh: cubit.load,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (message != null)
                  Card(
                    key: const Key('documents.status'),
                    child: ListTile(
                      leading: Icon(
                        onboarding.status == OnboardingStatus.inReview ? Icons.hourglass_top : Icons.info_outline,
                      ),
                      title: Text(message),
                    ),
                  ),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.directions_car),
                    title: Text(vehicle?.plate ?? 'Vehículo'),
                    subtitle: Text(
                      [vehicle?.brand, vehicle?.model, vehicle?.color, vehicle?.year?.toString()].nonNulls.join(' · '),
                    ),
                    trailing: TextButton(
                      onPressed: () => context.push('/onboarding/vehicle'),
                      child: const Text('Editar'),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                for (final d in state.documents) _DocumentTile(document: d),
                if (onboarding.status == OnboardingStatus.inReview ||
                    onboarding.status == OnboardingStatus.documentsOk) ...[
                  const SizedBox(height: 16),
                  if (!context.canPop())
                    FilledButton(onPressed: () => context.go('/'), child: const Text('Ir al inicio')),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DocumentTile extends StatelessWidget {
  const _DocumentTile({required this.document});

  final OnboardingDocument document;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (:label, :state) = documentStatusLabel(document);
    final (icon, color) = switch (state) {
      DocumentVisualState.missing => (Icons.upload_file, scheme.outline),
      DocumentVisualState.waiting => (Icons.hourglass_top, Colors.orange),
      DocumentVisualState.ok => (Icons.check_circle, Colors.green),
      DocumentVisualState.bad => (Icons.error, scheme.error),
    };
    final latest = document.latest;
    final current = document.current;
    final lines = <String>[
      label,
      if (latest?.status == DocumentStatus.rejected && latest?.rejectReason != null) 'Motivo: ${latest!.rejectReason}',
      if (current?.expiresAt != null && current?.status == DocumentStatus.approved)
        '${current!.expired ? 'Venció' : 'Vence'} el ${formatDate(current.expiresAt!)}',
      if (current?.legacy ?? false) 'Lo tenemos de tu registro anterior, sin foto: súbelo para no perderlo.',
      if (current?.exemptUntil != null) 'No se exige hasta el ${formatDate(current!.exemptUntil!)}',
      if (document.suggestSupport) 'Lo hemos rechazado varias veces: escríbenos a soporte y te ayudamos.',
      // Mientras revisan el reenvío, el aprobado anterior sigue sirviendo (FR-007).
      if (latest != null && current != null && latest.id != current.id && latest.status == DocumentStatus.submitted)
        'Sigues trabajando con el anterior mientras revisamos el nuevo.',
    ];
    final canSubmit = canSubmitDocument(document);
    return Card(
      child: ListTile(
        key: Key('documents.${docTypeToApi(document.docType)}'),
        leading: Icon(icon, color: color),
        title: Text(docTypeLabel(document.docType)),
        subtitle: Text(lines.join('\n')),
        isThreeLine: lines.length > 1,
        trailing: canSubmit ? const Icon(Icons.chevron_right) : null,
        onTap: canSubmit
            ? () => context.push(
                '/onboarding/documents/${docTypeToApi(document.docType)}',
                extra: latest?.status == DocumentStatus.rejected ? latest?.rejectReason : null,
              )
            : null,
      ),
    );
  }
}
