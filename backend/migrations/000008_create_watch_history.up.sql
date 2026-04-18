CREATE TABLE watch_history (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id         UUID         NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content_id      UUID         NOT NULL REFERENCES content(id) ON DELETE CASCADE,
    progress_secs   INTEGER      NOT NULL DEFAULT 0,
    completed       BOOLEAN      NOT NULL DEFAULT FALSE,
    last_watched_at TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    UNIQUE (user_id, content_id)
);

CREATE TABLE app_config (
    id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    broadcaster   VARCHAR(255) NOT NULL DEFAULT 'OpenAir',
    primary_color VARCHAR(7)   NOT NULL DEFAULT '#E63946',
    logo_url      TEXT,
    enable_vod     BOOLEAN NOT NULL DEFAULT TRUE,
    enable_podcasts BOOLEAN NOT NULL DEFAULT TRUE,
    enable_radio   BOOLEAN NOT NULL DEFAULT TRUE,
    updated_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

INSERT INTO app_config (id) VALUES (uuid_generate_v4());

CREATE INDEX idx_watch_history_user    ON watch_history(user_id);
CREATE INDEX idx_watch_history_content ON watch_history(user_id, content_id);
CREATE INDEX idx_watch_history_recent  ON watch_history(user_id, last_watched_at DESC);