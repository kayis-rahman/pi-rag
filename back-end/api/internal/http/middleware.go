package http

import (
	"context"
	"net/http"
	"strings"

	"github.com/kayis-rahman/time-beam/internal/auth"
	"github.com/kayis-rahman/time-beam/internal/config"
)

type ctxKey string

const userIDKey ctxKey = "userID"

func AuthMiddleware(cfg config.Config) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			authz := r.Header.Get("Authorization")
			if authz == "" || !strings.HasPrefix(authz, "Bearer ") {
				http.Error(w, "missing token", http.StatusUnauthorized)
				return
			}
			tok := strings.TrimPrefix(authz, "Bearer ")
			claims, err := auth.ParseToken(cfg.JWTSecret, tok)
			if err != nil {
				http.Error(w, "invalid token", http.StatusUnauthorized)
				return
			}
			ctx := context.WithValue(r.Context(), userIDKey, claims.UserID)
			next.ServeHTTP(w, r.WithContext(ctx))
		})
	}
}

func GetUserID(r *http.Request) (int64, bool) {
	v := r.Context().Value(userIDKey)
	if v == nil {
		return 0, false
	}
	id, ok := v.(int64)
	return id, ok
}
