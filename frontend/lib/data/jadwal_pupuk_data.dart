/// Jadwal pemupukan standar PPKS berdasarkan usia pohon sawit.
///
/// 3 fase utama:
/// - TBM (< 3 tahun): 4x/tahun, fokus pertumbuhan vegetatif
/// - TM Muda (3-8 tahun): 4x/tahun, persiapan produksi & peningkatan
/// - TM Dewasa (> 8 tahun): 2x/tahun, mempertahankan produktivitas

class JadwalPupukItem {
  final String bulan;
  final int bulanAngka;
  final String pupukUtama;
  final String pupukTambahan;
  final String dosisPerHa;
  final String catatan;

  const JadwalPupukItem({
    required this.bulan,
    required this.bulanAngka,
    required this.pupukUtama,
    required this.pupukTambahan,
    required this.dosisPerHa,
    required this.catatan,
  });
}

class FasePupuk {
  final String fase;
  final String deskripsi;
  final List<JadwalPupukItem> jadwal;

  const FasePupuk({
    required this.fase,
    required this.deskripsi,
    required this.jadwal,
  });
}

class JadwalPupukData {
  static FasePupuk getByUsia(int usiaPohon) {
    if (usiaPohon < 3) return _tbm;
    if (usiaPohon <= 8) return _tmMuda;
    return _tmDewasa;
  }

  static const _tbm = FasePupuk(
    fase: 'TBM (Tanaman Belum Menghasilkan)',
    deskripsi:
        'Fase pertumbuhan vegetatif (0-3 tahun). Pemupukan 4x setahun untuk pertumbuhan akar, batang, dan daun.',
    jadwal: [
      JadwalPupukItem(
        bulan: 'Januari',
        bulanAngka: 1,
        pupukUtama: 'NPK 15-15-6-4',
        pupukTambahan: 'Urea',
        dosisPerHa: 'NPK 1.0 kg/pohon + Urea 0.3 kg/pohon',
        catatan: 'Awal musim hujan, serapan optimal. Aplikasi melingkar piringan radius 1 m.',
      ),
      JadwalPupukItem(
        bulan: 'April',
        bulanAngka: 4,
        pupukUtama: 'NPK 15-15-6-4',
        pupukTambahan: 'Dolomit',
        dosisPerHa: 'NPK 1.0 kg/pohon + Dolomit 0.5 kg/pohon',
        catatan: 'Dolomit untuk koreksi pH tanah dan tambahan Mg.',
      ),
      JadwalPupukItem(
        bulan: 'Juli',
        bulanAngka: 7,
        pupukUtama: 'NPK 15-15-6-4',
        pupukTambahan: 'Urea',
        dosisPerHa: 'NPK 1.0 kg/pohon + Urea 0.3 kg/pohon',
        catatan: 'Pertengahan musim, fokus pada perkembangan kanopi.',
      ),
      JadwalPupukItem(
        bulan: 'Oktober',
        bulanAngka: 10,
        pupukUtama: 'NPK 15-15-6-4',
        pupukTambahan: 'KCl',
        dosisPerHa: 'NPK 1.0 kg/pohon + KCl 0.4 kg/pohon',
        catatan: 'Persiapan musim kering, KCl meningkatkan ketahanan.',
      ),
    ],
  );

  static const _tmMuda = FasePupuk(
    fase: 'TM Muda (Tanaman Menghasilkan Muda)',
    deskripsi:
        'Fase produksi awal (3-8 tahun). Pemupukan 4x setahun untuk peningkatan produktivitas tandan.',
    jadwal: [
      JadwalPupukItem(
        bulan: 'Februari',
        bulanAngka: 2,
        pupukUtama: 'NPK 13-8-27-4',
        pupukTambahan: 'Urea + Boraks',
        dosisPerHa: 'NPK 2.0 kg/pohon + Urea 0.5 kg + Boraks 50 g',
        catatan: 'Awal tahun, aplikasi penuh untuk produksi maksimal.',
      ),
      JadwalPupukItem(
        bulan: 'Mei',
        bulanAngka: 5,
        pupukUtama: 'NPK 13-8-27-4',
        pupukTambahan: 'Dolomit',
        dosisPerHa: 'NPK 2.0 kg/pohon + Dolomit 1.0 kg/pohon',
        catatan: 'Dolomit menjaga pH dan suplai Mg untuk fotosintesis.',
      ),
      JadwalPupukItem(
        bulan: 'Agustus',
        bulanAngka: 8,
        pupukUtama: 'NPK 13-8-27-4',
        pupukTambahan: 'KCl',
        dosisPerHa: 'NPK 2.0 kg/pohon + KCl 1.0 kg/pohon',
        catatan: 'KCl tinggi untuk kualitas dan bobot TBS.',
      ),
      JadwalPupukItem(
        bulan: 'November',
        bulanAngka: 11,
        pupukUtama: 'NPK 13-8-27-4',
        pupukTambahan: 'Urea',
        dosisPerHa: 'NPK 2.0 kg/pohon + Urea 0.5 kg/pohon',
        catatan: 'Aplikasi terakhir tahun, persiapan produksi tahun depan.',
      ),
    ],
  );

  static const _tmDewasa = FasePupuk(
    fase: 'TM Dewasa (Tanaman Menghasilkan Dewasa)',
    deskripsi:
        'Fase produktivitas puncak (>8 tahun). Pemupukan 2x setahun dengan dosis lebih besar.',
    jadwal: [
      JadwalPupukItem(
        bulan: 'Maret',
        bulanAngka: 3,
        pupukUtama: 'NPK 12-12-17-2',
        pupukTambahan: 'Dolomit + Borax',
        dosisPerHa: 'NPK 3.0 kg/pohon + Dolomit 1.5 kg + Borax 100 g',
        catatan: 'Aplikasi besar awal tahun untuk produksi penuh.',
      ),
      JadwalPupukItem(
        bulan: 'September',
        bulanAngka: 9,
        pupukUtama: 'MOP (KCl)',
        pupukTambahan: 'NPK + Urea',
        dosisPerHa: 'MOP 2.5 kg/pohon + NPK 1.5 kg + Urea 0.5 kg',
        catatan: 'Fokus K dosis tinggi untuk bobot tandan optimal.',
      ),
    ],
  );
}
