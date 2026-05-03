class LahanPhotoModel {
  final int id;
  final int lahanId;
  final String imageUrl;
  final String? caption;
  final DateTime takenAt;
  final String? bulan;
  final int? tahun;
  final int? bulanAngka;

  LahanPhotoModel({
    required this.id,
    required this.lahanId,
    required this.imageUrl,
    this.caption,
    required this.takenAt,
    this.bulan,
    this.tahun,
    this.bulanAngka,
  });

  factory LahanPhotoModel.fromJson(Map<String, dynamic> json) => LahanPhotoModel(
        id: json['id'],
        lahanId: json['lahanId'],
        imageUrl: json['imageUrl'],
        caption: json['caption'],
        takenAt: DateTime.parse(json['takenAt']),
        bulan: json['bulan'],
        tahun: json['tahun'],
        bulanAngka: json['bulanAngka'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'lahanId': lahanId,
        'imageUrl': imageUrl,
        'caption': caption,
        'takenAt': takenAt.toIso8601String(),
        'bulan': bulan,
        'tahun': tahun,
        'bulanAngka': bulanAngka,
      };
}
