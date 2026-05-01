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
