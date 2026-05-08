import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../models/lahan_model.dart';
import '../services/api_service.dart';
import '../widgets/common_widgets.dart';
import '../widgets/offline_banner.dart';
import 'main_screen.dart';
import 'lahan_screen.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  late final ApiService _api;
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;
  late int _selectedYear;

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
      final data = await _api.getPortfolio(year: _selectedYear);
      setState(() { _data = data; _loading = false; });
    } catch (_) {
      setState(() { _error = 'Gagal memuat data'; _loading = false; });
    }
  }

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
        title: Text('Dashboard Semua Kebun',
            style: AppTextStyles.display(18, color: Colors.white)),
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
    final totalLahan = (d['totalLahan'] as num?)?.toInt() ?? 0;
    final totalLuasHa = (d['totalLuasHa'] as num?)?.toDouble() ?? 0.0;
    final lahans = (d['lahans'] as List?) ?? [];

    if (lahans.isEmpty) {
      return _EmptyLahan(
        onAdd: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LahanFormScreen()),
        ),
      );
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
            // ── Top summary card ───────────────────────────────────────────
            _buildTopSummaryCard(
                totalRevenue, totalExpenses, netProfit, totalLahan, totalLuasHa),
            const SizedBox(height: 20),

            Text('DETAIL PER KEBUN',
                style: AppTextStyles.label()),
            const SizedBox(height: 12),

            // ── Per-lahan cards ────────────────────────────────────────────
            ...lahans.map((item) {
              final lahan = item as Map<String, dynamic>;
              return _LahanSummaryCard(
                data: lahan,
                fmt: _fmt,
                onTap: () => _openLahan(lahan),
              );
            }),
          ],
        ),
      ),
    );
  }

  Future<void> _openLahan(Map<String, dynamic> lahanData) async {
    // Build a lightweight LahanModel from portfolio data to navigate into MainScreen
    final lahan = LahanModel(
      id: (lahanData['lahanId'] as num).toInt(),
      namaLahan: lahanData['namaLahan'] as String? ?? '',
      luasHa: (lahanData['luasHa'] as num?)?.toDouble() ?? 0.0,
      usiaPohon: (lahanData['usiaPohon'] as num?)?.toInt() ?? 0,
      isActive: true,
      faseProduksi: lahanData['fase'] as String?,
    );
    final prefs = await SharedPreferences.getInstance();
    final paket = prefs.getString('user_paket') ?? 'GRATIS';
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MainScreen(lahan: lahan, userPaket: paket),
      ),
    );
  }

  Widget _buildTopSummaryCard(double revenue, double expenses, double profit,
      int lahanCount, double totalLuasHa) {
    final profitColor = profit >= 0 ? AppColors.primary3 : AppColors.danger;

    return Container(
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
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              'RINGKASAN $_selectedYear — $lahanCount KEBUN',
              style: AppTextStyles.body(10,
                  color: const Color(0xFF74C69D), weight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 16),

          // Net profit big number
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Profit',
                        style: AppTextStyles.body(12,
                            color: const Color(0xff74c69d99))),
                    const SizedBox(height: 4),
                    Text(
                      _fmt(profit),
                      style: AppTextStyles.mono(28,
                          color: profit >= 0
                              ? const Color(0xFF74C69D)
                              : const Color(0xFFFCA5A5),
                          weight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: profitColor.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(99),
                  border:
                      Border.all(color: profitColor.withOpacity(0.4)),
                ),
                child: Text(
                  profit >= 0 ? 'Untung' : 'Rugi',
                  style: AppTextStyles.body(11,
                      color: profit >= 0
                          ? const Color(0xFF74C69D)
                          : const Color(0xFFFCA5A5),
                      weight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
              height: 1, color: Colors.white.withOpacity(0.12)),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _HeroStat(
                    label: 'Pendapatan',
                    value: _fmt(revenue)),
              ),
              Expanded(
                child: _HeroStat(
                    label: 'Pengeluaran',
                    value: _fmt(expenses)),
              ),
              Expanded(
                child: _HeroStat(
                    label: 'Total Luas',
                    value: '${totalLuasHa.toStringAsFixed(1)} ha'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Per-lahan summary card ───────────────────────────────────────────────────

class _LahanSummaryCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String Function(double) fmt;
  final VoidCallback onTap;

  const _LahanSummaryCard({
    required this.data,
    required this.fmt,
    required this.onTap,
  });

  Color get _statusColor {
    final s = data['latestStatusPanen'] as String?;
    if (s == null) return AppColors.textLight;
    switch (s.toUpperCase()) {
      case 'NORMAL':
        return AppColors.primary3;
      case 'WARN':
        return AppColors.goldLight;
      default:
        return AppColors.danger;
    }
  }

  @override
  Widget build(BuildContext context) {
    final namaLahan = data['namaLahan'] as String? ?? '';
    final luasHa = (data['luasHa'] as num?)?.toDouble() ?? 0.0;
    final usiaPohon = (data['usiaPohon'] as num?)?.toInt() ?? 0;
    final fase = data['fase'] as String? ?? '';
    final revenue = (data['revenue'] as num?)?.toDouble() ?? 0.0;
    final expenses = (data['expenses'] as num?)?.toDouble() ?? 0.0;
    final profit = (data['profit'] as num?)?.toDouble() ?? 0.0;
    final profitPerHa = (data['profitPerHa'] as num?)?.toDouble() ?? 0.0;
    final avgTonPerHa = (data['avgTonPerHa'] as num?)?.toDouble() ?? 0.0;
    final panenCount = (data['panenCount'] as num?)?.toInt() ?? 0;
    final profitColor = profit >= 0 ? AppColors.primary3 : AppColors.danger;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(Radii.xl),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ──
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(namaLahan,
                      style: AppTextStyles.display(16)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(fase,
                      style: AppTextStyles.body(10,
                          color: AppColors.primary,
                          weight: FontWeight.w600)),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.arrow_forward_ios_rounded,
                    size: 14, color: AppColors.textLight),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${luasHa.toStringAsFixed(1)} ha · Usia $usiaPohon thn'
              '${panenCount > 0 ? ' · $panenCount bulan panen' : ''}',
              style: AppTextStyles.body(12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 14),

            // ── Financial row ──
            Row(
              children: [
                _FinStat(label: 'Pendapatan', value: fmt(revenue),
                    color: AppColors.primary3),
                const SizedBox(width: 12),
                _FinStat(label: 'Pengeluaran', value: fmt(expenses),
                    color: AppColors.danger),
                const SizedBox(width: 12),
                _FinStat(label: 'Profit', value: fmt(profit),
                    color: profitColor),
              ],
            ),
            const SizedBox(height: 12),

            // ── Subtlue metrics ──
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(Radii.md),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _SubMetric(
                      label: 'Profit/Ha',
                      value: '${fmt(profitPerHa)}/ha',
                    ),
                  ),
                  if (avgTonPerHa > 0)
                    Expanded(
                      child: _SubMetric(
                        label: 'Avg Ton/Ha',
                        value: '${avgTonPerHa.toStringAsFixed(2)} t/ha',
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Helper sub-widgets ───────────────────────────────────────────────────────

class _HeroStat extends StatelessWidget {
  final String label;
  final String value;
  const _HeroStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTextStyles.body(10,
                  color: const Color(0xff74c69d80))),
          const SizedBox(height: 3),
          Text(value,
              style: AppTextStyles.body(12,
                  color: const Color(0xFF74C69D),
                  weight: FontWeight.w600)),
        ],
      );
}

class _FinStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _FinStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(),
                style: AppTextStyles.body(9, color: AppColors.textMuted,
                    weight: FontWeight.w600)),
            const SizedBox(height: 3),
            Text(value,
                style: AppTextStyles.mono(12,
                    color: color, weight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      );
}

class _SubMetric extends StatelessWidget {
  final String label;
  final String value;
  const _SubMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTextStyles.body(10, color: AppColors.textMuted)),
          const SizedBox(height: 2),
          Text(value,
              style: AppTextStyles.body(12,
                  color: AppColors.textMid, weight: FontWeight.w600)),
        ],
      );
}

class _EmptyLahan extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyLahan({required this.onAdd});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🌱', style: TextStyle(fontSize: 52)),
              const SizedBox(height: 16),
              Text('Belum Ada Kebun',
                  style: AppTextStyles.display(20)),
              const SizedBox(height: 8),
              Text(
                'Tambahkan data kebun sawit untuk melihat dashboard portofolio.',
                style: AppTextStyles.body(13, color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              PrimaryButton(label: '+ Tambah Kebun', onTap: onAdd),
            ],
          ),
        ),
      );
}
