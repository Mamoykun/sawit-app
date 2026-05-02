import 'dart:convert';
import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../models/lahan_model.dart';
import '../services/api_service.dart';

class LahanRepository {
  final AppDatabase _db;
  final ApiService _api;

  LahanRepository({required AppDatabase db, required ApiService api})
      : _db = db, _api = api;

  /// Returns all active lahan.
  /// If cache is empty (first login / after wipe), awaits server fetch so the
  /// user does not see an empty list. Otherwise returns SQLite cache
  /// immediately and triggers a background refresh.
  Future<List<LahanModel>> getAll() async {
    final rows = await (
      _db.select(_db.lahans)
        ..where((t) => t.isActive.equals(true))
    ).get();

    if (rows.isEmpty) {
      // Cold start — fetch from server, KECUALI ada pending delete.
      final pendingDeletes = await _pendingDeleteIds();
      if (pendingDeletes.isNotEmpty) return [];
      try {
        final list = await _api.getMyLahan();
        for (final m in list) {
          await upsertFromServer(m);
        }
        return list.where((m) => m.isActive).toList();
      } catch (_) {
        // Offline + empty cache — return empty list, screen shows empty state.
        return [];
      }
    }

    _refreshFromServerBackground();
    return rows.map(_rowToModel).toList();
  }

  /// IDs lahan yang punya pending delete di sync_queue.
  Future<List<int>> _pendingDeleteIds() async {
    final rows = await (
      _db.select(_db.syncQueue)
        ..where((t) =>
            t.entity.equals('lahan') & t.operation.equals('delete'))
    ).get();
    return rows.map((r) => r.localId).toList();
  }

  /// Creates a new lahan via the server (network-required).
  /// Lahan creation is intentionally NOT offline-queued because:
  /// - [usiaPohon] is computed server-side from [tahunTanam]
  /// - The server-assigned [id] is needed immediately to proceed in the app
  /// After success, caches the result locally via [upsertFromServer].
  Future<LahanModel> create({
    required String namaLahan,
    required double luasHa,
    required int tahunTanam,
    int? jumlahPohon,
    String? lokasi,
  }) async {
    final result = await _api.createLahan(
      namaLahan: namaLahan,
      luasHa: luasHa,
      tahunTanam: tahunTanam,
      jumlahPohon: jumlahPohon,
      lokasi: lokasi,
    );
    await upsertFromServer(result);
    return result;
  }

  /// Updates a lahan via the server (network-required).
  /// Same rationale as [create] — server computes updated fields.
  /// After success, updates the local cache via [upsertFromServer].
  Future<LahanModel> update(int lahanId, {
    required String namaLahan,
    required double luasHa,
    required int tahunTanam,
    int? jumlahPohon,
    String? lokasi,
  }) async {
    final result = await _api.updateLahan(
      lahanId,
      namaLahan: namaLahan,
      luasHa: luasHa,
      tahunTanam: tahunTanam,
      jumlahPohon: jumlahPohon,
      lokasi: lokasi,
    );
    await upsertFromServer(result);
    return result;
  }

  /// Delete lahan — removes from SQLite and enqueues server delete.
  Future<void> delete(int lahanId) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.into(_db.syncQueue).insert(SyncQueueCompanion(
      entity: Value('lahan'),
      operation: Value('delete'),
      payload: Value(jsonEncode({'id': lahanId})),
      lahanId: Value(lahanId),
      localId: Value(lahanId),
      createdAt: Value(now),
    ));
    await (_db.delete(_db.lahans)..where((t) => t.id.equals(lahanId))).go();
  }

  /// Cache a server lahan into SQLite (upsert by id).
  Future<void> upsertFromServer(LahanModel model) async {
    await _db.into(_db.lahans).insertOnConflictUpdate(
      LahansCompanion(
        id: Value(model.id),
        namaLahan: Value(model.namaLahan),
        luasHa: Value(model.luasHa),
        usiaPohon: Value(model.usiaPohon),
        tahunTanam: Value(model.tahunTanam),
        jumlahPohon: Value(model.jumlahPohon),
        lokasi: Value(model.lokasi),
        isActive: Value(model.isActive),
        cachedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  void _refreshFromServerBackground() {
    Future.microtask(() async {
      try {
        final pendingDeletes = await _pendingDeleteIds();
        final list = await _api.getMyLahan();
        for (final m in list) {
          if (pendingDeletes.contains(m.id)) continue;
          await upsertFromServer(m);
        }
      } catch (_) {}
    });
  }

  LahanModel _rowToModel(Lahan row) => LahanModel(
    id: row.id,
    namaLahan: row.namaLahan,
    luasHa: row.luasHa,
    usiaPohon: row.usiaPohon,
    tahunTanam: row.tahunTanam,
    jumlahPohon: row.jumlahPohon,
    lokasi: row.lokasi,
    isActive: row.isActive,
  );
}
