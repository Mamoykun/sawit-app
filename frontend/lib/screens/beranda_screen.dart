import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../models/panen_model.dart';
import '../models/lahan_model.dart';
import '../services/api_service.dart';
import '../repositories/panen_repository.dart';
import '../main.dart' show appDb;
import '../widgets/common_widgets.dart';
import 'input_panen_screen.dart';
import 'riwayat_screen.dart';
import 'biaya_screen.dart';
import 'diagnosa_screen.dart';
import 'jadwal_pupuk_screen.dart';
import 'perbandingan_screen.dart';
import 'tips_screen.dart';

class BerandaScreen extends StatefulWidget {
  final LahanModel lahan;
  final ValueChanged<HasilAnalisa> onAnalisaDone;
  final VoidCallback onRefreshAnalisa;
  final String userPaket;

  const BerandaScreen({
    super.key,
    required this.lahan,
    required this.onAnalisaDone,
    required this.onRefreshAnalisa,
    this.userPaket = 'GRATIS',
  });

  @override
  State<BerandaScreen> createState() => _BerandaScreenState();
}

class _BerandaScreenState extends State<BerandaScreen> {
  late final PanenRepository _panenRepo;
  List<PanenModel>? _history;
  bool _loading = true;
  bool _showHint = false;

  @override
  void initState() {
    super.initState();
    _panenRepo = PanenRepository(db: appDb, api: ApiService());
    _loadData();
    _checkFirstVisitHint();
  }

  Future<void> _checkFirstVisitHint() async {
    final prefs = await SharedPreferences.getInstance();
    final dismissed = prefs.getBool('beranda_hint_dismissed') ?? false;
    if (!dismissed && mounted) {
      setState(() => _showHint = true);
    }
  }

  Future<void> _dismissHint() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('beranda_hint_dismissed', true);
    if (mounted) setState(() => _showHint = false);
  }

  @override
  void didUpdateWidget(BerandaScreen old) {
    super.didUpdateWidget(old);
    if (old.lahan.id != widget.lahan.id) _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final list = await _panenRepo.getByLahan(widget.lahan.id, limit: 8);
      setState(() { _history = list; _loading = false; });
    } catch (_) {
      setState(() { _history = []; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primary,
      child: _BerandaContent(
        lahan: widget.lahan,
        history: _history ?? [],
        onOpenInput: _openInput,
        onOpenRiwayat: _openRiwayat,
        onOpenBiaya: _openBiaya,
        onOpenDiagnosa: _openDiagnosa,
        onOpenJadwalPupuk: _openJadwalPupuk,
        onOpenPerbandingan: _openPerbandingan,
        onOpenTips: _openTips,
        showHint: _showHint,
        onDismissHint: _dismissHint,
      ),
    );
  }

  Future<void> _openInput() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InputPanenScreen(
          lahan: widget.lahan,
          onAnalisaDone: (hasil) {
            Navigator.of(context).pop();
            widget.onAnalisaDone(hasil);
          },
        ),
      ),
    );
    if (mounted) {
      _loadData();
      widget.onRefreshAnalisa();
    }
  }

  Future<void> _openRiwayat() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RiwayatScreen(lahan: widget.lahan, lastAnalisa: null),
      ),
    );
    if (mounted) _loadData();
  }

  Future<void> _openBiaya() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BiayaScreen(lahan: widget.lahan)),
    );
  }

  Future<void> _openDiagnosa() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DiagnosaScreen(lahan: widget.lahan)),
    );
  }

  Future<void> _openJadwalPupuk() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => JadwalPupukScreen(lahan: widget.lahan)),
    );
  }

  Future<void> _openPerbandingan() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PerbandinganScreen()),
    );
  }

  Future<void> _openTips() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TipsScreen()),
    );
  }

}

class _BerandaContent extends StatelessWidget {
  final LahanModel lahan;
  final List<PanenModel> history;
  final VoidCallback onOpenInput;
  final VoidCallback onOpenRiwayat;
  final VoidCallback onOpenBiaya;
  final VoidCallback onOpenDiagnosa;
  final VoidCallback onOpenJadwalPupuk;
  final VoidCallback onOpenPerbandingan;
  final VoidCallback onOpenTips;
  final bool showHint;
  final VoidCallback onDismissHint;

