package realtime

import (
	"fmt"
	"net/http"
	"sync"
	"time"
)

type Hub struct{
	mu sync.Mutex
	subs map[int64]map[chan string]struct{}
}

func NewHub()*Hub{ return &Hub{subs: make(map[int64]map[chan string]struct{})} }

func (h *Hub) Subscribe(userID int64) chan string {
	ch := make(chan string, 8)
	h.mu.Lock()
	defer h.mu.Unlock()
	m := h.subs[userID]
	if m == nil { m = make(map[chan string]struct{}); h.subs[userID]=m }
	m[ch]=struct{}{}
	return ch
}

func (h *Hub) Unsubscribe(userID int64, ch chan string){
	h.mu.Lock(); defer h.mu.Unlock()
	if m := h.subs[userID]; m!=nil {
		delete(m, ch)
		close(ch)
		if len(m)==0 { delete(h.subs, userID) }
	}
}

func (h *Hub) Broadcast(userID int64, msg string){
	h.mu.Lock(); defer h.mu.Unlock()
	for ch := range h.subs[userID] {
		select { case ch<-msg: default: }
	}
}

func (h *Hub) SSEHandler(getUserID func(*http.Request)(int64,bool)) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request){
		userID, ok := getUserID(r)
		if !ok { http.Error(w, "unauthorized", http.StatusUnauthorized); return }
		w.Header().Set("Content-Type", "text/event-stream")
		w.Header().Set("Cache-Control", "no-cache")
		w.Header().Set("Connection", "keep-alive")
		flusher, ok := w.(http.Flusher)
		if !ok { http.Error(w, "streaming unsupported", http.StatusInternalServerError); return }
		ch := h.Subscribe(userID)
		defer h.Unsubscribe(userID, ch)
		fmt.Fprintf(w, "event: ping\n")
		fmt.Fprintf(w, "data: %s\n\n", time.Now().Format(time.RFC3339))
		flusher.Flush()
		for {
			select{
			case <-r.Context().Done():
				return
			case msg := <-ch:
				fmt.Fprintf(w, "data: %s\n\n", msg)
				flusher.Flush()
			}
		}
	}
}
