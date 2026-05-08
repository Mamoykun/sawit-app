// frontend/lib/services/anomaly_detector.dart
import '../models/panen_model.dart';

enum AnomalyType { suddenDrop, suddenSpike }

class AnomalyResult {
  final AnomalyType type;
  final double currentValue;
  final double baselineAvg;
  final double dropPercent;
  final String message;

  const AnomalyResult({
    required this.type,
    required this.currentValue,
    required this.baselineAvg,
    required this.dropPercent,
    required this.message,
  });
}

class AnomalyDetector {
  /// Detects significant anomaly in panen pattern.
  /// Returns null if no anomaly, or [AnomalyResult] with details.
  /// Requires minimum 3 months of prior data as baseline.
  static AnomalyResult? detect(
      PanenModel current, List<PanenModel> history) {
    // Exclude the current record and any record from the same month/year.
    final excluding = history
        .where((p) =>
            p.id != current.id &&
            !(p.bulanAngka == current.bulanAngka &&
                p.tahun == current.tahun))
        .take(3)
        .toList();

    if (excluding.length < 3) return null;

    final avgPrev =
        excluding.fold<double>(0, (s, p) => s + p.tonAktual) /
            excluding.length;
    if (avgPrev <= 0) return null;

    final dropPct =
        ((avgPrev - current.tonAktual) / avgPrev) * 100;

    if (dropPct >= 30) {
      return AnomalyResult(
        type: AnomalyType.suddenDrop,
        currentValue: current.tonAktual,
        baselineAvg: avgPrev,
        dropPercent: dropPct,
        message:
            'Panen turun ${dropPct.toStringAsFixed(0)}% dari rata-rata '
            '3 bulan terakhir (${avgPrev.toStringAsFixed(1)} ton). '
            'Cek kondisi pohon, hama, atau curah hujan.',
      );
    }

    return null;
  }
}
