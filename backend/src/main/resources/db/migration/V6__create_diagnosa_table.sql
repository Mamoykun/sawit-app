CREATE TABLE diagnosa (
    id              BIGSERIAL PRIMARY KEY,
    lahan_id        BIGINT REFERENCES lahan(id) ON DELETE CASCADE NOT NULL,
    jenis           VARCHAR(20) NOT NULL CHECK (jenis IN ('BUAH', 'BATANG', 'PELEPAH')),
    image_base64    TEXT NOT NULL,
    kondisi         TEXT,
    penyebab        TEXT,
    rekomendasi     TEXT,
    severity        VARCHAR(20) NOT NULL DEFAULT 'NORMAL' CHECK (severity IN ('NORMAL', 'PERHATIAN', 'KRITIS')),
    is_fallback     BOOLEAN DEFAULT FALSE,
    created_at      TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_diagnosa_lahan_created ON diagnosa(lahan_id, created_at DESC);
