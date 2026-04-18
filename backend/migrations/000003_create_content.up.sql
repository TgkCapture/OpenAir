CREATE TABLE content (
    id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    channel_id    UUID         REFERENCES channels(id) ON DELETE SET NULL,
    title         VARCHAR(500) NOT NULL,
    description   TEXT,
    type          VARCHAR(20)  NOT NULL CHECK (type IN ('vod', 'promo', 'highlight')),
    file_url      TEXT         NOT NULL,
    thumbnail_url TEXT,
    category      VARCHAR(100),
    duration_secs INTEGER,
    is_premium    BOOLEAN      NOT NULL DEFAULT FALSE,
    is_published  BOOLEAN      NOT NULL DEFAULT FALSE,
    view_count    INTEGER      NOT NULL DEFAULT 0,
    published_at  TIMESTAMPTZ,
    created_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_content_channel_id  ON content(channel_id);
CREATE INDEX idx_content_type        ON content(type);
CREATE INDEX idx_content_category    ON content(category);
CREATE INDEX idx_content_is_premium  ON content(is_premium);
CREATE INDEX idx_content_is_published ON content(is_published);
CREATE INDEX idx_content_published_at ON content(published_at DESC);