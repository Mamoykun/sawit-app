// frontend/lib/database/tables/jadwal_pupuk_table.dart
import 'package:drift/drift.dart';

class JadwalPupuks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get lahanId => integer()();

  /// Siklus dalam hari (default 90)
  IntColumn get siklusHari => integer().withDefault(const Constant(90))();

  /// Tanggal pemupukan terakhir (unix ms timestamp)
  IntColumn get lastPemupukanAt => integer().nullable()();

  /// Tanggal jadwal berikutnya (computed; unix ms timestamp)
  IntColumn get nextReminderAt => integer().nullable()();

  /// Local notification ID (untuk cancel/reschedule)
  IntColumn get notificationId => integer().nullable()();

  /// Active flag — user bisa pause reminder per lahan
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  /// Catatan/jenis pupuk
  TextColumn get jenisPupuk => text().nullable()();

  IntColumn get updatedAt => integer()();
}
