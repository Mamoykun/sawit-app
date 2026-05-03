import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../models/lahan_model.dart';
import '../models/panen_model.dart';
import '../services/api_service.dart';
import '../repositories/lahan_repository.dart';
import '../repositories/panen_repository.dart';
import '../main.dart' show appDb;
import '../widgets/empty_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class PerbandinganScreen extends StatefulWidget {
  const PerbandinganScreen({super.key});

  @override
  State<PerbandinganScreen> createState() => _PerbandinganScreenState();
}

class _PerbandinganScreenState extends State<PerbandinganScreen> {
  late final LahanRepository _lahanRepo;
  late final PanenRepository _panenRepo;

  List<LahanModel>? _lahanList;
  Map<int, List<PanenModel>> _panenByLahan = {};
  bool _loading = true;

  /// 'tonase' | 'yield' | 'konsistensi'
  String _activeMetric = 'tonase';

  @override
  void initState() {
    super.initState();
    _lahanRepo = LahanRepository(db: appDb, api: ApiService());
    _panenRepo = PanenRepository(db: appDb, api: ApiService());
    _load();
  }

  // ── Data loading ────────────────────────────────────────────────────────────

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await _lahanRepo.getAll();
      final map = <int, List<PanenModel>>{};
      for (final lahan in list) {
        final panens = await _panenRepo.getByLahan(lahan.id, limit: 6);
        // Sort oldest → newest for sparkline
        final sorted = [...panens]
          ..sort((a, b) {
            final ay = (a.tahun ?? 0) * 12 + (a.bulanAngka ?? 0);
            final by = (b.tahun ?? 0) * 12 + (b.bulanAngka ?? 0);
            return ay.compareTo(by);
          });
        map[lahan.id] = sorted;
      }
      if (mounted) {
        setState(() {
          _lahanList = list;
          _panenByLahan = map;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _lahanList ??= [];
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Gagal memuat data perbandingan'),
          backgroundColor: AppColors.danger,
        ));
      }
    }
  }

  // ── Metric helpers ──────────────────────────────────────────────────────────

  double _avgTonase(int lahanId) {
    final list = _panenByLahan[lahanId] ?? [];
    if (list.isEmpty) return 0;
    return list.fold<double>(0, (s, p) => s + p.tonAktual) / list.length;
  }

  double _avgYield(int lahanId, double luasHa) {
    if (luasHa <= 0) return 0;
    return _avgTonase(lahanId) / luasHa;
  }

  double _konsistensi(int lahanId) {
    final list = _panenByLahan[lahanId] ?? [];
    if (list.isEmpty) return 0;
    final normal = list.where((p) => p.status == 'normal').length;
    return normal / list.length * 100;
  }

  double _metricValue(LahanModel l) {
    switch (_activeMetric) {
      case 'yield':
        return _avgYield(l.id, l.luasHa);
      case 'konsistensi':
        return _konsistensi(l.id);
      default:
        return _avgTonase(l.id);
    }
  }

  String _metricUnit() => switch (_activeMetric) {
        'yield' => 't/ha',
        'konsistensi' => '%',
        _ => 'ton',
      };

  String _metricLabel() => switch (_activeMetric) {
        'yield' => 'Yield Rata-rata',
        'konsistensi' => 'Konsistensi (Bulan Normal)',
        _ => 'Tonase Rata-rata',
      };

  // ── Color by quartile within sorted list ────────────────────────────────────

  Color _barColor(int rank, int total) {
    if (total <= 1) return AppColors.primary3;
    final q = rank / (total - 1); // 0.0 = best, 1.0 = worst
    if (q <= 0.25) return AppColors.primary3;
    if (q <= 0.60) return AppColors.warn;
    return AppColors.danger;
  }

  // ── Build ───────────────────────────────────────────────────────────────────

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
        title: Text('Perbandingan Lahan',
            style: AppTextStyles.display(18, color: Colors.white)),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    final list = _lahanList ?? [];
    if (list.length < 2) {
      return EmptyState.icon(
        iconData: Icons.compare_arrows_rounded,
        title: 'Butuh Minimal 2 Kebun',
        message:
            'Tambah kebun lain dulu untuk membandingkan kinerja antar lahan.',
        accent: const Color(0xFF2563EB),
      );
    }

    // Sort desc by active metric
    final sorted = [...list]
      ..sort((a, b) => _metricValue(b).compareTo(_metricValue(a)));

    final maxVal = sorted.fold<double>(
        0, (m, l) => _metricValue(l) > m ? _metricValue(l) : m);
    final avgVal = sorted.isEmpty
        ? 0.0
        : sorted.fold<double>(0, (s, l) => s + _metricValue(l)) /
            sorted.length;

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${list.length} kebun aktif',
                style: AppTextStyles.body(13, color: AppColors.textMuted)),
            const SizedBox(height: 16),

            // ── Section 1: Metric switcher ──────────────────────────────────
            _buildMetricSwitcher(),
            const SizedBox(height: 20),

            // ── Section 2: Insight cards ────────────────────────────────────
            _buildInsightRow(sorted, avgVal),
            const SizedBox(height: 20),

            // ── Section 3: Bar + sparkline chart ────────────────────────────
            Text(_metricLabel().toUpperCase(), style: AppTextStyles.label()),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
                boxShadow: Elevations.level1,
              ),
              child: Column(
                children: sorted.asMap().entries.map((e) {
                  final rank = e.key;
                  final lahan = e.value;
                  final val = _metricValue(lahan);
                  final pct = maxVal > 0 ? val / maxVal : 0.0;
                  final color = _barColor(rank, sorted.length);
                  return _LahanRow(
                    lahan: lahan,
                    value: val,
                    percentage: pct,
                    unit: _metricUnit(),
                    color: color,
                    sparklineData: _panenByLahan[lahan.id] ?? [],
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            // ── Section 4: Detail Compare CTA ───────────────────────────────
            _buildDetailCompareCta(list),
          ],
        ),
      ),
    );
  }

  // ── Metric switcher ─────────────────────────────────────────────────────────

  Widget _buildMetricSwitcher() {
    return Row(
      children: [
        _MetricChip(
          label: 'Tonase',
          selected: _activeMetric == 'tonase',
          onTap: () => setState(() => _activeMetric = 'tonase'),
        ),
        const SizedBox(width: 8),
        _MetricChip(
          label: 'Yield',
          selected: _activeMetric == 'yield',
          onTap: () => setState(() => _activeMetric = 'yield'),
        ),
        const SizedBox(width: 8),
        _MetricChip(
          label: 'Konsistensi',
          selected: _activeMetric == 'konsistensi',
          onTap: () => setState(() => _activeMetric = 'konsistensi'),
        ),
      ],
    );
  }

  // ── Insight cards ───────────────────────────────────────────────────────────

  Widget _buildInsightRow(List<LahanModel> sorted, double avgVal) {
    final unit = _metricUnit();
    final label = _metricLabel();
    final top = sorted.first;
    final topVal = _metricValue(top);
    final bottom = sorted.last;
    final bottomVal = _metricValue(bottom);
    final isUnderperformer = avgVal > 0 && bottomVal < avgVal * 0.80;

    final cards = <Widget>[
      _InsightCard(
        icon: '🏆',
        title: 'Top Performer',
        body: '${top.namaLahan} punya $label tertinggi: '
            '${topVal.toStringAsFixed(1)} $unit',
        color: AppColors.primary3,
      ),
      if (isUnderperformer)
        _InsightCard(
          icon: '📉',
          title: 'Perlu Perhatian',
          body: '${bottom.namaLahan} terendah: '
              '${bottomVal.toStringAsFixed(1)} $unit — perlu perhatian',
          color: AppColors.danger,
        ),
      _InsightCard(
        icon: '📊',
        title: 'Rata-rata',
        body:
            'Rata-rata $label: ${avgVal.toStringAsFixed(1)} $unit dari ${sorted.length} kebun',
        color: AppColors.textMid,
      ),
    ];

    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cards.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) => SizedBox(width: 240, child: cards[i]),
      ),
    );
  }

  // ── Detail Compare CTA ──────────────────────────────────────────────────────

  Widget _buildDetailCompareCta(List<LahanModel> list) {
    return GestureDetector(
      onTap: () => _openCompareSheet(list),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primary2],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: Elevations.primaryGlow(AppColors.primary),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.compare_arrows_rounded,
                  color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Bandingkan 2 Kebun',
                      style: AppTextStyles.display(14, color: Colors.white)),
                  const SizedBox(height: 2),
                  Text('Lihat statistik head-to-head & tren tumpang tindih',
                      style: AppTextStyles.body(11,
                          color: Colors.white.withOpacity(0.75))),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: Colors.white70, size: 22),
          ],
        ),
      ),
    );
  }

  void _openCompareSheet(List<LahanModel> list) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CompareSheet(
        lahanList: list,
        panenByLahan: _panenByLahan,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _MetricChip
// ─────────────────────────────────────────────────────────────────────────────

class _MetricChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _MetricChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(Radii.pill),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.body(12,
              color: selected ? Colors.white : AppColors.textMuted,
              weight: FontWeight.w600),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _InsightCard
// ─────────────────────────────────────────────────────────────────────────────

class _InsightCard extends StatelessWidget {
  final String icon;
  final String title;
  final String body;
  final Color color;

  const _InsightCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
        boxShadow: Elevations.level1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(title,
                  style: AppTextStyles.body(11,
                      color: color, weight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Text(
              body,
              style: AppTextStyles.body(11, color: AppColors.text),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _LahanRow  (bar + sparkline)
// ─────────────────────────────────────────────────────────────────────────────

class _LahanRow extends StatelessWidget {
  final LahanModel lahan;
  final double value;
  final double percentage;
  final String unit;
  final Color color;
  final List<PanenModel> sparklineData;

  const _LahanRow({
    required this.lahan,
    required this.value,
    required this.percentage,
    required this.unit,
    required this.color,
    required this.sparklineData,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: name + value
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                          color: color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(lahan.namaLahan,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.body(13,
                              color: AppColors.text,
                              weight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              Text('${value.toStringAsFixed(1)} $unit',
                  style: AppTextStyles.mono(13,
                      color: color, weight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 6),
          // Row 2: progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: percentage.clamp(0.04, 1.0),
              minHeight: 10,
              backgroundColor: AppColors.surfaceAlt,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 8),
          // Row 3: sparkline
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 28,
                  child: _Sparkline(data: sparklineData, color: color),
                ),
              ),
              const SizedBox(width: 8),
              Text('6 bln terakhir',
                  style: AppTextStyles.body(9, color: AppColors.textLight)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _Sparkline  (tiny fl_chart LineChart)
// ─────────────────────────────────────────────────────────────────────────────

class _Sparkline extends StatelessWidget {
  final List<PanenModel> data;
  final Color color;

  const _Sparkline({required this.data, required this.color});

  @override
  Widget build(BuildContext context) {
    if (data.length < 2) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Text('Belum cukup data',
            style: AppTextStyles.body(9, color: AppColors.textLight)),
      );
    }

    final spots = data.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.tonAktual);
    }).toList();

    final maxY = data.fold<double>(0, (m, p) => p.tonAktual > m ? p.tonAktual : m);
    final minY = data.fold<double>(double.infinity, (m, p) => p.tonAktual < m ? p.tonAktual : m);
    final yRange = (maxY - minY).clamp(1.0, double.infinity);

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (data.length - 1).toDouble(),
        minY: minY - yRange * 0.15,
        maxY: maxY + yRange * 0.15,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.35,
            color: color,
            barWidth: 1.5,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, pct, bar, idx) => FlDotCirclePainter(
                radius: 2,
                color: color,
                strokeWidth: 0,
                strokeColor: Colors.transparent,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  color.withOpacity(0.20),
                  color.withOpacity(0.02),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _CompareSheet  (side-by-side bottom sheet)
// ─────────────────────────────────────────────────────────────────────────────

class _CompareSheet extends StatefulWidget {
  final List<LahanModel> lahanList;
  final Map<int, List<PanenModel>> panenByLahan;

  const _CompareSheet({
    required this.lahanList,
    required this.panenByLahan,
  });

  @override
  State<_CompareSheet> createState() => _CompareSheetState();
}

class _CompareSheetState extends State<_CompareSheet> {
  final List<LahanModel> _selected = [];

  double _avgTonase(int id) {
    final list = widget.panenByLahan[id] ?? [];
    if (list.isEmpty) return 0;
    return list.fold<double>(0, (s, p) => s + p.tonAktual) / list.length;
  }

  double _avgYield(int id, double luasHa) {
    if (luasHa <= 0) return 0;
    return _avgTonase(id) / luasHa;
  }

  double _konsistensi(int id) {
    final list = widget.panenByLahan[id] ?? [];
    if (list.isEmpty) return 0;
    final n = list.where((p) => p.status == 'normal').length;
    return n / list.length * 100;
  }

  @override
  Widget build(BuildContext context) {
    final isComparing = _selected.length == 2;

    return DraggableScrollableSheet(
      initialChildSize: isComparing ? 0.90 : 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollCtrl) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(Radii.xl)),
          ),
          child: Column(
            children: [
              // Handle
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text('Bandingkan 2 Kebun',
                        style: AppTextStyles.display(16)),
                    const Spacer(),
                    if (_selected.isNotEmpty)
                      TextButton(
                        onPressed: () => setState(() => _selected.clear()),
                        child: Text('Reset',
                            style: AppTextStyles.body(12,
                                color: AppColors.danger,
                                weight: FontWeight.w600)),
                      ),
                  ],
                ),
              ),
              if (!isComparing) ...[
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Text(
                    'Pilih ${2 - _selected.length} kebun lagi',
                    style:
                        AppTextStyles.body(12, color: AppColors.textMuted),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Expanded(
                child: isComparing
                    ? _buildComparison(
                        scrollCtrl, _selected[0], _selected[1])
                    : _buildPicker(scrollCtrl),
              ),
            ],
          ),
        );
      },
    );
  }

  // Lahan picker list
  Widget _buildPicker(ScrollController ctrl) {
    return ListView.separated(
      controller: ctrl,
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      itemCount: widget.lahanList.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final lahan = widget.lahanList[i];
        final isSel = _selected.contains(lahan);
        final isDisabled = !isSel && _selected.length >= 2;
        return GestureDetector(
          onTap: isDisabled
              ? null
              : () => setState(() {
                    if (isSel) {
                      _selected.remove(lahan);
                    } else {
                      _selected.add(lahan);
                    }
                  }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isSel
                  ? AppColors.primaryTint
                  : isDisabled
                      ? AppColors.surfaceAlt
                      : AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSel ? AppColors.primary3 : AppColors.border,
                width: isSel ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isSel
                        ? AppColors.primary3.withOpacity(0.2)
                        : AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isSel
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked,
                    color: isSel ? AppColors.primary3 : AppColors.textLight,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(lahan.namaLahan,
                          style: AppTextStyles.body(13,
                              color: isDisabled
                                  ? AppColors.textLight
                                  : AppColors.text,
                              weight: FontWeight.w600)),
                      Text(
                          '${lahan.luasHa.toStringAsFixed(1)} ha · usia ${lahan.usiaPohon} thn',
                          style: AppTextStyles.body(11,
                              color: AppColors.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Side-by-side comparison
  Widget _buildComparison(
      ScrollController ctrl, LahanModel a, LahanModel b) {
    final tA = _avgTonase(a.id);
    final tB = _avgTonase(b.id);
    final yA = _avgYield(a.id, a.luasHa);
    final yB = _avgYield(b.id, b.luasHa);
    final kA = _konsistensi(a.id);
    final kB = _konsistensi(b.id);

    final rows = <_CompareRow>[
      _CompareRow(
          label: 'Tonase Rata-rata',
          valA: '${tA.toStringAsFixed(1)} ton',
          valB: '${tB.toStringAsFixed(1)} ton',
          winA: tA >= tB),
      _CompareRow(
          label: 'Yield Rata-rata',
          valA: '${yA.toStringAsFixed(2)} t/ha',
          valB: '${yB.toStringAsFixed(2)} t/ha',
          winA: yA >= yB),
      _CompareRow(
          label: 'Konsistensi',
          valA: '${kA.toStringAsFixed(0)}%',
          valB: '${kB.toStringAsFixed(0)}%',
          winA: kA >= kB),
      _CompareRow(
          label: 'Status Terkini',
          valA: a.statusTerkini ?? '-',
          valB: b.statusTerkini ?? '-',
          winA: (a.statusTerkini ?? '').toLowerCase() == 'normal'),
      _CompareRow(
          label: 'Luas Lahan',
          valA: '${a.luasHa.toStringAsFixed(1)} ha',
          valB: '${b.luasHa.toStringAsFixed(1)} ha',
          winA: a.luasHa >= b.luasHa),
      _CompareRow(
          label: 'Usia Pohon',
          valA: '${a.usiaPohon} thn',
          valB: '${b.usiaPohon} thn',
          winA: a.usiaPohon >= b.usiaPohon),
    ];

    // Sparkline data for overlay chart
    final dataA = widget.panenByLahan[a.id] ?? [];
    final dataB = widget.panenByLahan[b.id] ?? [];

    return SingleChildScrollView(
      controller: ctrl,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              const SizedBox(width: 140),
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.primary3.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text('A',
                            style: TextStyle(
                                color: AppColors.primary3,
                                fontWeight: FontWeight.w800,
                                fontSize: 14)),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(a.namaLahan,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body(11,
                            color: AppColors.text,
                            weight: FontWeight.w700),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.gold.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text('B',
                            style: TextStyle(
                                color: AppColors.gold,
                                fontWeight: FontWeight.w800,
                                fontSize: 14)),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(b.namaLahan,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body(11,
                            color: AppColors.text,
                            weight: FontWeight.w700),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.border),
          const SizedBox(height: 4),

          // Stat rows
          ...rows.map((r) => _buildCompareStatRow(r)),
          const SizedBox(height: 20),

          // Overlaid sparkline
          Text('TREN TONASE (6 BULAN)', style: AppTextStyles.label()),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: SizedBox(
              height: 120,
              child: _OverlaidSparkline(
                dataA: dataA,
                dataB: dataB,
                colorA: AppColors.primary3,
                colorB: AppColors.gold,
                labelA: a.namaLahan,
                labelB: b.namaLahan,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompareStatRow(_CompareRow row) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(row.label,
                style:
                    AppTextStyles.body(12, color: AppColors.textMuted)),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(row.valA,
                    style: AppTextStyles.mono(12,
                        color: row.winA
                            ? AppColors.primary3
                            : AppColors.text,
                        weight: row.winA
                            ? FontWeight.w700
                            : FontWeight.w400)),
                if (row.winA)
                  const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Icon(Icons.check_circle_rounded,
                        color: AppColors.primary3, size: 13),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(row.valB,
                    style: AppTextStyles.mono(12,
                        color: !row.winA
                            ? AppColors.gold
                            : AppColors.text,
                        weight: !row.winA
                            ? FontWeight.w700
                            : FontWeight.w400)),
                if (!row.winA)
                  const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Icon(Icons.check_circle_rounded,
                        color: AppColors.gold, size: 13),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _CompareRow  (simple data holder)
// ─────────────────────────────────────────────────────────────────────────────

class _CompareRow {
  final String label;
  final String valA;
  final String valB;
  final bool winA; // true = A wins / A is at-least-as-good

  const _CompareRow({
    required this.label,
    required this.valA,
    required this.valB,
    required this.winA,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// _OverlaidSparkline  (two lahan on same chart)
// ─────────────────────────────────────────────────────────────────────────────

class _OverlaidSparkline extends StatelessWidget {
  final List<PanenModel> dataA;
  final List<PanenModel> dataB;
  final Color colorA;
  final Color colorB;
  final String labelA;
  final String labelB;

  const _OverlaidSparkline({
    required this.dataA,
    required this.dataB,
    required this.colorA,
    required this.colorB,
    required this.labelA,
    required this.labelB,
  });

  @override
  Widget build(BuildContext context) {
    if (dataA.length < 2 && dataB.length < 2) {
      return Center(
        child: Text('Belum cukup data untuk tren',
            style: AppTextStyles.body(12, color: AppColors.textMuted)),
      );
    }

    List<FlSpot> toSpots(List<PanenModel> data) {
      return data.asMap().entries.map((e) {
        return FlSpot(e.key.toDouble(), e.value.tonAktual);
      }).toList();
    }

    final spotsA = toSpots(dataA);
    final spotsB = toSpots(dataB);

    final allVals = [
      ...dataA.map((p) => p.tonAktual),
      ...dataB.map((p) => p.tonAktual),
    ];
    final maxY = allVals.isEmpty
        ? 1.0
        : allVals.reduce((a, b) => a > b ? a : b) * 1.25;
    final maxX = [dataA.length - 1, dataB.length - 1, 1]
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    final lines = <LineChartBarData>[];
    if (spotsA.length >= 2) {
      lines.add(LineChartBarData(
        spots: spotsA,
        isCurved: true,
        curveSmoothness: 0.3,
        color: colorA,
        barWidth: 2,
        dotData: FlDotData(
          show: true,
          getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
            radius: 2.5,
            color: colorA,
            strokeWidth: 0,
            strokeColor: Colors.transparent,
          ),
        ),
        belowBarData: BarAreaData(
          show: true,
          color: colorA.withOpacity(0.08),
        ),
      ));
    }
    if (spotsB.length >= 2) {
      lines.add(LineChartBarData(
        spots: spotsB,
        isCurved: true,
        curveSmoothness: 0.3,
        color: colorB,
        barWidth: 2,
        dashArray: [5, 3],
        dotData: FlDotData(
          show: true,
          getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
            radius: 2.5,
            color: colorB,
            strokeWidth: 0,
            strokeColor: Colors.transparent,
          ),
        ),
        belowBarData: BarAreaData(
          show: true,
          color: colorB.withOpacity(0.08),
        ),
      ));
    }

    return Column(
      children: [
        Expanded(
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: maxX,
              minY: 0,
              maxY: maxY,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxY / 3,
                getDrawingHorizontalLine: (_) =>
                    const FlLine(color: AppColors.border, strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    interval: maxY / 3,
                    getTitlesWidget: (v, _) => Text(
                      v.toStringAsFixed(0),
                      style: AppTextStyles.body(8, color: AppColors.textLight),
                    ),
                  ),
                ),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                bottomTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
              ),
              lineBarsData: lines,
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  tooltipBgColor: AppColors.primary,
                  tooltipRoundedRadius: 8,
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((s) {
                      final name = s.barIndex == 0 ? labelA : labelB;
                      return LineTooltipItem(
                        '$name\n${s.y.toStringAsFixed(1)} ton',
                        AppTextStyles.body(9, color: Colors.white),
                      );
                    }).toList();
                  },
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _SparklineLegend(color: colorA, label: labelA, dashed: false),
            const SizedBox(width: 16),
            _SparklineLegend(color: colorB, label: labelB, dashed: true),
          ],
        ),
      ],
    );
  }
}

class _SparklineLegend extends StatelessWidget {
  final Color color;
  final String label;
  final bool dashed;

  const _SparklineLegend(
      {required this.color, required this.label, required this.dashed});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        dashed
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 5, height: 2, color: color),
                  const SizedBox(width: 2),
                  Container(width: 5, height: 2, color: color),
                ],
              )
            : Container(width: 14, height: 2, color: color),
        const SizedBox(width: 5),
        Text(label,
            style: AppTextStyles.body(10, color: AppColors.textMuted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
      ],
    );
  }
}
