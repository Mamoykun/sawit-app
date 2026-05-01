# Offline Mode Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add offline-first capability to Sawitku Flutter app so farmers can input panen/biaya and view history without network connectivity, with automatic sync when online.

**Architecture:** All reads serve from local SQLite (drift) first; writes go to SQLite immediately and enqueue into `sync_queue` table. `SyncService` flushes the queue when connectivity is restored or app resumes. Server always wins on conflict.

**Tech Stack:** Flutter, drift 2.18 (SQLite ORM), drift_flutter 0.2 (native bindings), connectivity_plus 6.0

---

## File Map

**New files:**
- `frontend/lib/database/app_database.dart` — Drift DB class
- `frontend/lib/database/app_database.g.dart` — generated (build_runner)
- `frontend/lib/database/tables/lahan_table.dart`
- `frontend/lib/database/tables/panen_table.dart`
- `frontend/lib/database/tables/biaya_table.dart`
- `frontend/lib/database/tables/sync_queue_table.dart`
- `frontend/lib/repositories/lahan_repository.dart`
- `frontend/lib/repositories/panen_repository.dart`
- `frontend/lib/repositories/biaya_repository.dart`
- `frontend/lib/services/sync_service.dart`
- `frontend/lib/widgets/offline_banner.dart`
- `frontend/test/repositories/panen_repository_test.dart`
- `frontend/test/repositories/biaya_repository_test.dart`
- `frontend/test/repositories/lahan_repository_test.dart`
- `frontend/test/services/sync_service_test.dart`

**Modified files:**
- `frontend/pubspec.yaml` — add drift, drift_flutter, connectivity_plus
- `frontend/lib/main.dart` — init AppDatabase + SyncService globals
- `frontend/lib/screens/main_screen.dart` — OfflineBanner + use PanenRepository
- `frontend/lib/screens/beranda_screen.dart` — use PanenRepository
- `frontend/lib/screens/riwayat_screen.dart` — use PanenRepository
- `frontend/lib/screens/input_panen_screen.dart` — use PanenRepository
- `frontend/lib/screens/biaya_screen.dart` — use BiayaRepository
- `frontend/lib/screens/lahan_screen.dart` — use LahanRepository

---

## Task 1: Add Dependencies

**Files:**
- Modify: `frontend/pubspec.yaml`

- [ ] **Step 1: Add drift, drift_flutter, connectivity_plus to pubspec.yaml**

Open `frontend/pubspec.yaml`. Under `dependencies:`, add after `webview_flutter`:

```yaml
  # Offline mode
  drift: ^2.18.0
  drift_flutter: ^0.2.0
  connectivity_plus: ^6.0.3
```

Under `dev_dependencies:`, add after `flutter_lints`:

```yaml
  drift_dev: ^2.18.0
```

- [ ] **Step 2: Get packages**

```bash
cd frontend
flutter pub get
```

Expected: resolves without conflicts. drift, drift_flutter, connectivity_plus appear in `.dart_tool/package_config.json`.

- [ ] **Step 3: Commit**

```bash
git add frontend/pubspec.yaml frontend/pubspec.lock
git commit -m "chore(deps): add drift, drift_flutter, connectivity_plus for offline mode"
```

---

## Task 2: Drift Table Definitions

**Files:**
- Create: `frontend/lib/database/tables/lahan_table.dart`
- Create: `frontend/lib/database/tables/panen_table.dart`
- Create: `frontend/lib/database/tables/biaya_table.dart`
- Create: `frontend/lib/database/tables/sync_queue_table.dart`

- [ ] **Step 1: Create lahan_table.dart**

```dart
// frontend/lib/database/tables/lahan_table.dart
import 'package:drift/drift.dart';

class Lahans extends Table {
  IntColumn get id => integer()();
  TextColumn get namaLahan => text()();
  RealColumn get luasHa => real()();
  IntColumn get usiaPohon => integer()();
  IntColumn get tahunTanam => integer().nullable()();
  IntColumn get jumlahPohon => integer().nullable()();
  TextColumn get lokasi => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  IntColumn get cachedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
```

- [ ] **Step 2: Create panen_table.dart**

```dart
// frontend/lib/database/tables/panen_table.dart
import 'package:drift/drift.dart';

class Panens extends Table {
  IntColumn get id => integer()();
  IntColumn get lahanId => integer()();
  TextColumn get bulan => text()();
  IntColumn get tahun => integer()();
  IntColumn get bulanAngka => integer()();
  IntColumn get tanggal => integer().nullable()();
  RealColumn get tonAktual => real()();
  RealColumn get targetMin => real().withDefault(const Constant(0.0))();
  RealColumn get targetMax => real().withDefault(const Constant(0.0))();
  RealColumn get targetMid => real().withDefault(const Constant(0.0))();
  RealColumn get hargaPerTon => real().withDefault(const Constant(2400000.0))();
  TextColumn get statusPanen => text().nullable()();
  RealColumn get persenKurang => real().withDefault(const Constant(0.0))();
  RealColumn get luasHa => real().withDefault(const Constant(14.0))();
  IntColumn get usiaPohon => integer().withDefault(const Constant(8))();
  IntColumn get cachedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
```

- [ ] **Step 3: Create biaya_table.dart**

```dart
// frontend/lib/database/tables/biaya_table.dart
import 'package:drift/drift.dart';

class Biayas extends Table {
  IntColumn get id => integer()();
  IntColumn get lahanId => integer()();
  TextColumn get bulan => text()();
  IntColumn get tahun => integer()();
  IntColumn get bulanAngka => integer()();
  TextColumn get kategori => text()();
  RealColumn get jumlah => real()();
  TextColumn get keterangan => text().nullable()();
  IntColumn get cachedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
```

- [ ] **Step 4: Create sync_queue_table.dart**

