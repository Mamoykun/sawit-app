ALTER TABLE lahan ADD COLUMN IF NOT EXISTS tahun_tanam INTEGER;
UPDATE lahan SET tahun_tanam = EXTRACT(YEAR FROM NOW())::INTEGER - usia_pohon WHERE tahun_tanam IS NULL;
