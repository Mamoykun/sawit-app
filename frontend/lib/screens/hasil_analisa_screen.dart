import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/panen_model.dart';
import '../models/lahan_model.dart';
import '../models/ai_usage_stats_model.dart';
import '../widgets/common_widgets.dart';
import '../widgets/help_tooltip.dart';

class AnalisaDataInfo {
  final int panenCount;
  final bool hasPupukData;
  final bool hasLokasi;
  const AnalisaDataInfo({
    required this.panenCount,
    required this.hasPupukData,
    required this.hasLokasi,
  });
}

class HasilAnalisaScreen extends StatelessWidget {
  final HasilAnalisa? hasil;
  final LahanModel? lahan;
  final AnalisaDataInfo? dataInfo;
  final VoidCallback onGoToInput;
  final VoidCallback onGoToRiwayat;
  final VoidCallback? onRefresh;
  /// Optional AI usage stats — passed from main_screen to avoid double-fetch.
  final AiUsageStatsModel? aiStats;

  const HasilAnalisaScreen({
    super.key,
    required this.hasil,
    this.lahan,
    this.dataInfo,
    required this.onGoToInput,
    required this.onGoToRiwayat,
    this.onRefresh,
    this.aiStats,
  });

  @override
  Widget build(BuildContext context) {
    if (hasil == null) return _EmptyState(onGoToInput: onGoToInput);

    final p = hasil!.panen;
    final statusCfg = _statusConfig(p.status);

    final luasHa = lahan?.luasHa ?? p.luasHa;
    final usiaTahun = lahan?.usiaPohon ?? p.usiaTahun;
    final namaLahan = lahan?.namaLahan;

    // Determine if the latest result is local/rule-based for the banner.
    final isLocal = p.analisa != null && !p.analisa!.isAiGenerated;
    final showExhaustedBanner = aiStats != null &&
        aiStats!.isExhausted &&
        !aiStats!.isPro &&
        isLocal;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(
            title: 'Hasil Analisa',
            subtitle: '${namaLahan != null ? '$namaLahan · ' : ''}'
                '${luasHa.toStringAsFixed(1)} ha · '
                'Usia $usiaTahun tahun · ${p.bulan}',
          ),

          // ─── Data Info Hint ──────────────────────────────────────────────
          if (dataInfo != null) ...[
            _DataInfoBadge(
              info: dataInfo!,
              lokasi: lahan?.lokasi,
              analisa: p.analisa,
            ),
            const SizedBox(height: 14),
          ],

          // ─── Quota Exhausted Banner ──────────────────────────────────────
          if (showExhaustedBanner) ...[
            _QuotaExhaustedBanner(
              onUpgrade: () => Navigator.pushNamed(context, '/subscription'),
            ),
            const SizedBox(height: 12),
          ],

          // ─── Status Banner ───────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: statusCfg.bg,
              border: Border.all(color: statusCfg.color.withOpacity(0.3), width: 2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Headline: ikon + verdict besar
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: statusCfg.color,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(statusCfg.icon, color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            statusCfg.title,
                            style: AppTextStyles.display(18, color: statusCfg.color),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            statusCfg.subtitle,
                            style: AppTextStyles.body(12, color: AppColors.textMid),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Angka utama: ton aktual besar di tengah
                Center(
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(children: [
                      TextSpan(
                        text: p.tonAktual.toStringAsFixed(1),
                        style: AppTextStyles.display(48, color: AppColors.text),
                      ),
                      TextSpan(
                        text: ' ton',
                        style: AppTextStyles.body(18, color: AppColors.textMid),
                      ),
                    ]),
                  ),
                ),
                const SizedBox(height: 4),
                // Sub-info: target range, friendly format
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Target normal: ${p.targetMin.toStringAsFixed(1)}–${p.targetMax.toStringAsFixed(1)} ton',
                        style: AppTextStyles.body(13, color: AppColors.textMid),
                      ),
                      const SizedBox(width: 4),
                      const HelpTooltip(
                        term: 'Target Panen',
                        explanation:
                            'Target panen dihitung berdasarkan luas lahan dan usia pohon. Setiap fase usia (puncak awal, puncak produktif, dll) punya rentang produksi normal.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Progress bar
                _ProgressBar(panen: p),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ─── Metric Cards ────────────────────────────────────────────────
          Row(
            children: [
              Expanded(child: MetricCard(
                label: 'Selisih',
                value: '${p.selisih >= 0 ? "+" : ""}${p.selisih.toStringAsFixed(1)}',
                unit: 'ton',
                color: p.selisih >= 0 ? AppColors.primary : AppColors.danger,
              )),
              const SizedBox(width: 10),
              Expanded(child: MetricCard(
                label: 'Per Hektar',
                value: (p.tonAktual / p.luasHa).toStringAsFixed(2),
                unit: 't/ha',
                color: AppColors.text,
              )),
              const SizedBox(width: 10),
              Expanded(child: MetricCard(
                label: 'Est. Nilai',
                value: 'Rp ${(p.nilaiEstimasi / 1000000).toStringAsFixed(0)}jt',
                unit: 'estimasi',
                color: AppColors.gold,
              )),
            ],
          ),
          const SizedBox(height: 20),

          // ─── Analisa Penyebab ────────────────────────────────────────────
          if (hasil!.penyebab.isNotEmpty && p.status != 'normal') ...[
            Row(
              children: [
                Text('Analisa Penyebab',
                    style: AppTextStyles.display(16, color: AppColors.text)),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: p.analisa?.penyebab.isNotEmpty == true
                        ? AppColors.gold
                        : AppColors.textLight,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    p.analisa?.penyebab.isNotEmpty == true ? 'AI' : 'Lokal',
                    style: AppTextStyles.body(10, color: Colors.white,
                        weight: FontWeight.w700)),
                ),
              ],
            ),
            if (p.analisa?.penyebab.isNotEmpty != true) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.goldTint,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.goldLight.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 10, height: 10,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text('Analisa AI sedang diproses di background...',
                          style: AppTextStyles.body(12, color: AppColors.gold)),
                    ),
                    if (onRefresh != null)
                      GestureDetector(
                        onTap: onRefresh,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.gold,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('Refresh',
                              style: AppTextStyles.body(11,
                                  color: Colors.white, weight: FontWeight.w700)),
                        ),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            ...hasil!.penyebab.map((c) => _PenyebabCard(penyebab: c)),
          ],

          // Normal state
          if (p.status == 'normal')
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primaryTint,
                border: Border.all(color: AppColors.primary3.withOpacity(0.4)),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.check_circle_rounded,
                        color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Panen Sesuai Target!',
                            style: AppTextStyles.display(16,
                                color: AppColors.primary)),
                        const SizedBox(height: 6),
                        Text(
                          'Pertahankan jadwal pemupukan rutin dan pastikan panen '
                          'dilakukan tepat waktu agar kualitas TBS tetap optimal '
                          'dan FFA rendah.',
                          style: AppTextStyles.body(13,
                              color: AppColors.textMid),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 20),

          // Actions
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  label: 'Riwayat',
                  icon: Icons.bar_chart_rounded,
                  onTap: onGoToRiwayat,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: PrimaryButton(
                  label: 'Input Lagi',
                  icon: Icons.add_rounded,
                  onTap: onGoToInput,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  ({Color color, Color bg, IconData icon, String title, String subtitle})
      _statusConfig(String status) {
    final p = hasil!.panen;
    // Selisih ton dari target minimum — positif kalau di bawah min.
    final tonKurang = (p.targetMin - p.tonAktual).clamp(0.0, double.infinity);
    switch (status) {
      case 'normal':
        return (
          color: AppColors.primary,
          bg: AppColors.primaryTint,
          icon: Icons.check_rounded,
          title: 'Panen Bagus',
          subtitle: 'Hasil sesuai target produksi normal',
        );
      case 'warn':
        return (
          color: AppColors.warn,
          bg: AppColors.warnTint,
          icon: Icons.trending_down_rounded,
          title: 'Sedikit di Bawah Target',
          subtitle: 'Kurang ${tonKurang.toStringAsFixed(1)} ton '
              '(${p.persenKurang.toStringAsFixed(0)}%) dari target minimum',
        );
      default:
        return (
          color: AppColors.danger,
          bg: AppColors.dangerTint,
          icon: Icons.warning_rounded,
          title: 'Perlu Tindakan',
          subtitle: 'Kurang ${tonKurang.toStringAsFixed(1)} ton '
              '(${p.persenKurang.toStringAsFixed(0)}%) — cek penyebab di bawah',
        );
    }
  }
}

