// Package storage keeps private objects (driver document photos) in an S3 compatible bucket:
// MinIO in development, Cloudflare R2 in production (research R4). Clients never read the bucket
// directly; they get short-lived signed URLs.
package storage

import (
	"context"
	"errors"
	"fmt"
	"net/http"
	"net/url"
	"time"

	"github.com/minio/minio-go/v7"
	"github.com/minio/minio-go/v7/pkg/credentials"
)

// ErrNotFound means the object does not exist.
var ErrNotFound = errors.New("object not found")

// ObjectInfo is what the API checks about an uploaded object.
type ObjectInfo struct {
	Size        int64
	ContentType string
}

// Objects stores private objects and signs URLs to upload or read them.
type Objects interface {
	// PresignPut returns a URL to upload key with exactly contentType for ttl.
	PresignPut(ctx context.Context, key, contentType string, ttl time.Duration) (string, error)
	// PresignGet returns a URL to read key for ttl.
	PresignGet(ctx context.Context, key string, ttl time.Duration) (string, error)
	// Stat returns ErrNotFound when key does not exist.
	Stat(ctx context.Context, key string) (ObjectInfo, error)
	Remove(ctx context.Context, key string) error
}

// S3Options configure NewS3. Endpoints are URLs with scheme, e.g. http://minio:9000.
type S3Options struct {
	Endpoint string
	// PublicEndpoint is the host the apps reach; signed URLs are signed for it. Empty: Endpoint.
	PublicEndpoint string
	AccessKey      string
	SecretKey      string
	Bucket         string
	Region         string
}

// S3 implements Objects with minio-go.
type S3 struct {
	api    *minio.Client // operaciones desde la API (red interna)
	signer *minio.Client // firma URLs para el host público; nunca hace peticiones
	bucket string
}

// NewS3 builds the client. It does not contact the server.
func NewS3(o S3Options) (*S3, error) {
	if o.PublicEndpoint == "" {
		o.PublicEndpoint = o.Endpoint
	}
	if o.Region == "" {
		o.Region = "us-east-1"
	}
	api, err := newClient(o.Endpoint, o)
	if err != nil {
		return nil, err
	}
	signer, err := newClient(o.PublicEndpoint, o)
	if err != nil {
		return nil, err
	}
	return &S3{api: api, signer: signer, bucket: o.Bucket}, nil
}

func newClient(endpoint string, o S3Options) (*minio.Client, error) {
	u, err := url.Parse(endpoint)
	if err != nil || u.Host == "" || (u.Scheme != "http" && u.Scheme != "https") {
		return nil, fmt.Errorf("s3 endpoint %q: must be http(s)://host[:port]", endpoint)
	}
	// Con la región fija, minio-go no consulta la ubicación del bucket al firmar.
	return minio.New(u.Host, &minio.Options{
		Creds:        credentials.NewStaticV4(o.AccessKey, o.SecretKey, ""),
		Secure:       u.Scheme == "https",
		Region:       o.Region,
		BucketLookup: minio.BucketLookupPath,
	})
}

// ErrBucketMissing means the storage answers but the documents bucket does not exist.
var ErrBucketMissing = errors.New("s3 bucket missing")

// Ping checks that the storage answers and the bucket exists (007, Healthline).
func (s *S3) Ping(ctx context.Context) error {
	ok, err := s.api.BucketExists(ctx, s.bucket)
	if err != nil {
		return fmt.Errorf("s3 bucket exists: %w", err)
	}
	if !ok {
		return ErrBucketMissing
	}
	return nil
}

// EnsureBucket creates the bucket when missing. Buckets are private by default.
func (s *S3) EnsureBucket(ctx context.Context) error {
	ok, err := s.api.BucketExists(ctx, s.bucket)
	if err != nil {
		return fmt.Errorf("s3 bucket exists: %w", err)
	}
	if ok {
		return nil
	}
	return s.api.MakeBucket(ctx, s.bucket, minio.MakeBucketOptions{})
}

func (s *S3) PresignPut(ctx context.Context, key, contentType string, ttl time.Duration) (string, error) {
	u, err := s.signer.PresignHeader(ctx, http.MethodPut, s.bucket, key, ttl, nil, http.Header{"Content-Type": {contentType}})
	if err != nil {
		return "", fmt.Errorf("presign put: %w", err)
	}
	return u.String(), nil
}

func (s *S3) PresignGet(ctx context.Context, key string, ttl time.Duration) (string, error) {
	u, err := s.signer.PresignedGetObject(ctx, s.bucket, key, ttl, nil)
	if err != nil {
		return "", fmt.Errorf("presign get: %w", err)
	}
	return u.String(), nil
}

func (s *S3) Stat(ctx context.Context, key string) (ObjectInfo, error) {
	info, err := s.api.StatObject(ctx, s.bucket, key, minio.StatObjectOptions{})
	if err != nil {
		if minio.ToErrorResponse(err).StatusCode == http.StatusNotFound {
			return ObjectInfo{}, ErrNotFound
		}
		return ObjectInfo{}, fmt.Errorf("stat object: %w", err)
	}
	return ObjectInfo{Size: info.Size, ContentType: info.ContentType}, nil
}

func (s *S3) Remove(ctx context.Context, key string) error {
	return s.api.RemoveObject(ctx, s.bucket, key, minio.RemoveObjectOptions{})
}
