-- ================================================================
-- Sawitku — Test Data Seed (~1 juta records)
-- Password semua user test: password
-- Jalankan di pgAdmin: Query Tool → buka file ini → Run (F5)
-- ================================================================

BEGIN;

-- ① USERS (1.000 records)
INSERT INTO users (name, email, password, phone, created_at, updated_at)
SELECT
  'Petani Test ' || n,
  'test' || n || '@sawitku.test',
  '$2a$10$EblZqNptyYvcLm/VwDptlOBMpFNybr3J0U65g.1W1P34bV2etq.8W',
  '0812' || LPAD(n::TEXT, 8, '0'),
  NOW() - ((random() * 730)::INT || ' days')::INTERVAL,
  NOW()
FROM generate_series(1, 1000) AS n
WHERE NOT EXISTS (
  SELECT 1 FROM users WHERE email = 'test' || n || '@sawitku.test'
);

-- ② SUBSCRIPTIONS (1 per user)
INSERT INTO subscriptions (user_id, paket, status, expired_at, created_at)
SELECT
  id,
  CASE id % 5
    WHEN 0 THEN 'PRO'
    WHEN 1 THEN 'PETANI'
    ELSE        'GRATIS'
  END,
  'ACTIVE',
  CASE id % 5
    WHEN 0 THEN NOW() + INTERVAL '30 days'
    WHEN 1 THEN NOW() + INTERVAL '15 days'
    ELSE        NULL
  END,
  NOW()
FROM users
WHERE email LIKE '%@sawitku.test'
  AND id NOT IN (SELECT user_id FROM subscriptions);

-- ③ LAHAN (3 per user = 3.000 records)
CREATE TEMP TABLE _seed_users AS
  SELECT id FROM users WHERE email LIKE '%@sawitku.test';

INSERT INTO lahan (
  user_id, nama_lahan, luas_ha, usia_pohon, tahun_tanam,
  jumlah_pohon, lokasi, is_active, created_at, updated_at
)
SELECT
  u.id,
  'Kebun ' || (ARRAY['Blok A','Blok B','Blok C'])[ln],
  ROUND((2 + random() * 48)::NUMERIC, 2),
  3 + ((u.id * ln) % 13),
  EXTRACT(YEAR FROM NOW())::INT - (3 + ((u.id * ln) % 13)),
  50 + ((u.id * ln) % 950),
  (ARRAY[
    'Riau', 'Kalimantan Barat', 'Sumatera Utara',
    'Kalimantan Timur', 'Jambi', 'Sumatera Selatan'
  ])[(u.id % 6) + 1],
  TRUE,
  NOW() - ((random() * 365)::INT || ' days')::INTERVAL,
  NOW()
FROM _seed_users su
JOIN users u ON u.id = su.id
CROSS JOIN generate_series(1, 3) AS ln;

CREATE TEMP TABLE _seed_lahan AS
  SELECT l.id, l.luas_ha
  FROM lahan l
  WHERE l.user_id IN (SELECT id FROM _seed_users);

-- ④ PANEN (~216.000 records: 6 tahun x 12 bulan x 3.000 lahan)
INSERT INTO panen (
  lahan_id, bulan, tahun, bulan_angka, tanggal,
  ton_aktual, target_min, target_max, target_mid,
  status_panen, persen_kurang, harga_per_ton, created_at
)
SELECT
  sl.id,
  (ARRAY[
    'Januari','Februari','Maret','April','Mei','Juni',
    'Juli','Agustus','September','Oktober','November','Desember'
  ])[m],
  y,
  m,
  1 + ((sl.id + m + y) % 27),
  ROUND((sl.luas_ha * (1.5 + random() * 2.0))::NUMERIC, 2),
  ROUND((sl.luas_ha * 1.5)::NUMERIC, 2),
  ROUND((sl.luas_ha * 3.5)::NUMERIC, 2),
  ROUND((sl.luas_ha * 2.5)::NUMERIC, 2),
  (ARRAY['NORMAL','NORMAL','NORMAL','RENDAH','TINGGI'])[(sl.id + m + y) % 5 + 1],
  0,
  ROUND((2000000 + random() * 800000)::NUMERIC, 2),
  make_timestamp(y, m, (1 + ((sl.id + m + y) % 27))::INT, 8, 0, 0)
FROM _seed_lahan sl
CROSS JOIN generate_series(2019, 2024) AS y
CROSS JOIN generate_series(1, 12) AS m
AND NOT EXISTS (
  SELECT 1 FROM panen p2
  WHERE p2.lahan_id = sl.id AND p2.tahun = y AND p2.bulan_angka = m
);

-- ⑤ BIAYA (~864.000 records: 4 kategori x 6 tahun x 12 bulan x 3.000 lahan)
INSERT INTO biaya (
  lahan_id, bulan, tahun, bulan_angka,
  kategori, jumlah, keterangan, created_at
)
SELECT
  sl.id,
  (ARRAY[
    'Januari','Februari','Maret','April','Mei','Juni',
    'Juli','Agustus','September','Oktober','November','Desember'
  ])[m],
  y,
  m,
  kat,
  ROUND((
    CASE kat
      WHEN 'PUPUK'        THEN (500000  + random() * 4500000) * sl.luas_ha
      WHEN 'TENAGA_KERJA' THEN (1000000 + random() * 9000000) * sl.luas_ha
      WHEN 'PESTISIDA'    THEN (200000  + random() * 1800000) * sl.luas_ha
      WHEN 'PERALATAN'    THEN (100000  + random() * 900000)  * sl.luas_ha
    END
  )::NUMERIC, 2),
  'Seed data otomatis',
  make_timestamp(y, m, 5, 9, 0, 0::DOUBLE PRECISION)
FROM _seed_lahan sl
CROSS JOIN generate_series(2019, 2024) AS y
CROSS JOIN generate_series(1, 12) AS m
CROSS JOIN (VALUES ('PUPUK'), ('TENAGA_KERJA'), ('PESTISIDA'), ('PERALATAN')) AS k(kat);

COMMIT;

-- Ringkasan hasil
SELECT
  tabel,
  TO_CHAR(jumlah, 'FM999,999,999') AS jumlah
FROM (
  SELECT 'users'         AS tabel, COUNT(*) AS jumlah FROM users WHERE email LIKE '%@sawitku.test'
  UNION ALL
  SELECT 'subscriptions'          , COUNT(*) FROM subscriptions WHERE user_id IN (SELECT id FROM users WHERE email LIKE '%@sawitku.test')
  UNION ALL
  SELECT 'lahan'                  , COUNT(*) FROM lahan WHERE user_id IN (SELECT id FROM users WHERE email LIKE '%@sawitku.test')
  UNION ALL
  SELECT 'panen'                  , COUNT(*) FROM panen WHERE lahan_id IN (SELECT id FROM lahan WHERE user_id IN (SELECT id FROM users WHERE email LIKE '%@sawitku.test'))
  UNION ALL
  SELECT 'biaya'                  , COUNT(*) FROM biaya WHERE lahan_id IN (SELECT id FROM lahan WHERE user_id IN (SELECT id FROM users WHERE email LIKE '%@sawitku.test'))
) t;
