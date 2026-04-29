package content

import (
	"context"
	"errors"
	"fmt"
	"strings"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

type Repository struct {
	db *pgxpool.Pool
}

func NewRepository(db *pgxpool.Pool) *Repository {
	return &Repository{db: db}
}

func (r *Repository) GetAll(ctx context.Context, contentType, category, search string, page, perPage int) (*ContentListResponse, error) {
	offset := (page - 1) * perPage
	conditions := []string{"is_published = true"}
	args := []interface{}{}
	argIdx := 1

	if contentType != "" {
		conditions = append(conditions, fmt.Sprintf("type = $%d", argIdx))
		args = append(args, contentType)
		argIdx++
	}
	if category != "" {
		conditions = append(conditions, fmt.Sprintf("category = $%d", argIdx))
		args = append(args, category)
		argIdx++
	}
	if search != "" {
		conditions = append(conditions, fmt.Sprintf("title ILIKE $%d", argIdx))
		args = append(args, "%"+search+"%")
		argIdx++
	}

	where := "WHERE " + strings.Join(conditions, " AND ")

	var total int
	countQuery := fmt.Sprintf("SELECT COUNT(*) FROM content %s", where)
	if err := r.db.QueryRow(ctx, countQuery, args...).Scan(&total); err != nil {
		return nil, fmt.Errorf("count content: %w", err)
	}

	args = append(args, perPage, offset)
	query := fmt.Sprintf(`
		SELECT id, channel_id, title, description, type, file_url,
		       thumbnail_url, category, duration_secs, is_premium,
		       is_published, view_count, published_at, created_at
		FROM content %s
		ORDER BY published_at DESC NULLS LAST, created_at DESC
		LIMIT $%d OFFSET $%d`, where, argIdx, argIdx+1)

	rows, err := r.db.Query(ctx, query, args...)
	if err != nil {
		return nil, fmt.Errorf("get content: %w", err)
	}
	defer rows.Close()

	var items []*Content
	for rows.Next() {
		c := &Content{}
		if err := rows.Scan(&c.ID, &c.ChannelID, &c.Title, &c.Description,
			&c.Type, &c.FileURL, &c.ThumbnailURL, &c.Category,
			&c.DurationSecs, &c.IsPremium, &c.IsPublished,
			&c.ViewCount, &c.PublishedAt, &c.CreatedAt); err != nil {
			return nil, err
		}
		items = append(items, c)
	}

	if items == nil {
		items = []*Content{}
	}

	return &ContentListResponse{
		Items:   items,
		Total:   total,
		Page:    page,
		PerPage: perPage,
	}, nil
}

func (r *Repository) GetByID(ctx context.Context, id string) (*Content, error) {
	c := &Content{}
	query := `
		SELECT id, channel_id, title, description, type, file_url,
		       thumbnail_url, category, duration_secs, is_premium,
		       is_published, view_count, published_at, created_at
		FROM content WHERE id = $1`

	err := r.db.QueryRow(ctx, query, id).Scan(
		&c.ID, &c.ChannelID, &c.Title, &c.Description,
		&c.Type, &c.FileURL, &c.ThumbnailURL, &c.Category,
		&c.DurationSecs, &c.IsPremium, &c.IsPublished,
		&c.ViewCount, &c.PublishedAt, &c.CreatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil
		}
		return nil, fmt.Errorf("get content by id: %w", err)
	}
	return c, nil
}

func (r *Repository) IncrementViewCount(ctx context.Context, id string) {
	_, _ = r.db.Exec(ctx, `UPDATE content SET view_count = view_count + 1 WHERE id = $1`, id)
}

