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

func Handler(baseURL string) gin.HandlerFunc {
	return func(c *gin.Context) {
		file, header, err := c.Request.FormFile("file")
		if err != nil {
			utils.BadRequest(c, "VALIDATION_ERROR", "no file provided")
			return
		}
		defer file.Close()

		uploadDir := "./uploads"
		if err := os.MkdirAll(uploadDir, 0755); err != nil {
			utils.InternalError(c)
			return
		}

		ext := filepath.Ext(header.Filename)
		filename := fmt.Sprintf("%d%s", time.Now().UnixMilli(), ext)
		dst := filepath.Join(uploadDir, filename)

		out, err := os.Create(dst)
		if err != nil {
			utils.InternalError(c)
			return
		}
		defer out.Close()

		if _, err := io.Copy(out, file); err != nil {
			utils.InternalError(c)
			return
		}

		url := fmt.Sprintf("%s/uploads/%s", baseURL, filename)
		c.JSON(http.StatusOK, gin.H{
			"success": true,
			"data":    gin.H{"url": url},
		})
	}
}