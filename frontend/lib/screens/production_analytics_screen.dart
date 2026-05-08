import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/lahan_model.dart';
import '../models/panen_model.dart';
import '../services/api_service.dart';
import '../repositories/panen_repository.dart';
import '../main.dart' show appDb;
import '../widgets/common_widgets.dart';
import '../widgets/offline_banner.dart';

class ProductionAnalyticsScreen extends StatefulWidget {
  final LahanModel lahan;

  const ProductionAnalyticsScreen({super.key, required this.lahan});

  @override
  State<ProductionAnalyticsScreen> createState() =>
      _ProductionAnalyticsScreenState();
}

class _ProductionAnalyticsScreenState
    extends State<ProductionAnalyticsScreen> {
  late final PanenRepository _panenRepo;
  List<PanenModel>? _allData;
  bool _loading = true;
  late int _selectedYear;

  static const _kMonthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];

  @override
  void initState() {
    super.initState();
    _panenRepo = PanenRepository(db: appDb, api: ApiService());
    _selectedYear = DateTime.now().year;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      // limit: 500 menampung petani yang punya data 40+ tahun (mustahil dilampaui).
      final list = await _panenRepo.getByLahan(widget.lahan.id, limit: 500);
      if (mounted) setState(() { _allData = list; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<int> get _years {
    final now = DateTime.now().year;
    final dataYears = (_allData ?? [])
        .map((p) => p.tahun ?? now)
        .toSet();
    dataYears.add(now);
    return dataYears.toList()..sort((a, b) => b.compareTo(a));
  }

  /// Recompute status from aggregated tonAktual vs targetMin.
  /// Formula mirrors PanenRepository.create: persenKurang relative to targetMin.
  static String _computeStatus(double tonAktual, double targetMin) {
    if (tonAktual >= targetMin) return 'normal';
    final persen = targetMin > 0
        ? max(0.0, (targetMin - tonAktual) / targetMin * 100)
        : 0.0;
    return persen <= 20 ? 'warn' : 'danger';
  }

  /// Months filtered to selected year, indexed 0–11 (Jan=0, Des=11).
  Map<int, _MonthData> get _monthMap {
    final data = _allData ?? [];
    final filtered = data.where((p) => p.tahun == _selectedYear).toList();
    final map = <int, _MonthData>{};
    for (final p in filtered) {
      final idx = (p.bulanAngka ?? 1) - 1;
      if (idx < 0 || idx > 11) continue;
      if (map.containsKey(idx)) {
        final e = map[idx]!;
        final sumTon = e.tonAktual + p.tonAktual;
        map[idx] = _MonthData(
          monthIdx: idx,
          bulan: e.bulan,
          tonAktual: sumTon,
          targetMin: e.targetMin,
          targetMid: e.targetMid,
          targetMax: e.targetMax,
          luasHa: p.luasHa,
          status: _computeStatus(sumTon, e.targetMin),
        );
      } else {
        map[idx] = _MonthData(
          monthIdx: idx,
          bulan: p.bulan,
          tonAktual: p.tonAktual,
          targetMin: p.targetMin,
          targetMid: p.targetMid,
          targetMax: p.targetMax,
          luasHa: p.luasHa,
          status: _computeStatus(p.tonAktual, p.targetMin),
        );
      }
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primary2, Color(0xFF1A5C40)],
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Analisa Produksi',
                style: AppTextStyles.display(18, color: Colors.white)),
            Text(widget.lahan.namaLahan,
                style: AppTextStyles.body(11, color: const Color(0xFF74C69D))),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: DropdownButton<int>(
              value: _selectedYear,
              dropdownColor: AppColors.primary,
              underline: const SizedBox.shrink(),
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: Colors.white70, size: 20),
              items: _years
                  .map((y) => DropdownMenuItem(
                        value: y,
                        child: Text('$y',
                            style: AppTextStyles.body(13,
                                color: Colors.white,
                                weight: FontWeight.w600)),
                      ))
                  .toList(),
              onChanged: (y) {
                if (y != null && y != _selectedYear) {
                  setState(() => _selectedYear = y);
                }
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }

    final monthMap = _monthMap;

    if (monthMap.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primaryTint,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.bar_chart_rounded,
                    size: 40, color: AppColors.primary3),
              ),
              const SizedBox(height: 20),
              Text('Belum Ada Data Panen',
                  style: AppTextStyles.display(20)),
              const SizedBox(height: 8),
              Text(
                'Tidak ada data panen untuk tahun $_selectedYear.\nTambah data panen tiap bulan untuk melihat analisa.',
                style: AppTextStyles.body(14, color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // ── Computed metrics ──────────────────────────────────────────────────────
    final totalTon = monthMap.values.fold(0.0, (a, b) => a + b.tonAktual);
    final bulanAktif = monthMap.length;
    final avgPerBulan = bulanAktif > 0 ? totalTon / bulanAktif : 0.0;

    double refTargetMin = 0, refTargetMax = 0;
    if (monthMap.isNotEmpty) {
      final first = monthMap.values.first;
      refTargetMin = first.targetMin;
      refTargetMax = first.targetMax;
    }

    int countBagus = 0, countKurang = 0, countDefisit = 0;
    for (final m in monthMap.values) {
      switch (m.status) {
        case 'normal': countBagus++; break;
        case 'warn': countKurang++; break;
        default: countDefisit++; break;
      }
    }

    // Best and worst month
    _MonthData? bestMonth, worstMonth;
    for (final m in monthMap.values) {
      if (bestMonth == null || m.tonAktual > bestMonth.tonAktual) {
        bestMonth = m;
      }
      if (worstMonth == null || m.tonAktual < worstMonth.tonAktual) {
        worstMonth = m;
      }
    }

    final tips = _buildTips(monthMap, totalTon, bulanAktif, countBagus,
        countKurang, countDefisit, refTargetMid: monthMap.values.isNotEmpty
            ? monthMap.values.first.targetMid
            : 0);

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section 1: Ringkasan Tahun Ini
            _SummaryCardBig(
              year: _selectedYear,
              totalTon: totalTon,
              bulanAktif: bulanAktif,
              avgPerBulan: avgPerBulan,
              countBagus: countBagus,
              countKurang: countKurang + countDefisit,
            ),
            const SizedBox(height: 20),

            // Section 2: Bar Chart Per Bulan
            AppCard(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Hasil Panen Tiap Bulan',
                      style: AppTextStyles.display(17)),
                  const SizedBox(height: 4),
                  Text(
                    'Hijau = sesuai target  ·  Kuning = sedikit kurang  ·  Merah = perlu perhatian',
                    style: AppTextStyles.body(13, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 18),
                  _SimpleMonthlyBars(
                    monthMap: monthMap,
                    monthNames: _kMonthNames,
                    targetMin: refTargetMin,
                    targetMax: refTargetMax,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Section 3: Bulan Terbaik vs Terlemah
            // Hanya tampil kalau ada minimal 2 bulan beda — kalau cuma 1 bulan,
            // best == worst dan section ini tidak bermakna.
            if (bestMonth != null &&
                worstMonth != null &&
                bestMonth.monthIdx != worstMonth.monthIdx) ...[
              _BestWorstCard(
                bestMonth: bestMonth,
                worstMonth: worstMonth,
                monthNames: _kMonthNames,
                year: _selectedYear,
                avgPerBulan: avgPerBulan,
              ),
              const SizedBox(height: 20),
            ],

            // Section 4: Pencapaian Target
            _AchievementBar(
              countBagus: countBagus,
              countKurang: countKurang,
              countDefisit: countDefisit,
              bulanAktif: bulanAktif,
            ),
            const SizedBox(height: 20),

            // Section 5: Tips Praktis
            if (tips.isNotEmpty)
              _TipsCard(tips: tips),
          ],
        ),
      ),
    );
  }

  List<String> _buildTips(
    Map<int, _MonthData> monthMap,
    double totalTon,
    int bulanAktif,
    int countBagus,
    int countKurang,
    int countDefisit, {
    required double refTargetMid,
  }) {
    final tips = <String>[];

    // Tip: bulan defisit berat (persen kurang > 20%)
    for (final m in monthMap.values) {
      if (m.status == 'danger') {
        final label = m.monthIdx < _kMonthNames.length
            ? _kMonthNames[m.monthIdx]
            : 'Bulan ${m.monthIdx + 1}';
        final pct = refTargetMid > 0
            ? ((refTargetMid - m.tonAktual) / refTargetMid * 100)
                .clamp(0, 100)
                .toStringAsFixed(0)
            : '?';
        tips.add(
            '$label panen turun $pct%. Cek kondisi pohon, pemupukan, dan curah hujan bulan tersebut.');
        break; // hanya satu tip per kategori agar tidak terlalu panjang
      }
    }

    // Tip: konsistensi bagus
    if (bulanAktif >= 3 && countBagus == bulanAktif) {
      tips.add(
          'Kebun Anda sangat stabil! Semua $countBagus bulan sesuai target. Pertahankan jadwal pemupukan dan perawatan.');
    } else if (bulanAktif >= 4) {
      final pct = (countBagus / bulanAktif * 100).round();
      if (pct >= 75) {
        tips.add(
            '$pct% bulan sudah sesuai target. Teruskan kebiasaan baik ini untuk hasil lebih konsisten.');
      }
    }

    // Tip: data belum lengkap
    if (bulanAktif < 12) {
      final sisa = 12 - bulanAktif;
      tips.add(
          'Masih ada $sisa bulan yang belum diisi. Lengkapi data tiap bulan agar analisa lebih akurat.');
    }

    return tips;
  }
}

