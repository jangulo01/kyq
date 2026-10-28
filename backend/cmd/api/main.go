// Command api runs the Kyq modular monolith HTTP server.
package main

import (
	"context"
	"errors"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"strings"
	"syscall"
	"time"

	"github.com/kyq/backend/internal/admin"
	"github.com/kyq/backend/internal/affiliations"
	"github.com/kyq/backend/internal/auth"
	"github.com/kyq/backend/internal/billing"
	"github.com/kyq/backend/internal/config"
	"github.com/kyq/backend/internal/control"
	"github.com/kyq/backend/internal/cooperatives"
	"github.com/kyq/backend/internal/crm"
	"github.com/kyq/backend/internal/domains"
	"github.com/kyq/backend/internal/drivers"
	"github.com/kyq/backend/internal/fares"
	"github.com/kyq/backend/internal/health"
	"github.com/kyq/backend/internal/httpapi"
	"github.com/kyq/backend/internal/kyc"
	"github.com/kyq/backend/internal/megaphone"
	"github.com/kyq/backend/internal/notify"
	"github.com/kyq/backend/internal/observability"
	"github.com/kyq/backend/internal/places"
	"github.com/kyq/backend/internal/ptt"
	"github.com/kyq/backend/internal/radio"
	"github.com/kyq/backend/internal/realtime"
	"github.com/kyq/backend/internal/reservations"
	"github.com/kyq/backend/internal/safety"
	"github.com/kyq/backend/internal/storage"
	"github.com/kyq/backend/internal/store"
	"github.com/kyq/backend/internal/support"
	"github.com/kyq/backend/internal/telemetry"
	"github.com/kyq/backend/internal/trippay"
	"github.com/kyq/backend/internal/trips"
)

func main() {
	logger := slog.New(slog.NewJSONHandler(os.Stdout, nil))
	slog.SetDefault(logger)
	if err := run(logger); err != nil {
		logger.Error("api stopped", "err", err)
		os.Exit(1)
	}
}

