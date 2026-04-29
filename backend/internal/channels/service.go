package channels

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

func (s *Service) GetAll(ctx context.Context, channelType string) ([]*Channel, error) {
	return s.repo.GetAll(ctx, channelType)
}

func (s *Service) GetByID(ctx context.Context, id string) (*Channel, error) {
	ch, err := s.repo.GetByID(ctx, id)
	if err != nil {
		return nil, err
	}
	if ch == nil {
		return nil, ErrChannelNotFound
	}
	return ch, nil
}

func (s *Service) GetStreamURL(ctx context.Context, id, userID string, isPremiumUser bool) (*StreamURLResponse, error) {
	ch, err := s.GetByID(ctx, id)
	if err != nil {
		return nil, err
	}

	if ch.IsPremium && !isPremiumUser {
		return nil, ErrPremiumRequired
	}

	// For free channels return URL directly
	if !ch.IsPremium {
		return &StreamURLResponse{
			URL:       ch.StreamURL,
			ExpiresAt: 0,
		}, nil
	}

	// For premium channels generate signed URL
	expiresAt := time.Now().Add(2 * time.Hour).Unix()
	signed := s.signURL(ch.StreamURL, userID, expiresAt)

	return &StreamURLResponse{
		URL:       fmt.Sprintf("%s?token=%s&expires=%d", ch.StreamURL, signed, expiresAt),
		ExpiresAt: expiresAt,
	}, nil
}

func (s *Service) signURL(url, userID string, expiresAt int64) string {
	h := hmac.New(sha256.New, []byte(s.cfg.RTMPSecret))
	h.Write([]byte(fmt.Sprintf("%s:%s:%d", url, userID, expiresAt)))
	return hex.EncodeToString(h.Sum(nil))
}

func (s *Service) Create(ctx context.Context, req CreateChannelRequest) (*Channel, error) {
	return s.repo.Create(ctx, req)
}

func (s *Service) Update(ctx context.Context, id string, req UpdateChannelRequest) (*Channel, error) {
	return s.repo.Update(ctx, id, req)
}

func (s *Service) Delete(ctx context.Context, id string) error {
	return s.repo.Delete(ctx, id)
}

func (s *Service) ToggleAccess(ctx context.Context, id string, isPremium bool) (*Channel, error) {
	return s.repo.ToggleAccess(ctx, id, isPremium)
}

func (s *Service) isUserPremium(ctx context.Context, userID, role string) (bool, error) {
	if role == "admin" {
		return true, nil
	}
	// For now only admins get premium access
	return false, nil
}