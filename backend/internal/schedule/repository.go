package schedule

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

type Repository struct {
	db *pgxpool.Pool
}

func NewRepository(db *pgxpool.Pool) *Repository {
	return &Repository{db: db}
}

func (r *Repository) GetByChannel(ctx context.Context, channelID string, date time.Time) ([]*Programme, error) {
	start := time.Date(date.Year(), date.Month(), date.Day(), 0, 0, 0, 0, time.UTC)
	end := start.Add(24 * time.Hour)

	rows, err := r.db.Query(ctx, `
		SELECT p.id, p.channel_id, c.name, p.title, p.description,
		       p.starts_at, p.ends_at, p.created_at
		FROM programmes p
		JOIN channels c ON c.id = p.channel_id
		WHERE p.channel_id = $1
		  AND p.starts_at >= $2
		  AND p.starts_at < $3
		ORDER BY p.starts_at ASC`,
		channelID, start, end)
	if err != nil {
		return nil, fmt.Errorf("get programmes: %w", err)
	}
	defer rows.Close()

	var programmes []*Programme
	for rows.Next() {
		p := &Programme{}
		if err := rows.Scan(&p.ID, &p.ChannelID, &p.ChannelName,
			&p.Title, &p.Description, &p.StartsAt, &p.EndsAt, &p.CreatedAt); err != nil {
			return nil, err
		}
		programmes = append(programmes, p)
	}
	if programmes == nil {
		programmes = []*Programme{}
	}
	return programmes, nil
}

func (r *Repository) GetNowAndNext(ctx context.Context, channelID string) (*NowAndNext, error) {
	now := time.Now().UTC()

	nn := &NowAndNext{ChannelID: channelID}

	// Current programme
	current := &Programme{}
	err := r.db.QueryRow(ctx, `
		SELECT p.id, p.channel_id, c.name, p.title, p.description,
		       p.starts_at, p.ends_at, p.created_at
		FROM programmes p
		JOIN channels c ON c.id = p.channel_id
		WHERE p.channel_id = $1
		  AND p.starts_at <= $2
		  AND p.ends_at > $2
		ORDER BY p.starts_at DESC
		LIMIT 1`,
		channelID, now).Scan(
		&current.ID, &current.ChannelID, &current.ChannelName,
		&current.Title, &current.Description,
		&current.StartsAt, &current.EndsAt, &current.CreatedAt)
	if err != nil && !errors.Is(err, pgx.ErrNoRows) {
		return nil, err
	}
	if err == nil {
		nn.Now = current
	}

	// Next programme
	next := &Programme{}
	err = r.db.QueryRow(ctx, `
		SELECT p.id, p.channel_id, c.name, p.title, p.description,
		       p.starts_at, p.ends_at, p.created_at
		FROM programmes p
		JOIN channels c ON c.id = p.channel_id
		WHERE p.channel_id = $1
		  AND p.starts_at > $2
		ORDER BY p.starts_at ASC
		LIMIT 1`,
		channelID, now).Scan(
		&next.ID, &next.ChannelID, &next.ChannelName,
		&next.Title, &next.Description,
		&next.StartsAt, &next.EndsAt, &next.CreatedAt)
	if err != nil && !errors.Is(err, pgx.ErrNoRows) {
		return nil, err
	}
	if err == nil {
		nn.Next = next
	}

	return nn, nil
}

func (r *Repository) GetAllNowAndNext(ctx context.Context) ([]*NowAndNext, error) {
	now := time.Now().UTC()

	rows, err := r.db.Query(ctx, `
		SELECT DISTINCT ON (p.channel_id)
		       p.id, p.channel_id, c.name, p.title, p.description,
		       p.starts_at, p.ends_at, p.created_at,
		       'now' as slot
		FROM programmes p
		JOIN channels c ON c.id = p.channel_id
		WHERE c.is_active = true
		  AND p.starts_at <= $1
		  AND p.ends_at > $1
		ORDER BY p.channel_id, p.starts_at DESC`,
		now)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	nowMap := map[string]*Programme{}
	for rows.Next() {
		p := &Programme{}
		var slot string
		rows.Scan(&p.ID, &p.ChannelID, &p.ChannelName,
			&p.Title, &p.Description, &p.StartsAt, &p.EndsAt, &p.CreatedAt, &slot)
		nowMap[p.ChannelID] = p
	}

	nextRows, err := r.db.Query(ctx, `
		SELECT DISTINCT ON (p.channel_id)
		       p.id, p.channel_id, c.name, p.title, p.description,
		       p.starts_at, p.ends_at, p.created_at
		FROM programmes p
		JOIN channels c ON c.id = p.channel_id
		WHERE c.is_active = true
		  AND p.starts_at > $1
		ORDER BY p.channel_id, p.starts_at ASC`,
		now)
	if err != nil {
		return nil, err
	}
	defer nextRows.Close()

	nextMap := map[string]*Programme{}
	for nextRows.Next() {
		p := &Programme{}
		nextRows.Scan(&p.ID, &p.ChannelID, &p.ChannelName,
			&p.Title, &p.Description, &p.StartsAt, &p.EndsAt, &p.CreatedAt)
		if _, exists := nextMap[p.ChannelID]; !exists {
			nextMap[p.ChannelID] = p
		}
	}

	// Merge
	seen := map[string]bool{}
	var result []*NowAndNext
	for channelID, prog := range nowMap {
		seen[channelID] = true
		result = append(result, &NowAndNext{
			ChannelID: channelID,
			Now:       prog,
			Next:      nextMap[channelID],
		})
	}
	for channelID, prog := range nextMap {
		if !seen[channelID] {
			result = append(result, &NowAndNext{
				ChannelID: channelID,
				Now:       nil,
				Next:      prog,
			})
		}
	}

	return result, nil
}

func (r *Repository) Create(ctx context.Context, req CreateProgrammeRequest) (*Programme, error) {
	p := &Programme{}
	err := r.db.QueryRow(ctx, `
		INSERT INTO programmes (channel_id, title, description, starts_at, ends_at)
		VALUES ($1,$2,$3,$4,$5)
		RETURNING id, channel_id, title, description, starts_at, ends_at, created_at`,
		req.ChannelID, req.Title, req.Description, req.StartsAt, req.EndsAt,
	).Scan(&p.ID, &p.ChannelID, &p.Title, &p.Description,
		&p.StartsAt, &p.EndsAt, &p.CreatedAt)
	return p, err
}

func (r *Repository) Update(ctx context.Context, id string, req UpdateProgrammeRequest) (*Programme, error) {
	p := &Programme{}
	err := r.db.QueryRow(ctx, `
		UPDATE programmes
		SET title=$2, description=$3, starts_at=$4, ends_at=$5, updated_at=NOW()
		WHERE id=$1
		RETURNING id, channel_id, title, description, starts_at, ends_at, created_at`,
		id, req.Title, req.Description, req.StartsAt, req.EndsAt,
	).Scan(&p.ID, &p.ChannelID, &p.Title, &p.Description,
		&p.StartsAt, &p.EndsAt, &p.CreatedAt)
	return p, err
}

func (r *Repository) Delete(ctx context.Context, id string) error {
	_, err := r.db.Exec(ctx, `DELETE FROM programmes WHERE id=$1`, id)
	return err
}