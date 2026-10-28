package storage

import (
	"context"
	"net/url"
	"sync"
	"time"
)

// Memory is an in-memory Objects for tests. Signed URLs look like
// https://objects.test/{key}?op=put&expires=...; Put simulates the client upload.
type Memory struct {
	mu      sync.Mutex
	objects map[string]memObject
}

type memObject struct {
	data        []byte
	contentType string
}

// NewMemory returns an empty store.
func NewMemory() *Memory { return &Memory{objects: map[string]memObject{}} }

// Put stores an object as if a client had uploaded it with a signed URL.
func (m *Memory) Put(key string, data []byte, contentType string) {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.objects[key] = memObject{data: data, contentType: contentType}
}

// Has reports whether key exists.
func (m *Memory) Has(key string) bool {
	m.mu.Lock()
	defer m.mu.Unlock()
	_, ok := m.objects[key]
	return ok
}

func signed(op, key string, ttl time.Duration) string {
	q := url.Values{"op": {op}, "ttl": {ttl.String()}, "X-Amz-Signature": {"test"}}
	return "https://objects.test/" + key + "?" + q.Encode()
}

func (m *Memory) PresignPut(_ context.Context, key, _ string, ttl time.Duration) (string, error) {
	return signed("put", key, ttl), nil
}

func (m *Memory) PresignGet(_ context.Context, key string, ttl time.Duration) (string, error) {
	return signed("get", key, ttl), nil
}

func (m *Memory) Stat(_ context.Context, key string) (ObjectInfo, error) {
	m.mu.Lock()
	defer m.mu.Unlock()
	o, ok := m.objects[key]
	if !ok {
		return ObjectInfo{}, ErrNotFound
	}
	return ObjectInfo{Size: int64(len(o.data)), ContentType: o.contentType}, nil
}

// Ping always succeeds: the memory store is always there.
func (m *Memory) Ping(context.Context) error { return nil }

func (m *Memory) Remove(_ context.Context, key string) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	delete(m.objects, key)
	return nil
}