```dart
// frontend/lib/database/tables/sync_queue_table.dart
import 'package:drift/drift.dart';

// entity: 'panen' | 'biaya' | 'lahan'
// operation: 'create' | 'update' | 'delete'
// payload: JSON-encoded request body
class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entity => text()();
  TextColumn get operation => text()();
  TextColumn get payload => text()();
  IntColumn get lahanId => integer()();
  IntColumn get localId => integer()();
  IntColumn get createdAt => integer()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
}
```

- [ ] **Step 5: Commit**

```bash
git add frontend/lib/database/tables/
git commit -m "feat(offline): drift table definitions — lahans, panens, biayas, sync_queue"
```

---

## Task 3: AppDatabase Class + Code Generation

**Files:**
- Create: `frontend/lib/database/app_database.dart`
- Create: `frontend/lib/database/app_database.g.dart` (generated)

- [ ] **Step 1: Create app_database.dart**

```dart
// frontend/lib/database/app_database.dart
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'tables/lahan_table.dart';
import 'tables/panen_table.dart';
import 'tables/biaya_table.dart';
import 'tables/sync_queue_table.dart';

export 'tables/lahan_table.dart';
export 'tables/panen_table.dart';
export 'tables/biaya_table.dart';
export 'tables/sync_queue_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Lahans, Panens, Biayas, SyncQueue])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'sawitku_offline'));

  @override
  int get schemaVersion => 1;
}
```

- [ ] **Step 2: Run build_runner to generate app_database.g.dart**

```bash
cd frontend
dart run build_runner build --delete-conflicting-outputs
```

Expected output: `[INFO] build_runner: Succeeded after ...` with no errors. File `frontend/lib/database/app_database.g.dart` is created.

- [ ] **Step 3: Verify the app still compiles**

```bash
flutter build apk --debug 2>&1 | tail -5
```

Expected: `Built build/app/outputs/flutter-apk/app-debug.apk` with no errors.

- [ ] **Step 4: Commit**

```bash
git add frontend/lib/database/app_database.dart frontend/lib/database/app_database.g.dart
git commit -m "feat(offline): AppDatabase with drift — schema v1"
```

---

## Task 4: Initialize Globals in main.dart

**Files:**
- Modify: `frontend/lib/main.dart`

The app currently initializes nothing beyond system UI. We add `appDb` and `syncService` as top-level globals initialized at startup.

- [ ] **Step 1: Update main.dart**

Replace the entire content of `frontend/lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'database/app_database.dart';
import 'services/sync_service.dart';
import 'services/api_service.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';

final navigatorKey = GlobalKey<NavigatorState>();
late final AppDatabase appDb;
late final SyncService syncService;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  appDb = AppDatabase();
  syncService = SyncService(db: appDb, api: ApiService());
  syncService.init();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const SawitKuApp());
}

class SawitKuApp extends StatelessWidget {
  const SawitKuApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'SawitKu',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.theme,
    navigatorKey: navigatorKey,
    home: const SplashScreen(),
  );
}
```

- [ ] **Step 2: Verify no immediate compile errors**

```bash
cd frontend
flutter analyze lib/main.dart
```

Expected: `No issues found!` (SyncService and AppDatabase will be created in later tasks — this step may show "Target of URI hasn't been created" warnings, which are expected until those files exist.)

- [ ] **Step 3: Commit**

```bash
git add frontend/lib/main.dart
git commit -m "feat(offline): initialize AppDatabase and SyncService globals at startup"
```

---

## Task 5: PanenRepository

**Files:**
- Create: `frontend/lib/repositories/panen_repository.dart`
- Create: `frontend/test/repositories/panen_repository_test.dart`

- [ ] **Step 1: Write the failing tests**

Create `frontend/test/repositories/panen_repository_test.dart`:

```dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sawitku/database/app_database.dart';
import 'package:sawitku/repositories/panen_repository.dart';
import 'package:sawitku/services/api_service.dart';

// Minimal fake ApiService — overrides only what PanenRepository needs
class _FakeApi extends ApiService {
  PanenModel? stubbedCreate;
  PanenModel? stubbedUpdate;

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
  }) async => stubbedUpdate!;

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
      await db.into(db.panens).insert(PanensCompanion.insert(
        id: Value(1), lahanId: Value(1), bulan: 'Januari',
        tahun: 2026, bulanAngka: 1,
        tonAktual: 10.0, cachedAt: DateTime.now().millisecondsSinceEpoch,
      ));

      final results = await repo.getByLahan(1);
      expect(results.length, 1);
      expect(results.first.tonAktual, 10.0);
    });

    test('delete removes row from SQLite and enqueues delete operation', () async {
      await db.into(db.panens).insert(PanensCompanion.insert(
        id: Value(42), lahanId: Value(1), bulan: 'Februari',
        tahun: 2026, bulanAngka: 2,
        tonAktual: 8.0, cachedAt: DateTime.now().millisecondsSinceEpoch,
      ));

      await repo.delete(lahanId: 1, panenId: 42);

      final rows = await db.select(db.panens).get();
      expect(rows, isEmpty);
      final queue = await db.select(db.syncQueue).get();
      expect(queue.first.operation, 'delete');
    });
  });
}
```

- [ ] **Step 2: Run tests — expect failures (file not found)**

```bash
cd frontend
flutter test test/repositories/panen_repository_test.dart
```

Expected: `Error: Cannot run with sound null safety` or `Target of URI hasn't been created` — tests fail because repository doesn't exist yet.

- [ ] **Step 3: Create panen_repository.dart**

