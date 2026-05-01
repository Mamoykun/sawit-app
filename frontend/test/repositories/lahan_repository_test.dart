import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sawitku/database/app_database.dart';
import 'package:sawitku/models/lahan_model.dart';
import 'package:sawitku/repositories/lahan_repository.dart';
import 'package:sawitku/services/api_service.dart';

class _FakeApi extends ApiService {
  @override
  Future<List<LahanModel>> getMyLahan() async => [];

  @override
  Future<LahanModel> createLahan({
    required String namaLahan, required double luasHa, required int tahunTanam,
    int? jumlahPohon, String? lokasi,
  }) async => LahanModel(
    id: 1, namaLahan: namaLahan, luasHa: luasHa,
    usiaPohon: DateTime.now().year - tahunTanam, isActive: true,
  );

  @override
  Future<LahanModel> updateLahan(int lahanId, {
    required String namaLahan, required double luasHa, required int tahunTanam,
    int? jumlahPohon, String? lokasi,
  }) async => LahanModel(
    id: lahanId, namaLahan: namaLahan, luasHa: luasHa,
    usiaPohon: DateTime.now().year - tahunTanam, isActive: true,
  );

  @override
  Future<void> deleteLahan(int lahanId) async {}
}

AppDatabase _memoryDb() => AppDatabase(NativeDatabase.memory());

void main() {
  group('LahanRepository', () {
    late AppDatabase db;
    late LahanRepository repo;

    setUp(() {
      db = _memoryDb();
      repo = LahanRepository(db: db, api: _FakeApi());
    });

    tearDown(() => db.close());

    test('getAll returns empty list when no cached data', () async {
      final result = await repo.getAll();
      expect(result, isEmpty);
    });

    test('upsertFromServer stores lahan in SQLite', () async {
      final model = LahanModel(
        id: 10, namaLahan: 'Kebun A', luasHa: 20.0, usiaPohon: 7, isActive: true,
      );
      await repo.upsertFromServer(model);
      final result = await repo.getAll();
      expect(result.length, 1);
      expect(result.first.namaLahan, 'Kebun A');
    });

    test('upsertFromServer updates existing lahan on conflict', () async {
      final model = LahanModel(id: 5, namaLahan: 'Kebun B', luasHa: 10.0, usiaPohon: 5, isActive: true);
      await repo.upsertFromServer(model);
      final updated = LahanModel(id: 5, namaLahan: 'Kebun B Updated', luasHa: 12.0, usiaPohon: 5, isActive: true);
      await repo.upsertFromServer(updated);
      final result = await repo.getAll();
      expect(result.length, 1);
      expect(result.first.namaLahan, 'Kebun B Updated');
    });

    test('delete removes lahan from SQLite and enqueues sync', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      await db.into(db.lahans).insert(LahansCompanion(
        id: Value(5),
        namaLahan: Value('Test Kebun'),
        luasHa: Value(10.0),
        usiaPohon: Value(6),
        cachedAt: Value(now),
      ));
      await repo.delete(5);
      final rows = await db.select(db.lahans).get();
      expect(rows, isEmpty);
      final queue = await db.select(db.syncQueue).get();
      expect(queue.first.entity, 'lahan');
      expect(queue.first.operation, 'delete');
    });

    test('create calls API and caches result in SQLite', () async {
      // _FakeApi.createLahan returns LahanModel(id:1, namaLahan: provided, ...)
      final result = await repo.create(
        namaLahan: 'Kebun Baru', luasHa: 15.0, tahunTanam: 2018,
      );
      expect(result.id, 1); // server-assigned id
      expect(result.namaLahan, 'Kebun Baru');
      // Should be cached in SQLite
      final cached = await repo.getAll();
      expect(cached.any((l) => l.namaLahan == 'Kebun Baru'), isTrue);
    });

    test('update calls API and updates SQLite cache', () async {
      // Seed an existing lahan in SQLite
      final now = DateTime.now().millisecondsSinceEpoch;
      await db.into(db.lahans).insert(LahansCompanion(
        id: Value(3),
        namaLahan: Value('Kebun Lama'),
        luasHa: Value(10.0),
        usiaPohon: Value(5),
        cachedAt: Value(now),
      ));
      // Update via repository
      final result = await repo.update(
        3, namaLahan: 'Kebun Diperbarui', luasHa: 12.0, tahunTanam: 2019,
      );
      expect(result.id, 3);
      expect(result.namaLahan, 'Kebun Diperbarui');
      // Cache should reflect the update
      final cached = await repo.getAll();
      expect(cached.any((l) => l.namaLahan == 'Kebun Diperbarui'), isTrue);
    });
  });
}
