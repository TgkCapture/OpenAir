package upload

import (
	"bytes"
	"encoding/json"
	"mime/multipart"
	"net/http"
	"net/http/httptest"
	"os"
	"strings"
	"testing"

	"github.com/gin-gonic/gin"
)

// post uploads a file of the given name and size and returns the response.
func post(t *testing.T, cfg Config, filename string, size int) *httptest.ResponseRecorder {
	t.Helper()
	gin.SetMode(gin.TestMode)

	var body bytes.Buffer
	form := multipart.NewWriter(&body)
	part, err := form.CreateFormFile("file", filename)
	if err != nil {
		t.Fatalf("create form file: %v", err)
	}
	if _, err := part.Write(bytes.Repeat([]byte("a"), size)); err != nil {
		t.Fatalf("write form file: %v", err)
	}
	form.Close()

	router := gin.New()
	router.POST("/upload", Handler(cfg))

	req := httptest.NewRequest(http.MethodPost, "/upload", &body)
	req.Host = "192.168.1.50:8000"
	req.Header.Set("Content-Type", form.FormDataContentType())
	rec := httptest.NewRecorder()
	router.ServeHTTP(rec, req)
	return rec
}

func uploadedURL(t *testing.T, rec *httptest.ResponseRecorder) string {
	t.Helper()
	var resp struct {
		Data struct {
			URL string `json:"url"`
		} `json:"data"`
	}
	if err := json.Unmarshal(rec.Body.Bytes(), &resp); err != nil {
		t.Fatalf("decode response: %v", err)
	}
	return resp.Data.URL
}

func errorCode(t *testing.T, rec *httptest.ResponseRecorder) string {
	t.Helper()
	var resp struct {
		Error struct {
			Code string `json:"code"`
		} `json:"error"`
	}
	if err := json.Unmarshal(rec.Body.Bytes(), &resp); err != nil {
		t.Fatalf("decode response: %v", err)
	}
	return resp.Error.Code
}

func TestUploadUsesConfiguredPublicURL(t *testing.T) {
	cfg := Config{Dir: t.TempDir(), PublicBaseURL: "https://media.example.com/", MaxBytes: 1 << 20}

	rec := post(t, cfg, "Episode One.MP3", 100)
	if rec.Code != http.StatusOK {
		t.Fatalf("got status %d, want 200: %s", rec.Code, rec.Body.String())
	}

	url := uploadedURL(t, rec)
	if !strings.HasPrefix(url, "https://media.example.com/uploads/") || !strings.HasSuffix(url, ".mp3") {
		t.Fatalf("unexpected url %q", url)
	}

	files, _ := os.ReadDir(cfg.Dir)
	if len(files) != 1 {
		t.Fatalf("expected one stored file, found %d", len(files))
	}
}

func TestUploadFallsBackToRequestHost(t *testing.T) {
	cfg := Config{Dir: t.TempDir(), MaxBytes: 1 << 20}

	url := uploadedURL(t, post(t, cfg, "logo.png", 100))
	if !strings.HasPrefix(url, "http://192.168.1.50:8000/uploads/") {
		t.Fatalf("unexpected url %q", url)
	}
}

func TestUploadRejectsUnsupportedType(t *testing.T) {
	cfg := Config{Dir: t.TempDir(), MaxBytes: 1 << 20}

	rec := post(t, cfg, "script.exe", 100)
	if rec.Code != http.StatusBadRequest || errorCode(t, rec) != "UNSUPPORTED_FILE_TYPE" {
		t.Fatalf("got %d %s, want 400 UNSUPPORTED_FILE_TYPE", rec.Code, rec.Body.String())
	}
	if files, _ := os.ReadDir(cfg.Dir); len(files) != 0 {
		t.Fatalf("a rejected file was stored")
	}
}

func TestUploadRejectsOversizedFile(t *testing.T) {
	cfg := Config{Dir: t.TempDir(), MaxBytes: 1 << 20}

	// Just over the limit, and far over it (cut off while reading the body).
	for _, size := range []int{1<<20 + 1, 4 << 20} {
		rec := post(t, cfg, "video.mp4", size)
		if rec.Code != http.StatusRequestEntityTooLarge || errorCode(t, rec) != "FILE_TOO_LARGE" {
			t.Fatalf("size %d: got %d %s, want 413 FILE_TOO_LARGE", size, rec.Code, rec.Body.String())
		}
	}
	if files, _ := os.ReadDir(cfg.Dir); len(files) != 0 {
		t.Fatalf("an oversized file was stored")
	}
}
