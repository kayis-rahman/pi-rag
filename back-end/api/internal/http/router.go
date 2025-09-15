package http

import (
	"net/http"

	"github.com/go-chi/chi/v5"
)

// NewRouter sets up the chi router and routes
func NewRouter() http.Handler {
	r := chi.NewRouter()

	// health check route
	r.Get("/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("ok"))
	})

	return r
}
