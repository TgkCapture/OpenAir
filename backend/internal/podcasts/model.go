package podcasts

import "time"

type Podcast struct {
	ID          string    `json:"id"`
	Title       string    `json:"title"`
	Description *string   `json:"description,omitempty"`
	ArtworkURL  *string   `json:"artwork_url,omitempty"`
	Author      *string   `json:"author,omitempty"`
	Category    *string   `json:"category,omitempty"`
	IsPremium   bool      `json:"is_premium"`
	IsActive    bool      `json:"is_active"`
	CreatedAt   time.Time `json:"created_at"`
}

type Episode struct {
	ID            string     `json:"id"`
	PodcastID     string     `json:"podcast_id"`
	Title         string     `json:"title"`
	Description   *string    `json:"description,omitempty"`
	AudioURL      string     `json:"audio_url"`
	ThumbnailURL  *string    `json:"thumbnail_url,omitempty"`
	DurationSecs  *int       `json:"duration_secs,omitempty"`
	EpisodeNumber *int       `json:"episode_number,omitempty"`
	SeasonNumber  *int       `json:"season_number,omitempty"`
	IsPremium     bool       `json:"is_premium"`
	PublishedAt   *time.Time `json:"published_at,omitempty"`
	CreatedAt     time.Time  `json:"created_at"`
}

type CreatePodcastRequest struct {
	Title       string  `json:"title" binding:"required,min=2"`
	Description *string `json:"description"`
	ArtworkURL  *string `json:"artwork_url"`
	Author      *string `json:"author"`
	Category    *string `json:"category"`
	IsPremium   bool    `json:"is_premium"`
}

type CreateEpisodeRequest struct {
	PodcastID     string  `json:"podcast_id" binding:"required"`
	Title         string  `json:"title" binding:"required,min=2"`
	Description   *string `json:"description"`
	AudioURL      string  `json:"audio_url" binding:"required"`
	ThumbnailURL  *string `json:"thumbnail_url"`
	DurationSecs  *int    `json:"duration_secs"`
	EpisodeNumber *int    `json:"episode_number"`
	SeasonNumber  *int    `json:"season_number"`
	IsPremium     bool    `json:"is_premium"`
}