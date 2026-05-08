// frontend/lib/database/tables/inventory_pupuk_table.dart
import 'package:drift/drift.dart';

class InventoryPupuks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get lahanId => integer()();
  TextColumn get namaPupuk => text()();
  RealColumn get stokKg => real().withDefault(const Constant(0))();
  RealColumn get thresholdAlert =>
      real().withDefault(const Constant(50))();
  IntColumn get expiredAt => integer().nullable()();
  TextColumn get catatan => text().nullable()();
  IntColumn get updatedAt => integer()();
}
