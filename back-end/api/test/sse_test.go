package test

import (
	"bufio"
	"context"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	realtime "github.com/kayis-rahman/time-beam/internal/realtime"
)

type flushRecorder struct{ *httptest.ResponseRecorder }

func (f flushRecorder) Flush() {}

func TestHubSubscribeBroadcastUnsubscribe(t *testing.T){
	h := realtime.NewHub()
	ch := h.Subscribe(1)
	h.Broadcast(1, "hello")
	select {
	case msg := <-ch:
		if msg != "hello" { t.Fatalf("expected hello, got %q", msg) }
	case <-time.After(100 * time.Millisecond):
		t.Fatal("timeout waiting for broadcast")
	}
	h.Unsubscribe(1, ch)
}

func TestSSEHandler_InitialPingAndMessage(t *testing.T){
	h := realtime.NewHub()
	handler := h.SSEHandler(func(r *http.Request)(int64,bool){ return 7,true })

	rec := flushRecorder{httptest.NewRecorder()}
	req := httptest.NewRequest(http.MethodGet, "/sync/stream", nil)
	req.Header.Set("Accept", "text/event-stream")

	// Attach cancelable context
	ctx, cancel := context.WithCancel(req.Context())
	req = req.WithContext(ctx)

	// run handler in a goroutine and then broadcast one message
	done := make(chan struct{})
	go func(){
		handler(rec, req)
		close(done)
	}()

	// Give it a moment to subscribe and write ping
	time.Sleep(30*time.Millisecond)
	h.Broadcast(7, "world")
	// Allow write
	time.Sleep(30*time.Millisecond)

	body := rec.Body.String()
	if !strings.Contains(body, "event: ping") { t.Fatalf("expected ping event, got %q", body) }
	if !strings.Contains(body, "data: world") { t.Fatalf("expected world data, got %q", body) }

	// cancel to let the handler exit
	cancel()
	select {
	case <-done:
	case <-time.After(200 * time.Millisecond):
		t.Fatal("handler did not exit after cancel")
	}
	_ = bufio.NewReader(strings.NewReader(body))
}
