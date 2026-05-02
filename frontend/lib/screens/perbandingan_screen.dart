import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/lahan_model.dart';
import '../services/api_service.dart';
import '../repositories/lahan_repository.dart';
import '../main.dart' show appDb;
import '../widgets/empty_state.dart';

class PerbandinganScreen extends StatefulWidget {
  const PerbandinganScreen({super.key});

  @override
  State<PerbandinganScreen> createState() => _PerbandinganScreenState();
}

class _PerbandinganScreenState extends State<PerbandinganScreen> {
  late final LahanRepository _lahanRepo = LahanRepository(db: appDb, api: ApiService());
  List<LahanModel>? _lahanList;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await _lahanRepo.getAll();
      if (mounted) setState(() { _lahanList = list; _loading = false; });
    } catch (_) {
      if (mounted) {
        setState(() { _loading = false; _lahanList ??= []; });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Gagal memuat data lahan'),
          backgroundColor: AppColors.danger,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text('Perbandingan Lahan',
            style: AppTextStyles.display(18, color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
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

    // Sort by performance (panenTerakhir / targetMid).
    final sorted = [...list];
    sorted.sort((a, b) {
      final aPerf = _getPerformance(a);
      final bPerf = _getPerformance(b);
      return bPerf.compareTo(aPerf);
    });

    final maxAktual = list.fold<double>(0, (m, l) {
      final a = l.panenTerakhir?.tonAktual ?? 0;
      return a > m ? a : m;
    });

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${list.length} kebun aktif',
                style: AppTextStyles.body(13, color: AppColors.textMuted)),
            const SizedBox(height: 20),

            Text('PANEN TERAKHIR (TON)', style: AppTextStyles.label()),
            const SizedBox(height: 12),

            // Horizontal bar chart
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: sorted.map((l) {
                  final aktual = l.panenTerakhir?.tonAktual ?? 0;
                  final percentage = maxAktual > 0 ? (aktual / maxAktual) : 0.0;
                  return _BarRow(
                    label: l.namaLahan,
                    value: aktual,
                    percentage: percentage,
                    isOk: l.statusTerkini == 'NORMAL',
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 24),
            Text('RANKING KINERJA', style: AppTextStyles.label()),
            const SizedBox(height: 12),

            ...sorted.asMap().entries.map((e) => _RankCard(
                  rank: e.key + 1,
                  lahan: e.value,
                  performance: _getPerformance(e.value),
                )),
          ],
        ),
      ),
    );
  }

  /// Performance = panenTerakhir / lahan area (ton/ha).
  double _getPerformance(LahanModel l) {
    final aktual = l.panenTerakhir?.tonAktual ?? 0;
    return l.luasHa > 0 ? aktual / l.luasHa : 0;
  }
}

class _BarRow extends StatelessWidget {
  final String label;
  final double value;
  final double percentage;
  final bool isOk;

  const _BarRow({
    required this.label,
    required this.value,
    required this.percentage,
    required this.isOk,
  });

  @override
  Widget build(BuildContext context) {
    final color = isOk ? AppColors.primary3 : AppColors.danger;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.body(13,
                              color: AppColors.text,
                              weight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              Text('${value.toStringAsFixed(1)} ton',
                  style: AppTextStyles.mono(13,
                      color: color, weight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: percentage.clamp(0.05, 1.0),
              minHeight: 12,
              backgroundColor: AppColors.surfaceAlt,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _RankCard extends StatelessWidget {
  final int rank;
  final LahanModel lahan;
  final double performance;

  const _RankCard({
    required this.rank,
    required this.lahan,
    required this.performance,
  });

  @override
  Widget build(BuildContext context) {
    final medalColor = switch (rank) {
      1 => AppColors.gold,
      2 => const Color(0xFF94A3B8),
      3 => const Color(0xFFCD7F32),
      _ => AppColors.textLight,
    };
    final isOk = lahan.statusTerkini == 'NORMAL';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: rank <= 3 ? medalColor.withOpacity(0.3) : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: medalColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(rank <= 3 ? '#$rank' : rank.toString(),
                    style: AppTextStyles.mono(13,
                        color: medalColor, weight: FontWeight.w800)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lahan.namaLahan,
                      style: AppTextStyles.body(14,
                          color: AppColors.text, weight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text('${lahan.luasHa.toStringAsFixed(1)} ha',
                          style: AppTextStyles.mono(11,
                              color: AppColors.textMuted)),
                      Text(' · ',
                          style: AppTextStyles.body(11,
                              color: AppColors.textMuted)),
                      Text(
                          '${performance.toStringAsFixed(2)} ton/ha',
                          style: AppTextStyles.mono(11,
                              color: AppColors.textMuted,
                              weight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: (isOk ? AppColors.success : AppColors.danger).withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isOk ? 'Normal' : 'Kurang',
                style: AppTextStyles.body(10,
                    color: isOk ? AppColors.success : AppColors.danger,
                    weight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
