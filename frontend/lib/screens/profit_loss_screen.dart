import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../models/lahan_model.dart';
import '../models/biaya_model.dart';
import '../services/api_service.dart';
import '../widgets/common_widgets.dart';
import '../widgets/offline_banner.dart';

class ProfitLossScreen extends StatefulWidget {
  final LahanModel lahan;

  const ProfitLossScreen({super.key, required this.lahan});

  @override
  State<ProfitLossScreen> createState() => _ProfitLossScreenState();
}

class _ProfitLossScreenState extends State<ProfitLossScreen> {
  late final ApiService _api;
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;
  late int _selectedYear;

  static const _kMonthAbbr = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];

  @override
  void initState() {
    super.initState();
    _api = ApiService();
    _selectedYear = DateTime.now().year;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await _api.getProfitLoss(widget.lahan.id, year: _selectedYear);
      setState(() { _data = data; _loading = false; });
    } catch (_) {
      setState(() { _error = 'Gagal memuat data'; _loading = false; });
    }
  }

  // ── Currency formatter ──────────────────────────────────────────────────────
  String _fmt(double v) {
    final abs = v.abs();
    final prefix = v < 0 ? '-' : '';
    if (abs >= 1e9) return '${prefix}Rp ${(abs / 1e9).toStringAsFixed(1)} M';
    if (abs >= 1e6) return '${prefix}Rp ${(abs / 1e6).toStringAsFixed(1)} jt';
    return '${prefix}Rp ${abs.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  List<int> get _years {
    final y = DateTime.now().year;
    return [y - 3, y - 2, y - 1, y, y + 1, y + 2];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Untung Rugi',
                style: AppTextStyles.display(18, color: Colors.white)),
            Text(widget.lahan.namaLahan,
                style: AppTextStyles.body(11, color: const Color(0xFF74C69D))),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
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
              items: _years.map((y) => DropdownMenuItem(
                value: y,
                child: Text('$y',
                    style: AppTextStyles.body(13,
                        color: Colors.white, weight: FontWeight.w600)),
              )).toList(),
              onChanged: (y) {
                if (y != null && y != _selectedYear) {
                  setState(() => _selectedYear = y);
                  _loadData();
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
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off_rounded,
                  size: 48, color: AppColors.textLight),
              const SizedBox(height: 16),
              Text(_error!,
                  style: AppTextStyles.body(14, color: AppColors.textMid),
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              PrimaryButton(label: 'Coba Lagi', onTap: _loadData),
            ],
          ),
        ),
      );
    }

    final d = _data!;
    final totalRevenue = (d['totalRevenue'] as num?)?.toDouble() ?? 0.0;
    final totalExpenses = (d['totalExpenses'] as num?)?.toDouble() ?? 0.0;
    final netProfit = (d['netProfit'] as num?)?.toDouble() ?? 0.0;
    final profitMarginRaw = d['profitMargin'];
    final profitMargin = profitMarginRaw != null
        ? (profitMarginRaw as num).toDouble()
        : null;

    final monthly = (d['monthly'] as List?) ?? [];
    final expensesByKategori =
        (d['expensesByKategori'] as Map<String, dynamic>?) ?? {};

    // True empty state: all zeros
    final allZero = totalRevenue == 0.0 && totalExpenses == 0.0;

    if (allZero) {
      return _EmptyState(year: _selectedYear);
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primary,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Summary Cards ──────────────────────────────────────────────
            _buildSummaryRow(
                totalRevenue, totalExpenses, netProfit, profitMargin),
            const SizedBox(height: 20),

            // ── Revenue vs Expenses Line Chart ─────────────────────────────
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pendapatan vs Pengeluaran per Bulan',
                      style: AppTextStyles.display(15)),
                  const SizedBox(height: 4),
                  Text('$_selectedYear',
                      style: AppTextStyles.body(11,
                          color: AppColors.textMuted)),
                  const SizedBox(height: 12),
                  _buildLegendRow([
                    _LegendItem('Pendapatan', AppColors.primary3),
                    _LegendItem('Pengeluaran', AppColors.danger),
                  ]),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: _buildLineChart(monthly),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Profit per Bulan Bar Chart ─────────────────────────────────
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Profit per Bulan',
                      style: AppTextStyles.display(15)),
                  const SizedBox(height: 4),
                  Text('Hijau = untung, Merah = rugi',
                      style: AppTextStyles.body(11,
                          color: AppColors.textMuted)),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 180,
                    child: _buildProfitBarChart(monthly),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Expenses Breakdown ─────────────────────────────────────────
            if (totalExpenses > 0)
              _buildExpensesBreakdown(expensesByKategori, totalExpenses),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(double revenue, double expenses, double profit,
      double? margin) {
    final profitColor =
        profit >= 0 ? AppColors.primary3 : AppColors.danger;
    final marginColor =
        (margin != null && margin >= 0) ? AppColors.primary3 : AppColors.danger;

    return Row(
      children: [
        Expanded(
          child: _SmallMetricCard(
            label: 'Pendapatan',
            value: _fmt(revenue),
            color: AppColors.primary3,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SmallMetricCard(
            label: 'Pengeluaran',
            value: _fmt(expenses),
            color: AppColors.danger,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SmallMetricCard(
            label: 'Profit',
            value: _fmt(profit),
            color: profitColor,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SmallMetricCard(
            label: 'Margin',
            value: margin != null
                ? '${margin.toStringAsFixed(1)}%'
                : '—',
            color: marginColor,
          ),
        ),
      ],
    );
  }

  Widget _buildLineChart(List monthly) {
    final revenueSpots = <FlSpot>[];
    final expenseSpots = <FlSpot>[];

    for (int i = 0; i < monthly.length; i++) {
      final m = monthly[i] as Map<String, dynamic>;
      final rev = (m['revenue'] as num?)?.toDouble() ?? 0.0;
      final exp = (m['expenses'] as num?)?.toDouble() ?? 0.0;
      revenueSpots.add(FlSpot(i.toDouble(), rev));
      expenseSpots.add(FlSpot(i.toDouble(), exp));
    }

    final allValues = [
      ...revenueSpots.map((s) => s.y),
      ...expenseSpots.map((s) => s.y),
    ];
    final maxY = allValues.isEmpty
        ? 1.0
        : (allValues.reduce((a, b) => a > b ? a : b) * 1.2).clamp(1.0, double.infinity);

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
          getDrawingHorizontalLine: (_) => FlLine(
            color: AppColors.border,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 48,
              interval: maxY / 4,
              getTitlesWidget: (v, _) => Text(
                v >= 1e6
                    ? '${(v / 1e6).toStringAsFixed(0)}jt'
                    : v >= 1e3
                        ? '${(v / 1e3).toStringAsFixed(0)}k'
                        : v.toStringAsFixed(0),
                style: AppTextStyles.body(9, color: AppColors.textLight),
              ),
            ),
          ),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (v, _) {
                final idx = v.toInt();
                if (idx < 0 || idx > 11) return const SizedBox.shrink();
                return Text(_kMonthAbbr[idx],
                    style:
                        AppTextStyles.body(9, color: AppColors.textMuted));
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: revenueSpots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: AppColors.primary3,
            barWidth: 2.5,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, pct, bar, idx) => FlDotCirclePainter(
                radius: 3,
                color: AppColors.primary3,
                strokeWidth: 1.5,
                strokeColor: Colors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primary3.withOpacity(0.06),
            ),
          ),
          LineChartBarData(
            spots: expenseSpots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: AppColors.danger,
            barWidth: 2.5,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, pct, bar, idx) => FlDotCirclePainter(
                radius: 3,
                color: AppColors.danger,
                strokeWidth: 1.5,
                strokeColor: Colors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.danger.withOpacity(0.04),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: AppColors.primary,
            tooltipRoundedRadius: 8,
            getTooltipItems: (spots) => spots.map((s) {
              final label =
                  s.barIndex == 0 ? 'Pendapatan' : 'Pengeluaran';
              return LineTooltipItem(
                '$label\n${_fmt(s.y)}',
                AppTextStyles.body(10, color: Colors.white),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildProfitBarChart(List monthly) {
    final groups = <BarChartGroupData>[];
    double maxAbs = 1.0;

    for (int i = 0; i < monthly.length; i++) {
      final m = monthly[i] as Map<String, dynamic>;
      final profit = (m['profit'] as num?)?.toDouble() ?? 0.0;
      if (profit.abs() > maxAbs) maxAbs = profit.abs();
      groups.add(BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: profit,
            fromY: 0,
            color: profit >= 0 ? AppColors.primary3 : AppColors.danger,
            width: 14,
            borderRadius: profit >= 0
                ? const BorderRadius.vertical(top: Radius.circular(4))
                : const BorderRadius.vertical(bottom: Radius.circular(4)),
          ),
        ],
      ));
    }

    final chartMax = maxAbs * 1.3;

    return BarChart(
      BarChartData(
        minY: -chartMax,
        maxY: chartMax,
        barGroups: groups,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: chartMax / 3,
          getDrawingHorizontalLine: (v) => FlLine(
            color: v == 0
                ? AppColors.borderDark
                : AppColors.border,
            strokeWidth: v == 0 ? 1.5 : 1,
            dashArray: v == 0 ? null : [4, 4],
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 48,
              interval: chartMax / 3,
              getTitlesWidget: (v, _) => Text(
                v >= 1e6
                    ? '${(v / 1e6).toStringAsFixed(0)}jt'
                    : v >= 1e3
                        ? '${(v / 1e3).toStringAsFixed(0)}k'
                        : v.toStringAsFixed(0),
                style: AppTextStyles.body(9, color: AppColors.textLight),
              ),
            ),
          ),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (v, _) {
                final idx = v.toInt();
                if (idx < 0 || idx > 11) return const SizedBox.shrink();
                return Text(_kMonthAbbr[idx],
                    style: AppTextStyles.body(9, color: AppColors.textMuted));
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: AppColors.primary,
            tooltipRoundedRadius: 8,
            getTooltipItem: (group, gi, rod, ri) {
              final m = monthly[group.x] as Map<String, dynamic>;
              final bulan = m['bulan'] as String? ?? '';
              return BarTooltipItem(
                '$bulan\n${_fmt(rod.toY)}',
                AppTextStyles.body(10, color: Colors.white),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildExpensesBreakdown(
      Map<String, dynamic> expensesByKategori, double totalExpenses) {
    final items = KategoriBiaya.values.map((k) {
      final amount =
          (expensesByKategori[k.code] as num?)?.toDouble() ?? 0.0;
      final pct = totalExpenses > 0 ? (amount / totalExpenses) * 100.0 : 0.0;
      return _KategoriItem(label: k.label, amount: amount, pct: pct);
    }).where((item) => item.amount > 0).toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    if (items.isEmpty) return const SizedBox.shrink();

    const colors = [
      AppColors.primary3,
      AppColors.gold,
      AppColors.danger,
      AppColors.accent,
      AppColors.textMuted,
    ];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Rincian Pengeluaran',
              style: AppTextStyles.display(15)),
          const SizedBox(height: 4),
          Text('Total: ${_fmt(totalExpenses)}',
              style: AppTextStyles.body(12, color: AppColors.textMuted)),
          const SizedBox(height: 16),
          ...items.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            final color = colors[idx % colors.length];
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(item.label,
                              style: AppTextStyles.body(13,
                                  color: AppColors.textMid,
                                  weight: FontWeight.w600)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(_fmt(item.amount),
                              style: AppTextStyles.mono(13,
                                  color: AppColors.text,
                                  weight: FontWeight.w700)),
                          Text('${item.pct.toStringAsFixed(1)}%',
                              style: AppTextStyles.body(10,
                                  color: AppColors.textMuted)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: (item.pct / 100).clamp(0.0, 1.0),
                      backgroundColor: AppColors.surfaceAlt,
                      valueColor: AlwaysStoppedAnimation(color),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLegendRow(List<_LegendItem> items) => Row(
        children: items
            .map((item) => Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: item.color,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(item.label,
                          style: AppTextStyles.body(11,
                              color: AppColors.textMid,
                              weight: FontWeight.w500)),
                    ],
                  ),
                ))
            .toList(),
      );
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

class _SmallMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SmallMetricCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 20,
              height: 3,
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(99)),
            ),
            const SizedBox(height: 8),
            Text(value,
                style: AppTextStyles.mono(12,
                    color: color, weight: FontWeight.w700),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(label.toUpperCase(),
                style: AppTextStyles.body(8, color: AppColors.textMuted,
                    weight: FontWeight.w600)),
          ],
        ),
      );
}

class _EmptyState extends StatelessWidget {
  final int year;
  const _EmptyState({required this.year});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('📊', style: TextStyle(fontSize: 52)),
              const SizedBox(height: 16),
              Text('Belum Ada Data untuk $year',
                  style: AppTextStyles.display(18)),
              const SizedBox(height: 8),
              Text(
                'Input data panen dan biaya untuk melihat laporan untung rugi.',
                style: AppTextStyles.body(13, color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
}

class _LegendItem {
  final String label;
  final Color color;
  const _LegendItem(this.label, this.color);
}

class _KategoriItem {
  final String label;
  final double amount;
  final double pct;
  const _KategoriItem(
      {required this.label, required this.amount, required this.pct});
}
