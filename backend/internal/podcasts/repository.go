package podcasts

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

func (r *Repository) GetAllPodcasts(ctx context.Context) ([]*Podcast, error) {
	rows, err := r.db.Query(ctx, `
		SELECT id, title, description, artwork_url, author, category,
		       is_premium, is_active, created_at
		FROM podcasts WHERE is_active = true
		ORDER BY created_at DESC`)
	if err != nil {
		return nil, fmt.Errorf("get podcasts: %w", err)
	}
	defer rows.Close()

	var podcasts []*Podcast
	for rows.Next() {
		p := &Podcast{}
		if err := rows.Scan(&p.ID, &p.Title, &p.Description, &p.ArtworkURL,
			&p.Author, &p.Category, &p.IsPremium, &p.IsActive, &p.CreatedAt); err != nil {
			return nil, err
		}
		podcasts = append(podcasts, p)
	}
	if podcasts == nil {
		podcasts = []*Podcast{}
	}
	return podcasts, nil
}

func (r *Repository) GetPodcastByID(ctx context.Context, id string) (*Podcast, error) {
	p := &Podcast{}
	err := r.db.QueryRow(ctx, `
		SELECT id, title, description, artwork_url, author, category,
		       is_premium, is_active, created_at
		FROM podcasts WHERE id = $1`, id).Scan(
		&p.ID, &p.Title, &p.Description, &p.ArtworkURL,
		&p.Author, &p.Category, &p.IsPremium, &p.IsActive, &p.CreatedAt)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil
		}
		return nil, err
	}
	return p, nil
}

func (r *Repository) GetEpisodes(ctx context.Context, podcastID string) ([]*Episode, error) {
	rows, err := r.db.Query(ctx, `
		SELECT id, podcast_id, title, description, audio_url, thumbnail_url,
		       duration_secs, episode_number, season_number, is_premium,
		       published_at, created_at
		FROM episodes
		WHERE podcast_id = $1
		ORDER BY published_at DESC NULLS LAST, episode_number DESC NULLS LAST`,
		podcastID)
	if err != nil {
		return nil, fmt.Errorf("get episodes: %w", err)
	}
	defer rows.Close()

	var episodes []*Episode
	for rows.Next() {
		e := &Episode{}
		if err := rows.Scan(&e.ID, &e.PodcastID, &e.Title, &e.Description,
			&e.AudioURL, &e.ThumbnailURL, &e.DurationSecs, &e.EpisodeNumber,
			&e.SeasonNumber, &e.IsPremium, &e.PublishedAt, &e.CreatedAt); err != nil {
			return nil, err
		}
		episodes = append(episodes, e)
	}
	if episodes == nil {
		episodes = []*Episode{}
	}
	return episodes, nil
}

func (r *Repository) GetEpisodeByID(ctx context.Context, id string) (*Episode, error) {
	e := &Episode{}
	err := r.db.QueryRow(ctx, `
		SELECT id, podcast_id, title, description, audio_url, thumbnail_url,
		       duration_secs, episode_number, season_number, is_premium,
		       published_at, created_at
		FROM episodes WHERE id = $1`, id).Scan(
		&e.ID, &e.PodcastID, &e.Title, &e.Description,
		&e.AudioURL, &e.ThumbnailURL, &e.DurationSecs, &e.EpisodeNumber,
		&e.SeasonNumber, &e.IsPremium, &e.PublishedAt, &e.CreatedAt)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil
		}
		return nil, err
	}
	return e, nil
}

func (r *Repository) CreatePodcast(ctx context.Context, req CreatePodcastRequest) (*Podcast, error) {
	p := &Podcast{}
	err := r.db.QueryRow(ctx, `
		INSERT INTO podcasts (title, description, artwork_url, author, category, is_premium)
		VALUES ($1,$2,$3,$4,$5,$6)
		RETURNING id, title, description, artwork_url, author, category,
		          is_premium, is_active, created_at`,
		req.Title, req.Description, req.ArtworkURL, req.Author,
		req.Category, req.IsPremium).Scan(
		&p.ID, &p.Title, &p.Description, &p.ArtworkURL,
		&p.Author, &p.Category, &p.IsPremium, &p.IsActive, &p.CreatedAt)
	return p, err
}

func (r *Repository) CreateEpisode(ctx context.Context, req CreateEpisodeRequest) (*Episode, error) {
	e := &Episode{}
	err := r.db.QueryRow(ctx, `
		INSERT INTO episodes (podcast_id, title, description, audio_url, thumbnail_url,
		                      duration_secs, episode_number, season_number, is_premium)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)
		RETURNING id, podcast_id, title, description, audio_url, thumbnail_url,
		          duration_secs, episode_number, season_number, is_premium,
		          published_at, created_at`,
		req.PodcastID, req.Title, req.Description, req.AudioURL,
		req.ThumbnailURL, req.DurationSecs, req.EpisodeNumber,
		req.SeasonNumber, req.IsPremium).Scan(
		&e.ID, &e.PodcastID, &e.Title, &e.Description,
		&e.AudioURL, &e.ThumbnailURL, &e.DurationSecs, &e.EpisodeNumber,
		&e.SeasonNumber, &e.IsPremium, &e.PublishedAt, &e.CreatedAt)
	return e, err
}