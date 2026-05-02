import 'dart:convert';
import 'dart:math';
import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../models/panen_model.dart';
import '../services/analisa_service.dart';
import '../services/api_service.dart';

int _tempIdCounter = 0;

class PanenRepository {
  final AppDatabase _db;
  final ApiService _api;

  PanenRepository({required AppDatabase db, required ApiService api})
      : _db = db, _api = api;

  Future<List<PanenModel>> getByLahan(int lahanId, {int limit = 7}) async {
    final rows = await (
      _db.select(_db.panens)
        ..where((t) => t.lahanId.equals(lahanId))
        ..orderBy([
          (t) => OrderingTerm.desc(t.tahun),
          (t) => OrderingTerm.desc(t.bulanAngka),
        ])
        ..limit(limit)
    ).get();

    if (rows.isEmpty) {
      // Cold start — try to fetch from server before returning.
      // Tapi kalau queue punya pending delete untuk lahan ini, jangan
      // cold-start fetch (akan revive item yang baru saja user hapus).
      final pendingDeletes = await _pendingDeleteIds(lahanId);
      if (pendingDeletes.isNotEmpty) {
        return [];
      }
      try {
        final list = await _api.getRiwayat(lahanId, limit: limit);
        for (final m in list) {
          await upsertFromServer(m, lahanId);
        }
        return list;
      } catch (_) {
        return [];
      }
    }

    _refreshFromServerBackground(lahanId, limit: limit);
    return rows.map(_rowToModel).toList();
  }

  /// IDs of panen records yang punya pending delete di sync_queue.
  /// Dipakai untuk filter background refresh supaya item yang baru di-delete
  /// (tapi belum di-flush ke server) tidak ter-upsert balik.
  Future<List<int>> _pendingDeleteIds(int lahanId) async {
    final rows = await (
      _db.select(_db.syncQueue)
        ..where((t) =>
            t.entity.equals('panen') &
            t.operation.equals('delete') &
            t.lahanId.equals(lahanId))
    ).get();
    return rows.map((r) => r.localId).toList();
  }

  Future<PanenModel> create({
    required int lahanId,
    required double luasHa,
    required int usiaPohon,
    required String bulan,
    required int tahun,
    required int bulanAngka,
    required int tanggal,
    required double tonAktual,
    double hargaPerTon = 2400000,
    String? catatan,
  }) async {
    final tempId = -(DateTime.now().millisecondsSinceEpoch * 1000 + (++_tempIdCounter % 1000));
    final now = DateTime.now().millisecondsSinceEpoch;

    final target = AnalisaService.getTarget(luasHa, usiaPohon);
    // persenKurang relatif ke target.min — konsisten dengan threshold status
    // (status normal saat aktual >= min, jadi persenKurang = 0% saat normal).
    final persenKurang = tonAktual < target.min
        ? max(0.0, (target.min - tonAktual) / target.min * 100)
        : 0.0;
    final statusPanen = tonAktual >= target.min
        ? 'NORMAL'
        : persenKurang <= 20
            ? 'WARN'
            : 'DANGER';

    await _db.into(_db.panens).insert(PanensCompanion(
      id: Value(tempId),
      lahanId: Value(lahanId),
      bulan: Value(bulan),
      tahun: Value(tahun),
      bulanAngka: Value(bulanAngka),
      tanggal: Value(tanggal),
      tonAktual: Value(tonAktual),
      hargaPerTon: Value(hargaPerTon),
      luasHa: Value(luasHa),
      usiaPohon: Value(usiaPohon),
      targetMin: Value(target.min),
      targetMax: Value(target.max),
      targetMid: Value(target.mid),
      persenKurang: Value(persenKurang),
      statusPanen: Value(statusPanen),
      cachedAt: Value(now),
    ));

    await _db.into(_db.syncQueue).insert(SyncQueueCompanion(
      entity: Value('panen'),
      operation: Value('create'),
      payload: Value(jsonEncode({
        'bulan': bulan,
        'tahun': tahun,
        'bulanAngka': bulanAngka,
        'tanggal': tanggal,
        'tonAktual': tonAktual,
        'hargaPerTon': hargaPerTon,
        'catatan': catatan,
      })),
      lahanId: Value(lahanId),
      localId: Value(tempId),
      createdAt: Value(now),
    ));

    return PanenModel(
      id: tempId,
      lahanId: lahanId,
      luasHa: luasHa,
      usiaTahun: usiaPohon,
      tonAktual: tonAktual,
      targetMin: target.min,
      targetMax: target.max,
      targetMid: target.mid,
      bulan: bulan,
      tahun: tahun,
      bulanAngka: bulanAngka,
      tanggal: tanggal,
      hargaPerTon: hargaPerTon,
      persenKurang: persenKurang,
      statusPanen: statusPanen,
    );
  }

