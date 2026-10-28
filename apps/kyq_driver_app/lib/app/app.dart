import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kyq_api/kyq_api.dart';
import 'package:kyq_ptt/kyq_ptt.dart';
import 'package:kyq_radio/kyq_radio.dart';
import 'package:kyq_realtime/kyq_realtime.dart';
import 'package:kyq_ui/kyq_ui.dart';

import '../onboarding/client_card_page.dart';
import '../reservations/agenda_cubit.dart';
import '../reservations/agenda_page.dart';
import '../megaphone/megaphone_banner.dart';
import '../megaphone/megaphone_cubit.dart';
import '../dispatch/dispatch_settings_cubit.dart';
import '../dispatch/dispatch_settings_page.dart';
import '../background/location_reporter.dart';
import '../handsfree/hands_free_settings_cubit.dart';
import '../cooperative/cooperative_channel_page.dart';
import '../cooperative/cooperative_cubit.dart';
import '../cooperative/cooperative_page.dart';
import '../notices/notices_cubit.dart';
import '../notices/notices_page.dart';
import '../offers/offer_cubit.dart';
import '../offers/offer_page.dart';
import '../onboarding/clients_page.dart';
import '../onboarding/document_capture_cubit.dart';
import '../onboarding/document_capture_page.dart';
import '../onboarding/documents_page.dart';
import '../onboarding/my_qr_page.dart';
import '../onboarding/onboarding_cubit.dart';
import '../onboarding/vehicle_page.dart';
import '../preconsult/preconsult_cubit.dart';
import '../preconsult/preconsult_page.dart';
import '../preconsult/preconsult_settings_cubit.dart';
import '../preconsult/preconsult_settings_page.dart';
import '../presence/presence_cubit.dart';
import '../radio/radio_mount.dart';
import '../realtime/driver_events.dart';
import '../subscription/subscription_cubit.dart';
import '../subscription/subscription_page.dart';
import '../trip/trip_cubit.dart';
import '../trip/trip_page.dart';
import '../trip_payments/trip_payment_cubit.dart';
import '../trip_payments/trip_payments_cubit.dart';
import '../trip_payments/trip_payments_page.dart';
import 'driver_services.dart';
import 'home_page.dart';

/// URL del backend. En el emulador de Android, 10.0.2.2 es el localhost del PC.
const apiBaseUrl = String.fromEnvironment('KYQ_API_URL', defaultValue: 'http://10.0.2.2:8080');

/// WebSocket de Centrifugo.
const realtimeUrl = String.fromEnvironment(
  'KYQ_REALTIME_URL',
  defaultValue: 'ws://192.168.1.66:8000/connection/websocket',
);

/// Crea el cliente, la sesión con almacenamiento seguro y los servicios de plataforma.
/// Con [domains] (009) usa los dominios espejo: la API rota sola y el tiempo real toma el
/// dominio en uso al abrir la app.
({KyqApiClient api, AuthCubit auth, DriverServices services}) bootstrap({
  TokenStore? tokenStore,
  DomainRotator? domains,
}) {
  late final AuthCubit auth;
  final api = KyqApiClient(
    baseUrl: apiBaseUrl,
    tokenStore: tokenStore ?? SecureTokenStore(),
    onSessionExpired: () => auth.sessionExpired(),
    onSupportOnly: () => auth.supportOnly(),
  );
  if (domains != null) useDomains(api, domains);
  auth = AuthCubit(
    api,
    allowedRoles: {UserRole.driver},
    wrongRoleMessage: 'Esta app es para conductores. Usa Kyq Pasajero.',
    // "Soy conductor": un teléfono nuevo se registra como conductor (FR-001).
    signUpRole: UserRole.driver,
  )..start();
  final realtime = KyqRealtime(
    url: domains?.current.realtimeUrl ?? realtimeUrl,
    connectionToken: api.realtimeToken,
    subscriptionToken: api.subscriptionToken,
  );
  return (api: api, auth: auth, services: DriverServices.platform(KyqRealtimeEventSource(realtime)));
}

class KyqDriverApp extends StatefulWidget {
  const KyqDriverApp({super.key, required this.api, required this.auth, required this.services});

  final KyqApiClient api;
  final AuthCubit auth;
  final DriverServices services;

  @override
  State<KyqDriverApp> createState() => _KyqDriverAppState();
}

