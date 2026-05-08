// frontend/lib/database/tables/pekerja_table.dart
import 'package:drift/drift.dart';

class Pekerjas extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get lahanId => integer()();
  TextColumn get nama => text().withLength(min: 1, max: 100)();
  TextColumn get peran => text().withLength(min: 1, max: 50)();
  TextColumn get kontak => text().nullable()();
  RealColumn get gajiHarian => real().withDefault(const Constant(150000))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  IntColumn get createdAt => integer()();
}

class HariKerjas extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get pekerjaId => integer().references(Pekerjas, #id)();
  IntColumn get lahanId => integer()();
  TextColumn get bulan => text()();
  IntColumn get tahun => integer()();
  IntColumn get bulanAngka => integer()();
  IntColumn get jumlahHari => integer()();
  RealColumn get totalGaji => real()();
  TextColumn get catatan => text().nullable()();
  IntColumn get createdAt => integer()();
}
