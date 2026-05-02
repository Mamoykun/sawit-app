CREATE TABLE audit_log (
    id BIGSERIAL PRIMARY KEY,
    occurred_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    user_id BIGINT,                          -- nullable: e.g. failed login before user identified
    user_email VARCHAR(255),                 -- denormalized snapshot
    action VARCHAR(64) NOT NULL,             -- e.g. 'PANEN_CREATE', 'AUTH_LOGIN_SUCCESS'
    entity_type VARCHAR(64),                 -- e.g. 'Panen', 'Lahan', null for AUTH
    entity_id BIGINT,                        -- e.g. panen.id
    ip_address VARCHAR(45),
    user_agent VARCHAR(500),
    metadata JSONB,                          -- free-form context
    success BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE INDEX idx_audit_user_id ON audit_log(user_id);
CREATE INDEX idx_audit_occurred_at ON audit_log(occurred_at);
CREATE INDEX idx_audit_action ON audit_log(action);
CREATE INDEX idx_audit_entity ON audit_log(entity_type, entity_id);
