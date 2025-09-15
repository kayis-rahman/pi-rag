package http

import (
	"encoding/json"
	"net/http"
	"time"
	"strconv"

	"github.com/redis/go-redis/v9"

	"github.com/kayis-rahman/time-beam/internal/config"
	"github.com/kayis-rahman/time-beam/internal/session"
)

type SessionHandlers struct {
	Cfg     config.Config
	Svc     *session.Service
	Redis   *redis.Client
}

type startReq struct{ Label string `json:"label"` }

func (h *SessionHandlers) Start(w http.ResponseWriter, r *http.Request) {
	userID, ok := GetUserID(r)
	if !ok { http.Error(w, "unauthorized", http.StatusUnauthorized); return }
	var req startReq
	_ = json.NewDecoder(r.Body).Decode(&req)
	id, err := h.Svc.Start(r.Context(), userID, req.Label)
	if err != nil { http.Error(w, err.Error(), http.StatusBadRequest); return }
	// cache active session flag
	h.Redis.Set(r.Context(), h.activeKey(userID), "1", 2*time.Hour)
	_ = json.NewEncoder(w).Encode(map[string]any{"session_id": id})
}

func (h *SessionHandlers) Stop(w http.ResponseWriter, r *http.Request) {
	userID, ok := GetUserID(r)
	if !ok { http.Error(w, "unauthorized", http.StatusUnauthorized); return }
	if err := h.Svc.Stop(r.Context(), userID); err != nil { http.Error(w, err.Error(), http.StatusBadRequest); return }
	h.Redis.Del(r.Context(), h.activeKey(userID))
	w.WriteHeader(http.StatusNoContent)
}

func (h *SessionHandlers) Active(w http.ResponseWriter, r *http.Request) {
	userID, ok := GetUserID(r)
	if !ok { http.Error(w, "unauthorized", http.StatusUnauthorized); return }
	// check redis first
	if val, err := h.Redis.Get(r.Context(), h.activeKey(userID)).Result(); err == nil && val == "1" {
		_ = json.NewEncoder(w).Encode(map[string]any{"active": true})
		return
	}
	active, err := h.Svc.Active(r.Context(), userID)
	if err != nil { http.Error(w, "server error", http.StatusInternalServerError); return }
	if active { h.Redis.Set(r.Context(), h.activeKey(userID), "1", 30*time.Minute) }
	_ = json.NewEncoder(w).Encode(map[string]any{"active": active})
}

func (h *SessionHandlers) DailyStats(w http.ResponseWriter, r *http.Request) {
	userID, ok := GetUserID(r)
	if !ok { http.Error(w, "unauthorized", http.StatusUnauthorized); return }
	dur, err := h.Svc.DailyStats(r.Context(), userID, time.Now())
	if err != nil { http.Error(w, "server error", http.StatusInternalServerError); return }
	_ = json.NewEncoder(w).Encode(map[string]any{"seconds": dur})
}

func (h *SessionHandlers) activeKey(userID int64) string { return "active:" + fmtInt(userID) }

func fmtInt(v int64) string { return strconv.FormatInt(v, 10) }
