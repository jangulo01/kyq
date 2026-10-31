// Package telemetry measures what each driver costs to serve (constitution VII): voice minutes
// in LiveKit, realtime events published and OSRM route requests. The MVP charges drivers a flat
// subscription, so these numbers tell whether the price covers the infrastructure.
package telemetry

import (
	"context"
	"log/slog"
	"sync"
	"time"

	"github.com/google/uuid"

	"github.com/kyq/backend/internal/store"
)

// Kind is one measured resource.
type Kind int

const (
	VoiceSeconds Kind = iota // segundos de participante en la sala (LiveKit factura por participante)
	Events                   // eventos publicados en Centrifugo
	Routes                   // peticiones a OSRM
	// 011 Radio Kyq (FR-038, R11).
	RadioVoiceSeconds // segundos de participante en salas radio-*
	RadioMessages     // mensajes de Radio enviados
	RadioStorageBytes // bytes de audio y fotos guardados en kyq-radio

	kinds // número de tipos; tamaño de los contadores
)

// Usage receives measurements. Implementations must be cheap and never block the caller.
type Usage interface {
	Add(driverID uuid.UUID, kind Kind, n int64)
}

// Add records n units on u; a nil Usage records nothing, so modules work without telemetry.
func Add(u Usage, driverID uuid.UUID, kind Kind, n int64) {
	if u != nil && n > 0 {
		u.Add(driverID, kind, n)
	}
}

type key struct {
	driver uuid.UUID
	day    time.Time
}

// Recorder buffers measurements in memory and adds them to driver_usage_daily on Flush, so
// counting an event costs a map update instead of a database write.
type Recorder struct {
	Store  *store.Store
	Now    func() time.Time
	Logger *slog.Logger

	mu      sync.Mutex
	pending map[key][kinds]int64
}

func (r *Recorder) now() time.Time {
	if r.Now != nil {
		return r.Now()
	}
	return time.Now()
}

func (r *Recorder) Add(driverID uuid.UUID, kind Kind, n int64) {
	t := r.now().UTC()
	k := key{driver: driverID, day: time.Date(t.Year(), t.Month(), t.Day(), 0, 0, 0, 0, time.UTC)}
	r.mu.Lock()
	defer r.mu.Unlock()
	if r.pending == nil {
		r.pending = map[key][kinds]int64{}
	}
	v := r.pending[k]
	v[kind] += n
	r.pending[k] = v
}

// Flush writes the buffered counters. On failure they go back to the buffer for the next try.
func (r *Recorder) Flush(ctx context.Context) error {
	r.mu.Lock()
	batch := r.pending
	r.pending = nil
	r.mu.Unlock()
	for k, v := range batch {
		err := r.Store.AddDriverUsage(ctx, store.AddDriverUsageParams{
			DriverID: k.driver, Day: k.day,
			VoiceParticipantSeconds: v[VoiceSeconds], RealtimeEvents: v[Events], RouteRequests: v[Routes],
			RadioVoiceSeconds: v[RadioVoiceSeconds], RadioMessages: v[RadioMessages], RadioStorageBytes: v[RadioStorageBytes],
		})
		if err != nil {
			r.mu.Lock()
			if r.pending == nil {
				r.pending = map[key][kinds]int64{}
			}
			for k2, v2 := range batch {
				cur := r.pending[k2]
				for i := range cur {
					cur[i] += v2[i]
				}
				r.pending[k2] = cur
			}
			r.mu.Unlock()
			return err
		}
		delete(batch, k)
	}
	return nil
}

// Run flushes every interval until ctx ends, then once more.
func (r *Recorder) Run(ctx context.Context, interval time.Duration) {
	ticker := time.NewTicker(interval)
	defer ticker.Stop()
	for {
		select {
		case <-ctx.Done():
			if err := r.Flush(context.WithoutCancel(ctx)); err != nil {
				r.logger().Error("flush usage on shutdown", "err", err)
			}
			return
		case <-ticker.C:
			if err := r.Flush(ctx); err != nil {
				r.logger().ErrorContext(ctx, "flush usage", "err", err)
			}
		}
	}
}

func (r *Recorder) logger() *slog.Logger {
	if r.Logger != nil {
		return r.Logger
	}
	return slog.Default()
}
