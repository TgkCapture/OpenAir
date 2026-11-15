DELETE FROM refresh_tokens;

DROP INDEX IF EXISTS idx_refresh_tokens_user_id;
DROP INDEX IF EXISTS idx_refresh_tokens_token_hash;

ALTER TABLE refresh_tokens DROP COLUMN IF EXISTS expires_at;

ALTER TABLE refresh_tokens ADD CONSTRAINT refresh_tokens_user_id_key UNIQUE (user_id);
