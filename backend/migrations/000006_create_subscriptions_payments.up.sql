CREATE TABLE subscriptions (
    id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id        UUID         NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    plan           VARCHAR(100) NOT NULL,
    status         VARCHAR(50)  NOT NULL DEFAULT 'active'
                   CHECK (status IN ('active', 'cancelled', 'expired', 'pending')),
    payment_method VARCHAR(50)  NOT NULL
                   CHECK (payment_method IN ('airtel_money', 'mpamba', 'stripe', 'manual')),
    amount         NUMERIC(10,2) NOT NULL,
    currency       VARCHAR(10)   NOT NULL DEFAULT 'MWK',
    starts_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    expires_at     TIMESTAMPTZ  NOT NULL,
    cancelled_at   TIMESTAMPTZ,
    created_at     TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at     TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TABLE payments (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id         UUID          NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    subscription_id UUID          REFERENCES subscriptions(id) ON DELETE SET NULL,
    amount          NUMERIC(10,2) NOT NULL,
    currency        VARCHAR(10)   NOT NULL DEFAULT 'MWK',
    provider        VARCHAR(50)   NOT NULL,
    provider_ref    VARCHAR(255),
    status          VARCHAR(50)   NOT NULL DEFAULT 'pending'
                    CHECK (status IN ('pending', 'completed', 'failed', 'refunded')),
    paid_at         TIMESTAMPTZ,
    created_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_subscriptions_user_id ON subscriptions(user_id);
CREATE INDEX idx_subscriptions_status  ON subscriptions(user_id, status);
CREATE INDEX idx_subscriptions_expiry  ON subscriptions(expires_at);
CREATE INDEX idx_payments_user_id      ON payments(user_id);
CREATE INDEX idx_payments_subscription ON payments(subscription_id);