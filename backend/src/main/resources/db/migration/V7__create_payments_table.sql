CREATE TABLE payments (
    id              BIGSERIAL PRIMARY KEY,
    user_id         BIGINT REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    order_id        VARCHAR(64) UNIQUE NOT NULL,
    target_paket    VARCHAR(20) NOT NULL CHECK (target_paket IN ('PETANI', 'PRO')),
    duration_months INTEGER NOT NULL DEFAULT 1 CHECK (duration_months > 0),
    gross_amount    NUMERIC(15,2) NOT NULL CHECK (gross_amount > 0),
    status          VARCHAR(20) NOT NULL DEFAULT 'PENDING'
                    CHECK (status IN ('PENDING', 'PAID', 'FAILED', 'EXPIRED', 'CANCELLED')),
    payment_method  VARCHAR(40),
    snap_token      VARCHAR(255),
    snap_url        VARCHAR(500),
    midtrans_response TEXT,
    paid_at         TIMESTAMP,
    expired_at      TIMESTAMP,
    created_at      TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_payments_user ON payments(user_id, created_at DESC);
CREATE UNIQUE INDEX idx_payments_order_id ON payments(order_id);
