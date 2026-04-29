package channels

import "time"

type Channel struct {
	ID          string    `json:"id"`
	Name        string    `json:"name"`
	Type        string    `json:"type"`
	StreamURL   string    `json:"stream_url"`
	LogoURL     *string   `json:"logo_url,omitempty"`
	Description *string   `json:"description,omitempty"`
	IsPremium   bool      `json:"is_premium"`
	IsActive    bool      `json:"is_active"`
	SortOrder   int       `json:"sort_order"`
	CreatedAt   time.Time `json:"created_at"`
}

type StreamURLResponse struct {
	URL       string `json:"url"`
	ExpiresAt int64  `json:"expires_at"`
}

type CreateChannelRequest struct {
	Name        string  `json:"name" binding:"required,min=2"`
	Type        string  `json:"type" binding:"required,oneof=tv radio"`
	StreamURL   string  `json:"stream_url" binding:"required,url"`
	LogoURL     *string `json:"logo_url"`
	Description *string `json:"description"`
	IsPremium   bool    `json:"is_premium"`
	SortOrder   int     `json:"sort_order"`
}

type UpdateChannelRequest struct {
	Name        string  `json:"name" binding:"required,min=2"`
	StreamURL   string  `json:"stream_url" binding:"required,url"`
	LogoURL     *string `json:"logo_url"`
	Description *string `json:"description"`
	IsPremium   bool    `json:"is_premium"`
	IsActive    bool    `json:"is_active"`
	SortOrder   int     `json:"sort_order"`
}