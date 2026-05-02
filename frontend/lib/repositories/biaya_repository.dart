import 'dart:convert';
import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../models/biaya_model.dart';
import '../services/api_service.dart';

int _tempIdCounter = 0;

class BiayaRepository {
  final AppDatabase _db;
  final ApiService _api;

  BiayaRepository({required AppDatabase db, required ApiService api})
      : _db = db, _api = api;

  Future<List<BiayaModel>> getByLahan(int lahanId, {int? tahun}) async {
    final query = _db.select(_db.biayas)
      ..where((t) => t.lahanId.equals(lahanId));
    if (tahun != null) {
      query.where((t) => t.tahun.equals(tahun));
    }
    query.orderBy([
      (t) => OrderingTerm.desc(t.tahun),
      (t) => OrderingTerm.desc(t.bulanAngka),
    ]);
    final rows = await query.get();
    _refreshFromServerBackground(lahanId, tahun: tahun);
    return rows.map(_rowToModel).toList();
  }

  Future<BiayaModel> create({
    required int lahanId,
    required String bulan,
    required int tahun,
    required int bulanAngka,
    required String kategoriCode,
    required double jumlah,
    String? keterangan,
  }) async {
    final tempId = -(DateTime.now().millisecondsSinceEpoch * 1000 + (++_tempIdCounter % 1000));
    final now = DateTime.now().millisecondsSinceEpoch;

    await _db.into(_db.biayas).insert(BiayasCompanion(
      id: Value(tempId),
      lahanId: Value(lahanId),
      bulan: Value(bulan),
      tahun: Value(tahun),
      bulanAngka: Value(bulanAngka),
      kategori: Value(kategoriCode),
      jumlah: Value(jumlah),
      keterangan: Value(keterangan),
      cachedAt: Value(now),
    ));

    await _db.into(_db.syncQueue).insert(SyncQueueCompanion(
      entity: Value('biaya'),
      operation: Value('create'),
      payload: Value(jsonEncode({
        'bulan': bulan,
        'tahun': tahun,
        'bulanAngka': bulanAngka,
        'kategori': kategoriCode,
        'jumlah': jumlah,
        'keterangan': keterangan,
      })),
      lahanId: Value(lahanId),
      localId: Value(tempId),
      createdAt: Value(now),
    ));

    return BiayaModel(
      id: tempId,
      lahanId: lahanId,
      bulan: bulan,
      tahun: tahun,
      bulanAngka: bulanAngka,
      kategori: KategoriBiaya.fromCode(kategoriCode),
      jumlah: jumlah,
      keterangan: keterangan,
    );
  }

  Future<BiayaModel> update({
    required int lahanId,
    required int biayaId,
    required String bulan,
    required int tahun,
    required int bulanAngka,
    required String kategoriCode,
    required double jumlah,
    String? keterangan,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    await (_db.update(_db.biayas)..where((t) => t.id.equals(biayaId))).write(
      BiayasCompanion(
        bulan: Value(bulan),
        tahun: Value(tahun),
        bulanAngka: Value(bulanAngka),
        kategori: Value(kategoriCode),
        jumlah: Value(jumlah),
        keterangan: Value(keterangan),
        cachedAt: Value(now),
      ),
    );

    await _db.into(_db.syncQueue).insert(SyncQueueCompanion(
      entity: Value('biaya'),
      operation: Value('update'),
      payload: Value(jsonEncode({
        'bulan': bulan,
        'tahun': tahun,
        'bulanAngka': bulanAngka,
        'kategori': kategoriCode,
        'jumlah': jumlah,
        'keterangan': keterangan,
      })),
      lahanId: Value(lahanId),
      localId: Value(biayaId),
      createdAt: Value(now),
    ));

    return BiayaModel(
      id: biayaId,
      lahanId: lahanId,
      bulan: bulan,
      tahun: tahun,
      bulanAngka: bulanAngka,
      kategori: KategoriBiaya.fromCode(kategoriCode),
      jumlah: jumlah,
      keterangan: keterangan,
    );
  }

  Future<void> delete({required int lahanId, required int biayaId}) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    final pendingCreate = await (
      _db.select(_db.syncQueue)
        ..where((t) =>
            t.localId.equals(biayaId) &
            t.operation.equals('create'))
    ).get();

    if (pendingCreate.isNotEmpty) {
      await (_db.delete(_db.syncQueue)
          ..where((t) =>
              t.localId.equals(biayaId) &
              t.operation.equals('create'))).go();
    } else {
      await _db.into(_db.syncQueue).insert(SyncQueueCompanion(
        entity: Value('biaya'),
        operation: Value('delete'),
        payload: Value(jsonEncode({'id': biayaId})),
        lahanId: Value(lahanId),
        localId: Value(biayaId),
        createdAt: Value(now),
      ));
    }

    await (_db.delete(_db.biayas)..where((t) => t.id.equals(biayaId))).go();
  }

  Future<void> upsertFromServer(BiayaModel model) async {
    await _db.into(_db.biayas).insertOnConflictUpdate(_modelToCompanion(model));
  }

  void _refreshFromServerBackground(int lahanId, {int? tahun}) {
    Future.microtask(() async {
      try {
        final list = await _api.getBiaya(lahanId, tahun: tahun);
        for (final m in list) {
          await upsertFromServer(m);
        }
      } catch (_) {}
    });
  }

  BiayaModel _rowToModel(Biaya row) => BiayaModel(
    id: row.id,
    lahanId: row.lahanId,
    bulan: row.bulan,
    tahun: row.tahun,
    bulanAngka: row.bulanAngka,
    kategori: KategoriBiaya.fromCode(row.kategori),
    jumlah: row.jumlah,
    keterangan: row.keterangan,
  );

  BiayasCompanion _modelToCompanion(BiayaModel m) => BiayasCompanion(
    id: Value(m.id),
    lahanId: Value(m.lahanId),
    bulan: Value(m.bulan),
    tahun: Value(m.tahun),
    bulanAngka: Value(m.bulanAngka),
    kategori: Value(m.kategori.code),
    jumlah: Value(m.jumlah),
    keterangan: Value(m.keterangan),
    cachedAt: Value(DateTime.now().millisecondsSinceEpoch),
  );
}