```dart
// frontend/lib/repositories/panen_repository.dart
import 'dart:convert';
import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../models/panen_model.dart';
import '../services/api_service.dart';

class PanenRepository {
  final AppDatabase _db;
  final ApiService _api;

  PanenRepository({required AppDatabase db, required ApiService api})
      : _db = db, _api = api;

  Future<List<PanenModel>> getByLahan(int lahanId, {int limit = 7}) async {
    final rows = await (
      _db.select(_db.panens)
        ..where((t) => t.lahanId.equals(lahanId))
        ..orderBy([(t) => OrderingTerm.desc(t.tahun),
                   (t) => OrderingTerm.desc(t.bulanAngka)])
        ..limit(limit)
    ).get();
    _refreshFromServerBackground(lahanId, limit: limit);
    return rows.map(_rowToModel).toList();
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
    final tempId = -DateTime.now().millisecondsSinceEpoch;
    final now = DateTime.now().millisecondsSinceEpoch;

    await _db.into(_db.panens).insert(PanensCompanion.insert(
      id: Value(tempId),
      lahanId: Value(lahanId),
      bulan: bulan,
      tahun: tahun,
      bulanAngka: bulanAngka,
      tanggal: Value(tanggal),
      tonAktual: tonAktual,
      hargaPerTon: Value(hargaPerTon),
      luasHa: Value(luasHa),
      usiaPohon: Value(usiaPohon),
      cachedAt: now,
    ));

    await _db.into(_db.syncQueue).insert(SyncQueueCompanion.insert(
      entity: 'panen',
      operation: 'create',
      payload: jsonEncode({
        'bulan': bulan, 'tahun': tahun, 'bulanAngka': bulanAngka,
        'tanggal': tanggal, 'tonAktual': tonAktual,
        'hargaPerTon': hargaPerTon, 'catatan': catatan,
      }),
      lahanId: lahanId,
      localId: tempId,
      createdAt: now,
    ));

    return PanenModel(
      id: tempId, lahanId: lahanId, luasHa: luasHa, usiaTahun: usiaPohon,
      tonAktual: tonAktual, targetMin: 0, targetMax: 0, targetMid: 0,
      bulan: bulan, tahun: tahun, bulanAngka: bulanAngka, tanggal: tanggal,
      hargaPerTon: hargaPerTon,
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

    await (_db.update(_db.panens)..where((t) => t.id.equals(panenId))).write(
      PanensCompanion(
        bulan: Value(bulan), tahun: Value(tahun), bulanAngka: Value(bulanAngka),
        tanggal: Value(tanggal), tonAktual: Value(tonAktual),
        hargaPerTon: Value(hargaPerTon), cachedAt: Value(now),
      ),
    );

    await _db.into(_db.syncQueue).insert(SyncQueueCompanion.insert(
      entity: 'panen',
      operation: 'update',
      payload: jsonEncode({
        'bulan': bulan, 'tahun': tahun, 'bulanAngka': bulanAngka,
        'tanggal': tanggal, 'tonAktual': tonAktual, 'hargaPerTon': hargaPerTon,
      }),
      lahanId: lahanId,
      localId: panenId,
      createdAt: now,
    ));

    return PanenModel(
      id: panenId, lahanId: lahanId, luasHa: luasHa, usiaTahun: usiaPohon,
      tonAktual: tonAktual, targetMin: 0, targetMax: 0, targetMid: 0,
      bulan: bulan, tahun: tahun, bulanAngka: bulanAngka, tanggal: tanggal,
      hargaPerTon: hargaPerTon,
    );
  }

  Future<void> delete({required int lahanId, required int panenId}) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    // If pending create for this id, cancel both
    final pendingCreate = await (
      _db.select(_db.syncQueue)
        ..where((t) => t.localId.equals(panenId) & t.operation.equals('create'))
    ).get();

    if (pendingCreate.isNotEmpty) {
      await (_db.delete(_db.syncQueue)
          ..where((t) => t.localId.equals(panenId) & t.operation.equals('create'))).go();
    } else {
      await _db.into(_db.syncQueue).insert(SyncQueueCompanion.insert(
        entity: 'panen',
        operation: 'delete',
        payload: jsonEncode({'id': panenId}),
        lahanId: lahanId,
        localId: panenId,
        createdAt: now,
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
        final list = await _api.getRiwayat(lahanId, limit: limit);
        for (final m in list) {
          await upsertFromServer(m, lahanId);
        }
      } catch (_) {}
    });
  }

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
```

- [ ] **Step 4: Run tests — expect pass**

```bash
cd frontend
flutter test test/repositories/panen_repository_test.dart
```

Expected: `All tests passed!`

- [ ] **Step 5: Commit**

```bash
git add frontend/lib/repositories/panen_repository.dart frontend/test/repositories/panen_repository_test.dart
git commit -m "feat(offline): PanenRepository — SQLite-first read/write with sync queue"
```

---

## Task 6: BiayaRepository

**Files:**
- Create: `frontend/lib/repositories/biaya_repository.dart`
- Create: `frontend/test/repositories/biaya_repository_test.dart`

- [ ] **Step 1: Write failing tests**

Create `frontend/test/repositories/biaya_repository_test.dart`:

```dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sawitku/database/app_database.dart';
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
    });

    test('create enqueues sync with operation=create', () async {
      await repo.create(
        lahanId: 1, bulan: 'Maret', tahun: 2026, bulanAngka: 3,
        kategoriCode: 'PUPUK', jumlah: 500000,
      );
      final queue = await db.select(db.syncQueue).get();
      expect(queue.first.entity, 'biaya');
      expect(queue.first.operation, 'create');
    });

    test('getByLahan returns SQLite rows filtered by lahanId', () async {
      await db.into(db.biayas).insert(BiayasCompanion.insert(
        id: Value(1), lahanId: Value(1), bulan: 'Januari',
        tahun: 2026, bulanAngka: 1, kategori: 'PUPUK', jumlah: 300000,
        cachedAt: DateTime.now().millisecondsSinceEpoch,
      ));
      await db.into(db.biayas).insert(BiayasCompanion.insert(
        id: Value(2), lahanId: Value(2), bulan: 'Januari',
        tahun: 2026, bulanAngka: 1, kategori: 'PUPUK', jumlah: 200000,
        cachedAt: DateTime.now().millisecondsSinceEpoch,
      ));
      final results = await repo.getByLahan(1);
      expect(results.length, 1);
      expect(results.first.lahanId, 1);
    });
  });
}
```

- [ ] **Step 2: Run tests — expect failure**

```bash
cd frontend
flutter test test/repositories/biaya_repository_test.dart
```

