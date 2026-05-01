import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sawitku/database/app_database.dart';
import 'package:sawitku/models/biaya_model.dart';
import 'package:sawitku/repositories/biaya_repository.dart';
import 'package:sawitku/services/api_service.dart';

class _FakeApi extends ApiService {
  @override
  Future<List<BiayaModel>> getBiaya(int lahanId, {int? tahun}) async => [];

  @override
  Future<BiayaModel> createBiaya(int lahanId, {
    required String bulan, required int tahun, required int bulanAngka,
    required String kategoriCode, required double jumlah, String? keterangan,
  }) async => BiayaModel(
    id: 99, lahanId: lahanId, bulan: bulan, tahun: tahun,
    bulanAngka: bulanAngka, kategori: KategoriBiaya.fromCode(kategoriCode),
    jumlah: jumlah,
  );

  @override
  Future<void> deleteBiaya(int lahanId, int biayaId) async {}
}

AppDatabase _memoryDb() => AppDatabase(NativeDatabase.memory());

void main() {
  group('BiayaRepository', () {
    late AppDatabase db;
    late BiayaRepository repo;

    setUp(() {
      db = _memoryDb();
      repo = BiayaRepository(db: db, api: _FakeApi());
    });

    tearDown(() => db.close());

    test('create writes to SQLite with negative temp id', () async {
      await repo.create(
        lahanId: 1, bulan: 'Maret', tahun: 2026, bulanAngka: 3,
        kategoriCode: 'PUPUK', jumlah: 500000,
      );
      final rows = await db.select(db.biayas).get();
      expect(rows.length, 1);
      expect(rows.first.id, isNegative);
      expect(rows.first.jumlah, 500000.0);
    });

    test('create enqueues sync with entity=biaya, operation=create', () async {
      await repo.create(
        lahanId: 1, bulan: 'Maret', tahun: 2026, bulanAngka: 3,
        kategoriCode: 'PUPUK', jumlah: 500000,
      );
      final queue = await db.select(db.syncQueue).get();
      expect(queue.length, 1);
      expect(queue.first.entity, 'biaya');
      expect(queue.first.operation, 'create');
    });

    test('getByLahan returns SQLite rows filtered by lahanId', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      await db.into(db.biayas).insert(BiayasCompanion(
        id: Value(1), lahanId: Value(1), bulan: Value('Januari'),
        tahun: Value(2026), bulanAngka: Value(1),
        kategori: Value('PUPUK'), jumlah: Value(300000.0),
        cachedAt: Value(now),
      ));
      await db.into(db.biayas).insert(BiayasCompanion(
        id: Value(2), lahanId: Value(2), bulan: Value('Januari'),
        tahun: Value(2026), bulanAngka: Value(1),
        kategori: Value('PUPUK'), jumlah: Value(200000.0),
        cachedAt: Value(now),
      ));
      final results = await repo.getByLahan(1);
      expect(results.length, 1);
      expect(results.first.lahanId, 1);
    });

    test('delete removes biaya from SQLite and enqueues delete', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      await db.into(db.biayas).insert(BiayasCompanion(
        id: Value(55), lahanId: Value(1), bulan: Value('April'),
        tahun: Value(2026), bulanAngka: Value(4),
        kategori: Value('TENAGA_KERJA'), jumlah: Value(800000.0),
        cachedAt: Value(now),
      ));
      await repo.delete(lahanId: 1, biayaId: 55);
      final rows = await db.select(db.biayas).get();
      expect(rows, isEmpty);
      final queue = await db.select(db.syncQueue).get();
      expect(queue.first.entity, 'biaya');
      expect(queue.first.operation, 'delete');
    });

    test('delete cancels pending create for unsynced biaya', () async {
      await repo.create(
        lahanId: 1, bulan: 'Mei', tahun: 2026, bulanAngka: 5,
        kategoriCode: 'PESTISIDA', jumlah: 200000,
      );
      final rows = await db.select(db.biayas).get();
      final tempId = rows.first.id;

      await repo.delete(lahanId: 1, biayaId: tempId);

      final queue = await db.select(db.syncQueue).get();
      expect(queue, isEmpty); // create was cancelled, no delete enqueued
      final remaining = await db.select(db.biayas).get();
      expect(remaining, isEmpty);
    });
  });
}
