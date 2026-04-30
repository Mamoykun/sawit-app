enum JenisDiagnosa {
  buah('BUAH', 'Buah Sawit'),
  batang('BATANG', 'Batang'),
  pelepah('PELEPAH', 'Pelepah/Daun');

  final String code;
  final String label;
  const JenisDiagnosa(this.code, this.label);

  static JenisDiagnosa fromCode(String code) =>
      JenisDiagnosa.values.firstWhere((j) => j.code == code,
          orElse: () => JenisDiagnosa.buah);
}

enum SeverityDiagnosa {
  normal('NORMAL', 'Normal'),
  perhatian('PERHATIAN', 'Perlu Perhatian'),
  kritis('KRITIS', 'Kritis');

  final String code;
  final String label;
  const SeverityDiagnosa(this.code, this.label);

  static SeverityDiagnosa fromCode(String code) =>
      SeverityDiagnosa.values.firstWhere((s) => s.code == code,
          orElse: () => SeverityDiagnosa.normal);
}

class DiagnosaModel {
  final int id;
  final int lahanId;
  final JenisDiagnosa jenis;
  final String? kondisi;
  final String? penyebab;
  final String? rekomendasi;
  final SeverityDiagnosa severity;
  final bool isFallback;
  final String? imageBase64;
  final DateTime? createdAt;

  DiagnosaModel({
    required this.id,
    required this.lahanId,
    required this.jenis,
    this.kondisi,
    this.penyebab,
    this.rekomendasi,
    required this.severity,
    this.isFallback = false,
    this.imageBase64,
    this.createdAt,
  });

  factory DiagnosaModel.fromJson(Map<String, dynamic> json) => DiagnosaModel(
        id: json['id'],
        lahanId: json['lahanId'],
        jenis: JenisDiagnosa.fromCode(json['jenis']),
        kondisi: json['kondisi'],
        penyebab: json['penyebab'],
        rekomendasi: json['rekomendasi'],
        severity: SeverityDiagnosa.fromCode(json['severity']),
        isFallback: json['isFallback'] ?? false,
        imageBase64: json['imageBase64'],
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'])
            : null,
      );
}
