package test

import (
	"net/http"
	"testing"

	apphttp "github.com/kayis-rahman/time-beam/internal/http"
)

func TestGetUserID_FromHeader(t *testing.T) {
	req, _ := http.NewRequest(http.MethodGet, "/", nil)
	req.Header.Set("X-Debug-User", "99")
	id, ok := apphttp.GetUserID(req)
	if !ok || id != 99 {
		t.Fatalf("expected ok and id=99, got ok=%v id=%d", ok, id)
	}
}

func TestGetUserID_Fallback(t *testing.T) {
	req, _ := http.NewRequest(http.MethodGet, "/", nil)
	id, ok := apphttp.GetUserID(req)
	if !ok || id != 1 {
		t.Fatalf("expected fallback id=1, got ok=%v id=%d", ok, id)
	}
}