class _ProgressBar extends StatelessWidget {
  final PanenModel panen;
  const _ProgressBar({required this.panen});

  @override
  Widget build(BuildContext context) {
    // Guard against zero/missing targets (e.g. stale offline cache before
    // computed targets were stored). Fall back to tonAktual-based scale so
    // the bar still renders without NaN.
    final rawMax = panen.targetMax * 1.35;
    final safeMax = rawMax > 0
        ? rawMax
        : (panen.tonAktual > 0 ? panen.tonAktual * 1.5 : 1.0);
    final aktualPct = (panen.tonAktual / safeMax).clamp(0.0, 1.0);
    final minPct = (panen.targetMin / safeMax).clamp(0.0, 1.0);
    final maxPct = (panen.targetMax / safeMax).clamp(0.0, 1.0);
    final barColor = panen.status == 'normal'
        ? AppColors.primary3
        : panen.status == 'warn'
            ? AppColors.goldLight
            : const Color(0xFFEF4444);

    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final barWidth = constraints.maxWidth;
            return Stack(
              children: [
                // Background
                Container(height: 10, decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(99),
                )),
                // Target zone (relatif ke lebar bar parent, bukan layar)
                Positioned(
                  left: barWidth * minPct,
                  width: barWidth * (maxPct - minPct),
                  top: 0, bottom: 0,
                  child: Container(color: AppColors.primary3.withOpacity(0.25)),
                ),
                // Actual bar
                FractionallySizedBox(
                  widthFactor: aktualPct,
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: barColor,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('0', style: AppTextStyles.body(10, color: AppColors.textLight)),
            Text(
              'Target: ${panen.targetMin.toStringAsFixed(0)}–${panen.targetMax.toStringAsFixed(0)} ton',
              style: AppTextStyles.body(10, color: AppColors.textLight),
            ),
          ],
        ),
      ],
    );
  }
}

