package auth

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

func (r *Repository) CreateUser(ctx context.Context, email, passwordHash, fullName string) (*User, error) {
	user := &User{}
	query := `
		INSERT INTO users (email, password_hash, full_name)
		VALUES ($1, $2, $3)
		RETURNING id, email, full_name, avatar_url, role, is_active, created_at, updated_at`

	err := r.db.QueryRow(ctx, query, email, passwordHash, fullName).Scan(
		&user.ID, &user.Email, &user.FullName, &user.AvatarURL,
		&user.Role, &user.IsActive, &user.CreatedAt, &user.UpdatedAt,
	)
	if err != nil {
		return nil, fmt.Errorf("create user: %w", err)
	}
	return user, nil
}

func (r *Repository) GetUserByEmail(ctx context.Context, email string) (*User, string, error) {
	var passwordHash string
	user := &User{}
	query := `
		SELECT id, email, full_name, avatar_url, role, is_active, created_at, updated_at, password_hash
		FROM users WHERE email = $1`

	err := r.db.QueryRow(ctx, query, email).Scan(
		&user.ID, &user.Email, &user.FullName, &user.AvatarURL,
		&user.Role, &user.IsActive, &user.CreatedAt, &user.UpdatedAt,
		&passwordHash,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, "", nil
		}
		return nil, "", fmt.Errorf("get user by email: %w", err)
	}
	return user, passwordHash, nil
}

func (r *Repository) GetUserByID(ctx context.Context, id string) (*User, error) {
	user := &User{}
	query := `
		SELECT id, email, full_name, avatar_url, role, is_active, created_at, updated_at
		FROM users WHERE id = $1`

	err := r.db.QueryRow(ctx, query, id).Scan(
		&user.ID, &user.Email, &user.FullName, &user.AvatarURL,
		&user.Role, &user.IsActive, &user.CreatedAt, &user.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil
		}
		return nil, fmt.Errorf("get user by id: %w", err)
	}
	return user, nil
}

func (r *Repository) EmailExists(ctx context.Context, email string) (bool, error) {
	var exists bool
	err := r.db.QueryRow(ctx, `SELECT EXISTS(SELECT 1 FROM users WHERE email = $1)`, email).Scan(&exists)
	if err != nil {
		return false, fmt.Errorf("check email exists: %w", err)
	}
	return exists, nil
}

func (r *Repository) UpdateUser(ctx context.Context, id, fullName string, avatarURL *string) (*User, error) {
	user := &User{}
	query := `
		UPDATE users SET full_name = $2, avatar_url = $3, updated_at = NOW()
		WHERE id = $1
		RETURNING id, email, full_name, avatar_url, role, is_active, created_at, updated_at`

	err := r.db.QueryRow(ctx, query, id, fullName, avatarURL).Scan(
		&user.ID, &user.Email, &user.FullName, &user.AvatarURL,
		&user.Role, &user.IsActive, &user.CreatedAt, &user.UpdatedAt,
	)
	if err != nil {
		return nil, fmt.Errorf("update user: %w", err)
	}
	return user, nil
}

// StoreRefreshToken saves the hash of a newly issued refresh token and
// clears out any of the user's tokens that have already expired.
func (r *Repository) StoreRefreshToken(ctx context.Context, userID, tokenHash string, expiresAt time.Time) error {
	if _, err := r.db.Exec(ctx,
		`DELETE FROM refresh_tokens WHERE user_id = $1 AND expires_at <= NOW()`, userID,
	); err != nil {
		return err
	}
	_, err := r.db.Exec(ctx, `
		INSERT INTO refresh_tokens (user_id, token_hash, expires_at)
		VALUES ($1, $2, $3)`,
		userID, tokenHash, expiresAt,
	)
	return err
}

// ConsumeRefreshToken deletes an unexpired refresh token and returns the ID
// of the user it belonged to. It returns "" when no such token exists, so a
// token can only ever be exchanged once.
func (r *Repository) ConsumeRefreshToken(ctx context.Context, tokenHash string) (string, error) {
	var userID string
	err := r.db.QueryRow(ctx, `
		DELETE FROM refresh_tokens
		WHERE token_hash = $1 AND expires_at > NOW()
		RETURNING user_id`, tokenHash,
	).Scan(&userID)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return "", nil
		}
		return "", err
	}
	return userID, nil
}

// DeleteRefreshToken removes one of a user's refresh tokens (one device).
func (r *Repository) DeleteRefreshToken(ctx context.Context, userID, tokenHash string) error {
	_, err := r.db.Exec(ctx,
		`DELETE FROM refresh_tokens WHERE user_id = $1 AND token_hash = $2`, userID, tokenHash,
	)
	return err
}

// DeleteAllRefreshTokens signs a user out of every device.
func (r *Repository) DeleteAllRefreshTokens(ctx context.Context, userID string) error {
	_, err := r.db.Exec(ctx, `DELETE FROM refresh_tokens WHERE user_id = $1`, userID)
	return err
}

// DeleteRefreshTokensByEmail signs the account with this email out of every device.
func (r *Repository) DeleteRefreshTokensByEmail(ctx context.Context, email string) error {
	_, err := r.db.Exec(ctx, `
		DELETE FROM refresh_tokens
		WHERE user_id IN (SELECT id FROM users WHERE email = $1)`, email,
	)
	return err
}

func (r *Repository) StoreOTP(ctx context.Context, email, otpHash string) error {
	_, err := r.db.Exec(ctx, `
		INSERT INTO password_reset_otps (email, otp_hash, expires_at)
		VALUES ($1, $2, NOW() + INTERVAL '15 minutes')
		ON CONFLICT (email) DO UPDATE SET otp_hash = $2, expires_at = NOW() + INTERVAL '15 minutes'`,
		email, otpHash,
	)
	return err
}

func (r *Repository) GetOTP(ctx context.Context, email string) (string, error) {
	var otpHash string
	err := r.db.QueryRow(ctx, `
		SELECT otp_hash FROM password_reset_otps
		WHERE email = $1 AND expires_at > NOW()`, email,
	).Scan(&otpHash)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return "", nil
		}
		return "", err
	}
	return otpHash, nil
}

func (r *Repository) DeleteOTP(ctx context.Context, email string) error {
	_, err := r.db.Exec(ctx, `DELETE FROM password_reset_otps WHERE email = $1`, email)
	return err
}

func (r *Repository) UpdatePassword(ctx context.Context, email, passwordHash string) error {
	_, err := r.db.Exec(ctx, `
		UPDATE users SET password_hash = $2, updated_at = NOW() WHERE email = $1`,
		email, passwordHash,
	)
	return err
}