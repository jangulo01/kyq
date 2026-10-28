package health

import (
	"context"
	"fmt"
	"io"
	"net/http"
	"strings"

	"github.com/jackc/pgx/v5/pgxpool"
)

// Las sondas usan la misma vía que el uso real (research R8). Los detalles son textos propios:
// nunca incluyen la URL, la llave ni el error crudo.

func httpStatusDetail(code int) string { return fmt.Sprintf("HTTP %d", code) }

func do(ctx context.Context, client *http.Client, req *http.Request) (int, error) {
	if client == nil {
		client = http.DefaultClient
	}
	resp, err := client.Do(req.WithContext(ctx))
	if err != nil {
		return 0, err
	}
	defer resp.Body.Close()
	_, _ = io.Copy(io.Discard, io.LimitReader(resp.Body, 64<<10))
	return resp.StatusCode, nil
}

func unreachable(err error) (string, error) { return "sin conexión", err }

// DatabaseProbe pings PostgreSQL and runs SELECT 1.
func DatabaseProbe(pool *pgxpool.Pool) Probe {
	return func(ctx context.Context) (string, error) {
		var one int
		if err := pool.QueryRow(ctx, "SELECT 1").Scan(&one); err != nil {
			return "sin conexión", err
		}
		return "disponible", nil
	}
}

// CentrifugoProbe calls the info method of the Centrifugo HTTP API with its key.
func CentrifugoProbe(client *http.Client, apiURL, apiKey string) Probe {
	return func(ctx context.Context) (string, error) {
		if apiURL == "" {
			return "sin URL configurada", ErrDisabled
		}
		req, err := http.NewRequest(http.MethodPost, strings.TrimRight(apiURL, "/")+"/info", strings.NewReader("{}"))
		if err != nil {
			return "configuración inválida", err
		}
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("X-API-Key", apiKey)
		code, err := do(ctx, client, req)
		if err != nil {
			return unreachable(err)
		}
		if code != http.StatusOK {
			return httpStatusDetail(code), fmt.Errorf("centrifugo: %d", code)
		}
		return "disponible", nil
	}
}

// LiveKitProbe calls the root of the LiveKit server, which answers 200 when it is up.
func LiveKitProbe(client *http.Client, apiURL string) Probe {
	return func(ctx context.Context) (string, error) {
		if apiURL == "" {
			return "sin URL configurada", ErrDisabled
		}
		req, err := http.NewRequest(http.MethodGet, strings.TrimRight(apiURL, "/")+"/", nil)
		if err != nil {
			return "configuración inválida", err
		}
		code, err := do(ctx, client, req)
		if err != nil {
			return unreachable(err)
		}
		if code != http.StatusOK {
			return httpStatusDetail(code), fmt.Errorf("livekit: %d", code)
		}
		return "disponible", nil
	}
}

// OSRMProbe asks for a short route between two points of (lat, lng): any answer below 500
// means the service is up (outside its coverage it answers 400).
func OSRMProbe(client *http.Client, baseURL string, lat, lng float64) Probe {
	return func(ctx context.Context) (string, error) {
		if baseURL == "" {
			return "sin URL configurada", ErrDisabled
		}
		url := fmt.Sprintf("%s/route/v1/driving/%f,%f;%f,%f?overview=false",
			strings.TrimRight(baseURL, "/"), lng, lat, lng+0.01, lat+0.01)
		req, err := http.NewRequest(http.MethodGet, url, nil)
		if err != nil {
			return "configuración inválida", err
		}
		code, err := do(ctx, client, req)
		if err != nil {
			return unreachable(err)
		}
		if code >= 500 {
			return httpStatusDetail(code), fmt.Errorf("osrm: %d", code)
		}
		if code != http.StatusOK {
			return "disponible (punto de prueba fuera de cobertura)", nil
		}
		return "disponible", nil
	}
}

// Pinger is the storage check (storage.S3.Ping).
type Pinger interface {
	Ping(ctx context.Context) error
}

// StorageProbe checks the documents bucket.
func StorageProbe(p Pinger) Probe {
	return func(ctx context.Context) (string, error) {
		if p == nil {
			return "", ErrDisabled
		}
		if err := p.Ping(ctx); err != nil {
			return "bucket no disponible", err
		}
		return "disponible", nil
	}
}

// BoldProbe lists the payment methods with the identity key (only when Bold is enabled).
func BoldProbe(client *http.Client, enabled bool, baseURL, identityKey string) Probe {
	return func(ctx context.Context) (string, error) {
		if !enabled {
			return "pagos con Bold desactivados", ErrDisabled
		}
		req, err := http.NewRequest(http.MethodGet, strings.TrimRight(baseURL, "/")+"/online/link/v1/payment_methods", nil)
		if err != nil {
			return "configuración inválida", err
		}
		req.Header.Set("Authorization", "x-api-key "+identityKey)
		code, err := do(ctx, client, req)
		if err != nil {
			return unreachable(err)
		}
		switch {
		case code == http.StatusUnauthorized || code == http.StatusForbidden:
			return "llave rechazada", fmt.Errorf("bold: %d", code)
		case code != http.StatusOK:
			return httpStatusDetail(code), fmt.Errorf("bold: %d", code)
		}
		return "disponible", nil
	}
}

// cityCenters are the test points for OSRM per city code; unknown codes use Bogotá.
var cityCenters = map[string][2]float64{
	"bogota":   {4.6097, -74.0817},
	"cali":     {3.4516, -76.5320},
	"medellin": {6.2442, -75.5812},
	"lima":     {-12.0464, -77.0428},
}

// CityCenter returns the OSRM test point of a city.
func CityCenter(cityCode string) (lat, lng float64) {
	c, ok := cityCenters[cityCode]
	if !ok {
		c = cityCenters["bogota"]
	}
	return c[0], c[1]
}
