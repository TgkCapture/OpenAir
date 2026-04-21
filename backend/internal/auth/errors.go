package auth

import "errors"

var (
	ErrEmailTaken         = errors.New("email already registered")
	ErrInvalidCredentials = errors.New("invalid email or password")
	ErrAccountDisabled    = errors.New("account is disabled")
	ErrInvalidToken       = errors.New("invalid or expired token")
	ErrInvalidOTP         = errors.New("invalid or expired OTP")
	ErrUserNotFound       = errors.New("user not found")
)