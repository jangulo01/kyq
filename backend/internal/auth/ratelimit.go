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
}

func newRateLimiter(max int, window time.Duration) *rateLimiter {
	return &rateLimiter{max: max, window: window, events: map[string][]time.Time{}}
}

// allow records an event for key at now and reports whether it is within the limit.
func (l *rateLimiter) allow(key string, now time.Time) bool {
	l.mu.Lock()
	defer l.mu.Unlock()
	cutoff := now.Add(-l.window)
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
