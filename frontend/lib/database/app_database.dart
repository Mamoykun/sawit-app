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
      : super(executor ?? driftDatabase(
          name: 'sawitku_offline',
          web: DriftWebOptions(
            sqlite3Wasm: Uri.parse('sqlite3.wasm'),
            driftWorker: Uri.parse('drift_worker.js'),
          ),
        ));

  @override
  int get schemaVersion => 1;

  /// Wipes all local data — used on logout to prevent the next user from
  /// seeing the previous user's cached lahan/panen/biaya.
  Future<void> clearAllData() async {
    await batch((b) {
      b.deleteAll(syncQueue);
      b.deleteAll(panens);
      b.deleteAll(biayas);
      b.deleteAll(lahans);
    });
  }
}
