package content

import "errors"

var (
	ErrContentNotFound = errors.New("content not found")
	ErrPremiumRequired = errors.New("premium subscription required")
)