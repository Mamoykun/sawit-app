import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/panen_model.dart';
import '../widgets/common_widgets.dart';

// Mock data riwayat untuk beranda
final _mockHistory = [
  PanenModel(luasHa: 14, usiaTahun: 8, tonAktual: 24.1, targetMin: 21, targetMax: 28, targetMid: 24.5, bulan: 'Okt', tanggalInput: DateTime(2024, 10)),
  PanenModel(luasHa: 14, usiaTahun: 8, tonAktual: 26.3, targetMin: 21, targetMax: 28, targetMid: 24.5, bulan: 'Nov', tanggalInput: DateTime(2024, 11)),
  PanenModel(luasHa: 14, usiaTahun: 8, tonAktual: 23.8, targetMin: 21, targetMax: 28, targetMid: 24.5, bulan: 'Des', tanggalInput: DateTime(2024, 12)),
  PanenModel(luasHa: 14, usiaTahun: 8, tonAktual: 21.4, targetMin: 21, targetMax: 28, targetMid: 24.5, bulan: 'Jan', tanggalInput: DateTime(2025, 1)),
  PanenModel(luasHa: 14, usiaTahun: 8, tonAktual: 19.6, targetMin: 21, targetMax: 28, targetMid: 24.5, bulan: 'Feb', tanggalInput: DateTime(2025, 2)),
  PanenModel(luasHa: 14, usiaTahun: 8, tonAktual: 22.9, targetMin: 21, targetMax: 28, targetMid: 24.5, bulan: 'Mar', tanggalInput: DateTime(2025, 3)),
  PanenModel(luasHa: 14, usiaTahun: 8, tonAktual: 17.2, targetMin: 21, targetMax: 28, targetMid: 24.5, bulan: 'Apr', tanggalInput: DateTime(2025, 4)),
];

class BerandaScreen extends StatelessWidget {
  final VoidCallback onGoToInput;
  const BerandaScreen({super.key, required this.onGoToInput});

  @override
  Widget build(BuildContext context) {
    final last = _mockHistory.last;
    final prev = _mockHistory[_mockHistory.length - 2];
    final tren = last.tonAktual - prev.tonAktual;
    final isBelowTarget = last.tonAktual < last.targetMin;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting
          Text('Selamat datang kembali',
              style: AppTextStyles.body(13, color: AppColors.textMuted)),
          const SizedBox(height: 4),
          Text('Kebun Sawit Anda', style: AppTextStyles.display(26)),
          const SizedBox(height: 4),
          Text('14 hektar · Usia 8 tahun · 7 blok aktif',
              style: AppTextStyles.body(13, color: AppColors.textMuted)),
          const SizedBox(height: 24),

          // Hero card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.primary2],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PANEN TERAKHIR · ${last.bulan}'.toUpperCase(),
                  style: AppTextStyles.body(12,
                      color: const Color(0xFF74C69D), weight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${last.tonAktual}',
                        style: AppTextStyles.display(44, color: Colors.white)),
                    const SizedBox(width: 6),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text('ton',
                          style: AppTextStyles.body(18, color: Colors.white70)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Target',
                            style: AppTextStyles.body(12,
                                color: const Color(0xFF74C69D99))),
                        Text('${last.targetMid} ton',
                            style: AppTextStyles.body(14,
                                color: const Color(0xFF74C69D),
                                weight: FontWeight.w600)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Tren vs Bulan Lalu',
                            style: AppTextStyles.body(12,
                                color: const Color(0xFF74C69D99))),
                        Text(
                          '${tren >= 0 ? "▲" : "▼"} ${tren.abs().toStringAsFixed(1)} ton',
                          style: AppTextStyles.body(14,
                              color: tren >= 0
                                  ? const Color(0xFF74C69D)
                                  : const Color(0xFFFCA5A5),
                              weight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Alert kalau di bawah target
          if (isBelowTarget)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.dangerTint,
                border: Border.all(color: const Color(0xFFFCA5A5)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Text('⚠️', style: TextStyle(fontSize: 26)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Panen Di Bawah Target',
                            style: AppTextStyles.body(13,
                                color: AppColors.danger,
                                weight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(
                          'Kurang ${last.persenKurang.toStringAsFixed(0)}% dari normal. Segera analisa penyebabnya.',
                          style: AppTextStyles.body(12,
                              color: const Color(0xFFB91C1C)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Mini chart
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Tren Panen 7 Bulan',
                        style: AppTextStyles.body(13,
                            color: AppColors.textMid, weight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 16),
                _MiniBarChart(data: _mockHistory),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Quick actions
          Text('AKSI CEPAT',
              style: AppTextStyles.label(color: AppColors.textLight)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _ActionCard(
                  icon: '📥',
                  label: 'Input Panen',
                  sub: 'Catat hasil bulan ini',
                  accent: true,
                  onTap: onGoToInput,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionCard(
                  icon: '📊',
                  label: 'Riwayat',
                  sub: 'Lihat tren historis',
                  onTap: () {},
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String icon;
  final String label;
  final String sub;
  final bool accent;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.sub,
    this.accent = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: accent ? AppColors.primary : AppColors.surface,
        border: Border.all(
            color: accent ? AppColors.primary : AppColors.border, width: 1.5),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 10),
          Text(label,
              style: AppTextStyles.body(14,
                  color: accent ? Colors.white : AppColors.text,
                  weight: FontWeight.w700)),
          const SizedBox(height: 3),
          Text(sub,
              style: AppTextStyles.body(11,
                  color: accent ? const Color(0xFF74C69D) : AppColors.textMuted)),
        ],
      ),
    ),
  );
}

class _MiniBarChart extends StatelessWidget {
  final List<PanenModel> data;
  const _MiniBarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    const maxVal = 32.0;
    const chartHeight = 80.0;

    return SizedBox(
      height: chartHeight + 24,
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
                SizedBox(
                  height: chartHeight,
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      // target line
                      Positioned(
                        bottom: tgtH - 1,
                        left: 0,
                        right: 0,
                        child: Container(height: 1.5, color: AppColors.goldLight.withOpacity(0.8)),
                      ),
                      // bar
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          width: 18,
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
                Text(d.bulan,
                    style: AppTextStyles.body(9, color: AppColors.textMuted,
                        weight: FontWeight.w500)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