// ─── Data holder ─────────────────────────────────────────────────────────────

class _MonthData {
  final int monthIdx;
  final String bulan;
  final double tonAktual;
  final double targetMin;
  final double targetMid;
  final double targetMax;
  final double luasHa;
  final String status;

  const _MonthData({
    required this.monthIdx,
    required this.bulan,
    required this.tonAktual,
    required this.targetMin,
    required this.targetMid,
    required this.targetMax,
    required this.luasHa,
    required this.status,
  });

  Color get barColor {
    switch (status) {
      case 'normal': return AppColors.primary3;
      case 'warn': return const Color(0xFFD97706); // amber-600
      default: return AppColors.danger;
    }
  }
}

// ─── Section 1: Ringkasan Tahun Ini ─────────────────────────────────────────

class _SummaryCardBig extends StatelessWidget {
  final int year;
  final double totalTon;
  final int bulanAktif;
  final double avgPerBulan;
  final int countBagus;
  final int countKurang;

  const _SummaryCardBig({
    required this.year,
    required this.totalTon,
    required this.bulanAktif,
    required this.avgPerBulan,
    required this.countBagus,
    required this.countKurang,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B4332), Color(0xFF2D6A4F)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: Elevations.level3,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Year badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'TAHUN $year',
              style: AppTextStyles.body(12,
                  color: Colors.white70, weight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 14),

          // Label
          Row(
            children: [
              const Text('\u{1F33E}', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Text('Total Hasil Panen Anda',
                  style: AppTextStyles.body(16, color: Colors.white70)),
            ],
          ),
          const SizedBox(height: 6),

          // Big number
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                totalTon.toStringAsFixed(0),
                style: AppTextStyles.mono(56,
                    color: Colors.white, weight: FontWeight.w800),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8, left: 6),
                child: Text('TON',
                    style: AppTextStyles.body(20,
                        color: Colors.white60, weight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Info row
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                _InfoRow(
                  icon: Icons.calendar_month_rounded,
                  text: 'Sudah panen $bulanAktif dari 12 bulan',
                ),
                const SizedBox(height: 8),
                _InfoRow(
                  icon: Icons.balance_rounded,
                  text:
                      'Rata-rata ${avgPerBulan.toStringAsFixed(1)} ton per bulan',
                ),
                const SizedBox(height: 8),
                _InfoRow(
                  icon: countBagus >= countKurang
                      ? Icons.check_circle_rounded
                      : Icons.warning_amber_rounded,
                  text: countKurang == 0
                      ? '$countBagus bulan sesuai target — bagus!'
                      : '$countBagus bulan bagus, $countKurang bulan perlu perhatian',
                  iconColor: countBagus >= countKurang
                      ? const Color(0xFF74C69D)
                      : const Color(0xFFD97706),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? iconColor;

  const _InfoRow({required this.icon, required this.text, this.iconColor});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon,
              size: 18, color: iconColor ?? Colors.white70),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: AppTextStyles.body(14, color: Colors.white)),
          ),
        ],
      );
}