Expected: fails with `Target of URI hasn't been created`.

- [ ] **Step 3: Create biaya_repository.dart**

```dart
// frontend/lib/repositories/biaya_repository.dart
import 'dart:convert';
import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../models/biaya_model.dart';
import '../services/api_service.dart';

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
    final tempId = -DateTime.now().millisecondsSinceEpoch;
    final now = DateTime.now().millisecondsSinceEpoch;

    await _db.into(_db.biayas).insert(BiayasCompanion.insert(
      id: Value(tempId),
      lahanId: Value(lahanId),
      bulan: bulan,
      tahun: tahun,
      bulanAngka: bulanAngka,
      kategori: kategoriCode,
      jumlah: jumlah,
      keterangan: Value(keterangan),
      cachedAt: now,
    ));

    await _db.into(_db.syncQueue).insert(SyncQueueCompanion.insert(
      entity: 'biaya',
      operation: 'create',
      payload: jsonEncode({
        'bulan': bulan, 'tahun': tahun, 'bulanAngka': bulanAngka,
        'kategori': kategoriCode, 'jumlah': jumlah, 'keterangan': keterangan,
      }),
      lahanId: lahanId,
      localId: tempId,
      createdAt: now,
    ));

    return BiayaModel(
      id: tempId, lahanId: lahanId, bulan: bulan, tahun: tahun,
      bulanAngka: bulanAngka,
      kategori: KategoriBiaya.fromCode(kategoriCode),
      jumlah: jumlah, keterangan: keterangan,
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
        bulan: Value(bulan), tahun: Value(tahun), bulanAngka: Value(bulanAngka),
        kategori: Value(kategoriCode), jumlah: Value(jumlah),
        keterangan: Value(keterangan), cachedAt: Value(now),
      ),
    );

    await _db.into(_db.syncQueue).insert(SyncQueueCompanion.insert(
      entity: 'biaya',
      operation: 'update',
      payload: jsonEncode({
        'bulan': bulan, 'tahun': tahun, 'bulanAngka': bulanAngka,
        'kategori': kategoriCode, 'jumlah': jumlah, 'keterangan': keterangan,
      }),
      lahanId: lahanId,
      localId: biayaId,
      createdAt: now,
    ));

    return BiayaModel(
      id: biayaId, lahanId: lahanId, bulan: bulan, tahun: tahun,
      bulanAngka: bulanAngka, kategori: KategoriBiaya.fromCode(kategoriCode),
      jumlah: jumlah, keterangan: keterangan,
    );
  }

  Future<void> delete({required int lahanId, required int biayaId}) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    final pendingCreate = await (
      _db.select(_db.syncQueue)
        ..where((t) => t.localId.equals(biayaId) & t.operation.equals('create'))
    ).get();

    if (pendingCreate.isNotEmpty) {
      await (_db.delete(_db.syncQueue)
          ..where((t) => t.localId.equals(biayaId) & t.operation.equals('create'))).go();
    } else {
      await _db.into(_db.syncQueue).insert(SyncQueueCompanion.insert(
        entity: 'biaya',
        operation: 'delete',
        payload: jsonEncode({'id': biayaId}),
        lahanId: lahanId,
        localId: biayaId,
        createdAt: now,
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
```

- [ ] **Step 4: Run tests — expect pass**

```bash
cd frontend
flutter test test/repositories/biaya_repository_test.dart
```

Expected: `All tests passed!`

- [ ] **Step 5: Commit**

```bash
git add frontend/lib/repositories/biaya_repository.dart frontend/test/repositories/biaya_repository_test.dart
git commit -m "feat(offline): BiayaRepository — SQLite-first with sync queue"
```

---

## Task 7: LahanRepository

**Files:**
- Create: `frontend/lib/repositories/lahan_repository.dart`
- Create: `frontend/test/repositories/lahan_repository_test.dart`

- [ ] **Step 1: Write failing tests**

Create `frontend/test/repositories/lahan_repository_test.dart`:

```dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sawitku/database/app_database.dart';
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

    test('delete removes lahan from SQLite and enqueues sync', () async {
      await db.into(db.lahans).insert(LahansCompanion.insert(
        id: Value(5), namaLahan: 'Test', luasHa: 10.0,
        usiaPohon: 6, cachedAt: DateTime.now().millisecondsSinceEpoch,
      ));
      await repo.delete(5);
      final rows = await db.select(db.lahans).get();
      expect(rows, isEmpty);
      final queue = await db.select(db.syncQueue).get();
      expect(queue.first.entity, 'lahan');
      expect(queue.first.operation, 'delete');
    });
  });
}
```

- [ ] **Step 2: Run tests — expect failure**

```bash
cd frontend
flutter test test/repositories/lahan_repository_test.dart
```

Expected: fails with `Target of URI hasn't been created`.

- [ ] **Step 3: Create lahan_repository.dart**

```dart
// frontend/lib/repositories/lahan_repository.dart
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

  Future<List<LahanModel>> getAll() async {
    final rows = await (_db.select(_db.lahans)
        ..where((t) => t.isActive.equals(true))).get();
    _refreshFromServerBackground();
    return rows.map(_rowToModel).toList();
  }

  Future<LahanModel> create({
    required String namaLahan,
    required double luasHa,
    required int tahunTanam,
    int? jumlahPohon,
    String? lokasi,
  }) async {
    // Lahan create always requires network (usiaPohon computed server-side)
    final result = await _api.createLahan(
      namaLahan: namaLahan, luasHa: luasHa, tahunTanam: tahunTanam,
      jumlahPohon: jumlahPohon, lokasi: lokasi,
    );
    await upsertFromServer(result);
    return result;
  }

  Future<LahanModel> update(int lahanId, {
    required String namaLahan,
    required double luasHa,
    required int tahunTanam,
    int? jumlahPohon,
    String? lokasi,
  }) async {
    final result = await _api.updateLahan(lahanId,
      namaLahan: namaLahan, luasHa: luasHa, tahunTanam: tahunTanam,
      jumlahPohon: jumlahPohon, lokasi: lokasi,
    );
    await upsertFromServer(result);
    return result;
  }

  Future<void> delete(int lahanId) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.into(_db.syncQueue).insert(SyncQueueCompanion.insert(
      entity: 'lahan',
      operation: 'delete',
      payload: jsonEncode({'id': lahanId}),
      lahanId: lahanId,
      localId: lahanId,
      createdAt: now,
    ));
    await (_db.delete(_db.lahans)..where((t) => t.id.equals(lahanId))).go();
  }

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
        final list = await _api.getMyLahan();
        for (final m in list) {
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
```

