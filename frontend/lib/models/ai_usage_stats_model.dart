class AiUsageStatsModel {
  final int callCount;
  final int totalTokens;
  final int costCents;
  final int capCents;
  final int remainingCents;
  final int percentUsed;
  final String paket; // 'GRATIS' | 'PETANI' | 'PRO'

  AiUsageStatsModel({
    required this.callCount,
    required this.totalTokens,
    required this.costCents,
    required this.capCents,
    required this.remainingCents,
    required this.percentUsed,
    this.paket = 'GRATIS',
  });

  factory AiUsageStatsModel.fromJson(Map<String, dynamic> json) =>
      AiUsageStatsModel(
        callCount: (json['callCount'] as num?)?.toInt() ?? 0,
        totalTokens: (json['totalTokens'] as num?)?.toInt() ?? 0,
        costCents: (json['costCents'] as num?)?.toInt() ?? 0,
        capCents: (json['capCents'] as num?)?.toInt() ?? 0,
        remainingCents: (json['remainingCents'] as num?)?.toInt() ?? 0,
        percentUsed: (json['percentUsed'] as num?)?.toInt() ?? 0,
        paket: (json['paket'] as String?) ?? 'GRATIS',
      );

  bool get isExhausted => remainingCents <= 0 || percentUsed >= 100;
  bool get isWarning => percentUsed >= 75 && !isExhausted;

  /// Display cap count based on paket tier.
  int get capCount {
    switch (paket) {
      case 'PRO':
        return 0; // unlimited — check isPro
      case 'PETANI':
        return 30;
      default:
        return 3; // GRATIS
    }
  }

  bool get isPro => paket == 'PRO';
}
