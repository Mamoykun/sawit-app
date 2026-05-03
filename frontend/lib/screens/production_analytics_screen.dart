import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
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

  static const _kMonthAbbr = [
    'J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'
  ];
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
      final list = await _panenRepo.getByLahan(widget.lahan.id, limit: 100);
      if (mounted) setState(() { _allData = list; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<int> get _years {
    final y = DateTime.now().year;
    return [y - 3, y - 2, y - 1, y, y + 1, y + 2];
  }

  /// Data filtered to the selected year, indexed 0–11 (month 1–12).
  /// Returns a map: month index (0-based) → summed PanenModel-like data.
  Map<int, _MonthData> get _monthMap {
    final data = _allData ?? [];
    final filtered = data.where((p) => p.tahun == _selectedYear).toList();
    final map = <int, _MonthData>{};
    for (final p in filtered) {
      final idx = (p.bulanAngka ?? 1) - 1;
      if (idx < 0 || idx > 11) continue;
      if (map.containsKey(idx)) {
        final e = map[idx]!;
        map[idx] = _MonthData(
          monthIdx: idx,
          bulan: e.bulan,
          tonAktual: e.tonAktual + p.tonAktual,
          targetMin: e.targetMin,
          targetMid: e.targetMid,
          targetMax: e.targetMax,
          luasHa: p.luasHa,
          status: p.status,
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
          status: p.status,
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
                style: AppTextStyles.body(11,
                    color: const Color(0xFF74C69D))),
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
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primaryTint,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.show_chart_rounded,
                    size: 36, color: AppColors.primary3),
              ),
              const SizedBox(height: 20),
              Text('Belum Ada Data', style: AppTextStyles.display(20)),
              const SizedBox(height: 8),
              Text(
                'Tidak ada data panen untuk tahun $_selectedYear',
                style:
                    AppTextStyles.body(13, color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Computed summary values
    final totalTon =
        monthMap.values.fold(0.0, (a, b) => a + b.tonAktual);
    final luasHa = monthMap.values.first.luasHa;
    final yieldTha = luasHa > 0 ? totalTon / luasHa : 0.0;
    final bulanAktif = monthMap.length;
    final avgPerBulan = bulanAktif > 0 ? totalTon / bulanAktif : 0.0;

    // Target reference from first non-zero month
    double refTargetMin = 0;
    double refTargetMax = 0;
    double refTargetMid = 0;
    if (monthMap.isNotEmpty) {
      final first = monthMap.values.first;
      refTargetMin = first.targetMin;
      refTargetMax = first.targetMax;
      refTargetMid = first.targetMid;
    }

    // Status counts
    int countNormal = 0, countWarn = 0, countDanger = 0;
    for (final m in monthMap.values) {
      switch (m.status) {
        case 'normal': countNormal++; break;
        case 'warn': countWarn++; break;
        default: countDanger++; break;
      }
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Section A: Summary cards ──────────────────────────────────
            Row(
              children: [
                Expanded(
                    child: _SummaryCard(
                  label: 'Total Panen',
                  value: totalTon.toStringAsFixed(1),
                  unit: 'ton',
                  color: AppColors.primary,
                )),
                const SizedBox(width: 8),
                Expanded(
                    child: _SummaryCard(
                  label: 'Rata-rata/Bln',
                  value: avgPerBulan.toStringAsFixed(1),
                  unit: 'ton',
                  color: AppColors.primary3,
                )),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                    child: _SummaryCard(
                  label: 'Yield',
                  value: yieldTha.toStringAsFixed(2),
                  unit: 't/ha',
                  color: AppColors.gold,
                )),
                const SizedBox(width: 8),
                Expanded(
                    child: _SummaryCard(
                  label: 'Bulan Aktif',
                  value: '$bulanAktif',
                  unit: 'dari 12',
                  color: AppColors.textMid,
                )),
              ],
            ),
            const SizedBox(height: 20),

            // ── Section B: Tonase 12 bulan (line chart) ───────────────────
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tonase 12 Bulan', style: AppTextStyles.display(15)),
                  const SizedBox(height: 4),
                  Text('$_selectedYear · ton aktual vs zona target',
                      style:
                          AppTextStyles.body(11, color: AppColors.textMuted)),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: _TonaseLineChart(
                      monthMap: monthMap,
                      targetMin: refTargetMin,
                      targetMax: refTargetMax,
                      monthAbbr: _kMonthAbbr,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 14,
                    runSpacing: 6,
                    children: [
                      _ChartLegend(
                          color: AppColors.primary3, label: 'Aktual', line: true),
                      _ChartLegend(
                          color: AppColors.primary3.withOpacity(0.25),
                          label: 'Zona Target',
                          line: false,
                          band: true),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Section C: Yield bar chart ────────────────────────────────
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Yield per Hektar', style: AppTextStyles.display(15)),
                  const SizedBox(height: 4),
                  Text('t/ha per bulan · garis target = ${(refTargetMid / (luasHa > 0 ? luasHa : 1)).toStringAsFixed(2)} t/ha',
                      style:
                          AppTextStyles.body(11, color: AppColors.textMuted)),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 180,
                    child: _YieldBarChart(
                      monthMap: monthMap,
                      targetMid: refTargetMid,
                      luasHa: luasHa,
                      monthAbbr: _kMonthAbbr,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 14,
                    runSpacing: 6,
                    children: [
                      _ChartLegend(
                          color: AppColors.primary3, label: 'Normal'),
                      _ChartLegend(
                          color: AppColors.warn, label: 'Warn'),
                      _ChartLegend(
                          color: AppColors.danger, label: 'Danger'),
                      _ChartLegend(
                          color: AppColors.gold,
                          label: 'Target mid',
                          line: true),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Section D: Akumulasi YTD ──────────────────────────────────
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Akumulasi Panen YTD',
                      style: AppTextStyles.display(15)),
                  const SizedBox(height: 4),
                  Text('Running total Jan–Des $_selectedYear',
                      style:
                          AppTextStyles.body(11, color: AppColors.textMuted)),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 180,
                    child: _CumulativeLineChart(
                      monthMap: monthMap,
                      monthNames: _kMonthNames,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Section E: Pencapaian target ──────────────────────────────
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pencapaian Target', style: AppTextStyles.display(15)),
                  const SizedBox(height: 4),
                  Text('Distribusi status seluruh bulan aktif',
                      style:
                          AppTextStyles.body(11, color: AppColors.textMuted)),
                  const SizedBox(height: 16),
                  if (bulanAktif == 0)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Belum ada data panen'),
                      ),
                    )
                  else ...[
                    _StatusBar(
                      normal: countNormal,
                      warn: countWarn,
                      danger: countDanger,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatusCount(
                            label: 'Normal',
                            count: countNormal,
                            color: AppColors.primary3),
                        _StatusCount(
                            label: 'Warn',
                            count: countWarn,
                            color: AppColors.warn),
                        _StatusCount(
                            label: 'Danger',
                            count: countDanger,
                            color: AppColors.danger),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
}

// ─── Summary card ─────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: AppTextStyles.body(11, color: AppColors.textMuted)),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(value,
                    style: AppTextStyles.mono(22,
                        color: color, weight: FontWeight.w700)),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(unit,
                      style: AppTextStyles.body(11,
                          color: AppColors.textMuted)),
                ),
              ],
            ),
          ],
        ),
      );
}