func run(logger *slog.Logger) error {
	cfg, err := config.Load()
	if err != nil {
		return err
	}

	flush, err := observability.Init(observability.Options{DSN: cfg.SentryDSN, Environment: cfg.SentryEnvironment, Release: "kyq-api"})
	if err != nil {
		return err
	}
	defer flush()

	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	st, err := store.Open(ctx, cfg.DatabaseURL)
	if err != nil {
		return err
	}
	defer st.Close()

	var otp auth.OTPSender
	if cfg.UsesDevOTP() {
		logger.Warn("OTP de desarrollo activo: no se envían SMS (KYQ_DEV_OTP_CODE)")
		otp = auth.DevOTP{Code: cfg.DevOTPCode}
	} else {
		otp = auth.TwilioVerify{
			AccountSID: cfg.TwilioAccountSID, AuthToken: cfg.TwilioAuthToken, ServiceSID: cfg.TwilioVerifyServiceSID,
		}
	}

	tokens := auth.NewTokenIssuer(cfg.JWTSecret, nil)
	affils := affiliations.NewService(affiliations.NewPgRepo(st.Queries))
	affils.Eligibility = drivers.Eligibility{Store: st}
	publisher := &realtime.Client{APIURL: cfg.CentrifugoAPIURL, APIKey: cfg.CentrifugoAPIKey}
	routes := fares.OSRM{BaseURL: cfg.OSRMURL}
	usage := &telemetry.Recorder{Store: st, Logger: logger}
	go usage.Run(ctx, 30*time.Second)
	tripService := &trips.Service{Store: st, Routes: routes, Publisher: publisher, Usage: usage, CityCode: cfg.CityCode, Logger: logger}
	apiURL := cfg.LiveKitAPIURL
	if apiURL == "" {
		apiURL = ptt.APIURLFrom(cfg.LiveKitURL)
	}
	livekit := ptt.LiveKit{APIURL: apiURL, APIKey: cfg.LiveKitAPIKey, APISecret: cfg.LiveKitAPISecret}
	pttService := &ptt.Service{
		Store: st, LiveKit: livekit, Rooms: livekit, Groups: livekit, PublicURL: cfg.LiveKitURL, Publisher: publisher, Usage: usage, Logger: logger,
	}
	go pttService.RunSweeper(ctx, time.Second)
	coopService := &cooperatives.Service{Store: st, Publisher: publisher, Group: pttService, Usage: usage, Logger: logger}

	objects, err := storage.NewS3(storage.S3Options{
		Endpoint: cfg.S3Endpoint, PublicEndpoint: cfg.S3PublicEndpoint, AccessKey: cfg.S3AccessKey,
		SecretKey: cfg.S3SecretKey, Bucket: cfg.S3Bucket, Region: cfg.S3Region,
	})
	if err != nil {
		return err
	}
	// El job minio-init crea el bucket; esto cubre arranques sin él (R2 o desarrollo local).
	bucketCtx, cancelBucket := context.WithTimeout(ctx, 10*time.Second)
	if err := objects.EnsureBucket(bucketCtx); err != nil {
		logger.Warn("bucket de documentos no disponible al arrancar", "err", err)
	}
	cancelBucket()

	var sms notify.SMSSender = notify.LogSMS{Logger: logger}
	switch {
	case cfg.UsesDevOTP():
	case cfg.TwilioSMSFrom != "":
		sms = notify.TwilioSMS{AccountSID: cfg.TwilioAccountSID, AuthToken: cfg.TwilioAuthToken, From: cfg.TwilioSMSFrom}
	default:
		logger.Warn("KYQ_TWILIO_SMS_FROM vacío: los avisos por SMS solo se registran")
	}
	notices := &notify.Service{Store: st, Publisher: publisher, SMS: sms, Logger: logger}
	go notices.RunSweeper(ctx, time.Minute)
	kycService := &kyc.Service{Store: st, Objects: objects, Notify: notices, Logger: logger}
	go kycService.RunExpirySweeper(ctx, time.Minute)
	billingService := &billing.Service{
		Store: st, Notify: notices, CityCode: cfg.CityCode, WebhookSecret: cfg.BoldWebhookSecret(), Logger: logger,
	}
	if cfg.BoldEnabled() {
		logger.Info("pagos con Bold activos", "env", cfg.BoldEnv)
		billingService.Bold = &billing.BoldClient{BaseURL: cfg.BoldAPIURL, IdentityKey: cfg.BoldIdentityKey}
	} else {
		logger.Warn("KYQ_BOLD_ENV vacío: pagos con Bold desactivados")
	}
	go billingService.RunSweeper(ctx, 10*time.Second, time.Minute)
	// 007: aviso en vivo de la torre (como mucho uno cada 3 s y solo si algo cambió).
	towerNotifier := &control.Notifier{Source: st.Queries, Publisher: publisher, Logger: logger}
	go towerNotifier.Run(ctx, 3*time.Second)
	probeClient := &http.Client{Timeout: health.Timeout}
	// 009: sesiones sin fallos desde Sentry (sin token: "no configurado").
	sentryProjects, err := health.ParseProjects(cfg.SentryProjects)
	if err != nil {
		return err
	}
	sentrySessions := &health.Sessions{
		APIURL: cfg.SentryAPIURL, Token: cfg.SentryAPIToken, Org: cfg.SentryOrg, Projects: sentryProjects,
		HTTP: &http.Client{Timeout: health.SessionsTimeout},
	}
	cityLat, cityLng := health.CityCenter(cfg.CityCode)
	checker := &health.Checker{Probes: []health.Named{
		{Name: health.Database, Probe: health.DatabaseProbe(st.Pool)},
		{Name: health.Centrifugo, Probe: health.CentrifugoProbe(probeClient, cfg.CentrifugoAPIURL, cfg.CentrifugoAPIKey)},
		{Name: health.LiveKit, Probe: health.LiveKitProbe(probeClient, apiURL)},
		{Name: health.OSRM, Probe: health.OSRMProbe(probeClient, cfg.OSRMURL, cityLat, cityLng)},
		{Name: health.Storage, Probe: health.StorageProbe(objects)},
		{Name: health.Bold, Probe: health.BoldProbe(probeClient, cfg.BoldEnabled(), cfg.BoldAPIURL, cfg.BoldIdentityKey)},
	}}

	// 003: grabaciones SOS en su propio bucket privado (expira a los 90 días, research R4).
	recordings, err := storage.NewS3(storage.S3Options{
		Endpoint: cfg.S3Endpoint, PublicEndpoint: cfg.S3PublicEndpoint, AccessKey: cfg.S3AccessKey,
		SecretKey: cfg.S3SecretKey, Bucket: cfg.S3SOSBucket, Region: cfg.S3Region,
	})
	if err != nil {
		return err
	}
	// El job minio-init crea el bucket; la expiración de 90 días la fija la API (idempotente).
	sosCtx, cancelSOS := context.WithTimeout(ctx, 10*time.Second)
	if err := recordings.EnsureBucket(sosCtx); err != nil {
		logger.Warn("bucket de grabaciones SOS no disponible al arrancar", "err", err)
	} else if err := recordings.EnsureExpiry(sosCtx, 90); err != nil {
		logger.Warn("no se pudo fijar la expiración de 90 días de las grabaciones SOS", "err", err)
	}
	cancelSOS()
	if !cfg.SOSRecording {
		logger.Warn("KYQ_SOS_RECORDING=false: las alertas SOS no se graban")
	}
	safetyService := &safety.Service{
		Store: st, LiveKit: livekit, Voice: livekit, VoiceURL: cfg.LiveKitURL, Publisher: publisher, SMS: sms,
		Recordings: recordings, Record: cfg.SOSRecording, PublicBaseURL: cfg.PublicBaseURL, Usage: usage, Logger: logger,
	}
	go safetyService.RunSweeper(ctx, 10*time.Second)

	// 004: el pago del viaje usa el mismo cliente de Bold; el webhook de 002 le delega sus
	// referencias y el viaje abre el pago al completarse.
	tripPayService := &trippay.Service{Store: st, Bold: billingService.Bold, Notify: notices, Publisher: publisher, Logger: logger}
	// 009: centro de soporte; los casos de pago se abren y resuelven con el pago (research R3).
	supportService := &support.Service{Store: st, Publisher: publisher, Payments: tripPayService, Logger: logger}
	tripPayService.Cases = supportService
	go supportService.RunSweeper(ctx, time.Minute)
	// 009: megáfono por zonas; el barrido corta los comunicados a los 60 s.
	megaphoneService := &megaphone.Service{Store: st, Voice: livekit, VoiceURL: cfg.LiveKitURL, Publisher: publisher, Logger: logger}
	go megaphoneService.RunSweeper(ctx, time.Second)
	// 010: agenda de reservas (barrido cada 10 s) y buscador de direcciones.
	reservationService := &reservations.Service{Store: st, Trips: tripService, Notify: notices, Publisher: publisher, Logger: logger}
	go reservationService.RunSweeper(ctx, 10*time.Second)
	cityBox, err := places.ParseBBox(cfg.CityBBox)
	if err != nil {
		return err
	}
	placeService := &places.Service{URL: cfg.GeocoderURL, BBox: cityBox, HTTP: &http.Client{Timeout: places.Timeout}}
	// 009: dominios espejo; sin clave de firma el panel los edita pero no se publica la lista.
	domainService := &domains.Service{Store: st, Probe: domains.HTTPProbe(probeClient)}
	if cfg.DomainsSigningKey != "" {
		signer, err := domains.NewSigner(cfg.DomainsSigningKey)
		if err != nil {
			return err
		}
		domainService.Signer = signer
	}
	// 011 Radio Kyq: buckets de mensajes (90 días como máximo de retención) y guardados (366).
	radioMedia, err := storage.NewS3(storage.S3Options{
		Endpoint: cfg.S3Endpoint, PublicEndpoint: cfg.S3PublicEndpoint, AccessKey: cfg.S3AccessKey,
		SecretKey: cfg.S3SecretKey, Bucket: cfg.S3RadioBucket, Region: cfg.S3Region,
	})
	if err != nil {
		return err
	}
	radioSaved, err := storage.NewS3(storage.S3Options{
		Endpoint: cfg.S3Endpoint, PublicEndpoint: cfg.S3PublicEndpoint, AccessKey: cfg.S3AccessKey,
		SecretKey: cfg.S3SecretKey, Bucket: cfg.S3RadioSavedBucket, Region: cfg.S3Region,
	})
	if err != nil {
		return err
	}
	radioCtx, cancelRadio := context.WithTimeout(ctx, 10*time.Second)
	for _, b := range []struct {
		bucket *storage.S3
		days   int
	}{{radioMedia, 90}, {radioSaved, 366}} {
		if err := b.bucket.EnsureBucket(radioCtx); err != nil {
			logger.Warn("bucket de Radio no disponible al arrancar", "bucket", b.bucket.Bucket(), "err", err)
		} else if err := b.bucket.EnsureExpiry(radioCtx, b.days); err != nil {
			logger.Warn("no se pudo fijar la expiración del bucket de Radio", "bucket", b.bucket.Bucket(), "err", err)
		}
	}
	cancelRadio()
	if !cfg.RadioRecording {
		logger.Warn("KYQ_RADIO_RECORDING=false: Radio no guarda el audio de los mensajes")
	}
	radioRooms := ptt.RadioRooms{LiveKit: livekit, S3: ptt.RadioS3{
		Endpoint: cfg.S3Endpoint, Region: cfg.S3Region, AccessKey: cfg.S3AccessKey, SecretKey: cfg.S3SecretKey, Bucket: cfg.S3RadioBucket,
	}}
	radioService := &radio.Service{
		Store: st, LiveKit: livekit, Rooms: radioRooms, VoiceURL: cfg.LiveKitURL, Publisher: publisher,
		Media: radio.S3Media{S3: radioMedia, SavedBucket: radioSaved}, Saved: radioSaved, SMS: sms,
		Record: cfg.RadioRecording, PublicBaseURL: cfg.PublicBaseURL, PlayDriverURL: cfg.PlayDriverURL,
		PlayRiderURL: cfg.PlayRiderURL, Usage: usage, Logger: logger,
	}
	go radioService.RunSweeper(ctx, time.Second)
	// 011: al verificar el OTP se aplican las invitaciones de Radio enviadas a ese teléfono.
	authService := auth.NewService(auth.NewPgRepo(st), otp, tokens, nil)
	authService.Invites = radioService
	// 011: la cooperativa de 006 habla en su conversación de Radio (FR-018): los endpoints del
	// canal de grupo usan la sala y el turno de Radio, y las bajas y suspensiones llegan a los dos.
	pttService.Radio = radioService
	coopService.Group = cooperatives.Groups{pttService, radioService}

	billingService.References = append(billingService.References, tripPayService)
	tripService.Payments = tripPayService
	go tripService.RunSweeper(ctx, time.Second)
	go tripPayService.RunSweeper(ctx, 10*time.Second, time.Minute)
	handler := httpapi.NewRouter(httpapi.Deps{
		Logger:      logger,
		CORSOrigins: strings.Split(os.Getenv("KYQ_CORS_ORIGINS"), ","),
		Tokens:      tokens,
		Auth:        auth.NewHandlers(authService),
		Realtime: &realtime.Handlers{
			Tokens: realtime.Tokens{Secret: cfg.CentrifugoTokenSecret},
			Authorizer: realtime.Authorizer{
				Affiliations: affils, Trips: trips.ParticipantChecker{Q: st.Queries}, Operators: st.Queries,
			},
		},
		Admin:        &admin.Handlers{Store: st},
		Affils:       &affiliations.Handlers{Service: affils},
		Drivers:      &drivers.Handlers{Store: st, PublicBaseURL: cfg.PublicBaseURL},
		Presence:     &drivers.Presence{Store: st, Routes: routes, Publisher: publisher, Usage: usage, Arrivals: tripService, Logger: logger},
		Trips:        &trips.Handlers{Service: tripService},
		PTT:          &ptt.Handlers{Service: pttService},
		Usage:        &telemetry.Handlers{Store: st},
		KYC:          &kyc.Handlers{Service: kycService},
		Billing:      &billing.Handlers{Service: billingService, WebhookEnabled: cfg.BoldEnabled()},
		Notices:      &notify.Handlers{Service: notices},
		Costs:        &telemetry.CostHandlers{Store: st, CityCode: cfg.CityCode},
		Tower:        &control.Handlers{Store: st},
		CRM:          &crm.Handlers{Store: st, Moderation: &crm.Moderation{Store: st, Publisher: publisher, Logger: logger}},
		Health:       &health.Handlers{Checker: checker, Sessions: sentrySessions},
		Cooperatives: &cooperatives.Handlers{Service: coopService},
		GroupPTT:     &ptt.GroupHandlers{Service: pttService},
		Safety:       &safety.Handlers{Service: safetyService, MapStyleURL: cfg.MapStyleURL},
		TripPay:      &trippay.Handlers{Service: tripPayService},
		Support:      &support.Handlers{Service: supportService},
		Megaphone:    &megaphone.Handlers{Service: megaphoneService},
		Domains:      &domains.Handlers{Service: domainService},
		Reservations: &reservations.Handlers{Service: reservationService},
		Places:       &places.Handlers{Service: placeService},
		Radio:        &radio.Handlers{Service: radioService},
		LiveKitWebhook: &telemetry.LiveKitWebhook{
			APIKey: cfg.LiveKitAPIKey, APISecret: cfg.LiveKitAPISecret, Store: st, Usage: usage, Radio: radioService,
		},
	})

	srv := &http.Server{
		Addr:              cfg.HTTPAddr,
		Handler:           handler,
		ReadHeaderTimeout: 5 * time.Second,
		ReadTimeout:       15 * time.Second,
		WriteTimeout:      15 * time.Second,
		IdleTimeout:       60 * time.Second,
	}

	errc := make(chan error, 1)
	go func() {
		logger.Info("http server listening", "addr", cfg.HTTPAddr)
		if err := srv.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			errc <- err
		}
		close(errc)
	}()

	select {
	case err := <-errc:
		return err
	case <-ctx.Done():
	}
	shutdownCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	return srv.Shutdown(shutdownCtx)
}
