package upload

import (
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/TgkCapture/openair/pkg/utils"
)

// Handler returns a gin handler function that handles file uploads
func Handler() gin.HandlerFunc {
	return func(c *gin.Context) {
		// Get the uploaded file
		file, header, err := c.Request.FormFile("file")
		if err != nil {
			utils.BadRequest(c, "VALIDATION_ERROR", "no file provided")
			return
		}
		defer file.Close()

		// Create uploads directory if it doesn't exist
		uploadDir := "./uploads"
		if err := os.MkdirAll(uploadDir, 0755); err != nil {
			utils.InternalError(c)
			return
		}

		// Generate unique filename using timestamp
		ext := filepath.Ext(header.Filename)
		filename := fmt.Sprintf("%d%s", time.Now().UnixMilli(), ext)
		dst := filepath.Join(uploadDir, filename)

		// Create the destination file
		out, err := os.Create(dst)
		if err != nil {
			utils.InternalError(c)
			return
		}
		defer out.Close()

		// Copy uploaded file content to destination
		if _, err := io.Copy(out, file); err != nil {
			utils.InternalError(c)
			return
		}

		// Derive URL from request host so mobile clients get the right IP
		scheme := "http"
		if c.Request.TLS != nil {
			scheme = "https"
		}
		host := c.Request.Host
		url := fmt.Sprintf("%s://%s/uploads/%s", scheme, host, filename)

		// Return success response with the file URL
		c.JSON(http.StatusOK, gin.H{
			"success": true,
			"data":    gin.H{"url": url},
		})
	}
}