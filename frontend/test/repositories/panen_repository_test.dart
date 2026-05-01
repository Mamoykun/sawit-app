import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sawitku/database/app_database.dart';
import 'package:sawitku/repositories/panen_repository.dart';
import 'package:sawitku/services/api_service.dart';
import 'package:sawitku/models/panen_model.dart';

// Fake ApiService — overrides only what PanenRepository calls
class _FakeApi extends ApiService {
  PanenModel? stubbedCreate;

  @override
  Future<PanenModel> inputPanen(int lahanId, {
    required String bulan, required int tahun, required int bulanAngka,
    required int tanggal, required double tonAktual,
    double hargaPerTon = 2400000, String? catatan,
  }) async => stubbedCreate!;

  @override
  Future<PanenModel> updatePanen(int lahanId, int panenId, {
    required String bulan, required int tahun, required int bulanAngka,
    required int tanggal, required double tonAktual, double hargaPerTon = 2400000,
  }) async => stubbedCreate!;

  @override
  Future<void> deletePanen(int lahanId, int panenId) async {}

  @override
  Future<List<PanenModel>> getRiwayat(int lahanId, {int limit = 7}) async => [];
}

AppDatabase _memoryDb() => AppDatabase(NativeDatabase.memory());

void main() {
  group('PanenRepository', () {
    late AppDatabase db;
    late _FakeApi api;
    late PanenRepository repo;

    setUp(() {
      db = _memoryDb();
      api = _FakeApi();
      repo = PanenRepository(db: db, api: api);
    });

    tearDown(() => db.close());

    test('create writes to SQLite immediately with negative temp id', () async {
      await repo.create(
        lahanId: 1, luasHa: 14.0, usiaPohon: 8,
        bulan: 'Januari', tahun: 2026, bulanAngka: 1, tanggal: 15,
        tonAktual: 12.5,
      );

      final rows = await db.select(db.panens).get();
      expect(rows.length, 1);
      expect(rows.first.id, isNegative);
      expect(rows.first.tonAktual, 12.5);
    });

    test('create enqueues one sync_queue item with operation=create', () async {
      await repo.create(
        lahanId: 1, luasHa: 14.0, usiaPohon: 8,
        bulan: 'Januari', tahun: 2026, bulanAngka: 1, tanggal: 15,
        tonAktual: 12.5,
      );

      final queue = await db.select(db.syncQueue).get();
      expect(queue.length, 1);
      expect(queue.first.entity, 'panen');
      expect(queue.first.operation, 'create');
    });

    test('getByLahan returns rows from SQLite without network', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      await db.into(db.panens).insert(PanensCompanion(
        id: Value(1),
        lahanId: Value(1),
        bulan: Value('Januari'),
        tahun: Value(2026),
        bulanAngka: Value(1),
        tonAktual: Value(10.0),
        cachedAt: Value(now),
      ));

      final results = await repo.getByLahan(1);
      expect(results.length, 1);
      expect(results.first.tonAktual, 10.0);
    });

    test('delete removes row from SQLite and enqueues delete operation', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      await db.into(db.panens).insert(PanensCompanion(
        id: Value(42),
        lahanId: Value(1),
        bulan: Value('Februari'),
        tahun: Value(2026),
        bulanAngka: Value(2),
        tonAktual: Value(8.0),
        cachedAt: Value(now),
      ));

      await repo.delete(lahanId: 1, panenId: 42);

      final rows = await db.select(db.panens).get();
      expect(rows, isEmpty);
      final queue = await db.select(db.syncQueue).get();
      expect(queue.first.operation, 'delete');
    });

    test('delete cancels pending create instead of enqueuing delete', () async {
      // Create an offline (negative id) panen
      await repo.create(
        lahanId: 1, luasHa: 14.0, usiaPohon: 8,
        bulan: 'Maret', tahun: 2026, bulanAngka: 3, tanggal: 10,
        tonAktual: 9.0,
      );
      final rows = await db.select(db.panens).get();
      final tempId = rows.first.id;

      // Delete the offline panen
      await repo.delete(lahanId: 1, panenId: tempId);

      // Queue should be empty (create was cancelled, no delete enqueued)
      final queue = await db.select(db.syncQueue).get();
      expect(queue, isEmpty);
      // Row should be gone
      final remaining = await db.select(db.panens).get();
      expect(remaining, isEmpty);
    });
  });
}
