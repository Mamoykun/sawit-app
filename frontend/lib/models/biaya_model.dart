enum KategoriBiaya {
  pupuk('PUPUK', 'Pupuk'),
  tenagaKerja('TENAGA_KERJA', 'Tenaga Kerja'),
  pestisida('PESTISIDA', 'Pestisida'),
  peralatan('PERALATAN', 'Peralatan'),
  lainnya('LAINNYA', 'Lainnya');

  final String code;
  final String label;
  const KategoriBiaya(this.code, this.label);

  static KategoriBiaya fromCode(String code) {
    return KategoriBiaya.values.firstWhere(
      (k) => k.code == code,
      orElse: () => KategoriBiaya.lainnya,
    );
  }
}

class BiayaModel {
  final int id;
  final int lahanId;
  final String bulan;
  final int tahun;
  final int bulanAngka;
  final KategoriBiaya kategori;
  final double jumlah;
  final String? keterangan;
  final DateTime? createdAt;

  BiayaModel({
    required this.id,
    required this.lahanId,
    required this.bulan,
    required this.tahun,
    required this.bulanAngka,
    required this.kategori,
    required this.jumlah,
    this.keterangan,
    this.createdAt,
  });

  factory BiayaModel.fromJson(Map<String, dynamic> json) => BiayaModel(
        id: json['id'],
        lahanId: json['lahanId'],
        bulan: json['bulan'],
        tahun: json['tahun'],
        bulanAngka: json['bulanAngka'],
        kategori: KategoriBiaya.fromCode(json['kategori']),
        jumlah: (json['jumlah'] as num).toDouble(),
        keterangan: json['keterangan'],
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'])
            : null,
      );
}