- [ ] **Step 4: Run tests — expect pass**

```bash
cd frontend
flutter test test/repositories/lahan_repository_test.dart
```

Expected: `All tests passed!`

- [ ] **Step 5: Commit**

```bash
git add frontend/lib/repositories/lahan_repository.dart frontend/test/repositories/lahan_repository_test.dart
git commit -m "feat(offline): LahanRepository — cache + sync for lahan CRUD"
```

---

## Task 8: SyncService

**Files:**
- Create: `frontend/lib/services/sync_service.dart`
- Create: `frontend/test/services/sync_service_test.dart`

- [ ] **Step 1: Write failing tests**

Create `frontend/test/services/sync_service_test.dart`:

```dart
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sawitku/database/app_database.dart';
import 'package:sawitku/models/panen_model.dart';
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

    Future<void> _enqueueCreatePanen(int localId) async {
      await db.into(db.syncQueue).insert(SyncQueueCompanion.insert(
        entity: 'panen',
        operation: 'create',
        payload: jsonEncode({
          'bulan': 'Januari', 'tahun': 2026, 'bulanAngka': 1,
          'tanggal': 10, 'tonAktual': 12.0,
        }),
        lahanId: 1,
        localId: localId,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ));
      await db.into(db.panens).insert(PanensCompanion.insert(
        id: Value(localId), lahanId: Value(1), bulan: 'Januari',
        tahun: 2026, bulanAngka: 1,
        tonAktual: 12.0, cachedAt: DateTime.now().millisecondsSinceEpoch,
      ));
    }

    test('flush removes item from queue on success', () async {
      await _enqueueCreatePanen(-111);

      await service.flush();

      final queue = await db.select(db.syncQueue).get();
      expect(queue, isEmpty);
    });

    test('flush replaces temp id with server id in panens table', () async {
      await _enqueueCreatePanen(-222);

      await service.flush();

      final rows = await db.select(db.panens).get();
      expect(rows.length, 1);
      expect(rows.first.id, 999); // server id from _FakeApi
    });

    test('flush increments retry_count on network error', () async {
      api.throwNetworkError = true;
      await _enqueueCreatePanen(-333);

      await service.flush();

      final queue = await db.select(db.syncQueue).get();
      expect(queue.length, 1);
      expect(queue.first.retryCount, 1);
    });

    test('flush removes item on 4xx client error', () async {
      api.throwClientError = true;
      await _enqueueCreatePanen(-444);

      await service.flush();

      final queue = await db.select(db.syncQueue).get();
      expect(queue, isEmpty);
    });

    test('flush abandons item after 3 retries', () async {
      api.throwNetworkError = true;
      await db.into(db.syncQueue).insert(SyncQueueCompanion.insert(
        entity: 'panen', operation: 'create',
        payload: jsonEncode({'bulan': 'Maret', 'tahun': 2026, 'bulanAngka': 3,
          'tanggal': 1, 'tonAktual': 5.0}),
        lahanId: 1, localId: -555,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        retryCount: Value(3),
      ));

      await service.flush();

      final queue = await db.select(db.syncQueue).get();
      expect(queue, isEmpty);
    });
  });
}
```

- [ ] **Step 2: Run tests — expect failure**

```bash
cd frontend
flutter test test/services/sync_service_test.dart
```

Expected: fails with `Target of URI hasn't been created`.

- [ ] **Step 3: Create sync_service.dart**