func (r *Repository) Create(ctx context.Context, req CreateContentRequest) (*Content, error) {
	c := &Content{}
	query := `
		INSERT INTO content (channel_id, title, description, type, file_url,
		                     thumbnail_url, category, duration_secs, is_premium, is_published)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)
		RETURNING id, channel_id, title, description, type, file_url,
		          thumbnail_url, category, duration_secs, is_premium,
		          is_published, view_count, published_at, created_at`

	err := r.db.QueryRow(ctx, query,
		req.ChannelID, req.Title, req.Description, req.Type,
		req.FileURL, req.ThumbnailURL, req.Category,
		req.DurationSecs, req.IsPremium, req.IsPublished,
	).Scan(&c.ID, &c.ChannelID, &c.Title, &c.Description,
		&c.Type, &c.FileURL, &c.ThumbnailURL, &c.Category,
		&c.DurationSecs, &c.IsPremium, &c.IsPublished,
		&c.ViewCount, &c.PublishedAt, &c.CreatedAt)

	return c, err
}

func (r *Repository) Update(ctx context.Context, id string, req UpdateContentRequest) (*Content, error) {
	c := &Content{}
	query := `
		UPDATE content
		SET title=$2, description=$3, thumbnail_url=$4, category=$5,
		    duration_secs=$6, is_premium=$7, is_published=$8, updated_at=NOW()
		WHERE id=$1
		RETURNING id, channel_id, title, description, type, file_url,
		          thumbnail_url, category, duration_secs, is_premium,
		          is_published, view_count, published_at, created_at`

	err := r.db.QueryRow(ctx, query,
		id, req.Title, req.Description, req.ThumbnailURL,
		req.Category, req.DurationSecs, req.IsPremium, req.IsPublished,
	).Scan(&c.ID, &c.ChannelID, &c.Title, &c.Description,
		&c.Type, &c.FileURL, &c.ThumbnailURL, &c.Category,
		&c.DurationSecs, &c.IsPremium, &c.IsPublished,
		&c.ViewCount, &c.PublishedAt, &c.CreatedAt)

	return c, err
}

func (r *Repository) ToggleAccess(ctx context.Context, id string, isPremium bool) error {
	_, err := r.db.Exec(ctx,
		`UPDATE content SET is_premium=$2, updated_at=NOW() WHERE id=$1`,
		id, isPremium)
	return err
}

func (r *Repository) GetCategories(ctx context.Context) ([]string, error) {
	rows, err := r.db.Query(ctx,
		`SELECT DISTINCT category FROM content WHERE category IS NOT NULL AND is_published=true ORDER BY category`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var cats []string
	for rows.Next() {
		var cat string
		if err := rows.Scan(&cat); err == nil {
			cats = append(cats, cat)
		}
	}
	return cats, nil
}

func (r *Repository) SaveWatchHistory(ctx context.Context, userID, contentID string, progressSecs int) error {
	_, err := r.db.Exec(ctx, `
		INSERT INTO watch_history (user_id, content_id, progress_secs, last_watched_at)
		VALUES ($1, $2, $3, NOW())
		ON CONFLICT (user_id, content_id)
		DO UPDATE SET progress_secs=$3, last_watched_at=NOW()`,
		userID, contentID, progressSecs)
	return err
}

func (r *Repository) GetWatchHistory(ctx context.Context, userID string, limit int) ([]*Content, error) {
	query := `
		SELECT c.id, c.channel_id, c.title, c.description, c.type, c.file_url,
		       c.thumbnail_url, c.category, c.duration_secs, c.is_premium,
		       c.is_published, c.view_count, c.published_at, c.created_at
		FROM content c
		JOIN watch_history wh ON wh.content_id = c.id
		WHERE wh.user_id = $1
		ORDER BY wh.last_watched_at DESC
		LIMIT $2`

	rows, err := r.db.Query(ctx, query, userID, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var items []*Content
	for rows.Next() {
		c := &Content{}
		if err := rows.Scan(&c.ID, &c.ChannelID, &c.Title, &c.Description,
			&c.Type, &c.FileURL, &c.ThumbnailURL, &c.Category,
			&c.DurationSecs, &c.IsPremium, &c.IsPublished,
			&c.ViewCount, &c.PublishedAt, &c.CreatedAt); err != nil {
			return nil, err
		}
		items = append(items, c)
	}
	return items, nil
}