// ─── Chart legend item ────────────────────────────────────────────────────────

class _ChartLegend extends StatelessWidget {
  final Color color;
  final String label;
  final bool line;
  final bool band;

  const _ChartLegend({
    required this.color,
    required this.label,
    this.line = false,
    this.band = false,
  });

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (band)
            Container(
              width: 18,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            )
          else if (line)
            Container(
              width: 18,
              height: 2,
              color: color,
            )
          else
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          const SizedBox(width: 5),
          Text(label,
              style: AppTextStyles.body(11, color: AppColors.textMuted)),
        ],
      );
}

// ─── Tonase line chart ────────────────────────────────────────────────────────

class _TonaseLineChart extends StatelessWidget {
  final Map<int, _MonthData> monthMap;
  final double targetMin;
  final double targetMax;
  final List<String> monthAbbr;

  const _TonaseLineChart({
    required this.monthMap,
    required this.targetMin,
    required this.targetMax,
    required this.monthAbbr,
  });

  @override
  Widget build(BuildContext context) {
    // Build spots only for months with data (gap for missing)
    final List<List<FlSpot>> segments = [];
    List<FlSpot> current = [];

    for (int i = 0; i < 12; i++) {
      final m = monthMap[i];
      if (m != null) {
        current.add(FlSpot(i.toDouble(), m.tonAktual));
      } else {
        if (current.isNotEmpty) {
          segments.add(List.from(current));
          current = [];
        }
      }
    }
    if (current.isNotEmpty) segments.add(current);

    // Build all spots for maxY computation
    final allTon = monthMap.values.map((m) => m.tonAktual);
    final maxTon = allTon.isEmpty
        ? targetMax
        : allTon.reduce((a, b) => a > b ? a : b);
    final maxY = (maxTon > targetMax ? maxTon : targetMax) * 1.25;

    // Target zone
    final targetMinSpots = List.generate(
        12, (i) => FlSpot(i.toDouble(), targetMin));
    final targetMaxSpots = List.generate(
        12, (i) => FlSpot(i.toDouble(), targetMax));

    final List<LineChartBarData> lines = [];

    // Target band (filled between min and max)
    lines.add(LineChartBarData(
      spots: targetMaxSpots,
      isCurved: false,
      color: Colors.transparent,
      barWidth: 0,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        color: AppColors.primary3.withOpacity(0.18),
        cutOffY: targetMin,
        applyCutOffY: true,
      ),
    ));

