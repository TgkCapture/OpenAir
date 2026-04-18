CREATE TABLE programmes (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    channel_id  UUID         NOT NULL REFERENCES channels(id) ON DELETE CASCADE,
    title       VARCHAR(500) NOT NULL,
    description TEXT,
    starts_at   TIMESTAMPTZ  NOT NULL,
    ends_at     TIMESTAMPTZ  NOT NULL,
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_programmes_channel_id ON programmes(channel_id);
CREATE INDEX idx_programmes_schedule   ON programmes(channel_id, starts_at);