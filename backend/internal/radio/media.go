package radio

import (
	"context"

	"github.com/kyq/backend/internal/storage"
)

// S3Media is Media on two buckets of the same server: kyq-radio and kyq-radio-saved.
type S3Media struct {
	*storage.S3
	SavedBucket *storage.S3
}

func (m S3Media) SaveCopy(ctx context.Context, key, savedKey string) error {
	return m.CopyTo(ctx, m.SavedBucket, key, savedKey)
}

// MemoryMedia is Media in memory for tests.
type MemoryMedia struct {
	*storage.Memory
	SavedBucket *storage.Memory
}

func (m MemoryMedia) SaveCopy(ctx context.Context, key, savedKey string) error {
	return m.CopyTo(ctx, m.SavedBucket, key, savedKey)
}
