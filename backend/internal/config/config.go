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
	TwilioSMSFrom          string // remitente de los avisos por SMS (002); vacío: solo log

	// Almacenamiento S3 compatible para fotos KYC (002). Endpoints como URL con esquema.
	S3Endpoint       string
	S3PublicEndpoint string // el que va en las URLs firmadas; por defecto S3Endpoint
	S3AccessKey      string
	S3SecretKey      string
	S3Bucket         string
	S3Region         string

	// Bold (002). BoldEnv vacío desactiva los pagos con Bold.
	BoldEnv         string // "" | sandbox | production
	BoldAPIURL      string
	BoldIdentityKey string
	BoldSecretKey   string
}

// Bold environments.
const (
	BoldSandbox    = "sandbox"
	BoldProduction = "production"
)

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
		TwilioSMSFrom:          os.Getenv("KYQ_TWILIO_SMS_FROM"),
		S3Endpoint:             os.Getenv("KYQ_S3_ENDPOINT"),
		S3PublicEndpoint:       os.Getenv("KYQ_S3_PUBLIC_ENDPOINT"),
		S3AccessKey:            os.Getenv("KYQ_S3_ACCESS_KEY"),
		S3SecretKey:            os.Getenv("KYQ_S3_SECRET_KEY"),
		S3Bucket:               getenv("KYQ_S3_BUCKET", "kyq-kyc"),
		S3Region:               getenv("KYQ_S3_REGION", "us-east-1"),
		BoldEnv:                os.Getenv("KYQ_BOLD_ENV"),
		BoldAPIURL:             getenv("KYQ_BOLD_API_URL", "https://integrations.api.bold.co"),
		BoldIdentityKey:        os.Getenv("KYQ_BOLD_IDENTITY_KEY"),
		BoldSecretKey:          os.Getenv("KYQ_BOLD_SECRET_KEY"),
	}
	if c.S3PublicEndpoint == "" {
		c.S3PublicEndpoint = c.S3Endpoint
	}
	return c, c.Validate()
}

// BoldEnabled reports whether drivers can pay with Bold.
func (c Config) BoldEnabled() bool { return c.BoldEnv != "" }

// BoldWebhookSecret is the key that signs Bold webhooks: Bold signs sandbox notifications with
// an empty key.
func (c Config) BoldWebhookSecret() string {
	if c.BoldEnv == BoldSandbox {
		return ""
	}
	return c.BoldSecretKey
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
	require("KYQ_S3_ENDPOINT", c.S3Endpoint)
	require("KYQ_S3_ACCESS_KEY", c.S3AccessKey)
	require("KYQ_S3_SECRET_KEY", c.S3SecretKey)
	switch c.BoldEnv {
	case "":
	case BoldSandbox, BoldProduction:
		require("KYQ_BOLD_IDENTITY_KEY", c.BoldIdentityKey)
		require("KYQ_BOLD_SECRET_KEY", c.BoldSecretKey)
	default:
		errs = append(errs, errors.New("KYQ_BOLD_ENV must be empty, sandbox or production"))
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
