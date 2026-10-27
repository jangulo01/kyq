package auth

import (
	"sync"
	"time"
)

// rateLimiter allows at most max events per key within window. In memory: valid for a single
// API instance, which is the MVP deployment.
type rateLimiter struct {
	mu     sync.Mutex
	max    int
	window time.Duration
	events map[string][]time.Time
	calls  int
}

func newRateLimiter(max int, window time.Duration) *rateLimiter {
	return &rateLimiter{max: max, window: window, events: map[string][]time.Time{}}
}

// sweepEvery bounds memory: every N calls, keys with no event inside the window are removed.
const sweepEvery = 1000

// allow records an event for key at now and reports whether it is within the limit.
func (l *rateLimiter) allow(key string, now time.Time) bool {
	l.mu.Lock()
	defer l.mu.Unlock()
	cutoff := now.Add(-l.window)
	if l.calls++; l.calls%sweepEvery == 0 {
		l.sweep(cutoff)
	}
	recent := l.events[key][:0]
	for _, t := range l.events[key] {
		if t.After(cutoff) {
			recent = append(recent, t)
		}
	}
	if len(recent) >= l.max {
		l.events[key] = recent
		return false
	}
	l.events[key] = append(recent, now)
	return true
}

func (l *rateLimiter) sweep(cutoff time.Time) {
	for key, events := range l.events {
		if len(events) == 0 || !events[len(events)-1].After(cutoff) {
			delete(l.events, key)
		}
	}
}

// size returns the number of tracked keys (tests).
func (l *rateLimiter) size() int {
	l.mu.Lock()
	defer l.mu.Unlock()
	return len(l.events)
}