// ─── Section 2: Bar Chart Sederhana Per Bulan ────────────────────────────────

class _SimpleMonthlyBars extends StatelessWidget {
  final Map<int, _MonthData> monthMap;
  final List<String> monthNames;
  final double targetMin;
  final double targetMax;

  const _SimpleMonthlyBars({
    required this.monthMap,
    required this.monthNames,
    required this.targetMin,
    required this.targetMax,
  });

  @override
  Widget build(BuildContext context) {
    // Compute max value for proportional height
    final maxVal = monthMap.values.isEmpty
        ? (targetMax > 0 ? targetMax : 30)
        : monthMap.values
            .map((m) => m.tonAktual)
            .reduce((a, b) => a > b ? a : b);
    final scale = maxVal > 0 ? maxVal : 1.0;
    const barAreaHeight = 180.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: barAreaHeight + 44, // bars + labels
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(12, (i) {
              final m = monthMap[i];
              final val = m?.tonAktual ?? 0.0;
              final color = m?.barColor ?? AppColors.border.withOpacity(0.4);
              final barHeight =
                  m != null ? (val / scale * barAreaHeight).clamp(6.0, barAreaHeight) : 0.0;
              final label = i < monthNames.length ? monthNames[i] : '?';
              final valText = m != null
                  ? val.toStringAsFixed(val >= 10 ? 0 : 1)
                  : '—';

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1.5),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Value on top
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          valText,
                          style: AppTextStyles.mono(11,
                              color: m != null
                                  ? color
                                  : AppColors.textLight,
                              weight: FontWeight.w700),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.clip,
                        ),
                      ),
                      const SizedBox(height: 3),
                      // Bar
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutCubic,
                        height: m != null ? barHeight : 4,
                        decoration: BoxDecoration(
                          color: m != null ? color : AppColors.border.withOpacity(0.3),
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(5)),
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Month label
                      Text(
                        label,
                        style: AppTextStyles.body(11,
                            color: m != null
                                ? AppColors.textMid
                                : AppColors.textLight),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
        // Target reference lines legend
        if (targetMin > 0 || targetMax > 0) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                _TargetLegendDot(
                    color: AppColors.primary3,
                    label: 'Min target: ${targetMin.toStringAsFixed(0)} ton'),
                const SizedBox(width: 16),
                _TargetLegendDot(
                    color: AppColors.gold,
                    label: 'Max target: ${targetMax.toStringAsFixed(0)} ton'),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _TargetLegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _TargetLegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(3)),
          ),
          const SizedBox(width: 5),
          Text(label,
              style: AppTextStyles.body(12, color: AppColors.textMuted)),
        ],
      );
}

