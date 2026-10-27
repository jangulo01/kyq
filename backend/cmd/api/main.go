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
	"github.com/kyq/backend/internal/config"
	"github.com/kyq/backend/internal/drivers"
	"github.com/kyq/backend/internal/httpapi"
	"github.com/kyq/backend/internal/realtime"
	"github.com/kyq/backend/internal/store"
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
	handler := httpapi.NewRouter(httpapi.Deps{
		Logger: logger,
		Tokens: tokens,
		Auth:   auth.NewHandlers(auth.NewService(auth.NewPgRepo(st.Queries), otp, tokens, nil)),
		Realtime: &realtime.Handlers{
			Tokens: realtime.Tokens{Secret: cfg.CentrifugoTokenSecret},
			// El verificador de participantes de viaje se conecta en US2.
			Authorizer: realtime.Authorizer{Affiliations: affils},
		},
		Admin:   &admin.Handlers{Store: st},
		Affils:  &affiliations.Handlers{Service: affils},
		Drivers: &drivers.Handlers{Store: st},
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
