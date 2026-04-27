import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/panen_model.dart';
import 'beranda_screen.dart';
import 'input_panen_screen.dart';
import 'hasil_analisa_screen.dart';
import 'riwayat_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  HasilAnalisa? _lastAnalisa;

  void _onAnalisaDone(HasilAnalisa hasil) {
    setState(() {
      _lastAnalisa = hasil;
      _currentIndex = 2; // pindah ke tab Analisa
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      BerandaScreen(onGoToInput: () => setState(() => _currentIndex = 1)),
      InputPanenScreen(onAnalisaDone: _onAnalisaDone),
      HasilAnalisaScreen(
        hasil: _lastAnalisa,
        onGoToInput: () => setState(() => _currentIndex = 1),
        onGoToRiwayat: () => setState(() => _currentIndex = 3),
      ),
      RiwayatScreen(lastAnalisa: _lastAnalisa),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SawitKu', style: AppTextStyles.display(18, color: Colors.white)),
            Text(
              'PLATFORM MANAJEMEN KEBUN',
              style: AppTextStyles.body(9,
                  color: const Color(0xFF74C69D), weight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.gold,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('PETANI',
                style: AppTextStyles.body(11,
                    color: Colors.white, weight: FontWeight.w700)),
          ),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
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
      const _NavItem(icon: Icons.add_circle_outline_rounded, label: 'Input'),
      _NavItem(icon: Icons.analytics_outlined, label: 'Analisa', badge: !hasAnalisa),
      const _NavItem(icon: Icons.bar_chart_rounded, label: 'Riwayat'),
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
          height: 64,
          child: Row(
            children: items.asMap().entries.map((e) {
              final i = e.key;
              final item = e.value;
              final isActive = currentIndex == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 40,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isActive ? AppColors.primaryTint : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          item.icon,
                          color: isActive ? AppColors.primary : AppColors.textLight,
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.label,
                        style: AppTextStyles.body(10,
                            color: isActive ? AppColors.primary : AppColors.textLight,
                            weight: isActive ? FontWeight.w700 : FontWeight.w400),
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
  const _NavItem({required this.icon, required this.label, this.badge = false});
}
