CREATE TABLE lahan_photos (
    id BIGSERIAL PRIMARY KEY,
    lahan_id BIGINT NOT NULL REFERENCES lahan(id) ON DELETE CASCADE,
    image_url VARCHAR(500) NOT NULL,
    caption VARCHAR(500),
    taken_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP,
    bulan VARCHAR(20),
    tahun INTEGER,
    bulan_angka INTEGER
);

CREATE INDEX idx_lahan_photos_lahan_id ON lahan_photos(lahan_id);
CREATE INDEX idx_lahan_photos_taken_at ON lahan_photos(taken_at);
CREATE INDEX idx_lahan_photos_deleted_at ON lahan_photos(deleted_at) WHERE deleted_at IS NOT NULL;
