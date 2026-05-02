import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/panen_model.dart';
import '../models/lahan_model.dart';
import '../widgets/common_widgets.dart';

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

  const HasilAnalisaScreen({
    super.key,
    required this.hasil,
    this.lahan,
    this.dataInfo,
    required this.onGoToInput,
    required this.onGoToRiwayat,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (hasil == null) return _EmptyState(onGoToInput: onGoToInput);

    final p = hasil!.panen;
    final statusCfg = _statusConfig(p.status);

    final luasHa = lahan?.luasHa ?? p.luasHa;
    final usiaTahun = lahan?.usiaPohon ?? p.usiaTahun;
    final namaLahan = lahan?.namaLahan;

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
            _DataInfoBadge(info: dataInfo!, lokasi: lahan?.lokasi),
            const SizedBox(height: 14),
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
                  child: Text(
                    'Target normal: ${p.targetMin.toStringAsFixed(1)}–${p.targetMax.toStringAsFixed(1)} ton',
                    style: AppTextStyles.body(13, color: AppColors.textMid),
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
  const _DataInfoBadge({required this.info, this.lokasi});

  @override
  Widget build(BuildContext context) {
    // Petani baru (1 panen, belum ada pupuk) → tip motivasi
    final isNewUser = info.panenCount <= 1 && !info.hasPupukData;
    if (isNewUser) {
      return Container(
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
          ],
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
    if (parts.isEmpty) return const SizedBox.shrink();

    return Container(
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
              'Berdasarkan ${parts.join(' + ')}',
              style: AppTextStyles.body(11,
                  color: AppColors.primary, weight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
