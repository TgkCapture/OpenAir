package notifications

import (
	"context"
	"fmt"

	"github.com/jackc/pgx/v5/pgxpool"
)

type Repository struct {
	db *pgxpool.Pool
}

func NewRepository(db *pgxpool.Pool) *Repository {
	return &Repository{db: db}
}

func (r *Repository) UpsertToken(ctx context.Context, userID, token, deviceType string) error {
	_, err := r.db.Exec(ctx, `
		INSERT INTO fcm_tokens (user_id, token, device_type)
		VALUES ($1, $2, $3)
		ON CONFLICT (token) DO UPDATE
		SET user_id=$1, device_type=$3, created_at=NOW()`,
		userID, token, deviceType)
	return err
}

// DeleteToken removes a device token, but only for the user who owns it.
func (r *Repository) DeleteToken(ctx context.Context, userID, token string) error {
	_, err := r.db.Exec(ctx,
		`DELETE FROM fcm_tokens WHERE user_id=$1 AND token=$2`, userID, token)
	return err
}

func (r *Repository) GetTokensByUserIDs(ctx context.Context, userIDs []string) ([]string, error) {
	rows, err := r.db.Query(ctx, `
		SELECT token FROM fcm_tokens WHERE user_id::text = ANY($1)`, userIDs)
	if err != nil {
		return nil, fmt.Errorf("get tokens: %w", err)
	}
	defer rows.Close()

	var tokens []string
	for rows.Next() {
		var t string
		rows.Scan(&t)
		tokens = append(tokens, t)
	}
	return tokens, nil
}

func (r *Repository) GetAllTokens(ctx context.Context) ([]string, error) {
	rows, err := r.db.Query(ctx, `SELECT DISTINCT token FROM fcm_tokens`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var tokens []string
	for rows.Next() {
		var t string
		rows.Scan(&t)
		tokens = append(tokens, t)
	}
	return tokens, nil
}

// SaveNotification stores an in-app notification for each listed user that
// exists and returns how many were stored.
func (r *Repository) SaveNotification(ctx context.Context, userIDs []string, title, body string) (int, error) {
	tag, err := r.db.Exec(ctx, `
		INSERT INTO notifications (user_id, title, body)
		SELECT id, $2, $3 FROM users WHERE id::text = ANY($1)`,
		userIDs, title, body)
	if err != nil {
		return 0, fmt.Errorf("save notifications: %w", err)
	}
	return int(tag.RowsAffected()), nil
}

// SaveNotificationForAll stores an in-app notification for every active user
// and returns how many were stored.
func (r *Repository) SaveNotificationForAll(ctx context.Context, title, body string) (int, error) {
	tag, err := r.db.Exec(ctx, `
		INSERT INTO notifications (user_id, title, body)
		SELECT id, $1, $2 FROM users WHERE is_active = true`,
		title, body)
	if err != nil {
		return 0, fmt.Errorf("save notifications for all: %w", err)
	}
	return int(tag.RowsAffected()), nil
}

func (r *Repository) GetUserNotifications(ctx context.Context, userID string) ([]map[string]interface{}, error) {
	rows, err := r.db.Query(ctx, `
		SELECT id, title, body, is_read, sent_at
		FROM notifications
		WHERE user_id=$1
		ORDER BY sent_at DESC
		LIMIT 50`, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var result []map[string]interface{}
	for rows.Next() {
		var id, title, body string
		var isRead bool
		var sentAt interface{}
		rows.Scan(&id, &title, &body, &isRead, &sentAt)
		result = append(result, map[string]interface{}{
			"id": id, "title": title, "body": body,
			"is_read": isRead, "sent_at": sentAt,
		})
	}
	if result == nil {
		result = []map[string]interface{}{}
	}
	return result, nil
}

func (r *Repository) MarkAllRead(ctx context.Context, userID string) error {
	_, err := r.db.Exec(ctx, `
		UPDATE notifications SET is_read=true WHERE user_id=$1`, userID)
	return err
}