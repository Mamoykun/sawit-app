class PanenModel {
  final int? id;
  final double luasHa;
  final int usiaTahun;
  final double tonAktual;
  final double targetMin;
  final double targetMax;
  final double targetMid;
  final String bulan;
  final DateTime tanggalInput;

  PanenModel({
    this.id,
    required this.luasHa,
    required this.usiaTahun,
    required this.tonAktual,
    required this.targetMin,
    required this.targetMax,
    required this.targetMid,
    required this.bulan,
    required this.tanggalInput,
  });

  double get selisih => tonAktual - targetMid;
  double get persenKurang => targetMid > 0
      ? ((targetMid - tonAktual) / targetMid * 100).clamp(0, 100)
      : 0;
  String get status {
    if (tonAktual >= targetMin) return 'normal';
    if (persenKurang <= 20) return 'warn';
    return 'danger';
  }
  double get nilaiEstimasi => tonAktual * 2400000;

  factory PanenModel.fromJson(Map<String, dynamic> json) => PanenModel(
    id: json['id'],
    luasHa: (json['luas_ha'] as num).toDouble(),
    usiaTahun: json['usia_tahun'],
    tonAktual: (json['ton_aktual'] as num).toDouble(),
    targetMin: (json['target_min'] as num).toDouble(),
    targetMax: (json['target_max'] as num).toDouble(),
    targetMid: (json['target_mid'] as num).toDouble(),
    bulan: json['bulan'],
    tanggalInput: DateTime.parse(json['tanggal_input']),
  );

  Map<String, dynamic> toJson() => {
    'luas_ha': luasHa,
    'usia_tahun': usiaTahun,
    'ton_aktual': tonAktual,
    'target_min': targetMin,
    'target_max': targetMax,
    'target_mid': targetMid,
    'bulan': bulan,
    'tanggal_input': tanggalInput.toIso8601String(),
  };
}

class AnalisaPenyebab {
  final String icon;
  final String title;
  final String detail;
  final String severity; // 'high' | 'medium' | 'low'

  AnalisaPenyebab({
    required this.icon,
    required this.title,
    required this.detail,
    required this.severity,
  });

  factory AnalisaPenyebab.fromJson(Map<String, dynamic> json) => AnalisaPenyebab(
    icon: json['icon'],
    title: json['title'],
    detail: json['detail'],
    severity: json['severity'],
  );
}

class HasilAnalisa {
  final PanenModel panen;
  final List<AnalisaPenyebab> penyebab;

  HasilAnalisa({required this.panen, required this.penyebab});
}
