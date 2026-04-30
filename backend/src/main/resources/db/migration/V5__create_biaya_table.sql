CREATE TABLE biaya (
    id              BIGSERIAL PRIMARY KEY,
    lahan_id        BIGINT REFERENCES lahan(id) ON DELETE CASCADE NOT NULL,
    bulan           VARCHAR(20) NOT NULL,
    tahun           INTEGER NOT NULL,
    bulan_angka     INTEGER NOT NULL,
    kategori        VARCHAR(30) NOT NULL CHECK (kategori IN ('PUPUK', 'TENAGA_KERJA', 'PESTISIDA', 'PERALATAN', 'LAINNYA')),
    jumlah          DECIMAL(15,2) NOT NULL CHECK (jumlah > 0),
    keterangan      TEXT,
    created_at      TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_biaya_lahan_tahun ON biaya(lahan_id, tahun, bulan_angka DESC);
