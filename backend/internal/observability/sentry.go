// Package observability reports server errors to Sentry without personal data (constitution,
// FR-020): no phones, OTP codes, tokens, request bodies or names leave the server.
package observability

import (
	"context"
	"fmt"
	"regexp"
	"sync/atomic"
	"time"

	"github.com/getsentry/sentry-go"
)

var enabled atomic.Bool

// Options configure Init. An empty DSN disables reporting.
type Options struct {
	DSN         string
	Environment string
	Release     string
}

// Init starts the Sentry client and returns a flush function for shutdown. Without a DSN it
// does nothing, so development and tests never send events.
func Init(o Options) (flush func(), err error) {
	if o.DSN == "" {
		return func() {}, nil
	}
	err = sentry.Init(sentry.ClientOptions{
		Dsn:              o.DSN,
		Environment:      o.Environment,
		Release:          o.Release,
		SendDefaultPII:   false,
		AttachStacktrace: true,
		BeforeSend:       func(e *sentry.Event, _ *sentry.EventHint) *sentry.Event { return Scrub(e) },
		BeforeBreadcrumb: func(b *sentry.Breadcrumb, _ *sentry.BreadcrumbHint) *sentry.Breadcrumb {
			return scrubBreadcrumb(b)
		},
	})
	if err != nil {
		return func() {}, err
	}
	enabled.Store(true)
	return func() { sentry.Flush(2 * time.Second) }, nil
}

// CaptureError reports an unexpected server error; path is the route without query string.
func CaptureError(ctx context.Context, err error, path string) {
	if !enabled.Load() || err == nil {
		return
	}
	hub := sentry.GetHubFromContext(ctx)
	if hub == nil {
		hub = sentry.CurrentHub().Clone()
	}
	hub.WithScope(func(s *sentry.Scope) {
		s.SetTag("path", path)
		hub.CaptureException(err)
	})
}

// CapturePanic reports a recovered panic.
func CapturePanic(ctx context.Context, v any, path string) {
	CaptureError(ctx, fmt.Errorf("panic: %v", v), path)
}

var (
	// E.164 y celulares colombianos de 10 dígitos que empiezan por 3.
	phoneRe = regexp.MustCompile(`\+[1-9]\d{6,14}|\b3\d{9}\b`)
	jwtRe   = regexp.MustCompile(`eyJ[\w-]+\.[\w-]+\.[\w-]+`)
	bearRe  = regexp.MustCompile(`(?i)bearer\s+\S+`)
	// Códigos OTP: 6 dígitos junto a la palabra code/código/otp.
	otpRe = regexp.MustCompile(`(?i)(code|código|codigo|otp)("?\s*[:=]\s*"?)\d{6}`)
)

// ScrubString removes phones, OTP codes and tokens from s.
func ScrubString(s string) string {
	s = jwtRe.ReplaceAllString(s, "[token]")
	s = bearRe.ReplaceAllString(s, "Bearer [token]")
	s = otpRe.ReplaceAllString(s, "$1$2[otp]")
	return phoneRe.ReplaceAllString(s, "[phone]")
}

func scrubValue(v any) any {
	switch x := v.(type) {
	case string:
		return ScrubString(x)
	case map[string]any:
		for k, e := range x {
			x[k] = scrubValue(e)
		}
		return x
	case []any:
		for i, e := range x {
			x[i] = scrubValue(e)
		}
		return x
	case map[string]string:
		for k, e := range x {
			x[k] = ScrubString(e)
		}
		return x
	}
	return v
}

// Scrub keeps only what is needed to fix a bug: the user id, method and path, the error text
// without personal data and the stack trace.
func Scrub(e *sentry.Event) *sentry.Event {
	if e == nil {
		return nil
	}
	e.User = sentry.User{ID: e.User.ID}
	e.ServerName = ""
	if r := e.Request; r != nil {
		e.Request = &sentry.Request{URL: stripQuery(r.URL), Method: r.Method}
	}
	e.Message = ScrubString(e.Message)
	for i := range e.Exception {
		e.Exception[i].Value = ScrubString(e.Exception[i].Value)
	}
	for _, c := range e.Contexts {
		scrubValue(map[string]any(c))
	}
	for k, v := range e.Tags {
		e.Tags[k] = ScrubString(v)
	}
	kept := e.Breadcrumbs[:0]
	for _, b := range e.Breadcrumbs {
		if b = scrubBreadcrumb(b); b != nil {
			kept = append(kept, b)
		}
	}
	e.Breadcrumbs = kept
	return e
}

func scrubBreadcrumb(b *sentry.Breadcrumb) *sentry.Breadcrumb {
	if b == nil {
		return nil
	}
	b.Message = ScrubString(b.Message)
	if url, ok := b.Data["url"].(string); ok {
		b.Data["url"] = stripQuery(url)
	}
	delete(b.Data, "body")
	delete(b.Data, "request_body")
	scrubValue(b.Data)
	return b
}

func stripQuery(url string) string {
	for i, c := range url {
		if c == '?' || c == '#' {
			url = url[:i]
			break
		}
	}
	return ScrubString(url)
}
