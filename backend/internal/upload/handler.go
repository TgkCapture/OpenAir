package upload

import (
	"crypto/rand"
	"encoding/hex"
	"errors"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/TgkCapture/openair/pkg/utils"
	"github.com/gin-gonic/gin"
)

// Config controls where uploads are stored and how they are limited.
type Config struct {
	// Dir is the folder files are written to. It is served at /uploads.
	Dir string
	// PublicBaseURL is the address clients use to reach this server, for
	// example "https://api.example.com". When empty, the URL is built from
	// the request, which is only right when every client reaches the server
	// by the same address.
	PublicBaseURL string
	// MaxBytes is the largest file accepted.
	MaxBytes int64
}

// allowedExtensions lists the file types the admin dashboard uploads:
// artwork and logos, podcast audio, and video.
var allowedExtensions = map[string]bool{
	".jpg": true, ".jpeg": true, ".png": true, ".webp": true, ".gif": true,
	".mp3": true, ".m4a": true, ".aac": true, ".wav": true, ".ogg": true,
	".mp4": true, ".mov": true, ".mkv": true, ".webm": true,
}

// Handler stores an uploaded file and returns the URL it is served from.
func Handler(cfg Config) gin.HandlerFunc {
	return func(c *gin.Context) {
		// The server's default read and write timeouts are sized for JSON
		// requests. Lift them for this request so a large video can finish.
		rc := http.NewResponseController(c.Writer)
		if err := rc.SetReadDeadline(time.Time{}); err != nil {
			log.Printf("WARN upload: cannot extend read deadline: %v", err)
		}
		if err := rc.SetWriteDeadline(time.Time{}); err != nil {
			log.Printf("WARN upload: cannot extend write deadline: %v", err)
		}

		// Stop reading once the body is clearly over the limit. The extra
		// megabyte leaves room for the multipart framing around the file.
		c.Request.Body = http.MaxBytesReader(c.Writer, c.Request.Body, cfg.MaxBytes+1<<20)

		file, header, err := c.Request.FormFile("file")
		if err != nil {
			var tooLarge *http.MaxBytesError
			if errors.As(err, &tooLarge) {
				fileTooLarge(c, cfg.MaxBytes)
				return
			}
			utils.BadRequest(c, "VALIDATION_ERROR", "no file provided")
			return
		}
		defer file.Close()

		if header.Size > cfg.MaxBytes {
			fileTooLarge(c, cfg.MaxBytes)
			return
		}

		ext := strings.ToLower(filepath.Ext(header.Filename))
		if !allowedExtensions[ext] {
			utils.BadRequest(c, "UNSUPPORTED_FILE_TYPE",
				"file type not allowed; upload an image, audio or video file")
			return
		}

		if err := os.MkdirAll(cfg.Dir, 0755); err != nil {
			log.Printf("ERROR upload: create dir: %v", err)
			utils.InternalError(c)
			return
		}

		filename := uniqueName(ext)
		dst := filepath.Join(cfg.Dir, filename)

		out, err := os.Create(dst)
		if err != nil {
			log.Printf("ERROR upload: create file: %v", err)
			utils.InternalError(c)
			return
		}

		_, copyErr := io.Copy(out, file)
		closeErr := out.Close()
		if copyErr != nil || closeErr != nil {
			// Do not leave a half-written file behind.
			_ = os.Remove(dst)
			log.Printf("ERROR upload: write file: %v", errors.Join(copyErr, closeErr))
			utils.InternalError(c)
			return
		}

		c.JSON(http.StatusOK, gin.H{
			"success": true,
			"data":    gin.H{"url": publicBaseURL(cfg, c.Request) + "/uploads/" + filename},
		})
	}
}

// uniqueName returns a filename that will not collide when two uploads land
// in the same millisecond.
func uniqueName(ext string) string {
	suffix := make([]byte, 4)
	_, _ = rand.Read(suffix)
	return fmt.Sprintf("%d-%s%s", time.Now().UnixMilli(), hex.EncodeToString(suffix), ext)
}

// publicBaseURL returns the configured public address, or falls back to the
// address this request arrived on.
func publicBaseURL(cfg Config, r *http.Request) string {
	if cfg.PublicBaseURL != "" {
		return strings.TrimRight(cfg.PublicBaseURL, "/")
	}
	scheme := "http"
	if r.TLS != nil || r.Header.Get("X-Forwarded-Proto") == "https" {
		scheme = "https"
	}
	return scheme + "://" + r.Host
}

func fileTooLarge(c *gin.Context, maxBytes int64) {
	c.JSON(http.StatusRequestEntityTooLarge, utils.Response{
		Success: false,
		Error: &utils.APIError{
			Code:    "FILE_TOO_LARGE",
			Message: fmt.Sprintf("file is larger than the %d MB limit", maxBytes>>20),
		},
	})
}
