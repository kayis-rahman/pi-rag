package test

import (
	"net/http"
	"net/http/httptest"
	"testing"

	apphttp "github.com/kayis-rahman/time-beam/internal/http"
)

func TestHealthEndpoint_Returns200(t *testing.T) {
	r := apphttp.NewRouter()

	req := httptest.NewRequest(http.MethodGet, "/health", nil)
	w := httptest.NewRecorder()

	r.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Fatalf("expected status 200, got %d", w.Code)
	}
}