// ─── Section 3: Bulan Terbaik vs Terlemah ───────────────────────────────────

class _BestWorstCard extends StatelessWidget {
  final _MonthData bestMonth;
  final _MonthData worstMonth;
  final List<String> monthNames;
  final int year;
  final double avgPerBulan;

  const _BestWorstCard({
    required this.bestMonth,
    required this.worstMonth,
    required this.monthNames,
    required this.year,
    required this.avgPerBulan,
  });

  @override
  Widget build(BuildContext context) {
    final bestLabel = bestMonth.monthIdx < monthNames.length
        ? monthNames[bestMonth.monthIdx]
        : 'Bln ${bestMonth.monthIdx + 1}';
    final worstLabel = worstMonth.monthIdx < monthNames.length
        ? monthNames[worstMonth.monthIdx]
        : 'Bln ${worstMonth.monthIdx + 1}';

    final bestPct = avgPerBulan > 0
        ? ((bestMonth.tonAktual - avgPerBulan) / avgPerBulan * 100).round()
        : 0;
    final worstPct = avgPerBulan > 0
        ? ((worstMonth.tonAktual - avgPerBulan) / avgPerBulan * 100).round()
        : 0;

    return Row(
      children: [
        Expanded(
          child: _ComparisonCard(
            emoji: '\u{1F3C6}',
            title: 'BULAN TERBAIK',
            monthLabel: '$bestLabel $year',
            ton: bestMonth.tonAktual,
            pctDiff: bestPct,
            isGood: true,
            note: 'Pertahankan!',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ComparisonCard(
            emoji: '\u{1F4C9}',
            title: 'PERLU PERBAIKAN',
            monthLabel: '$worstLabel $year',
            ton: worstMonth.tonAktual,
            pctDiff: worstPct,
            isGood: false,
            note: 'Cek penyebabnya',
          ),
        ),
      ],
    );
  }
}

class _ComparisonCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String monthLabel;
  final double ton;
  final int pctDiff;
  final bool isGood;
  final String note;

