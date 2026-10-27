// Package config loads the backend configuration from environment variables.
package config

import (
	"errors"
	"fmt"
	"os"
)

// Config holds every setting the API needs. See backend/.env.example.
type Config struct {
	HTTPAddr    string
	DatabaseURL string
	JWTSecret   []byte

	CentrifugoAPIURL      string
	CentrifugoAPIKey      string
	CentrifugoTokenSecret []byte

	LiveKitURL       string // WebSocket URL the apps connect to
	LiveKitAPIURL    string // HTTP URL the API calls; defaults to LiveKitURL
	LiveKitAPIKey    string
	LiveKitAPISecret string

	OSRMURL  string
	CityCode string

	SentryDSN         string // vacío: sin envío de errores
	SentryEnvironment string

	DevOTPCode             string
	TwilioAccountSID       string
	TwilioAuthToken        string
	TwilioVerifyServiceSID string
}

// Load reads the configuration from the environment and validates it.
func Load() (Config, error) {
	c := Config{
		HTTPAddr:               getenv("KYQ_HTTP_ADDR", ":8080"),
		DatabaseURL:            os.Getenv("KYQ_DATABASE_URL"),
		JWTSecret:              []byte(os.Getenv("KYQ_JWT_SECRET")),
		CentrifugoAPIURL:       os.Getenv("KYQ_CENTRIFUGO_API_URL"),
		CentrifugoAPIKey:       os.Getenv("KYQ_CENTRIFUGO_API_KEY"),
		CentrifugoTokenSecret:  []byte(os.Getenv("KYQ_CENTRIFUGO_TOKEN_SECRET")),
		LiveKitURL:             os.Getenv("KYQ_LIVEKIT_URL"),
		LiveKitAPIURL:          os.Getenv("KYQ_LIVEKIT_API_URL"),
		LiveKitAPIKey:          os.Getenv("KYQ_LIVEKIT_API_KEY"),
		LiveKitAPISecret:       os.Getenv("KYQ_LIVEKIT_API_SECRET"),
		OSRMURL:                os.Getenv("KYQ_OSRM_URL"),
		CityCode:               getenv("KYQ_CITY_CODE", "bogota"),
		SentryDSN:              os.Getenv("KYQ_SENTRY_DSN"),
		SentryEnvironment:      getenv("KYQ_SENTRY_ENVIRONMENT", "dev"),
		DevOTPCode:             os.Getenv("KYQ_DEV_OTP_CODE"),
		TwilioAccountSID:       os.Getenv("KYQ_TWILIO_ACCOUNT_SID"),
		TwilioAuthToken:        os.Getenv("KYQ_TWILIO_AUTH_TOKEN"),
		TwilioVerifyServiceSID: os.Getenv("KYQ_TWILIO_VERIFY_SERVICE_SID"),
	}
	return c, c.Validate()
}

// UsesDevOTP reports whether OTP codes are checked against a fixed development code.
func (c Config) UsesDevOTP() bool { return c.DevOTPCode != "" }

// Validate returns every missing or invalid setting joined in one error.
func (c Config) Validate() error {
	var errs []error
	require := func(name, value string) {
		if value == "" {
			errs = append(errs, fmt.Errorf("%s is required", name))
		}
	}
	require("KYQ_DATABASE_URL", c.DatabaseURL)
	require("KYQ_CENTRIFUGO_API_URL", c.CentrifugoAPIURL)
	require("KYQ_CENTRIFUGO_API_KEY", c.CentrifugoAPIKey)
	require("KYQ_LIVEKIT_URL", c.LiveKitURL)
	require("KYQ_LIVEKIT_API_KEY", c.LiveKitAPIKey)
	require("KYQ_LIVEKIT_API_SECRET", c.LiveKitAPISecret)
	if len(c.JWTSecret) < 32 {
		errs = append(errs, errors.New("KYQ_JWT_SECRET must be at least 32 bytes"))
	}
	if len(c.CentrifugoTokenSecret) == 0 {
		errs = append(errs, errors.New("KYQ_CENTRIFUGO_TOKEN_SECRET is required"))
	}
	if !c.UsesDevOTP() {
		require("KYQ_TWILIO_ACCOUNT_SID", c.TwilioAccountSID)
		require("KYQ_TWILIO_AUTH_TOKEN", c.TwilioAuthToken)
		require("KYQ_TWILIO_VERIFY_SERVICE_SID", c.TwilioVerifyServiceSID)
	}
	return errors.Join(errs...)
}

func getenv(name, fallback string) string {
	if v := os.Getenv(name); v != "" {
		return v
	}
	return fallback
}