class _PenyebabCard extends StatelessWidget {
  final AnalisaPenyebab penyebab;
  const _PenyebabCard({required this.penyebab});

  Color get _borderColor => penyebab.severity == 'high'
      ? AppColors.danger
      : penyebab.severity == 'medium'
          ? AppColors.goldLight
          : AppColors.primary3;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: AppColors.surface,
      border: Border(
        left: BorderSide(color: _borderColor, width: 4),
        top: const BorderSide(color: AppColors.border),
        right: const BorderSide(color: AppColors.border),
        bottom: const BorderSide(color: AppColors.border),
      ),
      borderRadius: BorderRadius.circular(16),
    ),
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary3.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(penyebabIconData(penyebab.iconKey),
                  color: AppColors.primary3, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(penyebab.title,
                  style: AppTextStyles.body(15, color: AppColors.textMid,
                      weight: FontWeight.w700)),
            ),
            StatusBadge(label: penyebab.severity, severity: penyebab.severity),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.tips_and_updates_rounded,
                  size: 16, color: AppColors.primary3),
              const SizedBox(width: 8),
              Expanded(
                child: Text(penyebab.detail,
                    style: AppTextStyles.body(14,
                        color: AppColors.textMid)),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onGoToInput;
  const _EmptyState({required this.onGoToInput});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📊', style: TextStyle(fontSize: 52)),
          const SizedBox(height: 16),
          Text('Belum Ada Analisa', style: AppTextStyles.display(20)),
          const SizedBox(height: 8),
          Text(
            'Input data panen terlebih dahulu untuk melihat hasil analisa lengkap',
            style: AppTextStyles.body(13, color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          PrimaryButton(label: 'Input Panen Sekarang', onTap: onGoToInput),
        ],
      ),
    ),
  );
}

class _DataInfoBadge extends StatelessWidget {
  final AnalisaDataInfo info;
  final String? lokasi;
  final AnalisaResult? analisa;
  const _DataInfoBadge({
    required this.info,
    this.lokasi,
    this.analisa,
  });

