class PanenModel {
  final int? id;
  final int? lahanId;
  final String? namaLahan;
  final double luasHa;
  final int usiaTahun;
  final double tonAktual;
  final double targetMin;
  final double targetMax;
  final double targetMid;
  final String bulan;
  final int? tahun;
  final int? bulanAngka;
  final int? tanggal;
  final String? statusPanen;
  final double persenKurang;
  final double hargaPerTon;
  final AnalisaResult? analisa;

  PanenModel({
    this.id,
    this.lahanId,
    this.namaLahan,
    required this.luasHa,
    required this.usiaTahun,
    required this.tonAktual,
    required this.targetMin,
    required this.targetMax,
    required this.targetMid,
    required this.bulan,
    this.tahun,
    this.bulanAngka,
    this.tanggal,
    this.statusPanen,
    this.persenKurang = 0,
    this.hargaPerTon = 2400000,
    this.analisa,
  });

  double get selisih => tonAktual - targetMid;
  String get status {
    if (statusPanen != null) return statusPanen!.toLowerCase();
    if (tonAktual >= targetMin) return 'normal';
    if (persenKurang <= 20) return 'warn';
    return 'danger';
  }
  double get nilaiEstimasi => tonAktual * hargaPerTon;

  factory PanenModel.fromJson(Map<String, dynamic> json) {
    final luasHa = (json['luasHa'] as num?)?.toDouble() ?? 14.0;
    final usiaPohon = (json['usiaPohon'] as num?)?.toInt() ?? (json['usiaTahun'] as num?)?.toInt() ?? 8;
    return PanenModel(
      id: json['id'],
      lahanId: json['lahanId'],
      namaLahan: json['namaLahan'],
      luasHa: luasHa,
      usiaTahun: usiaPohon,
      tonAktual: (json['tonAktual'] as num).toDouble(),
      targetMin: (json['targetMin'] as num).toDouble(),
      targetMax: (json['targetMax'] as num).toDouble(),
      targetMid: (json['targetMid'] as num).toDouble(),
      bulan: json['bulan'],
      tahun: json['tahun'],
      bulanAngka: json['bulanAngka'],
      tanggal: json['tanggal'],
      statusPanen: json['statusPanen'],
      persenKurang: (json['persenKurang'] as num?)?.toDouble() ?? 0,
      hargaPerTon: (json['hargaPerTon'] as num?)?.toDouble() ?? 2400000,
      analisa: json['analisa'] != null
          ? AnalisaResult.fromJson(json['analisa'])
          : null,
    );
  }

  Map<String, dynamic> toCreateJson() => {
    'bulan': bulan,
    'tahun': tahun ?? DateTime.now().year,
    'bulanAngka': bulanAngka ?? DateTime.now().month,
    'tonAktual': tonAktual,
    'hargaPerTon': hargaPerTon,
  };
}

class AnalisaResult {
  final int? id;
  final String status;
  final List<AnalisaPenyebab> penyebab;
  final String? ringkasan;
  final String? prioritasTindakan;

  AnalisaResult({
    this.id,
    required this.status,
    required this.penyebab,
    this.ringkasan,
    this.prioritasTindakan,
  });

  factory AnalisaResult.fromJson(Map<String, dynamic> json) => AnalisaResult(
    id: json['id'],
    status: json['status'] ?? 'DONE',
    penyebab: (json['penyebab'] as List?)
            ?.map((p) => AnalisaPenyebab.fromJson(p))
            .toList() ??
        [],
    ringkasan: json['ringkasan'],
    prioritasTindakan: json['prioritasTindakan'],
  );
}

class AnalisaPenyebab {
  final String icon; // legacy emoji string; resolved via iconData getter
  final String title;
  final String detail;
  final String severity;
  final String? estimasiDampak;

  AnalisaPenyebab({
    required this.icon,
    required this.title,
    required this.detail,
    required this.severity,
    this.estimasiDampak,
  });

  /// Map legacy emoji icons to Material icons (no emoji rendering).
  /// Falls back to category-derived icon based on title keywords.
  static const _emojiMap = {
    '🌿': 'eco',
    '💧': 'water',
    '🐛': 'bug',
    '🌡️': 'thermostat',
    '⚠️': 'warning',
    '🌱': 'eco',
    '🔥': 'local_fire',
    '☀️': 'wb_sunny',
  };

  String get iconKey {
    if (_emojiMap.containsKey(icon)) return _emojiMap[icon]!;
    final t = title.toLowerCase();
    if (t.contains('air') || t.contains('hujan') || t.contains('kering')) return 'water';
    if (t.contains('hama') || t.contains('penyakit') || t.contains('ulat')) return 'bug';
    if (t.contains('cuaca') || t.contains('musim')) return 'thermostat';
    if (t.contains('pupuk') || t.contains('nutrisi') || t.contains('defisien')) return 'eco';
    return 'warning';
  }

  factory AnalisaPenyebab.fromJson(Map<String, dynamic> json) => AnalisaPenyebab(
    icon: json['icon'] ?? '',
    title: json['title'] ?? '',
    detail: json['detail'] ?? '',
    severity: json['severity'] ?? 'medium',
    estimasiDampak: json['estimasiDampak'],
  );
}

class HasilAnalisa {
  final PanenModel panen;
  final List<AnalisaPenyebab> penyebab;

  HasilAnalisa({required this.panen, required this.penyebab});
}
