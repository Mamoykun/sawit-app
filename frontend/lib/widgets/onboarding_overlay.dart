import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

/// Full-screen overlay yang highlight feature utama.
/// Dipakai sekali per user (persisted via SharedPreferences key 'onboarding_done').
class OnboardingOverlay extends StatefulWidget {
  final VoidCallback onDone;
  const OnboardingOverlay({super.key, required this.onDone});

  static const String _prefsKey = 'onboarding_done';

  /// Cek apakah onboarding sudah pernah dilihat user.
  /// Return true kalau belum pernah dilihat (perlu tampilkan).
  static Future<bool> shouldShow() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_prefsKey) ?? false);
  }

  /// Mark onboarding as seen (persist).
  static Future<void> markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, true);
  }

  @override
  State<OnboardingOverlay> createState() => _OnboardingOverlayState();
}

class _OnboardingOverlayState extends State<OnboardingOverlay> {
  int _step = 0;

  static const _steps = [
    _StepContent(
      icon: Icons.add_circle_outline_rounded,
      title: 'Input Panen Tiap Bulan',
      description:
          'Catat hasil panen Anda setiap bulan. Tap tombol "Input Panen" — bisa input 2x sebulan, semua otomatis dijumlahkan.',
      tipText: 'Tip: Input rutin = analisa makin akurat',
    ),
    _StepContent(
      icon: Icons.auto_awesome_rounded,
      title: 'AI Analisa Otomatis',
      description:
          'Setelah input, AI akan analisa hasil panen dan beri rekomendasi tindakan: pupuk, hama, irigasi.',
      tipText: 'Tip: Lengkapi data biaya pupuk untuk analisa yang spesifik',
    ),
    _StepContent(
      icon: Icons.bar_chart_rounded,
      title: 'Lihat Tren & Cetak Laporan',
      description:
          'Grafik tren bulanan, perbandingan antar lahan, untung-rugi, semua tersedia. Bisa juga cetak laporan PDF untuk koperasi/bank.',
      tipText: 'Tip: Tap menu di Beranda untuk akses semua fitur',
    ),
  ];

  Future<void> _next() async {
    if (_step < _steps.length - 1) {
      setState(() => _step++);
    } else {
      await OnboardingOverlay.markSeen();
      widget.onDone();
    }
  }

  Future<void> _skip() async {
    await OnboardingOverlay.markSeen();
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_step];
    return Material(
      color: Colors.black.withOpacity(0.78),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Skip button
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: _skip,
                  child: Text('Lewati',
                      style: AppTextStyles.body(14,
                          color: Colors.white70, weight: FontWeight.w600)),
                ),
              ),
              const Spacer(),
              // Icon
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.4),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Icon(step.icon, size: 52, color: Colors.white),
              ),
              const SizedBox(height: 28),
              // Title
              Text(step.title,
                  style: AppTextStyles.display(24, color: Colors.white),
                  textAlign: TextAlign.center),
              const SizedBox(height: 14),
              // Description
              Text(step.description,
                  style: AppTextStyles.body(15,
                      color: Colors.white.withOpacity(0.85)),
                  textAlign: TextAlign.center),
              const SizedBox(height: 22),
              // Tip
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.gold.withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lightbulb_outline_rounded,
                        color: AppColors.gold, size: 16),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(step.tipText,
                          style: AppTextStyles.body(12,
                              color: AppColors.gold, weight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Page indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                    _steps.length,
                    (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: i == _step ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: i == _step ? Colors.white : Colors.white38,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        )),
              ),
              const SizedBox(height: 22),
              // CTA button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    _step == _steps.length - 1
                        ? 'Mulai Pakai Aplikasi'
                        : 'Lanjut',
                    style: AppTextStyles.body(15,
                        color: Colors.white, weight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepContent {
  final IconData icon;
  final String title;
  final String description;
  final String tipText;
  const _StepContent({
    required this.icon,
    required this.title,
    required this.description,
    required this.tipText,
  });
}
