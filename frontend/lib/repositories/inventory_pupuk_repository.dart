// frontend/lib/repositories/inventory_pupuk_repository.dart
import 'package:drift/drift.dart';
import '../database/app_database.dart';

class InventoryPupukModel {
  final int id;
  final int lahanId;
  final String namaPupuk;
  final double stokKg;
  final double thresholdAlert;
  final int? expiredAt;
  final String? catatan;
  final int updatedAt;

  const InventoryPupukModel({
    required this.id,
    required this.lahanId,
    required this.namaPupuk,
    required this.stokKg,
    required this.thresholdAlert,
    this.expiredAt,
    this.catatan,
    required this.updatedAt,
  });

  bool get isLowStock => stokKg < thresholdAlert;

  bool get isExpiringSoon {
    if (expiredAt == null) return false;
    final now = DateTime.now().millisecondsSinceEpoch;
    final thirtyDaysMs = 30 * 24 * 60 * 60 * 1000;
    return expiredAt! > now && expiredAt! - now <= thirtyDaysMs;
  }

  bool get isExpired {
    if (expiredAt == null) return false;
    return expiredAt! < DateTime.now().millisecondsSinceEpoch;
  }
}

class InventoryPupukRepository {
  final AppDatabase _db;

  InventoryPupukRepository({required AppDatabase db}) : _db = db;

  Future<List<InventoryPupukModel>> getByLahan(int lahanId) async {
    final rows = await (_db.select(_db.inventoryPupuks)
          ..where((t) => t.lahanId.equals(lahanId))
          ..orderBy([(t) => OrderingTerm.asc(t.namaPupuk)]))
        .get();
    return rows.map(_rowToModel).toList();
  }

  Future<InventoryPupukModel> create({
    required int lahanId,
    required String namaPupuk,
    double stokKg = 0,
    double thresholdAlert = 50,
    int? expiredAt,
    String? catatan,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = await _db.into(_db.inventoryPupuks).insert(
      InventoryPupuksCompanion(
        lahanId: Value(lahanId),
        namaPupuk: Value(namaPupuk.trim()),
        stokKg: Value(stokKg),
        thresholdAlert: Value(thresholdAlert),
        expiredAt: Value(expiredAt),
        catatan: Value(catatan?.trim()),
        updatedAt: Value(now),
      ),
    );
    return InventoryPupukModel(
      id: id,
      lahanId: lahanId,
      namaPupuk: namaPupuk.trim(),
      stokKg: stokKg,
      thresholdAlert: thresholdAlert,
      expiredAt: expiredAt,
      catatan: catatan?.trim(),
      updatedAt: now,
    );
  }

  Future<void> addStock(int id, double additionalKg) async {
    final row = await (_db.select(_db.inventoryPupuks)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (row == null) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    await (_db.update(_db.inventoryPupuks)..where((t) => t.id.equals(id)))
        .write(InventoryPupuksCompanion(
      stokKg: Value(row.stokKg + additionalKg),
      updatedAt: Value(now),
    ));
  }

  Future<void> consumeStock(int id, double kg) async {
    final row = await (_db.select(_db.inventoryPupuks)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (row == null) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    final newStok = (row.stokKg - kg).clamp(0.0, double.infinity);
    await (_db.update(_db.inventoryPupuks)..where((t) => t.id.equals(id)))
        .write(InventoryPupuksCompanion(
      stokKg: Value(newStok),
      updatedAt: Value(now),
    ));
  }

  Future<void> update({
    required int id,
    required String namaPupuk,
    required double stokKg,
    required double thresholdAlert,
    int? expiredAt,
    String? catatan,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await (_db.update(_db.inventoryPupuks)..where((t) => t.id.equals(id)))
        .write(InventoryPupuksCompanion(
      namaPupuk: Value(namaPupuk.trim()),
      stokKg: Value(stokKg),
      thresholdAlert: Value(thresholdAlert),
      expiredAt: Value(expiredAt),
      catatan: Value(catatan?.trim()),
      updatedAt: Value(now),
    ));
  }

  Future<void> delete(int id) async {
    await (_db.delete(_db.inventoryPupuks)..where((t) => t.id.equals(id))).go();
  }

  Future<List<InventoryPupukModel>> getLowStockAlerts(int lahanId) async {
    final all = await getByLahan(lahanId);
    return all.where((p) => p.isLowStock).toList();
  }

  Future<List<InventoryPupukModel>> getExpiringSoon(int lahanId) async {
    final all = await getByLahan(lahanId);
    return all.where((p) => p.isExpiringSoon).toList();
  }

  InventoryPupukModel _rowToModel(InventoryPupuk row) => InventoryPupukModel(
        id: row.id,
        lahanId: row.lahanId,
        namaPupuk: row.namaPupuk,
        stokKg: row.stokKg,
        thresholdAlert: row.thresholdAlert,
        expiredAt: row.expiredAt,
        catatan: row.catatan,
        updatedAt: row.updatedAt,
      );
}
