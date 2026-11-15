package server

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
)

func corsHeader(t *testing.T, allowed []string, origin, method string) (int, string) {
	t.Helper()
	gin.SetMode(gin.TestMode)

	router := gin.New()
	router.Use(corsMiddleware(allowed))
	router.GET("/ping", func(c *gin.Context) { c.Status(http.StatusOK) })

	req := httptest.NewRequest(method, "/ping", nil)
	if origin != "" {
		req.Header.Set("Origin", origin)
	}
	rec := httptest.NewRecorder()
	router.ServeHTTP(rec, req)
	return rec.Code, rec.Header().Get("Access-Control-Allow-Origin")
}

func TestCORSAllowsOnlyListedOrigins(t *testing.T) {
	allowed := []string{"https://admin.example.com"}

	if _, got := corsHeader(t, allowed, "https://admin.example.com", http.MethodGet); got != "https://admin.example.com" {
		t.Fatalf("listed origin: got %q", got)
	}
	if _, got := corsHeader(t, allowed, "https://evil.example.com", http.MethodGet); got != "" {
		t.Fatalf("unlisted origin must not be allowed, got %q", got)
	}
	if _, got := corsHeader(t, allowed, "", http.MethodGet); got != "" {
		t.Fatalf("no origin header: got %q", got)
	}
}

func TestCORSWildcardAllowsAnyOrigin(t *testing.T) {
	if _, got := corsHeader(t, []string{"*"}, "https://anything.example.com", http.MethodGet); got != "*" {
		t.Fatalf("got %q, want *", got)
	}
}

func TestCORSAnswersPreflight(t *testing.T) {
	code, got := corsHeader(t, []string{"https://admin.example.com"}, "https://admin.example.com", http.MethodOptions)
	if code != http.StatusNoContent || got != "https://admin.example.com" {
		t.Fatalf("got %d %q", code, got)
	}
}
