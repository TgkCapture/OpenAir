package middleware

import (
	"net/http"
	"net/http/httptest"
	"path/filepath"
	"testing"

	"github.com/TgkCapture/openair/pkg/token"
	"github.com/gin-gonic/gin"
)

func newTokenManager(t *testing.T) *token.Manager {
	t.Helper()
	dir := t.TempDir()
	private := filepath.Join(dir, "private.pem")
	public := filepath.Join(dir, "public.pem")
	if err := token.EnsureKeysExist(private, public); err != nil {
		t.Fatalf("generate keys: %v", err)
	}
	tm, err := token.NewManager(private, public)
	if err != nil {
		t.Fatalf("new token manager: %v", err)
	}
	return tm
}

// optionalAuthStatus calls a route guarded by OptionalAuth and returns the
// status code and the role the handler saw.
func optionalAuthStatus(t *testing.T, tm *token.Manager, authorization string) (int, string) {
	t.Helper()
	gin.SetMode(gin.TestMode)

	var role string
	router := gin.New()
	router.GET("/stream", OptionalAuth(tm), func(c *gin.Context) {
		role = c.GetString("user_role")
		c.Status(http.StatusOK)
	})

	req := httptest.NewRequest(http.MethodGet, "/stream", nil)
	if authorization != "" {
		req.Header.Set("Authorization", authorization)
	}
	rec := httptest.NewRecorder()
	router.ServeHTTP(rec, req)
	return rec.Code, role
}

func TestOptionalAuth(t *testing.T) {
	tm := newTokenManager(t)
	valid, err := tm.GenerateAccessToken("user-1", "viewer@example.com", "admin")
	if err != nil {
		t.Fatalf("generate token: %v", err)
	}

	t.Run("no token continues as a guest", func(t *testing.T) {
		code, role := optionalAuthStatus(t, tm, "")
		if code != http.StatusOK || role != "" {
			t.Fatalf("got status %d role %q, want 200 and no role", code, role)
		}
	})

	t.Run("valid token identifies the user", func(t *testing.T) {
		code, role := optionalAuthStatus(t, tm, "Bearer "+valid)
		if code != http.StatusOK || role != "admin" {
			t.Fatalf("got status %d role %q, want 200 and admin", code, role)
		}
	})

	t.Run("bad token is rejected, not treated as a guest", func(t *testing.T) {
		code, _ := optionalAuthStatus(t, tm, "Bearer not-a-real-token")
		if code != http.StatusUnauthorized {
			t.Fatalf("got status %d, want 401", code)
		}
	})
}