    lines.add(LineChartBarData(
      spots: targetMinSpots,
      isCurved: false,
      color: AppColors.primary3.withOpacity(0.35),
      barWidth: 1,
      dotData: const FlDotData(show: false),
      dashArray: [4, 4],
    ));

    // Actual data segments
    for (final seg in segments) {
      lines.add(LineChartBarData(
        spots: seg,
        isCurved: true,
        curveSmoothness: 0.3,
        color: AppColors.primary3,
        barWidth: 2.5,
        dotData: FlDotData(
          show: true,
          getDotPainter: (spot, pct, bar, idx) => FlDotCirclePainter(
            radius: 3.5,
            color: AppColors.primary3,
            strokeWidth: 1.5,
            strokeColor: Colors.white,
          ),
        ),
        belowBarData: BarAreaData(
          show: true,
          color: AppColors.primary3.withOpacity(0.05),
        ),
      ));
    }

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: 11,
        minY: 0,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 4,
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: AppColors.border, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: maxY / 4,
              getTitlesWidget: (v, _) => Text(
                v.toStringAsFixed(0),
                style: AppTextStyles.body(9, color: AppColors.textLight),
              ),
            ),
          ),
          rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (v, _) {
                final idx = v.toInt();
                if (idx < 0 || idx > 11) return const SizedBox.shrink();
                return Text(monthAbbr[idx],
                    style:
                        AppTextStyles.body(9, color: AppColors.textMuted));
              },
            ),
          ),
        ),
        lineBarsData: lines,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: AppColors.primary,
            tooltipRoundedRadius: 8,
            getTooltipItems: (spots) {
              return spots
                  .where((s) => s.barIndex >= 2) // skip target lines
                  .map((s) {
                final mIdx = s.x.toInt();
                final m = monthMap[mIdx];
                final statusEmoji = m == null
                    ? ''
                    : m.status == 'normal'
                        ? ' ✓'
                        : m.status == 'warn'
                            ? ' ⚠'
                            : ' ✗';
                final name = mIdx >= 0 && mIdx < 12
                    ? ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'][mIdx]
                    : '';
                return LineTooltipItem(
                  '$name: ${s.y.toStringAsFixed(1)} ton$statusEmoji',
                  AppTextStyles.body(10, color: Colors.white),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
}

// ─── Yield bar chart ──────────────────────────────────────────────────────────

class _YieldBarChart extends StatelessWidget {
  final Map<int, _MonthData> monthMap;
  final double targetMid;
  final double luasHa;
  final List<String> monthAbbr;

  const _YieldBarChart({
    required this.monthMap,
    required this.targetMid,
    required this.luasHa,
    required this.monthAbbr,
  });

  @override
  Widget build(BuildContext context) {
    final targetYield = luasHa > 0 ? targetMid / luasHa : 0.0;
    final groups = <BarChartGroupData>[];
    double maxY = targetYield * 1.5;

    for (int i = 0; i < 12; i++) {
      final m = monthMap[i];
      final yieldVal = m != null && luasHa > 0 ? m.tonAktual / luasHa : 0.0;
      if (yieldVal > maxY) maxY = yieldVal * 1.2;

      final color = m == null
          ? AppColors.border
          : m.status == 'normal'
              ? AppColors.primary3
              : m.status == 'warn'
                  ? AppColors.warn
                  : AppColors.danger;

      groups.add(BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: m != null ? yieldVal : 0,
            color: color,
            width: 14,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      ));
    }

    if (maxY <= 0) maxY = 1;

    return Stack(
      children: [
        BarChart(
          BarChartData(
            maxY: maxY,
            minY: 0,
            barGroups: groups,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: maxY / 4,
              getDrawingHorizontalLine: (_) =>
                  const FlLine(color: AppColors.border, strokeWidth: 1),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  interval: maxY / 4,
                  getTitlesWidget: (v, _) => Text(
                    v.toStringAsFixed(1),
                    style: AppTextStyles.body(9, color: AppColors.textLight),
                  ),
                ),
              ),
              rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 22,
                  getTitlesWidget: (v, _) {
                    final idx = v.toInt();
                    if (idx < 0 || idx > 11) return const SizedBox.shrink();
                    return Text(monthAbbr[idx],
                        style: AppTextStyles.body(9,
                            color: AppColors.textMuted));
                  },
                ),
              ),
            ),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                tooltipBgColor: AppColors.primary,
                tooltipRoundedRadius: 8,
                getTooltipItem: (group, gi, rod, ri) {
                  final idx = group.x;
                  final m = monthMap[idx];
                  final name = idx >= 0 && idx < 12
                      ? ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'][idx]
                      : '';
                  if (m == null) return null;
                  return BarTooltipItem(
                    '$name\n${rod.toY.toStringAsFixed(2)} t/ha',
                    AppTextStyles.body(10, color: Colors.white),
                  );
                },
              ),
            ),
          ),
        ),
        // Target mid dashed reference line overlay
        if (targetYield > 0 && maxY > 0)
          Positioned.fill(
            child: LayoutBuilder(builder: (context, constraints) {
              final chartHeight = constraints.maxHeight - 22; // minus x-axis
              final fraction = (targetYield / maxY).clamp(0.0, 1.0);
              final topPos = chartHeight * (1 - fraction);
              return Stack(
                children: [
                  Positioned(
                    top: topPos,
                    left: 40,
                    right: 0,
                    child: _DashedLine(color: AppColors.gold),
                  ),
                ],
              );
            }),
          ),
      ],
    );
  }
}

