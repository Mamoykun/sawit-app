-- Users
CREATE TABLE users (
    id          BIGSERIAL PRIMARY KEY,
    name        VARCHAR(100) NOT NULL,
    email       VARCHAR(100) UNIQUE NOT NULL,
    password    VARCHAR(255) NOT NULL,
    phone       VARCHAR(20),
    created_at  TIMESTAMP DEFAULT NOW(),
    updated_at  TIMESTAMP DEFAULT NOW()
);

-- Subscriptions
CREATE TABLE subscriptions (
    id          BIGSERIAL PRIMARY KEY,
    user_id     BIGINT REFERENCES users(id) ON DELETE CASCADE,
    paket       VARCHAR(20) NOT NULL DEFAULT 'GRATIS',
    status      VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    expired_at  TIMESTAMP,
    created_at  TIMESTAMP DEFAULT NOW()
);

-- Lahan
CREATE TABLE lahan (
    id              BIGSERIAL PRIMARY KEY,
    user_id         BIGINT REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    nama_lahan      VARCHAR(100) NOT NULL,
    luas_ha         DECIMAL(8,2) NOT NULL,
    usia_pohon      INTEGER NOT NULL,
    jumlah_pohon    INTEGER,
    lokasi          VARCHAR(255),
    latitude        DECIMAL(10,7),
    longitude       DECIMAL(10,7),
    catatan         TEXT,
    is_active       BOOLEAN DEFAULT TRUE,
    created_at      TIMESTAMP DEFAULT NOW(),
    updated_at      TIMESTAMP DEFAULT NOW()
);

-- Panen
CREATE TABLE panen (
    id              BIGSERIAL PRIMARY KEY,
    lahan_id        BIGINT REFERENCES lahan(id) ON DELETE CASCADE NOT NULL,
    bulan           VARCHAR(20) NOT NULL,
    tahun           INTEGER NOT NULL,
    bulan_angka     INTEGER NOT NULL,
    ton_aktual      DECIMAL(8,2) NOT NULL,
    target_min      DECIMAL(8,2) NOT NULL,
    target_max      DECIMAL(8,2) NOT NULL,
    target_mid      DECIMAL(8,2) NOT NULL,
    status_panen    VARCHAR(20) NOT NULL,
    persen_kurang   DECIMAL(5,2) DEFAULT 0,
    harga_per_ton   DECIMAL(12,2) DEFAULT 2400000,
    catatan         TEXT,
    created_at      TIMESTAMP DEFAULT NOW(),
    UNIQUE(lahan_id, tahun, bulan_angka)
);

-- Analisa
CREATE TABLE analisa (
    id              BIGSERIAL PRIMARY KEY,
    panen_id        BIGINT REFERENCES panen(id) ON DELETE CASCADE NOT NULL,
    lahan_id        BIGINT REFERENCES lahan(id) ON DELETE CASCADE NOT NULL,
    penyebab_json   JSONB NOT NULL,
    rekomendasi     TEXT,
    ai_response_raw TEXT,
    created_at      TIMESTAMP DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_lahan_user ON lahan(user_id);
CREATE INDEX idx_lahan_active ON lahan(user_id, is_active);
CREATE INDEX idx_panen_lahan ON panen(lahan_id);
CREATE INDEX idx_panen_tahun ON panen(lahan_id, tahun);
CREATE INDEX idx_analisa_panen ON analisa(panen_id);
CREATE INDEX idx_analisa_lahan ON analisa(lahan_id);