  void _showSourceSheet(BuildContext context, bool isAi) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isAi ? Icons.smart_toy_rounded : Icons.rule_rounded,
                  color: isAi ? AppColors.gold : AppColors.primary3,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Text(
                  isAi ? 'Analisa AI Premium' : 'Analisa Cepat (Rule-Based)',
                  style: AppTextStyles.display(16),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              isAi
                  ? 'Analisa ini dihasilkan oleh AI yang mempertimbangkan tren panen, riwayat pupuk, cuaca, dan profil lahan Anda secara menyeluruh.'
                  : 'Analisa ini berbasis aturan agronomi standar. Untuk analisa AI yang lebih spesifik dan personal, upgrade paket atau tunggu reset kuota bulan depan.',
              style: AppTextStyles.body(14, color: AppColors.textMid),
            ),
            const SizedBox(height: 20),
            if (!isAi) ...[
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: BorderRadius.circular(Radii.md),
                  ),
                  child: Center(
                    child: Text('Upgrade Paket',
                        style: AppTextStyles.body(14,
                            color: Colors.white, weight: FontWeight.w700)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine AI/local source — only show badge if analisa is available.
    final bool? isAi =
        analisa != null ? analisa!.isAiGenerated : null;

    // Petani baru (1 panen, belum ada pupuk) → tip motivasi
    final isNewUser = info.panenCount <= 1 && !info.hasPupukData;
    if (isNewUser) {
      return GestureDetector(
        onTap: isAi != null ? () => _showSourceSheet(context, isAi) : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.goldTint,
            border: Border.all(color: AppColors.goldLight.withOpacity(0.4)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(Icons.lightbulb_outline_rounded,
                  size: 16, color: AppColors.gold),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Input panen rutin tiap bulan — analisa AI semakin akurat seiring data bertambah.',
                  style: AppTextStyles.body(11,
                      color: AppColors.gold, weight: FontWeight.w500),
                ),
              ),
              if (isAi != null) ...[
                const SizedBox(width: 8),
                _SourcePill(isAi: isAi),
              ],
            ],
          ),
        ),
      );
    }

    // Petani lengkap → ringkasan sumber data
    final parts = <String>[];
    if (info.panenCount >= 2) {
      parts.add('${info.panenCount} bulan riwayat');
    }
    if (info.hasPupukData) parts.add('riwayat pupuk');
    if (info.hasLokasi && lokasi != null && lokasi!.isNotEmpty) {
      parts.add('cuaca ${lokasi!}');
    }
    if (parts.isEmpty && isAi == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: isAi != null ? () => _showSourceSheet(context, isAi) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.primaryTint,
          border: Border.all(color: AppColors.primary3.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.bar_chart_rounded,
                size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                parts.isNotEmpty
                    ? 'Berdasarkan ${parts.join(' + ')}'
                    : 'Data analisa tersedia',
                style: AppTextStyles.body(11,
                    color: AppColors.primary, weight: FontWeight.w500),
              ),
            ),
            if (isAi != null) ...[
              const SizedBox(width: 8),
              _SourcePill(isAi: isAi),
            ],
          ],
        ),
      ),
    );
  }
}

/// Small pill badge showing AI or rule-based source.
class _SourcePill extends StatelessWidget {
  final bool isAi;
  const _SourcePill({required this.isAi});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isAi
              ? AppColors.gold.withOpacity(0.15)
              : AppColors.primary3.withOpacity(0.12),
          borderRadius: BorderRadius.circular(Radii.pill),
          border: Border.all(
            color: isAi
                ? AppColors.gold.withOpacity(0.4)
                : AppColors.primary3.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isAi ? Icons.smart_toy_rounded : Icons.rule_rounded,
              size: 11,
              color: isAi ? AppColors.gold : AppColors.primary3,
            ),
            const SizedBox(width: 3),
            Text(
              isAi ? 'Analisa AI' : 'Analisa Cepat',
              style: AppTextStyles.body(10,
                  color: isAi ? AppColors.gold : AppColors.primary3,
                  weight: FontWeight.w700),
            ),
          ],
        ),
      );
}

/// Banner shown at the top of the analisa screen when quota is exhausted.
class _QuotaExhaustedBanner extends StatelessWidget {
  final VoidCallback? onUpgrade;
  const _QuotaExhaustedBanner({this.onUpgrade});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.warnTint,
          borderRadius: BorderRadius.circular(Radii.md),
          border:
              Border.all(color: AppColors.warn.withOpacity(0.35)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.bolt_rounded,
                size: 18, color: AppColors.warn),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kuota AI bulan ini sudah habis.',
                    style: AppTextStyles.body(13,
                        color: AppColors.warn, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Analisa berikutnya akan menggunakan mode cepat (rule-based).',
                    style: AppTextStyles.body(12, color: AppColors.warn),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onUpgrade,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.warn,
                  borderRadius: BorderRadius.circular(Radii.md),
                ),
                child: Text('Upgrade',
                    style: AppTextStyles.body(11,
                        color: Colors.white, weight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      );
}
