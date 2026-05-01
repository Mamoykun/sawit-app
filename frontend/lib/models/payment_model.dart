enum PaymentStatus {
  pending('PENDING', 'Menunggu Pembayaran'),
  paid('PAID', 'Lunas'),
  failed('FAILED', 'Gagal'),
  expired('EXPIRED', 'Kadaluarsa'),
  cancelled('CANCELLED', 'Dibatalkan');

  final String code;
  final String label;
  const PaymentStatus(this.code, this.label);

  static PaymentStatus fromCode(String code) =>
      PaymentStatus.values.firstWhere((s) => s.code == code,
          orElse: () => PaymentStatus.pending);
}

class PaymentModel {
  final int id;
  final String orderId;
  final String targetPaket; // PETANI | PRO
  final int durationMonths;
  final double grossAmount;
  final PaymentStatus status;
  final String? paymentMethod;
  final String? snapToken;
  final String? snapUrl;
  final DateTime? paidAt;
  final DateTime? createdAt;

  PaymentModel({
    required this.id,
    required this.orderId,
    required this.targetPaket,
    required this.durationMonths,
    required this.grossAmount,
    required this.status,
    this.paymentMethod,
    this.snapToken,
    this.snapUrl,
    this.paidAt,
    this.createdAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) => PaymentModel(
        id: json['id'],
        orderId: json['orderId'],
        targetPaket: json['targetPaket'],
        durationMonths: json['durationMonths'],
        grossAmount: (json['grossAmount'] as num).toDouble(),
        status: PaymentStatus.fromCode(json['status']),
        paymentMethod: json['paymentMethod'],
        snapToken: json['snapToken'],
        snapUrl: json['snapUrl'],
        paidAt: json['paidAt'] != null ? DateTime.tryParse(json['paidAt']) : null,
        createdAt:
            json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      );
}

class PricingTier {
  final String code; // PETANI | PRO
  final String name;
  final int monthlyPriceIDR;
  final List<String> features;
  final bool highlight;

  const PricingTier({
    required this.code,
    required this.name,
    required this.monthlyPriceIDR,
    required this.features,
    this.highlight = false,
  });

  static const all = [
    PricingTier(
      code: 'GRATIS',
      name: 'Gratis',
      monthlyPriceIDR: 0,
      features: [
        '2 kebun maksimal',
        '5 analisa AI per bulan',
        '3 diagnosa visual per bulan',
        'Riwayat panen lengkap',
        'Jadwal pemupukan',
      ],
    ),
    PricingTier(
      code: 'PETANI',
      name: 'Petani',
      monthlyPriceIDR: 25000,
      highlight: true,
      features: [
        '10 kebun maksimal',
        '30 analisa AI per bulan',
        '20 diagnosa visual per bulan',
        'Export laporan PDF',
        'Perbandingan antar kebun',
        'Priority support',
      ],
    ),
    PricingTier(
      code: 'PRO',
      name: 'Pro',
      monthlyPriceIDR: 75000,
      features: [
        'Kebun unlimited',
        'Analisa AI unlimited',
        'Diagnosa visual unlimited',
        'Semua fitur PETANI',
        'Akses fitur baru lebih awal',
        'Dedicated support',
      ],
    ),
  ];
}
