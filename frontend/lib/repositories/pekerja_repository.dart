// frontend/lib/repositories/pekerja_repository.dart
import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../models/biaya_model.dart';
import 'biaya_repository.dart';
import '../services/api_service.dart';

class PekerjaModel {
  final int id;
  final int lahanId;
  final String nama;
  final String peran;
  final String? kontak;
  final double gajiHarian;
  final bool isActive;

  const PekerjaModel({
    required this.id,
    required this.lahanId,
    required this.nama,
    required this.peran,
    this.kontak,
    required this.gajiHarian,
    required this.isActive,
  });
}

class HariKerjaModel {
  final int id;
  final int pekerjaId;
  final int lahanId;
  final String bulan;
  final int tahun;
  final int bulanAngka;
  final int jumlahHari;
  final double totalGaji;
  final String? catatan;
  final String? namaPekerja;

  const HariKerjaModel({
    required this.id,
    required this.pekerjaId,
    required this.lahanId,
    required this.bulan,
    required this.tahun,
    required this.bulanAngka,
    required this.jumlahHari,
    required this.totalGaji,
    this.catatan,
    this.namaPekerja,
  });
}

class PekerjaRepository {
  final AppDatabase _db;
  final BiayaRepository _biayaRepo;

  static const _bulanNames = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];

  PekerjaRepository({required AppDatabase db})
      : _db = db,
        _biayaRepo = BiayaRepository(db: db, api: ApiService());

  Future<List<PekerjaModel>> getByLahan(int lahanId) async {
    final rows = await (_db.select(_db.pekerjas)
          ..where((t) => t.lahanId.equals(lahanId) & t.isActive.equals(true))
          ..orderBy([(t) => OrderingTerm.asc(t.nama)]))
        .get();
    return rows.map(_rowToPekerjaModel).toList();
  }

  Future<PekerjaModel> create({
    required int lahanId,
    required String nama,
    required String peran,
    String? kontak,
    required double gajiHarian,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = await _db.into(_db.pekerjas).insert(PekerjasCompanion(
      lahanId: Value(lahanId),
      nama: Value(nama.trim()),
      peran: Value(peran.trim()),
      kontak: Value(kontak?.trim()),
      gajiHarian: Value(gajiHarian),
      isActive: const Value(true),
      createdAt: Value(now),
    ));
    return PekerjaModel(
      id: id,
      lahanId: lahanId,
      nama: nama.trim(),
      peran: peran.trim(),
      kontak: kontak?.trim(),
      gajiHarian: gajiHarian,
      isActive: true,
    );
  }

  Future<void> update({
    required int id,
    required String nama,
    required String peran,
    String? kontak,
    required double gajiHarian,
  }) async {
    await (_db.update(_db.pekerjas)..where((t) => t.id.equals(id))).write(
      PekerjasCompanion(
        nama: Value(nama.trim()),
        peran: Value(peran.trim()),
        kontak: Value(kontak?.trim()),
        gajiHarian: Value(gajiHarian),
      ),
    );
  }

  /// Soft-delete — preserves hari kerja references.
  Future<void> delete(int id) async {
    await (_db.update(_db.pekerjas)..where((t) => t.id.equals(id))).write(
      const PekerjasCompanion(isActive: Value(false)),
    );
  }

  Future<List<HariKerjaModel>> getHariKerja(
      int lahanId, int tahun, int bulanAngka) async {
    final hariKerjaRows = await (_db.select(_db.hariKerjas)
          ..where((t) =>
              t.lahanId.equals(lahanId) &
              t.tahun.equals(tahun) &
              t.bulanAngka.equals(bulanAngka)))
        .get();

    final pekerjaRows = await (_db.select(_db.pekerjas)
          ..where((t) => t.lahanId.equals(lahanId)))
        .get();

    final namaMap = {for (final p in pekerjaRows) p.id: p.nama};

    return hariKerjaRows
        .map((r) => HariKerjaModel(
              id: r.id,
              pekerjaId: r.pekerjaId,
              lahanId: r.lahanId,
              bulan: r.bulan,
              tahun: r.tahun,
              bulanAngka: r.bulanAngka,
              jumlahHari: r.jumlahHari,
              totalGaji: r.totalGaji,
              catatan: r.catatan,
              namaPekerja: namaMap[r.pekerjaId],
            ))
        .toList();
  }

  /// Records hari kerja and auto-creates a TENAGA_KERJA biaya entry.
  Future<HariKerjaModel> recordHariKerja({
    required int pekerjaId,
    required int lahanId,
    required int tahun,
    required int bulanAngka,
    required int jumlahHari,
    required double gajiHarian,
    String? catatan,
    required String namaPekerja,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final bulan = _bulanNames[bulanAngka - 1];
    final totalGaji = jumlahHari * gajiHarian;

    // Remove any existing entry for same pekerja/bulan/tahun before inserting.
    await (_db.delete(_db.hariKerjas)
          ..where((t) =>
              t.pekerjaId.equals(pekerjaId) &
              t.tahun.equals(tahun) &
              t.bulanAngka.equals(bulanAngka)))
        .go();

    final id = await _db.into(_db.hariKerjas).insert(HariKerjasCompanion(
      pekerjaId: Value(pekerjaId),
      lahanId: Value(lahanId),
      bulan: Value(bulan),
      tahun: Value(tahun),
      bulanAngka: Value(bulanAngka),
      jumlahHari: Value(jumlahHari),
      totalGaji: Value(totalGaji),
      catatan: Value(catatan),
      createdAt: Value(now),
    ));

    // Auto-create biaya TENAGA_KERJA via existing offline-first machinery.
    await _biayaRepo.create(
      lahanId: lahanId,
      bulan: bulan,
      tahun: tahun,
      bulanAngka: bulanAngka,
      kategoriCode: KategoriBiaya.tenagaKerja.code,
      jumlah: totalGaji,
      keterangan: '$namaPekerja — $jumlahHari hari kerja',
    );

    return HariKerjaModel(
      id: id,
      pekerjaId: pekerjaId,
      lahanId: lahanId,
      bulan: bulan,
      tahun: tahun,
      bulanAngka: bulanAngka,
      jumlahHari: jumlahHari,
      totalGaji: totalGaji,
      catatan: catatan,
      namaPekerja: namaPekerja,
    );
  }

  PekerjaModel _rowToPekerjaModel(Pekerja row) => PekerjaModel(
        id: row.id,
        lahanId: row.lahanId,
        nama: row.nama,
        peran: row.peran,
        kontak: row.kontak,
        gajiHarian: row.gajiHarian,
        isActive: row.isActive,
      );
}
