// Command api runs the Kyq modular monolith HTTP server.
package main

import (
	"context"
	"errors"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/kyq/backend/internal/admin"
	"github.com/kyq/backend/internal/affiliations"
	"github.com/kyq/backend/internal/auth"
	"github.com/kyq/backend/internal/billing"
	"github.com/kyq/backend/internal/config"
	"github.com/kyq/backend/internal/drivers"
	"github.com/kyq/backend/internal/fares"
	"github.com/kyq/backend/internal/httpapi"
	"github.com/kyq/backend/internal/kyc"
	"github.com/kyq/backend/internal/notify"
	"github.com/kyq/backend/internal/observability"
	"github.com/kyq/backend/internal/ptt"
	"github.com/kyq/backend/internal/realtime"
	"github.com/kyq/backend/internal/safety"
	"github.com/kyq/backend/internal/storage"
	"github.com/kyq/backend/internal/store"
	"github.com/kyq/backend/internal/telemetry"
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
	go tripService.RunSweeper(ctx, time.Second)
	apiURL := cfg.LiveKitAPIURL
	if apiURL == "" {
		apiURL = ptt.APIURLFrom(cfg.LiveKitURL)
	}
	livekit := ptt.LiveKit{APIURL: apiURL, APIKey: cfg.LiveKitAPIKey, APISecret: cfg.LiveKitAPISecret}
	pttService := &ptt.Service{
		Store: st, LiveKit: livekit, Rooms: livekit, PublicURL: cfg.LiveKitURL, Publisher: publisher, Usage: usage, Logger: logger,
	}
	go pttService.RunSweeper(ctx, time.Second)

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
	handler := httpapi.NewRouter(httpapi.Deps{
		Logger: logger,
		Tokens: tokens,
		Auth:   auth.NewHandlers(auth.NewService(auth.NewPgRepo(st), otp, tokens, nil)),
		Realtime: &realtime.Handlers{
			Tokens: realtime.Tokens{Secret: cfg.CentrifugoTokenSecret},
			Authorizer: realtime.Authorizer{
				Affiliations: affils, Trips: trips.ParticipantChecker{Q: st.Queries}, Operators: st.Queries,
			},
		},
		Admin:    &admin.Handlers{Store: st},
		Affils:   &affiliations.Handlers{Service: affils},
		Drivers:  &drivers.Handlers{Store: st},
		Presence: &drivers.Presence{Store: st, Routes: routes, Publisher: publisher, Usage: usage, Logger: logger},
		Trips:    &trips.Handlers{Service: tripService},
		PTT:      &ptt.Handlers{Service: pttService},
		Usage:    &telemetry.Handlers{Store: st},
		KYC:      &kyc.Handlers{Service: kycService},
		Billing:  &billing.Handlers{Service: billingService, WebhookEnabled: cfg.BoldEnabled()},
		Notices:  &notify.Handlers{Service: notices},
		Costs:    &telemetry.CostHandlers{Store: st, CityCode: cfg.CityCode},
		Safety:   &safety.Handlers{Service: safetyService, MapStyleURL: cfg.MapStyleURL},
		LiveKitWebhook: &telemetry.LiveKitWebhook{
			APIKey: cfg.LiveKitAPIKey, APISecret: cfg.LiveKitAPISecret, Store: st, Usage: usage,
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
