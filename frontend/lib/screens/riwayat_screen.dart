import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/panen_model.dart';
import '../widgets/common_widgets.dart';

final _mockHistory = [
  PanenModel(luasHa: 14, usiaTahun: 8, tonAktual: 24.1, targetMin: 21, targetMax: 28, targetMid: 24.5, bulan: 'Okt 2024', tanggalInput: DateTime(2024, 10)),
  PanenModel(luasHa: 14, usiaTahun: 8, tonAktual: 26.3, targetMin: 21, targetMax: 28, targetMid: 24.5, bulan: 'Nov 2024', tanggalInput: DateTime(2024, 11)),
  PanenModel(luasHa: 14, usiaTahun: 8, tonAktual: 23.8, targetMin: 21, targetMax: 28, targetMid: 24.5, bulan: 'Des 2024', tanggalInput: DateTime(2024, 12)),
  PanenModel(luasHa: 14, usiaTahun: 8, tonAktual: 21.4, targetMin: 21, targetMax: 28, targetMid: 24.5, bulan: 'Jan 2025', tanggalInput: DateTime(2025, 1)),
  PanenModel(luasHa: 14, usiaTahun: 8, tonAktual: 19.6, targetMin: 21, targetMax: 28, targetMid: 24.5, bulan: 'Feb 2025', tanggalInput: DateTime(2025, 2)),
  PanenModel(luasHa: 14, usiaTahun: 8, tonAktual: 22.9, targetMin: 21, targetMax: 28, targetMid: 24.5, bulan: 'Mar 2025', tanggalInput: DateTime(2025, 3)),
  PanenModel(luasHa: 14, usiaTahun: 8, tonAktual: 17.2, targetMin: 21, targetMax: 28, targetMid: 24.5, bulan: 'Apr 2025', tanggalInput: DateTime(2025, 4)),
];

class RiwayatScreen extends StatelessWidget {
  final HasilAnalisa? lastAnalisa;
  const RiwayatScreen({super.key, this.lastAnalisa});

  @override
  Widget build(BuildContext context) {
    // Gabungkan mock history dengan analisa terbaru kalau ada
    final data = [..._mockHistory];
    if (lastAnalisa != null) {
      final p = lastAnalisa!.panen;
      final exists = data.any((d) => d.bulan == p.bulan);
      if (!exists) data.add(p);
    }

    final total = data.fold(0.0, (a, b) => a + b.tonAktual);
    final avg = total / data.length;
    final best = data.map((d) => d.tonAktual).reduce((a, b) => a > b ? a : b);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(
            title: 'Riwayat Panen',
            subtitle: '${data.length} bulan terakhir · Kebun 14 ha',
          ),

          // Summary cards
          Row(
            children: [
              Expanded(child: MetricCard(label: 'Total', value: total.toStringAsFixed(1), unit: 'ton', color: AppColors.primary)),
              const SizedBox(width: 10),
              Expanded(child: MetricCard(label: 'Rata-rata', value: avg.toStringAsFixed(1), unit: 'ton/bln', color: AppColors.text)),
              const SizedBox(width: 10),
              Expanded(child: MetricCard(label: 'Terbaik', value: best.toStringAsFixed(1), unit: 'ton', color: AppColors.gold)),
            ],
          ),
          const SizedBox(height: 16),

          // Chart
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Grafik Produksi vs Target',
                    style: AppTextStyles.body(13, color: AppColors.textMid,
                        weight: FontWeight.w700)),
                const SizedBox(height: 20),
                _BarChart(data: data),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _Legend(color: AppColors.primary3, label: 'Aktual', isBar: true),
                    const SizedBox(width: 20),
                    _Legend(color: AppColors.goldLight, label: 'Target', isBar: false),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // List detail
          Text('DETAIL PER BULAN',
              style: AppTextStyles.label(color: AppColors.textLight)),
          const SizedBox(height: 14),
          ...data.reversed.map((p) => _RiwayatItem(panen: p)),
        ],
      ),
    );
  }
}

class _BarChart extends StatelessWidget {
  final List<PanenModel> data;
  const _BarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    const chartHeight = 110.0;
    final maxVal = data.map((d) => d.targetMax).reduce((a, b) => a > b ? a : b) * 1.2;

    return SizedBox(
      height: chartHeight + 28,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: data.map((d) {
          final barH = (d.tonAktual / maxVal) * chartHeight;
          final tgtH = (d.targetMid / maxVal) * chartHeight;
          final ok = d.tonAktual >= d.targetMin;

          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  d.tonAktual.toStringAsFixed(0),
                  style: AppTextStyles.body(9,
                      color: ok ? AppColors.primary3 : AppColors.danger,
                      weight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  height: chartHeight,
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      Positioned(
                        bottom: tgtH - 1,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 1.5,
                          color: AppColors.goldLight.withOpacity(0.8),
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOut,
                          width: 16,
                          height: barH,
                          decoration: BoxDecoration(
                            color: ok
                                ? AppColors.primary3.withOpacity(0.85)
                                : const Color(0xFFEF4444).withOpacity(0.85),
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  d.bulan.split(' ').first.substring(0, 3),
                  style: AppTextStyles.body(9, color: AppColors.textMuted,
                      weight: FontWeight.w500),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _RiwayatItem extends StatelessWidget {
  final PanenModel panen;
  const _RiwayatItem({required this.panen});

  @override
  Widget build(BuildContext context) {
    final ok = panen.tonAktual >= panen.targetMin;
    final pct = panen.persenKurang;
    final borderColor = ok
        ? AppColors.primary3
        : pct > 20
            ? AppColors.danger
            : AppColors.goldLight;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          left: BorderSide(color: borderColor, width: 4),
          top: BorderSide(color: AppColors.border),
          right: BorderSide(color: AppColors.border),
          bottom: BorderSide(color: AppColors.border),
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(panen.bulan,
                      style: AppTextStyles.body(14, weight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text('Target: ${panen.targetMid} ton',
                      style: AppTextStyles.body(12, color: AppColors.textMuted)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${panen.tonAktual} ton',
                    style: AppTextStyles.display(18,
                        color: ok ? AppColors.primary : AppColors.danger),
                  ),
                  Text(
                    ok ? '✓ Normal' : '↓ ${pct.toStringAsFixed(0)}%',
                    style: AppTextStyles.body(11,
                        color: ok ? AppColors.primary3 : AppColors.danger,
                        weight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          MiniProgressBar(
            value: (panen.tonAktual / (panen.targetMax * 1.2)).clamp(0.0, 1.0),
            color: ok ? AppColors.primary3 : const Color(0xFFEF4444),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  final bool isBar;

  const _Legend({required this.color, required this.label, required this.isBar});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      isBar
          ? Container(width: 14, height: 14, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)))
          : Container(width: 16, height: 2, color: color),
      const SizedBox(width: 6),
      Text(label, style: AppTextStyles.body(11, color: AppColors.textMuted)),
    ],
  );
}
