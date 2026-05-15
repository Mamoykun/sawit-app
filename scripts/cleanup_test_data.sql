-- ================================================================
-- Sawitku — Hapus semua data test (@sawitku.test)
-- Aman: hanya menghapus user dengan email *@sawitku.test
-- ================================================================

\echo 'Menghapus semua data test (@sawitku.test)...'

BEGIN;

DELETE FROM users WHERE email LIKE '%@sawitku.test';
-- Data lahan, panen, biaya, subscription ikut terhapus via ON DELETE CASCADE

COMMIT;

\echo 'Selesai. Semua data test sudah dihapus.'

SELECT
  'users tersisa (non-test)' AS info,
  COUNT(*)::TEXT AS jumlah
FROM users WHERE email NOT LIKE '%@sawitku.test';