  const _BerandaContent({
    required this.lahan,
    required this.history,
    required this.onOpenInput,
    required this.onOpenRiwayat,
    required this.onOpenBiaya,
    required this.onOpenDiagnosa,
    required this.onOpenJadwalPupuk,
    required this.onOpenPerbandingan,
    required this.onOpenTips,
    required this.showHint,
    required this.onDismissHint,
  });

  @override
  Widget build(BuildContext context) {
    // Group history by month for mini-chart
    final grouped = _groupByMonth(history);
    final last = history.isNotEmpty ? history.last : null;
    final prev = history.length >= 2 ? history[history.length - 2] : null;
    final tren = (last != null && prev != null)
        ? last.tonAktual - prev.tonAktual
        : 0.0;
    final isBelowTarget = last != null && last.tonAktual < last.targetMin;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // First-visit hint banner
          if (showHint) ...[
            _FirstVisitHint(onDismiss: onDismissHint),
            const SizedBox(height: 16),
          ],
          // ── Header ──
          Text('Selamat datang kembali',
              style: AppTextStyles.body(13, color: AppColors.textMuted)),
          const SizedBox(height: 3),
          Text(lahan.namaLahan, style: AppTextStyles.display(26)),
          const SizedBox(height: 4),
          Row(
            children: [
              _PillBadge(
                  text: '${lahan.luasHa.toStringAsFixed(1)} ha',
                  color: AppColors.primary3),
              const SizedBox(width: 6),
              _PillBadge(
                  text: 'Usia ${lahan.usiaPohon} thn',
                  color: AppColors.textMuted),
              if (lahan.faseProduksi != null) ...[
                const SizedBox(width: 6),
                _PillBadge(
                    text: lahan.faseProduksi!,
                    color: AppColors.gold),
              ],
            ],
          ),
          const SizedBox(height: 20),

          // ── Hero card ──
          if (last != null) ...[
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, AppColors.primary2, Color(0xFF1A5C40)],
                  stops: [0.0, 0.6, 1.0],
                ),
                borderRadius: BorderRadius.circular(Radii.xxl),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.32),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: AppColors.gold.withOpacity(0.06),
                    blurRadius: 16,
                    offset: const Offset(0, -2),
                    spreadRadius: -4,
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              foregroundDecoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Radii.xxl),
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    AppColors.gold.withOpacity(0.08),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          'PANEN TERAKHIR · ${last.bulan}'.toUpperCase(),
                          style: AppTextStyles.body(10,
                              color: const Color(0xFF74C69D),
                              weight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(last.tonAktual.toStringAsFixed(1),
                          style: AppTextStyles.mono(48,
                              color: Colors.white, weight: FontWeight.w700)),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text('ton',
                            style: AppTextStyles.body(18,
                                color: Colors.white60)),
                      ),
                      const Spacer(),
                      _StatusChip(isOk: last.tonAktual >= last.targetMin),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    height: 1,
                    color: Colors.white.withOpacity(0.12),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _HeroStat(
                        label: 'Target',
                        value: '${last.targetMid.toStringAsFixed(1)} ton',
                      ),
                      _HeroStat(
                        label: 'Tren vs bulan lalu',
                        value:
                            '${tren >= 0 ? "+" : ""}${tren.toStringAsFixed(1)} ton',
                        valueColor: tren >= 0
                            ? const Color(0xFF74C69D)
                            : const Color(0xFFFCA5A5),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Alert
            if (isBelowTarget)
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.dangerTint,
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.danger.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.warning_amber_rounded,
                          color: AppColors.danger, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Produksi Di Bawah Target',
                              style: AppTextStyles.body(13,
                                  color: AppColors.danger,
                                  weight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text(
                            'Kurang ${last.persenKurang.toStringAsFixed(0)}% dari normal. '
                            'Segera analisa penyebabnya.',
                            style: AppTextStyles.body(12,
                                color: const Color(0xFFB91C1C)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ] else ...[
            // Empty state
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryTint,
                    AppColors.primaryTint.withOpacity(0.5)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: AppColors.primary3.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.primary3.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.eco_rounded,
                        color: AppColors.primary3, size: 26),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Belum Ada Data Panen',
                            style: AppTextStyles.display(16,
                                color: AppColors.primary)),
                        const SizedBox(height: 4),
                        Text(
                          'Input data panen pertama untuk melihat analisa dan tren.',
                          style: AppTextStyles.body(12,
                              color: AppColors.primary3),
                        ),
                        const SizedBox(height: 14),
                        PrimaryButton(
                            label: 'Input Sekarang',
                            onTap: onOpenInput),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // ── Tren produksi (chart + plain-language summary) ──
          if (grouped.isNotEmpty) ...[
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Tren Produksi',
                              style: AppTextStyles.display(16)),
                          const SizedBox(height: 2),
                          Text('${grouped.length} bulan terakhir',
                              style: AppTextStyles.body(11,
                                  color: AppColors.textMuted)),
                        ],
                      ),
                      // Plain-language tren chip
                      _TrenChip(grouped: grouped),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Legend
                  Row(
                    children: [
                      _LegendDot(color: AppColors.primary3, label: 'Aktual'),
                      const SizedBox(width: 14),
                      _LegendDot(color: AppColors.danger, label: 'Di bawah target'),
                      const SizedBox(width: 14),
                      _LegendLine(color: AppColors.gold, label: 'Target'),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _MiniBarChart(grouped: grouped),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(Radii.md),
                    ),
                    child: _PlainSummary(grouped: grouped),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // ── Grid Fitur ──
          Text('FITUR', style: AppTextStyles.label()),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 14,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 0.78,
            children: [
              _GridIcon(
                icon: Icons.add_circle_outline_rounded,
                label: 'Input Panen',
                color: AppColors.primary3,
                onTap: onOpenInput,
              ),
              _GridIcon(
                icon: Icons.receipt_long_rounded,
                label: 'Biaya',
                color: AppColors.gold,
                onTap: onOpenBiaya,
              ),
              _GridIcon(
                icon: Icons.camera_alt_rounded,
                label: 'Diagnosa',
                color: AppColors.accent,
                onTap: onOpenDiagnosa,
              ),
              _GridIcon(
                icon: Icons.insights_rounded,
                label: 'Riwayat',
                color: AppColors.primary,
                onTap: onOpenRiwayat,
              ),
              _GridIcon(
                icon: Icons.eco_rounded,
                label: 'Jadwal Pupuk',
                color: const Color(0xFF059669),
                onTap: onOpenJadwalPupuk,
              ),
              _GridIcon(
                icon: Icons.compare_arrows_rounded,
                label: 'Bandingkan',
                color: const Color(0xFF2563EB),
                onTap: onOpenPerbandingan,
              ),
              _GridIcon(
                icon: Icons.lightbulb_outline_rounded,
                label: 'Tips',
                color: const Color(0xFFD97706),
                onTap: onOpenTips,
              ),
              _GridIcon(
                icon: Icons.picture_as_pdf_rounded,
                label: 'Export PDF',
                color: AppColors.danger,
                onTap: onOpenRiwayat,
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _GridIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _GridIcon({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(Radii.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Radii.lg),
          splashColor: color.withOpacity(0.10),
          highlightColor: color.withOpacity(0.04),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon tile (the visual hero)
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.withOpacity(0.18),
                      color.withOpacity(0.10),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(Radii.lg),
                  border: Border.all(
                    color: color.withOpacity(0.18),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.10),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 8),
              // Label
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body(11,
                      color: AppColors.textMid,
                      weight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
        ),
      );
}

// ── Helpers ─────────────────────────────────────────────────────────────────

class _MonthSummary {
  final String bulan;
  final int? tahun;
  final int bulanAngka;
  final double tonAktual;
  final double targetMin;
  final double targetMid;
  final double targetMax;
  final int count;

  _MonthSummary({
    required this.bulan,
    this.tahun,
    required this.bulanAngka,
    required this.tonAktual,
    required this.targetMin,
    required this.targetMid,
    required this.targetMax,
    required this.count,
  });

  bool get isNormal => tonAktual >= targetMin;
}

List<_MonthSummary> _groupByMonth(List<PanenModel> data) {
  final Map<String, _MonthSummary> map = {};
  for (final p in data) {
    final key = '${p.tahun ?? 0}_${p.bulanAngka}';
    if (map.containsKey(key)) {
      final e = map[key]!;
      map[key] = _MonthSummary(
        bulan: e.bulan,
        tahun: e.tahun,
        bulanAngka: e.bulanAngka,
        tonAktual: e.tonAktual + p.tonAktual,
        targetMin: e.targetMin,
        targetMid: e.targetMid,
        targetMax: e.targetMax,
        count: e.count + 1,
      );
    } else {
      map[key] = _MonthSummary(
        bulan: p.bulan,
        tahun: p.tahun,
        bulanAngka: p.bulanAngka!,
        tonAktual: p.tonAktual,
        targetMin: p.targetMin,
        targetMid: p.targetMid,
        targetMax: p.targetMax,
        count: 1,
      );
    }
  }
  return map.values.toList()
    ..sort((a, b) {
      if ((a.tahun ?? 0) != (b.tahun ?? 0)) {
        return (a.tahun ?? 0).compareTo(b.tahun ?? 0);
      }
      return a.bulanAngka.compareTo(b.bulanAngka);
    });
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _PillBadge extends StatelessWidget {
  final String text;
  final Color color;
  const _PillBadge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: color.withOpacity(0.2)),
    ),
    child: Text(text,
        style: AppTextStyles.body(11, color: color, weight: FontWeight.w600)),
  );
}

