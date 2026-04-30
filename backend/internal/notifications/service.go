package notifications

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"

	"github.com/TgkCapture/openair/pkg/config"
)

type Service struct {
	repo *Repository
	cfg  *config.Config
}

func NewService(repo *Repository, cfg *config.Config) *Service {
	return &Service{repo: repo, cfg: cfg}
}

func (s *Service) RegisterToken(ctx context.Context, userID, token, deviceType string) error {
	return s.repo.UpsertToken(ctx, userID, token, deviceType)
}

func (s *Service) Send(ctx context.Context, req SendNotificationRequest) (int, error) {
	var tokens []string
	var err error

	if req.SendAll {
		tokens, err = s.repo.GetAllTokens(ctx)
	} else if len(req.UserIDs) > 0 {
		tokens, err = s.repo.GetTokensByUserIDs(ctx, req.UserIDs)
	}
	if err != nil {
		return 0, err
	}

	if len(tokens) == 0 {
		return 0, nil
	}

	// Save in-app notifications
	if len(req.UserIDs) > 0 {
		s.repo.SaveNotification(ctx, req.UserIDs, req.Title, req.Body)
	}

	// Send FCM push
	sent := 0
	for _, token := range tokens {
		if err := s.sendFCM(token, req); err != nil {
			log.Printf("FCM send error for token %s: %v", token[:8]+"...", err)
		} else {
			sent++
		}
	}

	return sent, nil
}

func (s *Service) sendFCM(token string, req SendNotificationRequest) error {
	if s.cfg.FCMServerKey == "" {
		log.Printf("FCM: would send to %s: %s - %s", token[:8]+"...", req.Title, req.Body)
		return nil
	}

	msg := FCMMessage{
		Message: FCMMessageBody{
			Token: token,
			Notification: FCMNotification{
				Title:    req.Title,
				Body:     req.Body,
				ImageURL: req.ImageURL,
			},
			Data: req.Data,
		},
	}

	body, _ := json.Marshal(msg)
	httpReq, err := http.NewRequest("POST",
		"https://fcm.googleapis.com/v1/messages:send",
		bytes.NewBuffer(body))
	if err != nil {
		return err
	}

	httpReq.Header.Set("Content-Type", "application/json")
	httpReq.Header.Set("Authorization", "Bearer "+s.cfg.FCMServerKey)

	client := &http.Client{}
	resp, err := client.Do(httpReq)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("FCM returned status %d", resp.StatusCode)
	}
	return nil
}

func (s *Service) GetUserNotifications(ctx context.Context, userID string) ([]map[string]interface{}, error) {
	return s.repo.GetUserNotifications(ctx, userID)
}

func (s *Service) MarkAllRead(ctx context.Context, userID string) error {
	return s.repo.MarkAllRead(ctx, userID)
}