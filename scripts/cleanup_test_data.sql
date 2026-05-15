-- ================================================================
-- Sawitku — Hapus semua data test (@sawitku.test)
-- Aman: hanya menghapus user dengan email *@sawitku.test
-- Data lahan, panen, biaya, subscription ikut terhapus via CASCADE
-- ================================================================

BEGIN;

DELETE FROM users WHERE email LIKE '%@sawitku.test';

COMMIT;

SELECT
  'users tersisa (non-test)' AS info,
  COUNT(*)::TEXT AS jumlah
FROM users WHERE email NOT LIKE '%@sawitku.test';