```dart
// frontend/lib/services/sync_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter/widgets.dart';
import '../database/app_database.dart';
import '../services/api_service.dart';

class SyncService with WidgetsBindingObserver {
  final AppDatabase _db;
  final ApiService _api;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _isFlushing = false;

  SyncService({required AppDatabase db, required ApiService api})
      : _db = db, _api = api;

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

  Stream<int> get pendingCountStream =>
      (_db.select(_db.syncQueue)).watch().map((rows) => rows.length);

  Future<void> flush() async {
    if (_isFlushing) return;
    _isFlushing = true;
    try {
      final items = await (
        _db.select(_db.syncQueue)
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)])
      ).get();

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
      await (_db.delete(_db.syncQueue)..where((t) => t.id.equals(item.id))).go();
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final is4xx = status != null && status >= 400 && status < 500;
      if (is4xx || item.retryCount >= 3) {
        await (_db.delete(_db.syncQueue)..where((t) => t.id.equals(item.id))).go();
      } else {
        await (_db.update(_db.syncQueue)..where((t) => t.id.equals(item.id))).write(
          SyncQueueCompanion(retryCount: Value(item.retryCount + 1)),
        );
      }
    } catch (_) {
      // Non-Dio error — increment retry
      if (item.retryCount >= 3) {
        await (_db.delete(_db.syncQueue)..where((t) => t.id.equals(item.id))).go();
      } else {
        await (_db.update(_db.syncQueue)..where((t) => t.id.equals(item.id))).write(
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
          bulan: p['bulan'], tahun: p['tahun'], bulanAngka: p['bulanAngka'],
          tanggal: p['tanggal'], tonAktual: (p['tonAktual'] as num).toDouble(),
          hargaPerTon: (p['hargaPerTon'] as num?)?.toDouble() ?? 2400000,
          catatan: p['catatan'],
        );
        await (_db.delete(_db.panens)..where((t) => t.id.equals(item.localId))).go();
        await _db.into(_db.panens).insert(_panenToCompanion(result, item.lahanId));
        break;

      case 'panen_update':
        final result = await _api.updatePanen(
          item.lahanId, item.localId,
          bulan: p['bulan'], tahun: p['tahun'], bulanAngka: p['bulanAngka'],
          tanggal: p['tanggal'], tonAktual: (p['tonAktual'] as num).toDouble(),
          hargaPerTon: (p['hargaPerTon'] as num?)?.toDouble() ?? 2400000,
        );
        await (_db.update(_db.panens)..where((t) => t.id.equals(item.localId))).write(
          _panenToCompanion(result, item.lahanId),
        );
        break;

      case 'panen_delete':
        await _api.deletePanen(item.lahanId, item.localId);
        break;

      case 'biaya_create':
        final result = await _api.createBiaya(
          item.lahanId,
          bulan: p['bulan'], tahun: p['tahun'], bulanAngka: p['bulanAngka'],
          kategoriCode: p['kategori'], jumlah: (p['jumlah'] as num).toDouble(),
          keterangan: p['keterangan'],
        );
        await (_db.delete(_db.biayas)..where((t) => t.id.equals(item.localId))).go();
        await _db.into(_db.biayas).insert(_biayaToCompanion(result));
        break;

      case 'biaya_update':
        final result = await _api.updateBiaya(
          item.lahanId, item.localId,
          bulan: p['bulan'], tahun: p['tahun'], bulanAngka: p['bulanAngka'],
          kategoriCode: p['kategori'], jumlah: (p['jumlah'] as num).toDouble(),
          keterangan: p['keterangan'],
        );
        await (_db.update(_db.biayas)..where((t) => t.id.equals(item.localId))).write(
          _biayaToCompanion(result),
        );
        break;

      case 'biaya_delete':
        await _api.deleteBiaya(item.lahanId, item.localId);
        break;

      case 'lahan_delete':
        await _api.deleteLahan(item.localId);
        break;
    }
  }

  PanensCompanion _panenToCompanion(dynamic m, int lahanId) => PanensCompanion(
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

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySub?.cancel();
  }
}
```

- [ ] **Step 4: Run tests — expect pass**

```bash
cd frontend
flutter test test/services/sync_service_test.dart
```

Expected: `All tests passed!`

- [ ] **Step 5: Commit**

```bash
git add frontend/lib/services/sync_service.dart frontend/test/services/sync_service_test.dart
git commit -m "feat(offline): SyncService — flush queue on connectivity restore and app resume"
```

---

## Task 9: OfflineBanner Widget

**Files:**
- Create: `frontend/lib/widgets/offline_banner.dart`

- [ ] **Step 1: Create offline_banner.dart**

```dart
// frontend/lib/widgets/offline_banner.dart
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import '../main.dart';

class OfflineBanner extends StatefulWidget {
  const OfflineBanner({super.key});

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner> {
  bool _isOffline = false;
  StreamSubscription<List<ConnectivityResult>>? _sub;

  @override
  void initState() {
    super.initState();
    _checkNow();
    _sub = Connectivity().onConnectivityChanged.listen((results) {
      final offline = results.every((r) => r == ConnectivityResult.none);
      if (mounted) setState(() => _isOffline = offline);
      if (!offline) syncService.flush();
    });
  }

  Future<void> _checkNow() async {
    final results = await Connectivity().checkConnectivity();
    final offline = results.every((r) => r == ConnectivityResult.none);
    if (mounted) setState(() => _isOffline = offline);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      child: _isOffline
          ? Container(
              width: double.infinity,
              color: const Color(0xFFFBBF24),
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wifi_off_rounded, size: 13, color: Colors.black87),
                  SizedBox(width: 6),
                  Text(
                    'Mode Offline — data tersimpan lokal',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add frontend/lib/widgets/offline_banner.dart
git commit -m "feat(offline): OfflineBanner widget — amber strip shown when no connectivity"
```

---

## Task 10: Update main_screen.dart

**Files:**
- Modify: `frontend/lib/screens/main_screen.dart`

Two changes: (1) add OfflineBanner above the IndexedStack, (2) replace direct `ApiService().getRiwayat()` call in `_loadLastAnalisa` with `PanenRepository`.

- [ ] **Step 1: Add imports at top of main_screen.dart**

After the existing imports, add:

```dart
import '../repositories/panen_repository.dart';
import '../widgets/offline_banner.dart';
import '../main.dart' show appDb;
```

- [ ] **Step 2: Replace _loadLastAnalisa method**

Find the existing `_loadLastAnalisa` method (around line 36–49) and replace it:

```dart
Future<void> _loadLastAnalisa() async {
  try {
    final repo = PanenRepository(db: appDb, api: ApiService());
    final list = await repo.getByLahan(widget.lahan.id, limit: 1);
    if (list.isNotEmpty && mounted) {
      final last = list.first;
      final penyebab = last.analisa?.penyebab.isNotEmpty == true
          ? last.analisa!.penyebab
          : AnalisaService.getPenyebab(last.persenKurang);
      setState(() {
        _lastAnalisa = HasilAnalisa(panen: last, penyebab: penyebab);
      });
    }
  } catch (_) {}
}
```

- [ ] **Step 3: Wrap body with OfflineBanner**

Find this line in the `build` method (around line 145):

```dart
body: IndexedStack(index: _currentIndex, children: screens),
```

Replace with:

```dart
body: Column(
  children: [
    const OfflineBanner(),
    Expanded(child: IndexedStack(index: _currentIndex, children: screens)),
  ],
),
```

- [ ] **Step 4: Verify no analysis errors**

```bash
cd frontend
flutter analyze lib/screens/main_screen.dart
```

Expected: `No issues found!`

- [ ] **Step 5: Commit**

```bash
git add frontend/lib/screens/main_screen.dart
git commit -m "feat(offline): main_screen — OfflineBanner + PanenRepository for last analisa"
```

---

## Task 11: Update beranda_screen.dart

