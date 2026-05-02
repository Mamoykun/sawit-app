ALTER TABLE lahan ADD COLUMN deleted_at TIMESTAMP;
ALTER TABLE panen ADD COLUMN deleted_at TIMESTAMP;
ALTER TABLE biaya ADD COLUMN deleted_at TIMESTAMP;
ALTER TABLE users ADD COLUMN deleted_at TIMESTAMP;
ALTER TABLE diagnosa ADD COLUMN deleted_at TIMESTAMP;

CREATE INDEX idx_lahans_deleted_at ON lahan(deleted_at) WHERE deleted_at IS NOT NULL;
CREATE INDEX idx_panens_deleted_at ON panen(deleted_at) WHERE deleted_at IS NOT NULL;
CREATE INDEX idx_biayas_deleted_at ON biaya(deleted_at) WHERE deleted_at IS NOT NULL;
CREATE INDEX idx_users_deleted_at ON users(deleted_at) WHERE deleted_at IS NOT NULL;
CREATE INDEX idx_diagnosas_deleted_at ON diagnosa(deleted_at) WHERE deleted_at IS NOT NULL;
