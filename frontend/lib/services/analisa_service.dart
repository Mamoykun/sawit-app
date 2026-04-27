import '../models/panen_model.dart';

class AnalisaService {
  /// Hitung target panen berdasarkan luas & usia pohon
  static ({double min, double max, double mid, String fase}) getTarget(
      double ha, int usia) {
    double minPerHa, maxPerHa;
    String fase;

    if (usia < 3) {
      minPerHa = 0.3; maxPerHa = 0.8; fase = 'Belum Produksi';
    } else if (usia <= 5) {
      minPerHa = 0.8; maxPerHa = 1.4; fase = 'Produksi Awal';
    } else if (usia <= 10) {
      minPerHa = 1.5; maxPerHa = 2.0; fase = 'Puncak Awal';
    } else if (usia <= 15) {
      minPerHa = 1.8; maxPerHa = 2.3; fase = 'Puncak Produktif';
    } else if (usia <= 20) {
      minPerHa = 1.5; maxPerHa = 1.9; fase = 'Produksi Stabil';
    } else {
      minPerHa = 1.0; maxPerHa = 1.5; fase = 'Produksi Menurun';
    }

    final min = minPerHa * ha;
    final max = maxPerHa * ha;
    final mid = (min + max) / 2;
    return (min: min, max: max, mid: mid, fase: fase);
  }

  /// Analisa penyebab berdasarkan % kekurangan
  static List<AnalisaPenyebab> getPenyebab(double persenKurang) {
    final list = <AnalisaPenyebab>[];

    if (persenKurang > 8) {
      list.add(AnalisaPenyebab(
        icon: '🌿',
        title: 'Defisiensi Kalium (K)',
        detail: 'Aplikasikan pupuk MOP 0.5–1 kg per pohon. '
            'Kalium meningkatkan bobot tandan dan kualitas minyak sawit.',
        severity: 'high',
      ));
    }
    if (persenKurang > 15) {
      list.add(AnalisaPenyebab(
        icon: '💧',
        title: 'Stres Kekeringan',
        detail: 'Pasang mulsa pelepah di piringan pohon radius 2 meter '
            'untuk menjaga kelembaban tanah di musim kering.',
        severity: 'high',
      ));
    }
    if (persenKurang > 20) {
      list.add(AnalisaPenyebab(
        icon: '🐛',
        title: 'Serangan Hama / Penyakit',
        detail: 'Periksa tanda ulat api, kumbang badak, atau gejala '
            'Ganoderma di pangkal batang pohon.',
        severity: 'medium',
      ));
    }
    if (persenKurang > 28) {
      list.add(AnalisaPenyebab(
        icon: '🌾',
        title: 'Kompetisi Gulma',
        detail: 'Lakukan penyiangan di piringan pohon. '
            'Gulma bersaing langsung menyerap nutrisi dan air dari tanah.',
        severity: 'medium',
      ));
    }
    if (persenKurang > 35) {
      list.add(AnalisaPenyebab(
        icon: '✂️',
        title: 'Pruning Tidak Optimal',
        detail: 'Pertahankan 40–48 pelepah aktif. Terlalu lebat menghambat '
            'penyerbukan dan perkembangan tandan buah segar.',
        severity: 'low',
      ));
    }

    if (list.isEmpty && persenKurang > 0) {
      list.add(AnalisaPenyebab(
        icon: '🌡️',
        title: 'Faktor Musiman Normal',
        detail: 'Fluktuasi 1–8% masih dalam batas wajar akibat '
            'perubahan cuaca dan siklus alami tanaman sawit.',
        severity: 'low',
      ));
    }

    return list;
  }

  /// Build PanenModel lengkap dari input user
  static PanenModel buildPanen({
    required double ha,
    required int usia,
    required double ton,
    required String bulan,
  }) {
    final target = getTarget(ha, usia);
    return PanenModel(
      luasHa: ha,
      usiaTahun: usia,
      tonAktual: ton,
      targetMin: target.min,
      targetMax: target.max,
      targetMid: target.mid,
      bulan: bulan,
      tanggalInput: DateTime.now(),
    );
  }
}
