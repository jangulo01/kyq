import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_ui/kyq_ui.dart';

import '../notices/notices_cubit.dart';
import '../onboarding/onboarding_cubit.dart';
import '../onboarding/onboarding_texts.dart';
import '../preconsult/preconsult_page.dart';
import '../presence/presence_cubit.dart';
import 'online_switch_card.dart';

/// Inicio del conductor: interruptor ONLINE, estado de la cuenta y del alta, avisos y accesos a
/// documentos, suscripción, QR y cartera.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<void> _refresh(BuildContext context) => Future.wait([
    context.read<PresenceCubit>().load(),
    context.read<OnboardingCubit>().load(),
    context.read<NoticesCubit>().load(),
  ]);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kyq Conductor'),
        actions: [
          BlocSelector<NoticesCubit, NoticesState, int>(
            selector: (s) => s.unread,
            builder: (context, unread) => IconButton(
              key: const Key('home.notices'),
              tooltip: 'Avisos',
              icon: Badge(
                isLabelVisible: unread > 0,
                label: Text('$unread', key: const Key('home.notices.badge')),
                child: const Icon(Icons.notifications_outlined),
              ),
              onPressed: () => context.push('/notices'),
            ),
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthCubit>().signOut(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _refresh(context),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Consulta de voz en curso de un cliente (005, RN-KYQ-010).
            const ActivePreconsultCard(),
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
                final onboarding = context.watch<OnboardingCubit>().state.status;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ActiveTripBanner(
                      load: context.read<KyqApiClient>().activeTrip,
                      onOpen: (trip) => context.push('/trip/${trip.id}', extra: trip),
                      // Pasar a ocupado o a libre es cuando aparece o termina un viaje.
                      refreshKey: state.presence,
                    ),
                    OnlineSwitchCard(
                      state: state,
                      // El backend decide si puede conectarse; aquí solo se explica el porqué.
                      blockedReason: me.canGoOnline
                          ? null
                          : onboardingBlockMessage(onboarding) ?? accountBlockMessage(me),
                    ),
                    const SizedBox(height: 8),
                    _AccountStatusCard(me: me, onboarding: onboarding),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                key: const Key('home.documents'),
                leading: const Icon(Icons.badge_outlined),
                title: const Text('Mis documentos'),
                subtitle: const Text('Estado de tus documentos y renovaciones'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/onboarding/documents'),
              ),
            ),
            Card(
              child: ListTile(
                key: const Key('home.subscription'),
                leading: const Icon(Icons.payments_outlined),
                title: const Text('Mi suscripción'),
                subtitle: const Text('Pagar, historial y en qué se va tu suscripción'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/subscription'),
              ),
            ),
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
            Card(
              child: ListTile(
                key: const Key('home.preconsults'),
                leading: const Icon(Icons.record_voice_over),
                title: const Text('Consultas de voz'),
                subtitle: const Text('Tus clientes te preguntan por voz antes de pedir el viaje'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/preconsults'),
              ),
            ),
            Card(
              child: ListTile(
                key: const Key('home.cooperative'),
                leading: const Icon(Icons.diversity_3),
                title: const Text('Mi cooperativa'),
                subtitle: const Text('Compañeros, solicitudes derivadas y canal de voz del grupo'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/cooperative'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountStatusCard extends StatelessWidget {
  const _AccountStatusCard({required this.me, required this.onboarding});

  final DriverMe me;
  final OnboardingStatus? onboarding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pendingOnboarding = onboardingBlockMessage(onboarding);
    final (icon, color, title, detail, route) = me.canGoOnline
        ? (
            Icons.check_circle,
            Colors.green,
            'Puedes trabajar',
            me.subscriptionStatus == SubscriptionStatus.gracePeriod
                ? 'Tu suscripción está en periodo de gracia. Renuévala pronto.'
                : 'Suscripción y documentos al día.',
            me.subscriptionStatus == SubscriptionStatus.gracePeriod ? '/subscription' : null,
          )
        : pendingOnboarding != null
        ? (
            onboarding == OnboardingStatus.inReview ? Icons.hourglass_top : Icons.description,
            onboarding == OnboardingStatus.inReview ? Colors.orange : scheme.error,
            onboarding == OnboardingStatus.inReview ? 'Documentos en revisión' : 'Documentos pendientes',
            pendingOnboarding,
            '/onboarding/documents',
          )
        : (me.blockReason ?? '').startsWith('subscription')
        ? (
            Icons.block,
            scheme.error,
            me.blockReason == 'subscription_suspended' ? 'Suscripción suspendida' : 'Suscripción sin pagar',
            'Paga tu mensualidad para volver a recibir viajes.',
            '/subscription',
          )
        : (Icons.description, scheme.error, 'Documentos pendientes', accountBlockMessage(me), '/onboarding/documents');
    return Card(
      child: ListTile(
        key: const Key('home.account'),
        leading: Icon(icon, color: color, size: 32),
        title: Text(title),
        subtitle: Text(detail),
        trailing: route == null ? null : const Icon(Icons.chevron_right),
        onTap: route == null ? null : () => context.push(route),
      ),
    );
  }
}
