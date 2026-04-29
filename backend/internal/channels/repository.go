package channels

import (
	"context"
	"errors"
	"fmt"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

type Repository struct {
	db *pgxpool.Pool
}

func NewRepository(db *pgxpool.Pool) *Repository {
	return &Repository{db: db}
}

func (r *Repository) GetAll(ctx context.Context, channelType string) ([]*Channel, error) {
	query := `
		SELECT id, name, type, stream_url, logo_url, description,
		       is_premium, is_active, sort_order, created_at
		FROM channels
		WHERE is_active = true`

	args := []interface{}{}
	if channelType != "" {
		query += " AND type = $1"
		args = append(args, channelType)
	}
	query += " ORDER BY sort_order ASC, name ASC"

	rows, err := r.db.Query(ctx, query, args...)
	if err != nil {
		return nil, fmt.Errorf("get channels: %w", err)
	}
	defer rows.Close()

	var channels []*Channel
	for rows.Next() {
		c := &Channel{}
		if err := rows.Scan(&c.ID, &c.Name, &c.Type, &c.StreamURL,
			&c.LogoURL, &c.Description, &c.IsPremium,
			&c.IsActive, &c.SortOrder, &c.CreatedAt); err != nil {
			return nil, err
		}
		channels = append(channels, c)
	}
	return channels, nil
}

func (r *Repository) GetByID(ctx context.Context, id string) (*Channel, error) {
	c := &Channel{}
	query := `
		SELECT id, name, type, stream_url, logo_url, description,
		       is_premium, is_active, sort_order, created_at
		FROM channels WHERE id = $1`

	err := r.db.QueryRow(ctx, query, id).Scan(
		&c.ID, &c.Name, &c.Type, &c.StreamURL,
		&c.LogoURL, &c.Description, &c.IsPremium,
		&c.IsActive, &c.SortOrder, &c.CreatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil
		}
		return nil, fmt.Errorf("get channel by id: %w", err)
	}
	return c, nil
}

func (r *Repository) Create(ctx context.Context, req CreateChannelRequest) (*Channel, error) {
	c := &Channel{}
	query := `
		INSERT INTO channels (name, type, stream_url, logo_url, description, is_premium, sort_order)
		VALUES ($1, $2, $3, $4, $5, $6, $7)
		RETURNING id, name, type, stream_url, logo_url, description,
		          is_premium, is_active, sort_order, created_at`

	err := r.db.QueryRow(ctx, query,
		req.Name, req.Type, req.StreamURL, req.LogoURL,
		req.Description, req.IsPremium, req.SortOrder,
	).Scan(&c.ID, &c.Name, &c.Type, &c.StreamURL,
		&c.LogoURL, &c.Description, &c.IsPremium,
		&c.IsActive, &c.SortOrder, &c.CreatedAt)
	if err != nil {
		return nil, fmt.Errorf("create channel: %w", err)
	}
	return c, nil
}

func (r *Repository) Update(ctx context.Context, id string, req UpdateChannelRequest) (*Channel, error) {
	c := &Channel{}
	query := `
		UPDATE channels
		SET name=$2, stream_url=$3, logo_url=$4, description=$5,
		    is_premium=$6, is_active=$7, sort_order=$8, updated_at=NOW()
		WHERE id=$1
		RETURNING id, name, type, stream_url, logo_url, description,
		          is_premium, is_active, sort_order, created_at`

	err := r.db.QueryRow(ctx, query,
		id, req.Name, req.StreamURL, req.LogoURL,
		req.Description, req.IsPremium, req.IsActive, req.SortOrder,
	).Scan(&c.ID, &c.Name, &c.Type, &c.StreamURL,
		&c.LogoURL, &c.Description, &c.IsPremium,
		&c.IsActive, &c.SortOrder, &c.CreatedAt)
	if err != nil {
		return nil, fmt.Errorf("update channel: %w", err)
	}
	return c, nil
}

func (r *Repository) Delete(ctx context.Context, id string) error {
	_, err := r.db.Exec(ctx, `UPDATE channels SET is_active=false WHERE id=$1`, id)
	return err
}

func (r *Repository) ToggleAccess(ctx context.Context, id string, isPremium bool) (*Channel, error) {
	c := &Channel{}
	query := `
		UPDATE channels SET is_premium=$2, updated_at=NOW()
		WHERE id=$1
		RETURNING id, name, type, stream_url, logo_url, description,
		          is_premium, is_active, sort_order, created_at`

	err := r.db.QueryRow(ctx, query, id, isPremium).Scan(
		&c.ID, &c.Name, &c.Type, &c.StreamURL,
		&c.LogoURL, &c.Description, &c.IsPremium,
		&c.IsActive, &c.SortOrder, &c.CreatedAt,
	)
	return c, err
}