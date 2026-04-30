package schedule

import "time"

type Programme struct {
	ID          string    `json:"id"`
	ChannelID   string    `json:"channel_id"`
	ChannelName string    `json:"channel_name,omitempty"`
	Title       string    `json:"title"`
	Description *string   `json:"description,omitempty"`
	StartsAt    time.Time `json:"starts_at"`
	EndsAt      time.Time `json:"ends_at"`
	CreatedAt   time.Time `json:"created_at"`
}

type CreateProgrammeRequest struct {
	ChannelID   string    `json:"channel_id" binding:"required"`
	Title       string    `json:"title" binding:"required,min=2"`
	Description *string   `json:"description"`
	StartsAt    time.Time `json:"starts_at" binding:"required"`
	EndsAt      time.Time `json:"ends_at" binding:"required"`
}

type UpdateProgrammeRequest struct {
	Title       string    `json:"title" binding:"required,min=2"`
	Description *string   `json:"description"`
	StartsAt    time.Time `json:"starts_at" binding:"required"`
	EndsAt      time.Time `json:"ends_at" binding:"required"`
}

type NowAndNext struct {
	ChannelID string     `json:"channel_id"`
	Now       *Programme `json:"now"`
	Next      *Programme `json:"next"`
}