  const _ComparisonCard({
    required this.emoji,
    required this.title,
    required this.monthLabel,
    required this.ton,
    required this.pctDiff,
    required this.isGood,
    required this.note,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor =
        isGood ? const Color(0xFFF0FDF4) : const Color(0xFFFFFBEB);
    final accentColor = isGood ? AppColors.primary3 : const Color(0xFFD97706);
    final borderColor = isGood
        ? AppColors.primary3.withOpacity(0.3)
        : const Color(0xFFD97706).withOpacity(0.3);
    final signStr = pctDiff >= 0 ? '+$pctDiff%' : '$pctDiff%';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
        boxShadow: Elevations.level1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 8),
          Text(title,
              style: AppTextStyles.body(11,
                  color: accentColor, weight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(monthLabel,
              style: AppTextStyles.display(14, color: AppColors.text)),
          const SizedBox(height: 6),
          Text(
            '${ton.toStringAsFixed(0)} ton',
            style: AppTextStyles.mono(22,
                color: accentColor, weight: FontWeight.w800),
          ),
          Text(signStr,
              style: AppTextStyles.body(13,
                  color: accentColor.withOpacity(0.8),
                  weight: FontWeight.w600)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(note,
                style: AppTextStyles.body(12,
                    color: accentColor, weight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ─── Section 4: Pencapaian Target ───────────────────────────────────────────

class _AchievementBar extends StatelessWidget {
  final int countBagus;
  final int countKurang;
  final int countDefisit;
  final int bulanAktif;

  const _AchievementBar({
    required this.countBagus,
    required this.countKurang,
    required this.countDefisit,
    required this.bulanAktif,
  });

  @override
  Widget build(BuildContext context) {
    final total = countBagus + countKurang + countDefisit;
    final pct = total > 0 ? (countBagus / total * 100).round() : 0;

    return AppCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Berapa Bulan yang Sesuai Target?',
              style: AppTextStyles.display(17)),
          const SizedBox(height: 6),
          Text(
            'Dari $bulanAktif bulan yang sudah dicatat',
            style: AppTextStyles.body(13, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),

          // Big number
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$countBagus',
                  style: AppTextStyles.mono(40,
                      color: AppColors.primary3, weight: FontWeight.w800)),
              Padding(
                padding: const EdgeInsets.only(bottom: 6, left: 4),
                child: Text(' dari $total bulan ($pct%)',
                    style: AppTextStyles.body(15, color: AppColors.textMuted)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Stacked bar
          if (total > 0)
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LayoutBuilder(builder: (context, constraints) {
                final w = constraints.maxWidth;
                return Row(
                  children: [
                    if (countBagus > 0)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOutCubic,
                        width: w * countBagus / total,
                        height: 24,
                        color: AppColors.primary3,
                      ),
                    if (countKurang > 0)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOutCubic,
                        width: w * countKurang / total,
                        height: 24,
                        color: const Color(0xFFD97706),
                      ),
                    if (countDefisit > 0)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOutCubic,
                        width: w * countDefisit / total,
                        height: 24,
                        color: AppColors.danger,
                      ),
                  ],
                );
              }),
            ),

          const SizedBox(height: 12),

          // Legend
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              _LegendItem(
                  color: AppColors.primary3,
                  label: 'Bagus  $countBagus bln'),
              if (countKurang > 0)
                _LegendItem(
                    color: const Color(0xFFD97706),
                    label: 'Kurang  $countKurang bln'),
              if (countDefisit > 0)
                _LegendItem(
                    color: AppColors.danger,
                    label: 'Defisit  $countDefisit bln'),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(3)),
          ),
          const SizedBox(width: 5),
          Text(label,
              style: AppTextStyles.body(13, color: AppColors.textMid)),
        ],
      );
}

// ─── Section 5: Tips Praktis ─────────────────────────────────────────────────

class _TipsCard extends StatelessWidget {
  final List<String> tips;

  const _TipsCard({required this.tips});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('\u{1F4A1}', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text('Tips Untuk Anda',
                  style: AppTextStyles.display(16,
                      color: const Color(0xFF1D4ED8))),
            ],
          ),
          const SizedBox(height: 12),
          ...tips.asMap().entries.map((entry) {
            final idx = entry.key;
            final tip = entry.value;
            return Padding(
              padding: EdgeInsets.only(top: idx == 0 ? 0 : 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 3),
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFF3B82F6),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(tip,
                        style: AppTextStyles.body(14,
                            color: const Color(0xFF1E3A5F))),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
