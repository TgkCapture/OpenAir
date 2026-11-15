package middleware

import (
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/TgkCapture/openair/pkg/token"
	"github.com/TgkCapture/openair/pkg/utils"
)

func Auth(tokenManager *token.Manager) gin.HandlerFunc {
	return func(c *gin.Context) {
		header := c.GetHeader("Authorization")
		if !strings.HasPrefix(header, "Bearer ") {
			utils.Unauthorized(c, "UNAUTHORIZED", "missing authorization header")
			c.Abort()
			return
		}

		tokenStr := strings.TrimPrefix(header, "Bearer ")
		claims, err := tokenManager.VerifyAccessToken(tokenStr)
		if err != nil {
			utils.Unauthorized(c, "UNAUTHORIZED", "invalid or expired token")
			c.Abort()
			return
		}

		c.Set("user_id", claims.UserID)
		c.Set("user_email", claims.Email)
		c.Set("user_role", claims.Role)
		c.Next()
	}
}

// OptionalAuth is for routes that guests may use but that behave differently
// for signed-in users. A request with no token continues as a guest. A request
// with a bad or expired token is rejected, so the client knows to renew it
// instead of being silently treated as a guest.
func OptionalAuth(tokenManager *token.Manager) gin.HandlerFunc {
	return func(c *gin.Context) {
		header := c.GetHeader("Authorization")
		if header == "" {
			c.Next()
			return
		}
		if !strings.HasPrefix(header, "Bearer ") {
			utils.Unauthorized(c, "UNAUTHORIZED", "invalid authorization header")
			c.Abort()
			return
		}

		claims, err := tokenManager.VerifyAccessToken(strings.TrimPrefix(header, "Bearer "))
		if err != nil {
			utils.Unauthorized(c, "UNAUTHORIZED", "invalid or expired token")
			c.Abort()
			return
		}

		c.Set("user_id", claims.UserID)
		c.Set("user_email", claims.Email)
		c.Set("user_role", claims.Role)
		c.Next()
	}
}

func RequireRole(role string) gin.HandlerFunc {
	return func(c *gin.Context) {
		userRole := c.GetString("user_role")
		if userRole != role {
			utils.Forbidden(c, "FORBIDDEN", "insufficient permissions")
			c.Abort()
			return
		}
		c.Next()
	}
}