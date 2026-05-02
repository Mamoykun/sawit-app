import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter/widgets.dart';
import '../database/app_database.dart';
import '../models/biaya_model.dart';
import '../models/panen_model.dart';
import '../services/api_service.dart';

class SyncService with WidgetsBindingObserver {
  final AppDatabase _db;
  final ApiService _api;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _isFlushing = false;

  SyncService({required AppDatabase db, required ApiService api})
      : _db = db, _api = api;

  /// Start listening to connectivity changes and app lifecycle events.
  void init() {
    WidgetsBinding.instance.addObserver(this);
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final isOnline = results.any((r) => r != ConnectivityResult.none);
      if (isOnline) flush();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) flush();
  }

  /// Stream of pending sync queue item count.
  Stream<int> get pendingCountStream =>
      (_db.select(_db.syncQueue)).watch().map((rows) => rows.length);

  /// Process all pending sync queue items in order.
  /// Safe to call concurrently — second call is a no-op if already flushing.
  Future<void> flush() async {
    if (_isFlushing) return;
    _isFlushing = true;
    try {
      final items = await (
        _db.select(_db.syncQueue)
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)])
      ).get();

      // SQLite serialises writes via Drift's connection pool, so concurrent
      // background refreshes (from repositories) and flush() are safe —
      // they queue internally and will not interleave at the row level.
      // _isFlushing guards against concurrent flush() calls only.
      for (final item in items) {
        await _processItem(item);
      }
    } finally {
      _isFlushing = false;
    }
  }

  Future<void> _processItem(SyncQueueData item) async {
    try {
      final payload = jsonDecode(item.payload) as Map<String, dynamic>;
      await _dispatch(item, payload);
      // Success — remove from queue
      await (_db.delete(_db.syncQueue)
          ..where((t) => t.id.equals(item.id))).go();
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final is4xx = status != null && status >= 400 && status < 500;
      if (is4xx || item.retryCount >= 3) {
        // Client error or exhausted retries — abandon
        await (_db.delete(_db.syncQueue)
            ..where((t) => t.id.equals(item.id))).go();
      } else {
        // Server/network error — increment retry count
        await (_db.update(_db.syncQueue)
            ..where((t) => t.id.equals(item.id))).write(
          SyncQueueCompanion(retryCount: Value(item.retryCount + 1)),
        );
      }
    } catch (_) {
      // Non-Dio error — treat as retriable
      if (item.retryCount >= 3) {
        await (_db.delete(_db.syncQueue)
            ..where((t) => t.id.equals(item.id))).go();
      } else {
        await (_db.update(_db.syncQueue)
            ..where((t) => t.id.equals(item.id))).write(
          SyncQueueCompanion(retryCount: Value(item.retryCount + 1)),
        );
      }
    }
  }

  Future<void> _dispatch(SyncQueueData item, Map<String, dynamic> p) async {
    switch ('${item.entity}_${item.operation}') {
      case 'panen_create':
        final result = await _api.inputPanen(
          item.lahanId,
          bulan: p['bulan'] as String,
          tahun: p['tahun'] as int,
          bulanAngka: p['bulanAngka'] as int,
          tanggal: p['tanggal'] as int,
          tonAktual: (p['tonAktual'] as num).toDouble(),
          hargaPerTon: (p['hargaPerTon'] as num?)?.toDouble() ?? 2400000,
          catatan: p['catatan'] as String?,
        );
        // Replace temp record with server record
        await (_db.delete(_db.panens)
            ..where((t) => t.id.equals(item.localId))).go();
        await _db.into(_db.panens).insertOnConflictUpdate(
          _panenToCompanion(result, item.lahanId),
        );
        break;

      case 'panen_update':
        final result = await _api.updatePanen(
          item.lahanId,
          item.localId,
          bulan: p['bulan'] as String,
          tahun: p['tahun'] as int,
          bulanAngka: p['bulanAngka'] as int,
          tanggal: p['tanggal'] as int,
          tonAktual: (p['tonAktual'] as num).toDouble(),
          hargaPerTon: (p['hargaPerTon'] as num?)?.toDouble() ?? 2400000,
        );
        await (_db.update(_db.panens)
            ..where((t) => t.id.equals(item.localId))).write(
          _panenToCompanion(result, item.lahanId),
        );
        break;

      case 'panen_delete':
        await _api.deletePanen(item.lahanId, item.localId);
        break;

      case 'biaya_create':
        final result = await _api.createBiaya(
          item.lahanId,
          bulan: p['bulan'] as String,
          tahun: p['tahun'] as int,
          bulanAngka: p['bulanAngka'] as int,
          kategoriCode: p['kategori'] as String,
          jumlah: (p['jumlah'] as num).toDouble(),
          keterangan: p['keterangan'] as String?,
        );
        await (_db.delete(_db.biayas)
            ..where((t) => t.id.equals(item.localId))).go();
        await _db.into(_db.biayas).insertOnConflictUpdate(
          _biayaToCompanion(result),
        );
        break;

      case 'biaya_update':
        final result = await _api.updateBiaya(
          item.lahanId,
          item.localId,
          bulan: p['bulan'] as String,
          tahun: p['tahun'] as int,
          bulanAngka: p['bulanAngka'] as int,
          kategoriCode: p['kategori'] as String,
          jumlah: (p['jumlah'] as num).toDouble(),
          keterangan: p['keterangan'] as String?,
        );
        await (_db.update(_db.biayas)
            ..where((t) => t.id.equals(item.localId))).write(
          _biayaToCompanion(result),
        );
        break;

      case 'biaya_delete':
        await _api.deleteBiaya(item.lahanId, item.localId);
        break;

      case 'lahan_delete':
        await _api.deleteLahan(item.localId);
        break;

      default:
        throw StateError(
          'SyncService: unknown operation "${item.entity}_${item.operation}" (queue id ${item.id})',
        );
    }
  }

  PanensCompanion _panenToCompanion(PanenModel m, int lahanId) => PanensCompanion(
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

  BiayasCompanion _biayaToCompanion(dynamic m) => BiayasCompanion(
    id: Value(m.id as int),
    lahanId: Value(m.lahanId as int),
    bulan: Value(m.bulan as String),
    tahun: Value(m.tahun as int),
    bulanAngka: Value(m.bulanAngka as int),
    kategori: Value((m.kategori as KategoriBiaya).code),
    jumlah: Value(m.jumlah as double),
    keterangan: Value(m.keterangan as String?),
    cachedAt: Value(DateTime.now().millisecondsSinceEpoch),
  );

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySub?.cancel();
  }
}
