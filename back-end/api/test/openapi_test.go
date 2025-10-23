package test

import (
	"net/http"
	"net/http/httptest"
	"testing"

	apphttp "github.com/kayis-rahman/time-beam/internal/http"
)

func TestOpenAPI_Served(t *testing.T){
	r := apphttp.NewRouter()
	req := httptest.NewRequest(http.MethodGet, "/openapi.yaml", nil)
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)
	if w.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d", w.Code)
	}
	ct := w.Header().Get("Content-Type")
	if ct == "" { t.Fatalf("expected content type header for yaml") }
}