**Files:**
- Modify: `frontend/lib/screens/beranda_screen.dart`

Replace `ApiService().getRiwayat()` with `PanenRepository.getByLahan()`.

- [ ] **Step 1: Add imports at top of beranda_screen.dart**

After existing imports, add:

```dart
import '../repositories/panen_repository.dart';
import '../main.dart' show appDb;
```

- [ ] **Step 2: Replace _loadData method**

Find the existing `_loadData` method (around line 66–80) and replace it:

```dart
Future<void> _loadData() async {
  setState(() => _loading = true);
  try {
    final repo = PanenRepository(db: appDb, api: ApiService());
    final list = await repo.getByLahan(widget.lahan.id, limit: 8);
    if (mounted) setState(() { _history = list; _loading = false; });
  } catch (e) {
    if (mounted) setState(() => _loading = false);
  }
}
```

- [ ] **Step 3: Verify no analysis errors**

```bash
cd frontend
flutter analyze lib/screens/beranda_screen.dart
```

Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add frontend/lib/screens/beranda_screen.dart
git commit -m "feat(offline): beranda_screen — use PanenRepository for offline-first history"
```

---

## Task 12: Update riwayat_screen.dart

**Files:**
- Modify: `frontend/lib/screens/riwayat_screen.dart`

Replace direct `ApiService()` calls with `PanenRepository`.

- [ ] **Step 1: Add imports at top of riwayat_screen.dart**

After existing imports, add:

```dart
import '../repositories/panen_repository.dart';
import '../main.dart' show appDb;
```

- [ ] **Step 2: Find and replace getRiwayat call**

Search for `ApiService().getRiwayat(` in `riwayat_screen.dart`. Replace the entire `_loadData`-style call with:

```dart
final repo = PanenRepository(db: appDb, api: ApiService());
final list = await repo.getByLahan(widget.lahan.id, limit: 50);
```

- [ ] **Step 3: Find and replace deletePanen call**

Search for `ApiService().deletePanen(` in `riwayat_screen.dart`. Replace with:

```dart
final repo = PanenRepository(db: appDb, api: ApiService());
await repo.delete(lahanId: widget.lahan.id, panenId: panenId);
```

- [ ] **Step 4: Find and replace updatePanen call**

Search for `ApiService().updatePanen(` in `riwayat_screen.dart`. Replace with:

```dart
final repo = PanenRepository(db: appDb, api: ApiService());
await repo.update(
  lahanId: widget.lahan.id,
  panenId: panenId,
  luasHa: widget.lahan.luasHa,
  usiaPohon: widget.lahan.usiaPohon,
  bulan: bulan, tahun: tahun, bulanAngka: bulanAngka,
  tanggal: tanggal, tonAktual: tonAktual, hargaPerTon: hargaPerTon,
);
```

- [ ] **Step 5: Verify no analysis errors**

```bash
cd frontend
flutter analyze lib/screens/riwayat_screen.dart
```

Expected: `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add frontend/lib/screens/riwayat_screen.dart
git commit -m "feat(offline): riwayat_screen — use PanenRepository for offline-first"
```

---

## Task 13: Update input_panen_screen.dart

**Files:**
- Modify: `frontend/lib/screens/input_panen_screen.dart`

Replace `ApiService().inputPanen()` with `PanenRepository.create()`.

- [ ] **Step 1: Add imports**

After existing imports in `input_panen_screen.dart`, add:

```dart
import '../repositories/panen_repository.dart';
import '../main.dart' show appDb;
```

- [ ] **Step 2: Find and replace the inputPanen call**

Search for `ApiService().inputPanen(` in `input_panen_screen.dart`. The surrounding code looks like:

```dart
final panen = await ApiService().inputPanen(
  widget.lahan.id,
  bulan: _bulanNames[_selectedDate.month - 1],
  tahun: _selectedDate.year,
  bulanAngka: _selectedDate.month,
  tanggal: _selectedDate.day,
  tonAktual: tonAktual,
  hargaPerTon: hargaPerTon,
);
```

Replace with:

```dart
final repo = PanenRepository(db: appDb, api: ApiService());
final panen = await repo.create(
  lahanId: widget.lahan.id,
  luasHa: widget.lahan.luasHa,
  usiaPohon: widget.lahan.usiaPohon,
  bulan: _bulanNames[_selectedDate.month - 1],
  tahun: _selectedDate.year,
  bulanAngka: _selectedDate.month,
  tanggal: _selectedDate.day,
  tonAktual: tonAktual,
  hargaPerTon: hargaPerTon,
);
```

- [ ] **Step 3: Verify no analysis errors**

```bash
cd frontend
flutter analyze lib/screens/input_panen_screen.dart
```

Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add frontend/lib/screens/input_panen_screen.dart
git commit -m "feat(offline): input_panen_screen — use PanenRepository (offline create)"
```

---

## Task 14: Update biaya_screen.dart

**Files:**
- Modify: `frontend/lib/screens/biaya_screen.dart`

Replace all `ApiService()` biaya calls with `BiayaRepository`.

- [ ] **Step 1: Add imports**

After existing imports in `biaya_screen.dart`, add:

```dart
import '../repositories/biaya_repository.dart';
import '../main.dart' show appDb;
```

- [ ] **Step 2: Replace getBiaya call**

Find `ApiService().getBiaya(` and replace surrounding load call with:

```dart
final repo = BiayaRepository(db: appDb, api: ApiService());
final list = await repo.getByLahan(widget.lahan.id, tahun: selectedTahun);
```

- [ ] **Step 3: Replace createBiaya call**

Find `ApiService().createBiaya(` and replace with:

```dart
final repo = BiayaRepository(db: appDb, api: ApiService());
await repo.create(
  lahanId: widget.lahan.id,
  bulan: bulan, tahun: tahun, bulanAngka: bulanAngka,
  kategoriCode: kategoriCode, jumlah: jumlah, keterangan: keterangan,
);
```

- [ ] **Step 4: Replace updateBiaya call**

Find `ApiService().updateBiaya(` and replace with:

```dart
final repo = BiayaRepository(db: appDb, api: ApiService());
await repo.update(
  lahanId: widget.lahan.id, biayaId: biayaId,
  bulan: bulan, tahun: tahun, bulanAngka: bulanAngka,
  kategoriCode: kategoriCode, jumlah: jumlah, keterangan: keterangan,
);
```

- [ ] **Step 5: Replace deleteBiaya call**

Find `ApiService().deleteBiaya(` and replace with:

```dart
final repo = BiayaRepository(db: appDb, api: ApiService());
await repo.delete(lahanId: widget.lahan.id, biayaId: biayaId);
```

- [ ] **Step 6: Verify no analysis errors**

```bash
cd frontend
flutter analyze lib/screens/biaya_screen.dart
```

Expected: `No issues found!`

- [ ] **Step 7: Commit**

```bash
git add frontend/lib/screens/biaya_screen.dart
git commit -m "feat(offline): biaya_screen — use BiayaRepository for offline-first CRUD"
```

---

## Task 15: Update lahan_screen.dart

**Files:**
- Modify: `frontend/lib/screens/lahan_screen.dart`

Replace `ApiService()` lahan calls with `LahanRepository`.

- [ ] **Step 1: Add imports**

After existing imports in `lahan_screen.dart`, add:

```dart
import '../repositories/lahan_repository.dart';
import '../main.dart' show appDb;
```

- [ ] **Step 2: Replace getMyLahan call**

Find `ApiService().getMyLahan(` and replace surrounding load with:

```dart
final repo = LahanRepository(db: appDb, api: ApiService());
final list = await repo.getAll();
```

- [ ] **Step 3: Replace createLahan call**

Find `ApiService().createLahan(` and replace with:

```dart
final repo = LahanRepository(db: appDb, api: ApiService());
final lahan = await repo.create(
  namaLahan: namaLahan, luasHa: luasHa, tahunTanam: tahunTanam,
  jumlahPohon: jumlahPohon, lokasi: lokasi,
);
```

- [ ] **Step 4: Replace updateLahan call**

Find `ApiService().updateLahan(` and replace with:

```dart
final repo = LahanRepository(db: appDb, api: ApiService());
final lahan = await repo.update(lahanId,
  namaLahan: namaLahan, luasHa: luasHa, tahunTanam: tahunTanam,
  jumlahPohon: jumlahPohon, lokasi: lokasi,
);
```

- [ ] **Step 5: Replace deleteLahan call**

Find `ApiService().deleteLahan(` and replace with:

```dart
final repo = LahanRepository(db: appDb, api: ApiService());
await repo.delete(lahanId);
```

- [ ] **Step 6: Verify full project — no analysis errors**

```bash
cd frontend
flutter analyze lib/
```

Expected: `No issues found!`

- [ ] **Step 7: Final integration test — build debug APK**

```bash
cd frontend
flutter build apk --debug 2>&1 | tail -5
```

Expected: `Built build/app/outputs/flutter-apk/app-debug.apk`

- [ ] **Step 8: Commit**

```bash
git add frontend/lib/screens/lahan_screen.dart
git commit -m "feat(offline): lahan_screen — use LahanRepository for offline-first CRUD"
```

---

## Verification Checklist

After all 15 tasks:

- [ ] `flutter analyze lib/` returns no issues
- [ ] `flutter test` passes all repository and sync service tests
- [ ] App launches on emulator — no crash
- [ ] With airplane mode ON: open app, lahan list shows cached data (no error screen)
- [ ] With airplane mode ON: input panen → snackbar success, row appears in riwayat
- [ ] With airplane mode ON: input biaya → snackbar success, row appears in biaya screen
- [ ] Turn airplane mode OFF → OfflineBanner disappears, data syncs silently
- [ ] After sync: negative temp IDs replaced with real server IDs

---

## Implementation Notes (Self-Review Fixes)

### Drift Companion Constructor Syntax

Drift generates two companion constructors. Use them correctly:

**`XCompanion.insert()`** — for `INSERT` statements. Required columns (no nullable, no default) take **raw values**. Optional columns take `Value<T>`:

```dart
// CORRECT
PanensCompanion.insert(
  id: tempId,           // raw int — required
  lahanId: lahanId,     // raw int — required
  bulan: bulan,         // raw String — required
  tahun: tahun,         // raw int — required
  bulanAngka: bulanAngka,
  tonAktual: tonAktual,
  cachedAt: now,
  tanggal: Value(tanggal),       // nullable — use Value<T>
  hargaPerTon: Value(hargaPerTon), // has default — use Value<T>
)

// WRONG — do not use Value() for required fields in .insert()
PanensCompanion.insert(id: Value(tempId), ...)
```

**`XCompanion()`** — for `UPDATE` / `insertOnConflictUpdate`. All fields use `Value<T>`:

```dart
// CORRECT for update/upsert
PanensCompanion(
  id: Value(m.id!),
  lahanId: Value(lahanId),
  tonAktual: Value(m.tonAktual),
  ...
)
```

Apply this rule to all `PanensCompanion`, `BiayasCompanion`, `LahansCompanion`, and `SyncQueueCompanion` usages throughout the tasks above.

### Missing Imports in Test Files

Each test file must explicitly import the models it constructs. Add these where missing:

- `panen_repository_test.dart` → already imports `api_service.dart` which re-exports models ✅
- `biaya_repository_test.dart` → add `import 'package:sawitku/models/biaya_model.dart';`
- `lahan_repository_test.dart` → add `import 'package:sawitku/models/lahan_model.dart';`
- `sync_service_test.dart` → add `import 'package:sawitku/models/panen_model.dart';` (already present ✅)

### LahanRepository — create/update are Network-Required

`LahanRepository.create()` and `.update()` call the server directly (no offline queue). This is intentional: lahan creation requires server to compute `usiaPohon`, and the returned ID is needed immediately to proceed in the app. Lahan CRUD offline queueing is out of scope.