// ─── Cumulative line chart ────────────────────────────────────────────────────

class _CumulativeLineChart extends StatelessWidget {
  final Map<int, _MonthData> monthMap;
  final List<String> monthNames;

  const _CumulativeLineChart({
    required this.monthMap,
    required this.monthNames,
  });

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[];
    double running = 0;
    int lastMonth = -1;

    for (int i = 0; i < 12; i++) {
      final m = monthMap[i];
      if (m != null) {
        running += m.tonAktual;
        spots.add(FlSpot(i.toDouble(), running));
        lastMonth = i;
      }
    }

    if (spots.isEmpty) {
      return const Center(child: Text('Belum ada data'));
    }

    final maxY = running * 1.25;

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: lastMonth.toDouble(),
        minY: 0,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 4,
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: AppColors.border, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              interval: maxY / 4,
              getTitlesWidget: (v, _) => Text(
                v.toStringAsFixed(0),
                style: AppTextStyles.body(9, color: AppColors.textLight),
              ),
            ),
          ),
          rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (v, _) {
                final idx = v.toInt();
                if (idx < 0 || idx > 11) return const SizedBox.shrink();
                // Only show label if we have data for this month
                if (!monthMap.containsKey(idx)) return const SizedBox.shrink();
                return Text(
                    idx < monthNames.length ? monthNames[idx] : '',
                    style:
                        AppTextStyles.body(9, color: AppColors.textMuted));
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: AppColors.primary3,
            barWidth: 2.5,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, pct, bar, idx) => FlDotCirclePainter(
                radius: 3.5,
                color: AppColors.primary3,
                strokeWidth: 1.5,
                strokeColor: Colors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primary3.withOpacity(0.22),
                  AppColors.primary3.withOpacity(0.02),
                ],
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: AppColors.primary,
            tooltipRoundedRadius: 8,
            getTooltipItems: (spots) => spots.map((s) {
              final idx = s.x.toInt();
              final name =
                  idx >= 0 && idx < monthNames.length ? monthNames[idx] : '';
              return LineTooltipItem(
                '$name (kum.)\n${s.y.toStringAsFixed(1)} ton',
                AppTextStyles.body(10, color: Colors.white),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// ─── Status stacked bar ───────────────────────────────────────────────────────

class _StatusBar extends StatelessWidget {
  final int normal;
  final int warn;
  final int danger;

  const _StatusBar(
      {required this.normal, required this.warn, required this.danger});

  @override
  Widget build(BuildContext context) {
    final total = normal + warn + danger;
    if (total == 0) return const SizedBox.shrink();
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      return ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: Row(
          children: [
            if (normal > 0)
              Container(
                width: w * normal / total,
                height: 24,
                color: AppColors.primary3,
              ),
            if (warn > 0)
              Container(
                width: w * warn / total,
                height: 24,
                color: AppColors.warn,
              ),
            if (danger > 0)
              Container(
                width: w * danger / total,
                height: 24,
                color: AppColors.danger,
              ),
          ],
        ),
      );
    });
  }
}

class _StatusCount extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatusCount(
      {required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text('$count',
              style: AppTextStyles.mono(22,
                  color: color, weight: FontWeight.w700)),
          Text(label,
              style: AppTextStyles.body(11, color: AppColors.textMuted)),
          Text('bulan',
              style: AppTextStyles.body(10, color: AppColors.textLight)),
        ],
      );
}

// ─── Dashed line ──────────────────────────────────────────────────────────────

class _DashedLine extends StatelessWidget {
  final Color color;
  const _DashedLine({required this.color});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          const dashWidth = 5.0;
          const dashGap = 4.0;
          final count =
              (constraints.maxWidth / (dashWidth + dashGap)).floor();
          return SizedBox(
            height: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                count,
                (_) => SizedBox(
                  width: dashWidth,
                  height: 2,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
}
