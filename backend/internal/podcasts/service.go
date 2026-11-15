package podcasts

import (
	"context"
	"errors"
)

var (
	ErrPodcastNotFound = errors.New("podcast not found")
	ErrEpisodeNotFound = errors.New("episode not found")
	ErrPremiumRequired = errors.New("premium subscription required")
)

type Service struct {
	repo *Repository
}

func NewService(repo *Repository) *Service {
	return &Service{repo: repo}
}

func (s *Service) GetAll(ctx context.Context) ([]*Podcast, error) {
	return s.repo.GetAllPodcasts(ctx, false)
}

// GetAllForAdmin also returns deactivated podcasts.
func (s *Service) GetAllForAdmin(ctx context.Context) ([]*Podcast, error) {
	return s.repo.GetAllPodcasts(ctx, true)
}

func (s *Service) DeletePodcast(ctx context.Context, id string) error {
	found, err := s.repo.DeletePodcast(ctx, id)
	if err != nil {
		return err
	}
	if !found {
		return ErrPodcastNotFound
	}
	return nil
}

func (s *Service) DeleteEpisode(ctx context.Context, id string) error {
	found, err := s.repo.DeleteEpisode(ctx, id)
	if err != nil {
		return err
	}
	if !found {
		return ErrEpisodeNotFound
	}
	return nil
}

func (s *Service) GetByID(ctx context.Context, id string) (*Podcast, error) {
	p, err := s.repo.GetPodcastByID(ctx, id)
	if err != nil {
		return nil, err
	}
	if p == nil {
		return nil, ErrPodcastNotFound
	}
	return p, nil
}

func (s *Service) GetEpisodes(ctx context.Context, podcastID string) ([]*Episode, error) {
	return s.repo.GetEpisodes(ctx, podcastID)
}

func (s *Service) GetEpisodeStreamURL(ctx context.Context, id string, isPremium bool) (string, error) {
	e, err := s.repo.GetEpisodeByID(ctx, id)
	if err != nil {
		return "", err
	}
	if e == nil {
		return "", ErrEpisodeNotFound
	}
	if e.IsPremium && !isPremium {
		return "", ErrPremiumRequired
	}
	return e.AudioURL, nil
}

func (s *Service) CreatePodcast(ctx context.Context, req CreatePodcastRequest) (*Podcast, error) {
	return s.repo.CreatePodcast(ctx, req)
}

func (s *Service) CreateEpisode(ctx context.Context, req CreateEpisodeRequest) (*Episode, error) {
	return s.repo.CreateEpisode(ctx, req)
}