class _StatusChip extends StatelessWidget {
  final bool isOk;
  const _StatusChip({required this.isOk});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: isOk
          ? const Color(0xFF52B788).withOpacity(0.2)
          : AppColors.danger.withOpacity(0.2),
      borderRadius: BorderRadius.circular(99),
      border: Border.all(
        color: isOk
            ? const Color(0xFF52B788).withOpacity(0.5)
            : AppColors.danger.withOpacity(0.5),
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isOk ? Icons.check_circle_outline_rounded : Icons.trending_down_rounded,
          size: 12,
          color: isOk ? const Color(0xFF74C69D) : const Color(0xFFFCA5A5),
        ),
        const SizedBox(width: 4),
        Text(
          isOk ? 'Normal' : 'Kurang',
          style: AppTextStyles.body(11,
              color: isOk ? const Color(0xFF74C69D) : const Color(0xFFFCA5A5),
              weight: FontWeight.w600),
        ),
      ],
    ),
  );
}

class _HeroStat extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _HeroStat({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label,
          style: AppTextStyles.body(11, color: const Color(0xff74c69d80))),
      const SizedBox(height: 3),
      Text(value,
          style: AppTextStyles.body(13,
              color: valueColor ?? const Color(0xFF74C69D),
              weight: FontWeight.w600)),
    ],
  );
}

