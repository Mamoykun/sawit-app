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
