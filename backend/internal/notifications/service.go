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

func (s *Service) UnregisterToken(ctx context.Context, userID, token string) error {
	return s.repo.DeleteToken(ctx, userID, token)
}

// Send stores an in-app notification for every recipient, then pushes to the
// devices that have registered a token. The in-app copy is stored even for
// users with no registered device.
func (s *Service) Send(ctx context.Context, req SendNotificationRequest) (*SendResult, error) {
	var (
		saved  int
		tokens []string
		err    error
	)

	if req.SendAll {
		if saved, err = s.repo.SaveNotificationForAll(ctx, req.Title, req.Body); err != nil {
			return nil, err
		}
		tokens, err = s.repo.GetAllTokens(ctx)
	} else {
		if saved, err = s.repo.SaveNotification(ctx, req.UserIDs, req.Title, req.Body); err != nil {
			return nil, err
		}
		tokens, err = s.repo.GetTokensByUserIDs(ctx, req.UserIDs)
	}
	if err != nil {
		return nil, err
	}

	sent := 0
	for _, token := range tokens {
		if err := s.sendFCM(token, req); err != nil {
			log.Printf("FCM send error for token %s: %v", shortToken(token), err)
		} else {
			sent++
		}
	}

	return &SendResult{Saved: saved, Sent: sent}, nil
}

// shortToken returns a few characters of a device token for logs.
func shortToken(token string) string {
	if len(token) <= 8 {
		return token
	}
	return token[:8] + "..."
}

func (s *Service) sendFCM(token string, req SendNotificationRequest) error {
	if s.cfg.FCMServerKey == "" {
		log.Printf("FCM: would send to %s: %s - %s", shortToken(token), req.Title, req.Body)
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