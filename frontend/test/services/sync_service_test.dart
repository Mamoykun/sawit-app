import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sawitku/database/app_database.dart';
import 'package:sawitku/models/panen_model.dart';
import 'package:sawitku/models/biaya_model.dart';
import 'package:sawitku/services/api_service.dart';
import 'package:sawitku/services/sync_service.dart';

class _FakeApi extends ApiService {
  bool throwNetworkError = false;
  bool throwClientError = false;
  int inputPanenCallCount = 0;

  @override
  Future<PanenModel> inputPanen(int lahanId, {
    required String bulan, required int tahun, required int bulanAngka,
    required int tanggal, required double tonAktual,
    double hargaPerTon = 2400000, String? catatan,
  }) async {
    inputPanenCallCount++;
    if (throwNetworkError) {
      throw DioException(
        requestOptions: RequestOptions(path: '/panen'),
        type: DioExceptionType.connectionError,
      );
    }
    if (throwClientError) {
      throw DioException(
        requestOptions: RequestOptions(path: '/panen'),
        response: Response(
          requestOptions: RequestOptions(path: '/panen'),
          statusCode: 422,
        ),
      );
    }
    return PanenModel(
      id: 999, lahanId: lahanId, luasHa: 14.0, usiaTahun: 8,
      tonAktual: tonAktual, targetMin: 10.0, targetMax: 20.0, targetMid: 15.0,
      bulan: bulan, tahun: tahun, bulanAngka: bulanAngka,
    );
  }

  @override
  Future<BiayaModel> createBiaya(int lahanId, {
    required String bulan, required int tahun, required int bulanAngka,
    required String kategoriCode, required double jumlah, String? keterangan,
  }) async {
    if (throwNetworkError) {
      throw DioException(
        requestOptions: RequestOptions(path: '/biaya'),
        type: DioExceptionType.connectionError,
      );
    }
    return BiayaModel(
      id: 888, lahanId: lahanId, bulan: bulan, tahun: tahun,
      bulanAngka: bulanAngka, kategori: KategoriBiaya.fromCode(kategoriCode),
      jumlah: jumlah,
    );
  }
}

AppDatabase _memoryDb() => AppDatabase(NativeDatabase.memory());

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  group('SyncService.flush()', () {
    late AppDatabase db;
    late _FakeApi api;
    late SyncService service;

    setUp(() {
      db = _memoryDb();
      api = _FakeApi();
      service = SyncService(db: db, api: api);
    });

    tearDown(() {
      service.dispose();
      db.close();
    });

    Future<void> _enqueuePanenCreate(int localId) async {
      final now = DateTime.now().millisecondsSinceEpoch;
      await db.into(db.syncQueue).insert(SyncQueueCompanion(
        entity: Value('panen'),
        operation: Value('create'),
        payload: Value(jsonEncode({
          'bulan': 'Januari', 'tahun': 2026, 'bulanAngka': 1,
          'tanggal': 10, 'tonAktual': 12.0,
        })),
        lahanId: Value(1),
        localId: Value(localId),
        createdAt: Value(now),
      ));
      await db.into(db.panens).insert(PanensCompanion(
        id: Value(localId),
        lahanId: Value(1),
        bulan: Value('Januari'),
        tahun: Value(2026),
        bulanAngka: Value(1),
        tonAktual: Value(12.0),
        cachedAt: Value(now),
      ));
    }

    test('flush removes queue item on success', () async {
      await _enqueuePanenCreate(-111);
      await service.flush();
      final queue = await db.select(db.syncQueue).get();
      expect(queue, isEmpty);
    });

    test('flush replaces temp id with server id in panens table', () async {
      await _enqueuePanenCreate(-222);
      await service.flush();
      final rows = await db.select(db.panens).get();
      expect(rows.length, 1);
      expect(rows.first.id, 999); // server id from _FakeApi
    });

    test('flush increments retry_count on network error', () async {
      api.throwNetworkError = true;
      await _enqueuePanenCreate(-333);
      await service.flush();
      final queue = await db.select(db.syncQueue).get();
      expect(queue.length, 1);
      expect(queue.first.retryCount, 1);
    });

    test('flush removes item on 4xx client error', () async {
      api.throwClientError = true;
      await _enqueuePanenCreate(-444);
      await service.flush();
      final queue = await db.select(db.syncQueue).get();
      expect(queue, isEmpty);
    });

    test('flush abandons item after retry_count reaches 3', () async {
      api.throwNetworkError = true;
      final now = DateTime.now().millisecondsSinceEpoch;
      await db.into(db.syncQueue).insert(SyncQueueCompanion(
        entity: Value('panen'),
        operation: Value('create'),
        payload: Value(jsonEncode({
          'bulan': 'Maret', 'tahun': 2026, 'bulanAngka': 3,
          'tanggal': 1, 'tonAktual': 5.0,
        })),
        lahanId: Value(1),
        localId: Value(-555),
        createdAt: Value(now),
        retryCount: Value(3),
      ));
      await service.flush();
      final queue = await db.select(db.syncQueue).get();
      expect(queue, isEmpty);
    });

    test('flush is no-op when queue is empty', () async {
      await service.flush(); // should not throw
      final queue = await db.select(db.syncQueue).get();
      expect(queue, isEmpty);
    });
  });
}
