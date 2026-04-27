import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/panen_model.dart';
import '../widgets/common_widgets.dart';

class HasilAnalisaScreen extends StatelessWidget {
  final HasilAnalisa? hasil;
  final VoidCallback onGoToInput;
  final VoidCallback onGoToRiwayat;

  const HasilAnalisaScreen({
    super.key,
    required this.hasil,
    required this.onGoToInput,
    required this.onGoToRiwayat,
  });

  @override
  Widget build(BuildContext context) {
    if (hasil == null) return _EmptyState(onGoToInput: onGoToInput);

    final p = hasil!.panen;
    final statusCfg = _statusConfig(p.status);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(
            title: 'Hasil Analisa',
            subtitle: '${p.luasHa} ha · Usia ${p.usiaTahun} tahun · ${p.bulan}',
          ),

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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hasil Panen Anda',
                            style: AppTextStyles.body(12, color: AppColors.textMuted,
                                weight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        RichText(
                          text: TextSpan(children: [
                            TextSpan(
                              text: '${p.tonAktual}',
                              style: AppTextStyles.display(40, color: AppColors.text),
                            ),
                            TextSpan(
                              text: ' ton',
                              style: AppTextStyles.body(16, color: AppColors.textMid),
                            ),
                          ]),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Target Normal',
                            style: AppTextStyles.body(12, color: AppColors.textMuted,
                                weight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        Text(
                          '${p.targetMin.toStringAsFixed(1)}–${p.targetMax.toStringAsFixed(1)} ton',
                          style: AppTextStyles.display(18, color: AppColors.textMid),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Progress bar
                _ProgressBar(panen: p),
                const SizedBox(height: 16),

                // Status chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: statusCfg.color,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    statusCfg.label,
                    style: AppTextStyles.body(13, color: Colors.white, weight: FontWeight.w700),
                  ),
                ),
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
                    color: AppColors.gold,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text('AI',
                      style: AppTextStyles.body(10, color: Colors.white,
                          weight: FontWeight.w700)),
                ),
              ],
            ),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🎉', style: TextStyle(fontSize: 24)),
                  const SizedBox(height: 8),
                  Text('Panen Sesuai Target!',
                      style: AppTextStyles.display(16, color: AppColors.primary)),
                  const SizedBox(height: 6),
                  Text(
                    'Pertahankan jadwal pemupukan rutin dan pastikan panen dilakukan '
                    'tepat waktu agar kualitas TBS tetap optimal dan FFA rendah.',
                    style: AppTextStyles.body(13, color: AppColors.textMid),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 20),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onGoToRiwayat,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('📊 Lihat Riwayat',
                      style: AppTextStyles.body(13, color: AppColors.primary,
                          weight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: onGoToInput,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: Text('+ Input Lagi',
                      style: AppTextStyles.body(13, color: Colors.white,
                          weight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  ({Color color, Color bg, String label}) _statusConfig(String status) {
    switch (status) {
      case 'normal':
        return (color: AppColors.primary, bg: AppColors.primaryTint, label: '✅  Panen Normal');
      case 'warn':
        return (color: AppColors.warn, bg: AppColors.warnTint,
            label: '⚠️  Kurang ${hasil!.panen.persenKurang.toStringAsFixed(0)}% dari Target');
      default:
        return (color: AppColors.danger, bg: AppColors.dangerTint,
            label: '🚨  Defisit ${hasil!.panen.persenKurang.toStringAsFixed(0)}% — Perlu Tindakan');
    }
  }
}

class _ProgressBar extends StatelessWidget {
  final PanenModel panen;
  const _ProgressBar({required this.panen});

  @override
  Widget build(BuildContext context) {
    final maxVal = panen.targetMax * 1.35;
    final aktualPct = (panen.tonAktual / maxVal).clamp(0.0, 1.0);
    final minPct = panen.targetMin / maxVal;
    final maxPct = panen.targetMax / maxVal;
    final barColor = panen.status == 'normal'
        ? AppColors.primary3
        : panen.status == 'warn'
            ? AppColors.goldLight
            : const Color(0xFFEF4444);

    return Column(
      children: [
        Stack(
          children: [
            // Background
            Container(height: 10, decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.08),
              borderRadius: BorderRadius.circular(99),
            )),
            // Target zone
            Positioned(
              left: MediaQuery.of(context).size.width * minPct * 0.75,
              width: MediaQuery.of(context).size.width * (maxPct - minPct) * 0.75,
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
        top: BorderSide(color: AppColors.border),
        right: BorderSide(color: AppColors.border),
        bottom: BorderSide(color: AppColors.border),
      ),
      borderRadius: BorderRadius.circular(16),
    ),
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(penyebab.icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(penyebab.title,
                  style: AppTextStyles.body(14, color: AppColors.textMid,
                      weight: FontWeight.w700)),
            ),
            StatusBadge(label: penyebab.severity, severity: penyebab.severity),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(penyebab.detail,
              style: AppTextStyles.body(13, color: AppColors.textMid)),
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
