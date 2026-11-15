-- Refresh tokens are now looked up by a SHA-256 hash of the token, expire,
-- and are stored one per device instead of one per user.
-- Existing rows hold bcrypt hashes that can no longer be matched.
DELETE FROM refresh_tokens;

ALTER TABLE refresh_tokens DROP CONSTRAINT IF EXISTS refresh_tokens_user_id_key;

ALTER TABLE refresh_tokens
    ADD COLUMN expires_at TIMESTAMPTZ NOT NULL DEFAULT NOW() + INTERVAL '30 days';

CREATE UNIQUE INDEX idx_refresh_tokens_token_hash ON refresh_tokens (token_hash);
CREATE INDEX idx_refresh_tokens_user_id ON refresh_tokens (user_id);
