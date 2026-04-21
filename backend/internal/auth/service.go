package auth

import (
	"context"
	"crypto/rand"
	"fmt"
	"math/big"
	"net/smtp"

	"github.com/TgkCapture/openair/pkg/config"
	"github.com/TgkCapture/openair/pkg/token"
	"golang.org/x/crypto/bcrypt"
)

type Service struct {
	repo    *Repository
	tokens  *token.Manager
	cfg     *config.Config
}

func NewService(repo *Repository, tokens *token.Manager, cfg *config.Config) *Service {
	return &Service{repo: repo, tokens: tokens, cfg: cfg}
}

func (s *Service) Register(ctx context.Context, req RegisterRequest) (*AuthResponse, error) {
	exists, err := s.repo.EmailExists(ctx, req.Email)
	if err != nil {
		return nil, err
	}
	if exists {
		return nil, ErrEmailTaken
	}

	hash, err := bcrypt.GenerateFromPassword([]byte(req.Password), 12)
	if err != nil {
		return nil, fmt.Errorf("hash password: %w", err)
	}

	user, err := s.repo.CreateUser(ctx, req.Email, string(hash), req.FullName)
	if err != nil {
		return nil, err
	}

	return s.issueTokens(ctx, user)
}

func (s *Service) Login(ctx context.Context, req LoginRequest) (*AuthResponse, error) {
	user, passwordHash, err := s.repo.GetUserByEmail(ctx, req.Email)
	if err != nil {
		return nil, err
	}
	if user == nil {
		return nil, ErrInvalidCredentials
	}
	if !user.IsActive {
		return nil, ErrAccountDisabled
	}

	if err := bcrypt.CompareHashAndPassword([]byte(passwordHash), []byte(req.Password)); err != nil {
		return nil, ErrInvalidCredentials
	}

	return s.issueTokens(ctx, user)
}

func (s *Service) RefreshToken(ctx context.Context, req RefreshRequest) (*AuthResponse, error) {
	claims, err := s.tokens.VerifyAccessToken(req.RefreshToken)
	if err != nil {
		return nil, ErrInvalidToken
	}

	user, err := s.repo.GetUserByID(ctx, claims.UserID)
	if err != nil || user == nil {
		return nil, ErrInvalidToken
	}

	storedHash, err := s.repo.GetRefreshToken(ctx, user.ID)
	if err != nil || storedHash == "" {
		return nil, ErrInvalidToken
	}

	if err := bcrypt.CompareHashAndPassword([]byte(storedHash), []byte(req.RefreshToken)); err != nil {
		return nil, ErrInvalidToken
	}

	return s.issueTokens(ctx, user)
}

func (s *Service) Logout(ctx context.Context, userID string) error {
	return s.repo.DeleteRefreshToken(ctx, userID)
}

func (s *Service) ForgotPassword(ctx context.Context, req ForgotPasswordRequest) error {
	user, _, err := s.repo.GetUserByEmail(ctx, req.Email)
	if err != nil {
		return err
	}
	if user == nil {
		return nil
	}

	otp, err := generateOTP()
	if err != nil {
		return err
	}

	hash, err := bcrypt.GenerateFromPassword([]byte(otp), 10)
	if err != nil {
		return err
	}

	if err := s.repo.StoreOTP(ctx, req.Email, string(hash)); err != nil {
		return err
	}

	return s.sendOTPEmail(req.Email, otp)
}

func (s *Service) ResetPassword(ctx context.Context, req ResetPasswordRequest) error {
	otpHash, err := s.repo.GetOTP(ctx, req.Email)
	if err != nil {
		return err
	}
	if otpHash == "" {
		return ErrInvalidOTP
	}

	if err := bcrypt.CompareHashAndPassword([]byte(otpHash), []byte(req.OTP)); err != nil {
		return ErrInvalidOTP
	}

	hash, err := bcrypt.GenerateFromPassword([]byte(req.NewPassword), 12)
	if err != nil {
		return err
	}

	if err := s.repo.UpdatePassword(ctx, req.Email, string(hash)); err != nil {
		return err
	}

	return s.repo.DeleteOTP(ctx, req.Email)
}

func (s *Service) GetProfile(ctx context.Context, userID string) (*User, error) {
	user, err := s.repo.GetUserByID(ctx, userID)
	if err != nil {
		return nil, err
	}
	if user == nil {
		return nil, ErrUserNotFound
	}
	return user, nil
}

func (s *Service) UpdateProfile(ctx context.Context, userID, fullName string, avatarURL *string) (*User, error) {
	return s.repo.UpdateUser(ctx, userID, fullName, avatarURL)
}

func (s *Service) issueTokens(ctx context.Context, user *User) (*AuthResponse, error) {
	accessToken, err := s.tokens.GenerateAccessToken(user.ID, user.Email, user.Role)
	if err != nil {
		return nil, fmt.Errorf("generate access token: %w", err)
	}

	refreshToken := s.tokens.GenerateRefreshToken()
	hash, err := bcrypt.GenerateFromPassword([]byte(refreshToken), 10)
	if err != nil {
		return nil, fmt.Errorf("hash refresh token: %w", err)
	}

	if err := s.repo.StoreRefreshToken(ctx, user.ID, string(hash)); err != nil {
		return nil, fmt.Errorf("store refresh token: %w", err)
	}

	return &AuthResponse{
		User:         *user,
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
	}, nil
}

func generateOTP() (string, error) {
	const digits = "0123456789"
	otp := make([]byte, 6)
	for i := range otp {
		n, err := rand.Int(rand.Reader, big.NewInt(int64(len(digits))))
		if err != nil {
			return "", err
		}
		otp[i] = digits[n.Int64()]
	}
	return string(otp), nil
}

func (s *Service) sendOTPEmail(to, otp string) error {
	if s.cfg.SMTPHost == "" {
		return nil
	}
	auth := smtp.PlainAuth("", s.cfg.SMTPUser, s.cfg.SMTPPass, s.cfg.SMTPHost)
	msg := []byte(fmt.Sprintf(
		"To: %s\r\nSubject: OpenAir Password Reset\r\n\r\nYour OTP is: %s\r\nExpires in 15 minutes.",
		to, otp,
	))
	return smtp.SendMail(
		fmt.Sprintf("%s:%s", s.cfg.SMTPHost, s.cfg.SMTPPort),
		auth, s.cfg.SMTPUser, []string{to}, msg,
	)
}