class _KyqDriverAppState extends State<KyqDriverApp> {
  final _messenger = GlobalKey<ScaffoldMessengerState>();
  late final DriverEvents _events = DriverEvents(widget.services.events);
  late final OfferCubit _offers = OfferCubit(widget.api, _events.stream);
  // 009: comunicados de Kyq por zona; esperan a que termine la voz del viaje.
  late final MegaphoneCubit _megaphone = MegaphoneCubit(_events.stream, room: widget.services.megaphoneRoom);
  late final PresenceCubit _presence = PresenceCubit(
    api: widget.api,
    events: _events,
    permissions: widget.services.permissions,
    service: widget.services.onlineService,
    reporter: LocationReporter(
      source: widget.services.positions,
      sink: (fix) => widget.api.sendLocation(
        GeoPoint(lat: fix.lat, lng: fix.lng),
        heading: fix.heading,
        speedMps: fix.speedMps,
        recordedAt: fix.recordedAt,
        accuracyM: fix.accuracyM,
      ),
      onError: (e) => debugPrint('Ubicación: $e'),
    ),
  );
  late final OnboardingCubit _onboarding = OnboardingCubit(widget.api);
  late final NoticesCubit _notices = NoticesCubit(widget.api, _events.stream, onNotice: _onNotice);
  // 005: botón físico y burbuja para el canal abierto, y pre-consultas de voz.
  late final HandsFreePtt _handsFree = HandsFreePtt(widget.services.handsFree);
  late final HandsFreeSettingsCubit _handsFreeSettings = HandsFreeSettingsCubit(
    store: widget.services.handsFreePrefs,
    overlay: widget.services.overlayPermission,
    handsFree: _handsFree,
  );
  late final PreconsultCubit _preconsults = PreconsultCubit(
    api: widget.api,
    events: _events.stream,
    ptt: widget.services.preconsultPtt,
    handsFree: _handsFree,
  );
  // 011: Radio Kyq; arranca al conocer la cuenta y escucha aunque se cambie de pantalla.
  late final RadioMount _radio = RadioMount(
    api: widget.services.radioApi ?? widget.api,
    events: _events.stream,
    factory: widget.services.radio,
    newPlayer: widget.services.radioPlayer,
    location: PositionRadioLocation(widget.services.positions),
    onShareLink: shareWithPlatform,
  );
  late final StreamSubscription<PresenceState> _presenceSub;
  late final AppLifecycleListener _lifecycle;
  late final StreamSubscription<AuthState> _authSub;
  late final StreamSubscription<OnboardingStatus?> _onboardingSub;

