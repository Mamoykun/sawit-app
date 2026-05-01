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
