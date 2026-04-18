CREATE TABLE notifications (
    id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id    UUID         REFERENCES users(id) ON DELETE CASCADE,
    title      VARCHAR(255) NOT NULL,
    body       TEXT         NOT NULL,
    type       VARCHAR(100),
    data       JSONB,
    is_read    BOOLEAN      NOT NULL DEFAULT FALSE,
    sent_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TABLE fcm_tokens (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id     UUID         NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token       TEXT         NOT NULL UNIQUE,
    device_type VARCHAR(20)  NOT NULL CHECK (device_type IN ('android', 'ios')),
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_is_read ON notifications(user_id, is_read);
CREATE INDEX idx_fcm_tokens_user_id    ON fcm_tokens(user_id);