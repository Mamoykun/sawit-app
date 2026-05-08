// frontend/lib/repositories/jadwal_pupuk_repository.dart
import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../services/notification_service.dart';

class JadwalPupukRepository {
  final AppDatabase _db;

  JadwalPupukRepository({required AppDatabase db}) : _db = db;

  /// Get jadwal for a lahan (creates default if none exists).
  Future<JadwalPupuk> getOrCreate(int lahanId) async {
    final existing = await (_db.select(_db.jadwalPupuks)
          ..where((t) => t.lahanId.equals(lahanId)))
        .getSingleOrNull();
    if (existing != null) return existing;

    final id = await _db.into(_db.jadwalPupuks).insert(JadwalPupuksCompanion(
      lahanId: Value(lahanId),
      siklusHari: const Value(90),
      isActive: const Value(true),
      updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
    ));

    return (_db.select(_db.jadwalPupuks)..where((t) => t.id.equals(id)))
        .getSingle();
  }

  /// Update siklus hari (e.g. user changes from 90 to 60).
  Future<void> setSiklus(int lahanId, int siklusHari) async {
    final j = await getOrCreate(lahanId);
    await (_db.update(_db.jadwalPupuks)..where((t) => t.id.equals(j.id)))
        .write(JadwalPupuksCompanion(
      siklusHari: Value(siklusHari),
      updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
    ));
    await _rescheduleNotification(lahanId);
  }

  /// Toggle active — pause or resume reminder for this lahan.
  Future<void> setActive(int lahanId, {required bool active}) async {
    final j = await getOrCreate(lahanId);
    await (_db.update(_db.jadwalPupuks)..where((t) => t.id.equals(j.id)))
        .write(JadwalPupuksCompanion(
      isActive: Value(active),
      updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
    ));
    if (active) {
      await _rescheduleNotification(lahanId);
    } else {
      if (j.notificationId != null) {
        await NotificationService.cancel(j.notificationId!);
      }
    }
  }

  /// Mark a pemupukan event happened today.
  /// Called automatically by biaya save when kategori == PUPUK.
  Future<void> markPupukDone(int lahanId, {String? jenisPupuk}) async {
    final j = await getOrCreate(lahanId);
    final now = DateTime.now();
    final nextDate = now.add(Duration(days: j.siklusHari));

    await (_db.update(_db.jadwalPupuks)..where((t) => t.id.equals(j.id)))
        .write(JadwalPupuksCompanion(
      lastPemupukanAt: Value(now.millisecondsSinceEpoch),
      nextReminderAt: Value(nextDate.millisecondsSinceEpoch),
      jenisPupuk:
          jenisPupuk != null ? Value(jenisPupuk) : const Value.absent(),
      updatedAt: Value(now.millisecondsSinceEpoch),
    ));

    if (j.isActive) {
      await _rescheduleNotification(lahanId);
    }
  }

  /// Get jadwal data for display. Returns null if never set up.
  Future<JadwalPupuk?> get(int lahanId) async {
    return (_db.select(_db.jadwalPupuks)
          ..where((t) => t.lahanId.equals(lahanId)))
        .getSingleOrNull();
  }

  /// Reschedule notification based on current persisted state.
  Future<void> _rescheduleNotification(
    int lahanId, {
    String namaLahan = 'Kebun',
  }) async {
    final j = await getOrCreate(lahanId);
    if (!j.isActive) return;

    // Stable notification ID per lahan (avoids collision)
    final notifId = lahanId * 1000 + 1;

    if (j.nextReminderAt == null) {
      final when = DateTime.now().add(Duration(days: j.siklusHari));
      await NotificationService.scheduleAt(
        id: notifId,
        title: 'Saatnya Pemupukan',
        body:
            'Sudah ${j.siklusHari} hari sejak pemupukan terakhir di $namaLahan.',
        when: when,
      );
    } else {
      final when =
          DateTime.fromMillisecondsSinceEpoch(j.nextReminderAt!);
      await NotificationService.scheduleAt(
        id: notifId,
        title: 'Saatnya Pemupukan',
        body: 'Jadwal pemupukan tiba untuk $namaLahan.',
        when: when,
      );
    }

    // Persist notification id for future cancel
    await (_db.update(_db.jadwalPupuks)..where((t) => t.id.equals(j.id)))
        .write(JadwalPupuksCompanion(notificationId: Value(notifId)));
  }

  /// Reschedule with lahan name (called from screen after name is known).
  Future<void> rescheduleWithName(int lahanId, String namaLahan) async {
    await _rescheduleNotification(lahanId, namaLahan: namaLahan);
  }
}