class _MiniBarChart extends StatelessWidget {
  final List<_MonthSummary> grouped;
  const _MiniBarChart({required this.grouped});

  @override
  Widget build(BuildContext context) {
    const chartHeight = 120.0;
    final allMax = grouped
        .map((m) => m.targetMax > m.tonAktual ? m.targetMax : m.tonAktual)
        .reduce((a, b) => a > b ? a : b);
    final maxVal = allMax * 1.30;

    // Average target line shared across months (use most recent)
    final targetMid = grouped.last.targetMid;
    final tgtFraction = (targetMid / maxVal).clamp(0.0, 1.0);

    return SizedBox(
      height: chartHeight + 28,
      child: Stack(
        children: [
          // Dotted target line spanning full width
          Positioned(
            left: 0,
            right: 0,
            bottom: 28 + (chartHeight * tgtFraction) - 1,
            child: _DottedLine(color: AppColors.gold),
          ),
          // Target label
          Positioned(
            right: 0,
            bottom: 28 + (chartHeight * tgtFraction) + 3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.gold,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Target ${targetMid.toStringAsFixed(1)}t',
                style: AppTextStyles.mono(9,
                    color: Colors.white, weight: FontWeight.w700),
              ),
            ),
          ),
          // Bars
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: grouped.map((m) {
              final barH = ((m.tonAktual / maxVal) * chartHeight)
                  .clamp(8.0, chartHeight);
              final abbr = m.bulan.length > 3 ? m.bulan.substring(0, 3) : m.bulan;
              final color = m.isNormal ? AppColors.primary3 : AppColors.danger;

              return Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SizedBox(
                      height: chartHeight,
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: FractionallySizedBox(
                              widthFactor: 0.7,
                              child: Container(
                                height: barH,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      color.withOpacity(0.95),
                                      color.withOpacity(0.55),
                                    ],
                                  ),
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(6)),
                                ),
                                // Value label inside/above the bar
                                child: Align(
                                  alignment: Alignment.topCenter,
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      m.tonAktual.toStringAsFixed(1),
                                      style: AppTextStyles.mono(
                                        barH > 32 ? 11 : 9,
                                        color: Colors.white,
                                        weight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(abbr,
                        style: AppTextStyles.body(11,
                            color: AppColors.textMid,
                            weight: FontWeight.w600)),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// Dotted horizontal line for target reference
class _DottedLine extends StatelessWidget {
  final Color color;
  const _DottedLine({required this.color});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          const dashWidth = 4.0;
          const dashGap = 4.0;
          final count = (constraints.maxWidth / (dashWidth + dashGap)).floor();
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

// ─── LEGEND HELPERS ──────────────────────────────────────────────────────────

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10, height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 6),
          Text(label,
              style: AppTextStyles.body(11,
                  color: AppColors.textMid, weight: FontWeight.w500)),
        ],
      );
}

class _LegendLine extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendLine({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: List.generate(
              3,
              (i) => Container(
                width: 4, height: 2,
                margin: EdgeInsets.only(right: i < 2 ? 2 : 0),
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(label,
              style: AppTextStyles.body(11,
                  color: AppColors.textMid, weight: FontWeight.w500)),
        ],
      );
}

// ─── TREN CHIP ────────────────────────────────────────────────────────────────

class _TrenChip extends StatelessWidget {
  final List<_MonthSummary> grouped;
  const _TrenChip({required this.grouped});

  @override
  Widget build(BuildContext context) {
    if (grouped.length < 2) return const SizedBox.shrink();
    final last = grouped.last.tonAktual;
    final prev = grouped[grouped.length - 2].tonAktual;
    final diff = last - prev;
    final isUp = diff >= 0;
    final color = isUp ? AppColors.success : AppColors.danger;
    final icon = isUp
        ? Icons.trending_up_rounded
        : Icons.trending_down_rounded;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text('${isUp ? '+' : ''}${diff.toStringAsFixed(1)} t',
              style: AppTextStyles.mono(11,
                  color: color, weight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ─── PLAIN LANGUAGE SUMMARY ──────────────────────────────────────────────────

class _PlainSummary extends StatelessWidget {
  final List<_MonthSummary> grouped;
  const _PlainSummary({required this.grouped});

  @override
  Widget build(BuildContext context) {
    final last = grouped.last;
    final isOk = last.isNormal;
    final selisihMid = last.tonAktual - last.targetMid;
    final pctVsMid = last.targetMid > 0
        ? (selisihMid / last.targetMid * 100).abs()
        : 0.0;

    final headlineIcon = isOk
        ? Icons.check_circle_rounded
        : Icons.error_rounded;
    final headlineColor = isOk ? AppColors.success : AppColors.danger;
    final headlineText = isOk
        ? 'Bulan ${last.bulan} CUKUP — sesuai target'
        : 'Bulan ${last.bulan} KURANG — di bawah target';

    final detailText = isOk
        ? 'Hasil ${last.tonAktual.toStringAsFixed(1)} ton, target ${last.targetMid.toStringAsFixed(1)} ton.'
        : 'Hasil ${last.tonAktual.toStringAsFixed(1)} ton, target ${last.targetMid.toStringAsFixed(1)} ton — kurang ${selisihMid.abs().toStringAsFixed(1)} ton (${pctVsMid.toStringAsFixed(0)}%).';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(headlineIcon, color: headlineColor, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(headlineText,
                  style: AppTextStyles.body(13,
                      color: headlineColor, weight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text(detailText,
                  style: AppTextStyles.body(12, color: AppColors.textMid)),
            ],
          ),
        ),
      ],
    );
  }
}

class _FirstVisitHint extends StatelessWidget {
  final VoidCallback onDismiss;
  const _FirstVisitHint({required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.gold.withOpacity(0.12),
            AppColors.goldLight.withOpacity(0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(color: AppColors.gold.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: AppColors.gold,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.tips_and_updates_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tips Memulai',
                    style: AppTextStyles.body(12,
                        color: AppColors.gold,
                        weight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(
                  'Tap ikon "Input Panen" di bawah untuk catat hasil panen pertama Anda. '
                  'Setelah ada data, AI akan analisa & beri rekomendasi otomatis.',
                  style: AppTextStyles.body(12.5,
                      color: AppColors.textMid),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded,
                size: 18, color: AppColors.textMuted),
            tooltip: 'Tutup',
            onPressed: onDismiss,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}