  Future<PanenModel> update({
    required int lahanId,
    required int panenId,
    required double luasHa,
    required int usiaPohon,
    required String bulan,
    required int tahun,
    required int bulanAngka,
    required int tanggal,
    required double tonAktual,
    double hargaPerTon = 2400000,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    final target = AnalisaService.getTarget(luasHa, usiaPohon);
    // persenKurang relatif ke target.min — konsisten dengan threshold status.
    final persenKurang = tonAktual < target.min
        ? max(0.0, (target.min - tonAktual) / target.min * 100)
        : 0.0;
    final statusPanen = tonAktual >= target.min
        ? 'NORMAL'
        : persenKurang <= 20
            ? 'WARN'
            : 'DANGER';

    await (_db.update(_db.panens)..where((t) => t.id.equals(panenId))).write(
      PanensCompanion(
        bulan: Value(bulan),
        tahun: Value(tahun),
        bulanAngka: Value(bulanAngka),
        tanggal: Value(tanggal),
        tonAktual: Value(tonAktual),
        hargaPerTon: Value(hargaPerTon),
        luasHa: Value(luasHa),
        usiaPohon: Value(usiaPohon),
        targetMin: Value(target.min),
        targetMax: Value(target.max),
        targetMid: Value(target.mid),
        persenKurang: Value(persenKurang),
        statusPanen: Value(statusPanen),
        cachedAt: Value(now),
      ),
    );

    await _db.into(_db.syncQueue).insert(SyncQueueCompanion(
      entity: Value('panen'),
      operation: Value('update'),
      payload: Value(jsonEncode({
        'bulan': bulan,
        'tahun': tahun,
        'bulanAngka': bulanAngka,
        'tanggal': tanggal,
        'tonAktual': tonAktual,
        'hargaPerTon': hargaPerTon,
      })),
      lahanId: Value(lahanId),
      localId: Value(panenId),
      createdAt: Value(now),
    ));

    return PanenModel(
      id: panenId,
      lahanId: lahanId,
      luasHa: luasHa,
      usiaTahun: usiaPohon,
      tonAktual: tonAktual,
      targetMin: target.min,
      targetMax: target.max,
      targetMid: target.mid,
      bulan: bulan,
      tahun: tahun,
      bulanAngka: bulanAngka,
      tanggal: tanggal,
      hargaPerTon: hargaPerTon,
      persenKurang: persenKurang,
      statusPanen: statusPanen,
    );
  }

  Future<void> delete({required int lahanId, required int panenId}) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    // Check if there's a pending create for this id — cancel both
    final pendingCreate = await (
      _db.select(_db.syncQueue)
        ..where((t) =>
            t.localId.equals(panenId) &
            t.operation.equals('create'))
    ).get();

    if (pendingCreate.isNotEmpty) {
      // Cancel pending create — no need to enqueue delete
      await (_db.delete(_db.syncQueue)
          ..where((t) =>
              t.localId.equals(panenId) &
              t.operation.equals('create'))).go();
    } else {
      // Enqueue delete for server-side record
      await _db.into(_db.syncQueue).insert(SyncQueueCompanion(
        entity: Value('panen'),
        operation: Value('delete'),
        payload: Value(jsonEncode({'id': panenId})),
        lahanId: Value(lahanId),
        localId: Value(panenId),
        createdAt: Value(now),
      ));
    }

    await (_db.delete(_db.panens)..where((t) => t.id.equals(panenId))).go();
  }

  Future<void> upsertFromServer(PanenModel model, int lahanId) async {
    await _db.into(_db.panens).insertOnConflictUpdate(
      _modelToCompanion(model, lahanId),
    );
  }

  void _refreshFromServerBackground(int lahanId, {int limit = 7}) {
    Future.microtask(() async {
      try {
        final pendingDeletes = await _pendingDeleteIds(lahanId);
        final list = await _api.getRiwayat(lahanId, limit: limit);
        for (final m in list) {
          // Skip item yang punya pending delete — kalau di-upsert akan
          // muncul lagi sampai SyncService selesai flush delete-nya.
          if (m.id != null && pendingDeletes.contains(m.id)) continue;
          await upsertFromServer(m, lahanId);
        }
      } catch (_) {}
    });
  }

  // Note: catatan is sync-payload-only (included in SyncQueue JSON for the
  // server) and is not stored in the local Panens table or PanenModel.
  PanenModel _rowToModel(Panen row) => PanenModel(
    id: row.id,
    lahanId: row.lahanId,
    luasHa: row.luasHa,
    usiaTahun: row.usiaPohon,
    tonAktual: row.tonAktual,
    targetMin: row.targetMin,
    targetMax: row.targetMax,
    targetMid: row.targetMid,
    bulan: row.bulan,
    tahun: row.tahun,
    bulanAngka: row.bulanAngka,
    tanggal: row.tanggal,
    statusPanen: row.statusPanen,
    persenKurang: row.persenKurang,
    hargaPerTon: row.hargaPerTon,
  );

  PanensCompanion _modelToCompanion(PanenModel m, int lahanId) =>
      PanensCompanion(
        id: Value(m.id!),
        lahanId: Value(lahanId),
        bulan: Value(m.bulan),
        tahun: Value(m.tahun ?? DateTime.now().year),
        bulanAngka: Value(m.bulanAngka ?? DateTime.now().month),
        tanggal: Value(m.tanggal),
        tonAktual: Value(m.tonAktual),
        targetMin: Value(m.targetMin),
        targetMax: Value(m.targetMax),
        targetMid: Value(m.targetMid),
        hargaPerTon: Value(m.hargaPerTon),
        statusPanen: Value(m.statusPanen),
        persenKurang: Value(m.persenKurang),
        luasHa: Value(m.luasHa),
        usiaPohon: Value(m.usiaTahun),
        cachedAt: Value(DateTime.now().millisecondsSinceEpoch),
      );
}
