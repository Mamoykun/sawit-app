import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/panen_model.dart';
import '../models/lahan_model.dart';
import '../models/biaya_model.dart' show KategoriBiaya;
import '../models/ai_usage_stats_model.dart';
import '../services/api_service.dart';
import '../services/analisa_service.dart';
import 'beranda_screen.dart';
import 'hasil_analisa_screen.dart';
import 'lahan_screen.dart';
import 'profile_screen.dart';
import '../repositories/panen_repository.dart';
import '../repositories/biaya_repository.dart';
import '../widgets/offline_banner.dart';
import '../main.dart' show appDb;

class MainScreen extends StatefulWidget {
  final LahanModel lahan;
  final String userPaket;

  const MainScreen({
    super.key,
    required this.lahan,
    this.userPaket = 'GRATIS',
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  HasilAnalisa? _lastAnalisa;
  AnalisaDataInfo? _analisaDataInfo;
  AiUsageStatsModel? _aiStats;
  bool _analisaRetryScheduled = false;

  @override
  void initState() {
    super.initState();
    _loadLastAnalisa();
  }

  Future<void> _loadLastAnalisa({bool fromRetry = false}) async {
    try {
      final panenRepo = PanenRepository(db: appDb, api: ApiService());
      final biayaRepo = BiayaRepository(db: appDb, api: ApiService());
      // Ambil sampai 6 record riwayat — bisa ada >1 record per bulan.
      final list = await panenRepo.getByLahan(widget.lahan.id, limit: 6);
      if (!mounted) return;
      if (list.isEmpty) {
        // Tidak ada panen lagi — clear analisa.
        setState(() {
          _lastAnalisa = null;
          _analisaDataInfo = null;
        });
        return;
      }
      // Cek apakah ada biaya kategori PUPUK untuk lahan ini.
      final biayaList = await biayaRepo.getByLahan(widget.lahan.id);
      final hasPupuk = biayaList.any(
          (b) => b.kategori == KategoriBiaya.pupuk);

      // Aggregate all records for the latest month — user may have input panen 2x.
      final latestKey = '${list.first.bulan}-${list.first.tahun}';
      final sameMonth = list
          .where((p) => '${p.bulan}-${p.tahun}' == latestKey)
          .toList();
      final totalTon = sameMonth.fold<double>(0, (s, p) => s + p.tonAktual);
      final base = sameMonth.first;

      // Recompute status from aggregate — same formula as PanenRepository.create.
      final persenKurang = totalTon < base.targetMin
          ? max(0.0, (base.targetMin - totalTon) / base.targetMin * 100)
          : 0.0;
      final newStatus = totalTon >= base.targetMin
          ? 'NORMAL'
          : persenKurang <= 20
              ? 'WARN'
              : 'DANGER';

      final aggregated = PanenModel(
        id: base.id,
        lahanId: base.lahanId,
        namaLahan: base.namaLahan,
        luasHa: base.luasHa,
        usiaTahun: base.usiaTahun,
        tonAktual: totalTon,
        targetMin: base.targetMin,
        targetMax: base.targetMax,
        targetMid: base.targetMid,
        bulan: base.bulan,
        tahun: base.tahun,
        bulanAngka: base.bulanAngka,
        tanggal: base.tanggal,
        hargaPerTon: base.hargaPerTon,
        statusPanen: newStatus,
        persenKurang: persenKurang,
        analisa: base.analisa,
      );

      final penyebab = aggregated.analisa?.penyebab.isNotEmpty == true
          ? aggregated.analisa!.penyebab
          : AnalisaService.getPenyebab(persenKurang);
      setState(() {
        _lastAnalisa = HasilAnalisa(panen: aggregated, penyebab: penyebab);
        _analisaDataInfo = AnalisaDataInfo(
          panenCount: list.length,
          hasPupukData: hasPupuk,
          hasLokasi: widget.lahan.lokasi != null &&
              widget.lahan.lokasi!.isNotEmpty,
        );
      });
      // If analisa is null (async AI not yet computed), schedule retries.
      // fromRetry guard prevents infinite recursion: retry → _loadLastAnalisa → retry.
      if (!fromRetry) {
        if (base.analisa != null) {
          // Analisa already arrived — clear retry guard so next pending case can retry.
          _analisaRetryScheduled = false;
        } else if (!_analisaRetryScheduled) {
          _analisaRetryScheduled = true;
          _scheduleAnalisaRetry(3);
        }
      }
      try {
        final stats = await ApiService().getAiUsageStats();
        if (mounted) setState(() => _aiStats = stats);
      } catch (_) {
        // Silent fallback — quota UI optional
      }
    } catch (_) {}
  }

  /// Retries loading analisa up to [maxRetries] times with a 2s gap.
  /// Delegates to [_loadLastAnalisa] so aggregation, dataInfo, and aiStats
  /// are all updated consistently. Uses fromRetry=true to prevent recursion.
  Future<void> _scheduleAnalisaRetry(int maxRetries) async {
    try {
      for (int i = 0; i < maxRetries; i++) {
        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) return;
        await _loadLastAnalisa(fromRetry: true);
        // Stop early if analisa arrived.
        if (_lastAnalisa?.panen.analisa != null) return;
      }
    } finally {
      _analisaRetryScheduled = false; // Always clear guard so future panen creates can retry
    }
  }

  void _onAnalisaDone(HasilAnalisa hasil) {
    setState(() {
      _lastAnalisa = hasil;
      _currentIndex = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final lahan = widget.lahan;
    final screens = [
      BerandaScreen(
        lahan: lahan,
        onAnalisaDone: _onAnalisaDone,
        onRefreshAnalisa: _loadLastAnalisa,
        userPaket: widget.userPaket,
      ),
      HasilAnalisaScreen(
        hasil: _lastAnalisa,
        lahan: widget.lahan,
        dataInfo: _analisaDataInfo,
        aiStats: _aiStats,
        onGoToInput: () => setState(() => _currentIndex = 0),
        onGoToRiwayat: () => setState(() => _currentIndex = 0),
        onRefresh: _loadLastAnalisa,
      ),
      const ProfileScreen(embedded: true),
    ];

    final titles = ['SawitKu', 'Hasil Analisa', 'Profil Saya'];

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primary2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titles[_currentIndex],
                style: AppTextStyles.display(18, color: Colors.white)),
            if (_currentIndex == 0)
              Text(
                lahan.namaLahan.toUpperCase(),
                style: AppTextStyles.body(9,
                    color: const Color(0xFF74C69D),
                    weight: FontWeight.w600),
              ),
          ],
        ),
        actions: [
          if (_currentIndex == 0)
            GestureDetector(
              onTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LahanScreen()),
              ),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.swap_horiz_rounded,
                        color: Colors.white70, size: 16),
                    const SizedBox(width: 4),
                    Text('Kebun',
                        style: AppTextStyles.body(11, color: Colors.white70)),
                  ],
                ),
              ),
            ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: widget.userPaket == 'GRATIS'
                  ? Colors.white.withOpacity(0.15)
                  : AppColors.gold,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(widget.userPaket,
                style: AppTextStyles.body(11,
                    color: Colors.white, weight: FontWeight.w700)),
          ),
        ],
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(child: IndexedStack(index: _currentIndex, children: screens)),
        ],
      ),
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex,
        onTap: (i) {
          setState(() => _currentIndex = i);
          // Saat user buka tab Analisa, pastikan datanya fresh.
          if (i == 1) _loadLastAnalisa();
        },
        hasAnalisa: _lastAnalisa != null,
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool hasAnalisa;

  const _BottomNav({
    required this.currentIndex,
    required this.onTap,
    required this.hasAnalisa,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      const _NavItem(icon: Icons.grid_view_rounded, label: 'Beranda'),
      _NavItem(
          icon: Icons.analytics_outlined,
          label: 'Analisa',
          badge: !hasAnalisa),
      const _NavItem(icon: Icons.person_outline_rounded, label: 'Profil'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 70,
          child: Row(
            children: items.asMap().entries.map((e) {
              final i = e.key;
              final item = e.value;
              final isActive = currentIndex == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      // Active top indicator pill
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        margin: const EdgeInsets.only(top: 0),
                        width: isActive ? 28 : 0,
                        height: 3,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(99),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 40,
                              height: 36,
                              decoration: BoxDecoration(
                                color: isActive
                                    ? AppColors.primaryTint
                                    : Colors.transparent,
                                borderRadius:
                                    BorderRadius.circular(Radii.md),
                              ),
                              child: Icon(
                                item.icon,
                                color: isActive
                                    ? AppColors.primary
                                    : AppColors.textLight,
                                size: 22,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              item.label,
                              style: AppTextStyles.body(10,
                                  color: isActive
                                      ? AppColors.primary
                                      : AppColors.textLight,
                                  weight: isActive
                                      ? FontWeight.w700
                                      : FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final bool badge;
  const _NavItem(
      {required this.icon, required this.label, this.badge = false});
}
