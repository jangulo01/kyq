// Package httpapi wires the HTTP routes of every backend module.
package httpapi

import "net/http"

// NewRouter returns the root handler. Modules register their routes here.
func NewRouter() http.Handler {
	mux := http.NewServeMux()
	mux.HandleFunc("GET /healthz", func(w http.ResponseWriter, _ *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		_, _ = w.Write([]byte(`{"status":"ok"}`))
	})
	return mux
}
