package content

import "time"

type Content struct {
	ID           string     `json:"id"`
	ChannelID    *string    `json:"channel_id,omitempty"`
	Title        string     `json:"title"`
	Description  *string    `json:"description,omitempty"`
	Type         string     `json:"type"`
	FileURL      string     `json:"file_url"`
	ThumbnailURL *string    `json:"thumbnail_url,omitempty"`
	Category     *string    `json:"category,omitempty"`
	DurationSecs *int       `json:"duration_secs,omitempty"`
	IsPremium    bool       `json:"is_premium"`
	IsPublished  bool       `json:"is_published"`
	ViewCount    int        `json:"view_count"`
	PublishedAt  *time.Time `json:"published_at,omitempty"`
	CreatedAt    time.Time  `json:"created_at"`
}

type ContentListResponse struct {
	Items  []*Content `json:"items"`
	Total  int        `json:"total"`
	Page   int        `json:"page"`
	PerPage int       `json:"per_page"`
}

type CreateContentRequest struct {
	ChannelID    *string `json:"channel_id"`
	Title        string  `json:"title" binding:"required,min=2"`
	Description  *string `json:"description"`
	Type         string  `json:"type" binding:"required,oneof=vod promo highlight"`
	FileURL      string  `json:"file_url" binding:"required"`
	ThumbnailURL *string `json:"thumbnail_url"`
	Category     *string `json:"category"`
	DurationSecs *int    `json:"duration_secs"`
	IsPremium    bool    `json:"is_premium"`
	IsPublished  bool    `json:"is_published"`
}

type UpdateContentRequest struct {
	Title        string  `json:"title" binding:"required,min=2"`
	Description  *string `json:"description"`
	ThumbnailURL *string `json:"thumbnail_url"`
	Category     *string `json:"category"`
	DurationSecs *int    `json:"duration_secs"`
	IsPremium    bool    `json:"is_premium"`
	IsPublished  bool    `json:"is_published"`
}