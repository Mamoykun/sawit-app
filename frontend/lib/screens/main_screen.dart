import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/panen_model.dart';
import '../models/lahan_model.dart';
import '../services/api_service.dart';
import '../services/analisa_service.dart';
import 'beranda_screen.dart';
import 'hasil_analisa_screen.dart';
import 'lahan_screen.dart';
import 'profile_screen.dart';
import '../repositories/panen_repository.dart';
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

  @override
  void initState() {
    super.initState();
    _loadLastAnalisa();
  }

  Future<void> _loadLastAnalisa() async {
    try {
      final repo = PanenRepository(db: appDb, api: ApiService());
      final list = await repo.getByLahan(widget.lahan.id, limit: 1);
      if (!mounted) return;
      if (list.isEmpty) {
        // Tidak ada panen lagi (mis. user hapus semua dari riwayat).
        // Clear analisa supaya tab Analisa balik ke empty state.
        setState(() => _lastAnalisa = null);
        return;
      }
      final last = list.first;
      final penyebab = last.analisa?.penyebab.isNotEmpty == true
          ? last.analisa!.penyebab
          : AnalisaService.getPenyebab(last.persenKurang);
      setState(() {
        _lastAnalisa = HasilAnalisa(panen: last, penyebab: penyebab);
      });
    } catch (_) {}
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
