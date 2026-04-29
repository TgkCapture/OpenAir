package content

import (
	"context"
	"crypto/hmac"
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"time"

	"github.com/TgkCapture/openair/pkg/config"
)

type Service struct {
	repo *Repository
	cfg  *config.Config
}

func NewService(repo *Repository, cfg *config.Config) *Service {
	return &Service{repo: repo, cfg: cfg}
}

func (s *Service) GetAll(ctx context.Context, contentType, category, search string, page, perPage int) (*ContentListResponse, error) {
	if page < 1 {
		page = 1
	}
	if perPage < 1 || perPage > 50 {
		perPage = 20
	}
	return s.repo.GetAll(ctx, contentType, category, search, page, perPage)
}

func (s *Service) GetByID(ctx context.Context, id string) (*Content, error) {
	c, err := s.repo.GetByID(ctx, id)
	if err != nil {
		return nil, err
	}
	if c == nil {
		return nil, ErrContentNotFound
	}
	return c, nil
}

func (s *Service) GetStreamURL(ctx context.Context, id, userID string, isPremium bool) (string, error) {
	c, err := s.GetByID(ctx, id)
	if err != nil {
		return "", err
	}

	go s.repo.IncrementViewCount(ctx, id)

	if c.IsPremium && !isPremium {
		return "", ErrPremiumRequired
	}

	if !c.IsPremium {
		return c.FileURL, nil
	}

	expiresAt := time.Now().Add(2 * time.Hour).Unix()
	token := s.signURL(c.FileURL, userID, expiresAt)
	return fmt.Sprintf("%s?token=%s&expires=%d", c.FileURL, token, expiresAt), nil
}

func (s *Service) signURL(url, userID string, expiresAt int64) string {
	h := hmac.New(sha256.New, []byte(s.cfg.RTMPSecret))
	h.Write([]byte(fmt.Sprintf("%s:%s:%d", url, userID, expiresAt)))
	return hex.EncodeToString(h.Sum(nil))
}

func (s *Service) Create(ctx context.Context, req CreateContentRequest) (*Content, error) {
	return s.repo.Create(ctx, req)
}

func (s *Service) Update(ctx context.Context, id string, req UpdateContentRequest) (*Content, error) {
	return s.repo.Update(ctx, id, req)
}

func (s *Service) ToggleAccess(ctx context.Context, id string, isPremium bool) error {
	return s.repo.ToggleAccess(ctx, id, isPremium)
}

func (s *Service) GetCategories(ctx context.Context) ([]string, error) {
	return s.repo.GetCategories(ctx)
}

func (s *Service) SaveWatchHistory(ctx context.Context, userID, contentID string, progressSecs int) error {
	return s.repo.SaveWatchHistory(ctx, userID, contentID, progressSecs)
}

func (s *Service) GetWatchHistory(ctx context.Context, userID string) ([]*Content, error) {
	return s.repo.GetWatchHistory(ctx, userID, 20)
}