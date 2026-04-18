CREATE TABLE channels (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name        VARCHAR(255) NOT NULL,
    type        VARCHAR(10)  NOT NULL CHECK (type IN ('tv', 'radio')),
    stream_url  TEXT         NOT NULL,
    logo_url    TEXT,
    description TEXT,
    is_premium  BOOLEAN      NOT NULL DEFAULT FALSE,
    is_active   BOOLEAN      NOT NULL DEFAULT TRUE,
    sort_order  INTEGER      NOT NULL DEFAULT 0,
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_channels_type      ON channels(type);
CREATE INDEX idx_channels_is_active ON channels(is_active);