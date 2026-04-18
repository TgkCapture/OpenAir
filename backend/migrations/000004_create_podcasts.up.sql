CREATE TABLE podcasts (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title       VARCHAR(500) NOT NULL,
    description TEXT,
    artwork_url TEXT,
    author      VARCHAR(255),
    category    VARCHAR(100),
    is_premium  BOOLEAN      NOT NULL DEFAULT FALSE,
    is_active   BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TABLE episodes (
    id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    podcast_id    UUID         NOT NULL REFERENCES podcasts(id) ON DELETE CASCADE,
    title         VARCHAR(500) NOT NULL,
    description   TEXT,
    audio_url     TEXT         NOT NULL,
    thumbnail_url TEXT,
    duration_secs INTEGER,
    episode_number INTEGER,
    season_number  INTEGER,
    is_premium    BOOLEAN      NOT NULL DEFAULT FALSE,
    published_at  TIMESTAMPTZ,
    created_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_podcasts_category   ON podcasts(category);
CREATE INDEX idx_episodes_podcast_id ON episodes(podcast_id);
CREATE INDEX idx_episodes_published  ON episodes(podcast_id, published_at DESC);