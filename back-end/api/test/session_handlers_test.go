package test

import (
	"bytes"
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	miniredis "github.com/alicebob/miniredis/v2"
	"github.com/redis/go-redis/v9"

	apphttp "github.com/kayis-rahman/time-beam/internal/http"
)

type fakeSessionService struct{
	started bool
	active bool
	id int64
	label string
}

func (s *fakeSessionService) Start(_ context.Context, userID int64, label string) (int64, error){
	s.started=true; s.active=true; s.id=123; s.label=label; _ = userID; return s.id,nil
}
func (s *fakeSessionService) Stop(_ context.Context, _ int64) error{ s.active=false; return nil }
func (s *fakeSessionService) Active(_ context.Context, _ int64) (bool, error){ return s.active, nil }
func (s *fakeSessionService) DailyStats(_ context.Context, _ int64, _ time.Time) (int, error){ return 3600, nil }

func setupRedis(t *testing.T) (*miniredis.Miniredis, *redis.Client){
	mr, err := miniredis.Run()
	if err != nil { t.Fatal(err) }
	rdb := redis.NewClient(&redis.Options{Addr: mr.Addr()})
	return mr, rdb
}

func newHandlers(t *testing.T) (*apphttp.SessionHandlers, *fakeSessionService, func()){
	mr, rdb := setupRedis(t)
	svc := &fakeSessionService{}
	h := &apphttp.SessionHandlers{Redis: rdb, Svc: svc}
	cleanup := func(){ mr.Close(); rdb.Close() }
	return h, svc, cleanup
}

func TestStartSetsCacheAndReturnsID(t *testing.T){
	h, _, cleanup := newHandlers(t)
	defer cleanup()
	req := httptest.NewRequest(http.MethodPost, "/session/start", bytes.NewBufferString(`{"label":"focus"}`))
	rec := httptest.NewRecorder()
	h.Start(rec, req)
	if rec.Code != http.StatusOK { t.Fatalf("expected 200, got %d", rec.Code) }
	var resp map[string]any
	_ = json.Unmarshal(rec.Body.Bytes(), &resp)
	if _, ok := resp["session_id"]; !ok { t.Fatalf("missing session_id in response: %s", rec.Body.String()) }
}

func TestActiveUsesCacheThenService(t *testing.T){
	h, svc, cleanup := newHandlers(t)
	defer cleanup()
	// Initially inactive
	rec := httptest.NewRecorder()
	req := httptest.NewRequest(http.MethodGet, "/session/active", nil)
	h.Active(rec, req)
	if rec.Code != http.StatusOK { t.Fatalf("expected 200, got %d", rec.Code) }
	if !bytes.Contains(rec.Body.Bytes(), []byte("false")) { t.Fatalf("expected inactive, got %s", rec.Body.String()) }
	// Start sets cache active
	rec2 := httptest.NewRecorder()
	req2 := httptest.NewRequest(http.MethodPost, "/session/start", nil)
	h.Start(rec2, req2)
	// Now Active should be true from cache
	rec3 := httptest.NewRecorder()
	req3 := httptest.NewRequest(http.MethodGet, "/session/active", nil)
	h.Active(rec3, req3)
	if !bytes.Contains(rec3.Body.Bytes(), []byte("true")) { t.Fatalf("expected active true, got %s", rec3.Body.String()) }
	// Stop clears cache and service inactive
	svc.active = false
	rec4 := httptest.NewRecorder()
	req4 := httptest.NewRequest(http.MethodPost, "/session/stop", nil)
	h.Stop(rec4, req4)
	if rec4.Code != http.StatusNoContent { t.Fatalf("expected 204, got %d", rec4.Code) }
}

func TestDailyStats(t *testing.T){
	h, _, cleanup := newHandlers(t)
	defer cleanup()
	rec := httptest.NewRecorder()
	req := httptest.NewRequest(http.MethodGet, "/stats/daily", nil)
	h.DailyStats(rec, req)
	if rec.Code != http.StatusOK { t.Fatalf("expected 200, got %d", rec.Code) }
	if !bytes.Contains(rec.Body.Bytes(), []byte("3600")) { t.Fatalf("expected 3600 seconds, got %s", rec.Body.String()) }
}
