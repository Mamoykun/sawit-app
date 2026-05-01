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