  late final GoRouter _router = buildAuthRouter(
    auth: widget.auth,
    title: 'Kyq Conductor',
    // 009: Ayuda, y lo único que ve una cuenta suspendida.
    withSupport: true,
    subtitle: 'Soy conductor',
    newAccountHint: 'Crearemos tu cuenta de conductor. Luego te pediremos tu vehículo y tus documentos.',
    // 011: kyq://radio/{code} y …/r/{code} abren la invitación de Radio.
    guard: (context, state) => radioDeepLinkRedirect(state.uri) ?? _onboardingRedirect(state.matchedLocation),
    routes: [
      GoRoute(path: '/onboarding/vehicle', builder: (context, state) => const VehiclePage()),
      GoRoute(
        path: '/onboarding/documents',
        builder: (context, state) => const DocumentsPage(),
        routes: [
          GoRoute(
            path: ':type',
            builder: (context, state) {
              final type = DocType.values.firstWhere(
                (t) => docTypeToApi(t) == state.pathParameters['type'],
                orElse: () => DocType.nationalId,
              );
              return BlocProvider(
                create: (_) => DocumentCaptureCubit(
                  api: widget.api,
                  photos: widget.services.photos,
                  scanner: widget.services.scanner,
                  docType: type,
                  onSubmitted: _onboarding.load,
                ),
                child: DocumentCapturePage(rejectReason: state.extra is String ? state.extra! as String : null),
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const HomePage(),
        routes: [
          GoRoute(path: 'qr', builder: (context, state) => const MyQrPage()),
          radioRoute(scope: _radio.wrap),
          GoRoute(
            path: 'clients',
            builder: (context, state) => const ClientsPage(),
            routes: [
              // 010: ficha del cliente con nota privada.
              GoRoute(
                path: ':id',
                builder: (context, state) => ClientCardPage(passengerId: state.pathParameters['id']!),
              ),
            ],
          ),
          // 010: agenda de reservas.
          GoRoute(
            path: 'agenda',
            builder: (context, state) =>
                BlocProvider(create: (_) => AgendaCubit(widget.api, _events.stream)..load(), child: const AgendaPage()),
          ),
          GoRoute(
            path: 'dispatch',
            builder: (context, state) => BlocProvider(
              create: (_) => DispatchSettingsCubit(widget.api)..load(),
              child: const DispatchSettingsPage(),
            ),
          ),
          GoRoute(path: 'notices', builder: (context, state) => const NoticesPage()),
          GoRoute(
            path: 'preconsults',
            builder: (context, state) => const PreconsultPage(),
            routes: [
              GoRoute(
                path: 'settings',
                builder: (context, state) => BlocProvider(
                  create: (_) => PreconsultSettingsCubit(widget.api)..load(),
                  child: const PreconsultSettingsPage(),
                ),
              ),
            ],
          ),
          GoRoute(
            path: 'cooperative',
            builder: (context, state) => BlocProvider(
              create: (_) => CooperativeCubit(widget.api, _events.stream)..load(),
              child: const CooperativePage(),
            ),
            routes: [
              GoRoute(
                path: 'channel',
                builder: (context, state) => BlocProvider(
                  create: (_) => widget.services.cooperativePtt(widget.api),
                  child: Builder(
                    builder: (context) => CooperativeChannelPage(
                      controller: context.read<PttController>(),
                      members: state.extra is List<CooperativeMember>
                          ? state.extra! as List<CooperativeMember>
                          : const [],
                    ),
                  ),
                ),
              ),
            ],
          ),
          GoRoute(
            path: 'safety',
            builder: (context, state) =>
                BlocProvider(create: (_) => SafetyCubit(widget.api)..load(), child: const SafetyPage()),
          ),
          GoRoute(
            path: 'trip-payments',
            builder: (context, state) =>
                BlocProvider(create: (_) => TripPaymentsCubit(widget.api)..load(), child: const TripPaymentsPage()),
          ),
          GoRoute(
            path: 'subscription',
            builder: (context, state) => BlocProvider(
              create: (_) => SubscriptionCubit(
                widget.api,
                widget.services.checkout,
                onApproved: () => unawaited(_presence.refreshMe()),
              )..load(),
              child: const SubscriptionPage(),
            ),
          ),
          GoRoute(path: 'offer', builder: (context, state) => const OfferPage()),
          GoRoute(
            path: 'trip/:id',
            builder: (context, state) {
              final tripId = state.pathParameters['id']!;
              return MultiBlocProvider(
                providers: [
                  BlocProvider(
                    create: (_) {
                      final initial = state.extra is Trip ? state.extra! as Trip : null;
                      final cubit = TripCubit(widget.api, _events.stream, tripId, initial: initial);
                      unawaited(cubit.refresh());
                      return cubit;
                    },
                  ),
                  BlocProvider(
                    create: (_) => widget.services.ptt(
                      widget.api,
                      tripId,
                      _events.stream.where((e) => e is PttClosed && e.tripId == tripId),
                    ),
                  ),
                  // SOS del conductor (003): el pasajero no ve nada de la alerta (FR-006).
                  BlocProvider(create: (_) => widget.services.safety.sosFor(widget.api, tripId)),
                  // Pago del viaje (004): existe desde que el viaje se completa.
                  BlocProvider(create: (_) => TripPaymentCubit(widget.api, _events.stream, tripId)..load()),
                ],
                child: Builder(
                  builder: (context) => BlocListener<TripCubit, TripState>(
                    listenWhen: (a, b) =>
                        a.trip?.status != TripStatus.completed && b.trip?.status == TripStatus.completed,
                    listener: (context, _) => context.read<TripPaymentCubit>().load(),
                    // El botón físico y la burbuja hablan por el canal del viaje (RN-KYQ-012).
                    child: HandsFreeAttachment(
                      handsFree: _handsFree,
                      controller: context.read<PttController>(),
                      child: TripPage(
                        ptt: context.read<PttController>(),
                        payments: true,
                        safety: TripSafety(
                          api: widget.api,
                          tripId: tripId,
                          sos: context.read<SosCubit>(),
                          platform: widget.services.safety,
                          onSetupPin: () => context.push('/safety'),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    ],
  );

  @override
  void initState() {
    super.initState();
    _authSub = widget.auth.stream.listen(_onAuth);
    _presenceSub = _presence.stream.listen((s) {
      if (s.me case final me?) _radio.start(me.driverId);
    });
    _lifecycle = AppLifecycleListener(onStateChange: _onLifecycle);
    unawaited(_handsFreeSettings.load());
    // Sin refreshListenable: refrescar el router reconstruye las páginas apiladas (un viaje, una
    // captura a medias). Basta con salir del inicio cuando el alta queda pendiente.
    _onboardingSub = _onboarding.stream.map((s) => s.status).distinct().listen((_) {
      final target = _onboardingRedirect(_router.routerDelegate.currentConfiguration.uri.path);
      if (target != null && _router.routerDelegate.currentConfiguration.uri.path == '/') _router.go(target);
    });
    _onAuth(widget.auth.state);
  }

  void _onAuth(AuthState state) {
    switch (state) {
      case AuthSignedIn():
        if (_presence.state.me == null && !_presence.state.loading) unawaited(_presence.load());
        if (_onboarding.state.onboarding == null && !_onboarding.state.loading) unawaited(_onboarding.load());
        unawaited(_notices.load());
        unawaited(_preconsults.load());
      case AuthSignedOut():
        if (_presence.state.me != null) unawaited(_presence.reset());
        _onboarding.reset();
        _notices.reset();
        unawaited(_radio.stop());
      default:
        break;
    }
  }

  /// La burbuja solo se muestra con Kyq en segundo plano (FR-014); al volver se revisa el permiso.
  void _onLifecycle(AppLifecycleState state) {
    final foreground = state == AppLifecycleState.resumed;
    _handsFree.setForeground(foreground);
    if (foreground) unawaited(_handsFreeSettings.refreshPermission());
  }

  /// Alta sin terminar (T018): sin vehículo → vehículo; documentos pendientes → documentos. En
  /// revisión o al día se deja usar el inicio, que explica por qué aún no puede conectarse.
  /// Nunca durante un viaje u oferta: no se interrumpe un viaje en curso (RN-KYQ-003).
  String? _onboardingRedirect(String location) {
    if (location.startsWith('/trip') || location.startsWith('/offer')) return null;
    return switch (_onboarding.state.status) {
      OnboardingStatus.profileIncomplete when location != '/onboarding/vehicle' => '/onboarding/vehicle',
      OnboardingStatus.documentsPending when !location.startsWith('/onboarding') => '/onboarding/documents',
      _ => null,
    };
  }

  /// Un aviso en vivo suele acompañar un cambio de estado: se recarga lo que depende de él.
  void _onNotice(Notice notice) {
    if (notice.kind.startsWith('doc_')) unawaited(_onboarding.load());
    unawaited(_presence.refreshMe());
    final route = noticeRoute(notice.kind);
    _messenger.currentState?.showSnackBar(
      SnackBar(
        content: Text(notice.title),
        action: route == null ? null : SnackBarAction(label: 'Ver', onPressed: () => _router.push(route)),
      ),
    );
  }

  void _onOffer(BuildContext context, OfferState state) {
    switch (state) {
      case OfferShown():
        _router.go('/offer');
      case OfferTaken(:final trip):
        _router.go('/trip/${trip.id}', extra: trip);
      case OfferIdle(:final notice):
        if (_router.routerDelegate.currentConfiguration.uri.path == '/offer') _router.go('/');
        if (notice != null) _messenger.currentState?.showSnackBar(SnackBar(content: Text(notice)));
    }
  }

  @override
  void dispose() {
    _authSub.cancel();
    _presenceSub.cancel();
    unawaited(_radio.dispose());
    _router.dispose();
    _onboardingSub.cancel();
    _offers.close();
    _megaphone.close();
    _presence.close();
    _onboarding.close();
    _notices.close();
    _lifecycle.dispose();
    _preconsults.close();
    _handsFreeSettings.close();
    _handsFree.dispose();
    _events.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: widget.api),
        RepositoryProvider.value(value: _events),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: widget.auth),
          BlocProvider.value(value: _presence),
          BlocProvider.value(value: _offers),
          BlocProvider.value(value: _megaphone),
          BlocProvider.value(value: _onboarding),
          BlocProvider.value(value: _notices),
          BlocProvider.value(value: _preconsults),
          BlocProvider.value(value: _handsFreeSettings),
        ],
        child: MaterialApp.router(
          title: 'Kyq Conductor',
          theme: kyqTheme(),
          routerConfig: _router,
          scaffoldMessengerKey: _messenger,
          builder: (context, child) => MegaphoneBanner(
            child: MultiBlocListener(
              listeners: [
                BlocListener<OfferCubit, OfferState>(
                  bloc: _offers,
                  listenWhen: (a, b) => a.runtimeType != b.runtimeType,
                  listener: _onOffer,
                ),
                // Motivo de cierre de una consulta de voz (005).
                BlocListener<PreconsultCubit, PreconsultState>(
                  bloc: _preconsults,
                  listenWhen: (a, b) => b.notice != null && a.notice != b.notice,
                  listener: (context, s) => _messenger.currentState?.showSnackBar(SnackBar(content: Text(s.notice!))),
                ),
              ],
              child: child!,
            ),
          ),
        ),
      ),
    );
  }
}
