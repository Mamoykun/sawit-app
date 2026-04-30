class LahanModel {
  final int id;
  final String namaLahan;
  final double luasHa;
  final int usiaPohon;
  final int? tahunTanam;
  final int? jumlahPohon;
  final String? lokasi;
  final bool isActive;
  final PanenSummary? panenTerakhir;
  final String? statusTerkini;
  final String? faseProduksi;

  LahanModel({
    required this.id,
    required this.namaLahan,
    required this.luasHa,
    required this.usiaPohon,
    this.tahunTanam,
    this.jumlahPohon,
    this.lokasi,
    required this.isActive,
    this.panenTerakhir,
    this.statusTerkini,
    this.faseProduksi,
  });

  factory LahanModel.fromJson(Map<String, dynamic> json) => LahanModel(
    id: json['id'],
    namaLahan: json['namaLahan'],
    luasHa: (json['luasHa'] as num).toDouble(),
    usiaPohon: json['usiaPohon'],
    tahunTanam: json['tahunTanam'],
    jumlahPohon: json['jumlahPohon'],
    lokasi: json['lokasi'],
    isActive: json['isActive'] ?? true,
    panenTerakhir: json['panenTerakhir'] != null
        ? PanenSummary.fromJson(json['panenTerakhir'])
        : null,
    statusTerkini: json['statusTerkini'],
    faseProduksi: json['faseProduksi'],
  );
}

class PanenSummary {
  final int id;
  final String bulan;
  final int tahun;
  final double tonAktual;
  final double targetMid;
  final String statusPanen;
  final double persenKurang;

  PanenSummary({
    required this.id,
    required this.bulan,
    required this.tahun,
    required this.tonAktual,
    required this.targetMid,
    required this.statusPanen,
    required this.persenKurang,
  });

  factory PanenSummary.fromJson(Map<String, dynamic> json) => PanenSummary(
    id: json['id'],
    bulan: json['bulan'],
    tahun: json['tahun'],
    tonAktual: (json['tonAktual'] as num).toDouble(),
    targetMid: (json['targetMid'] as num).toDouble(),
    statusPanen: json['statusPanen'],
    persenKurang: (json['persenKurang'] as num?)?.toDouble() ?? 0,
  );
}
