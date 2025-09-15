package http

import (
	"database/sql"
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/redis/go-redis/v9"

	"github.com/kayis-rahman/time-beam/internal/config"
	"github.com/kayis-rahman/time-beam/internal/session"
	"github.com/kayis-rahman/time-beam/internal/store"
	"github.com/kayis-rahman/time-beam/internal/realtime"
)

// NewRouter sets up the chi router and routes for basic health (legacy tests)
func NewRouter() http.Handler {
	r := chi.NewRouter()

	// health check route
	r.Get("/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("ok"))
	})

	return r
}

// NewRouterWithDeps sets routes with all dependencies
func NewRouterWithDeps(cfg config.Config, db *sql.DB, rdb *redis.Client) http.Handler {
	r := chi.NewRouter()

	// health check route
	r.Get("/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("ok"))
	})

	// dependencies
	users := store.NewUserStore(db)
	authH := &AuthHandlers{Cfg: cfg, Users: users}
	sessSvc := session.NewService(db)
	sessH := &SessionHandlers{Cfg: cfg, Svc: sessSvc, Redis: rdb}
 // realtime SSE
	hub := realtime.NewHub()

	// auth routes
	r.Route("/auth", func(r chi.Router) {
		r.Post("/register", authH.Register)
		r.Post("/login", authH.Login)
	})

	// protected
	r.Group(func(pr chi.Router) {
		pr.Use(AuthMiddleware(cfg))
		pr.Get("/sync/stream", hub.SSEHandler(GetUserID))
		pr.Post("/session/start", sessH.Start)
		pr.Post("/session/stop", sessH.Stop)
		pr.Get("/session/active", sessH.Active)
		pr.Get("/stats/daily", sessH.DailyStats)
	})

	// auth routes
	r.Route("/auth", func(r chi.Router) {
		r.Post("/register", authH.Register)
		r.Post("/login", authH.Login)
	})

	// protected routes
	r.Group(func(pr chi.Router) {
		pr.Use(AuthMiddleware(cfg))
		pr.Get("/sync/stream", hub.SSEHandler(GetUserID))
		pr.Post("/session/start", sessH.Start)
		pr.Post("/session/stop", sessH.Stop)
		pr.Get("/session/active", sessH.Active)
		pr.Get("/stats/daily", sessH.DailyStats)
	})

	return r
}
