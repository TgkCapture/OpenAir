package channels

import "errors"

var (
	ErrChannelNotFound = errors.New("channel not found")
	ErrPremiumRequired = errors.New("premium subscription required")
)