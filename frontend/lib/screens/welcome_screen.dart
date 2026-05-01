import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../widgets/sawit_logo.dart';
import '../widgets/organic_background.dart';
import '../widgets/common_widgets.dart';
/// Onboarding flow: 3 slides intro → Mulai CTA → [destination] screen.
/// Persists `seen_welcome=true` flag so this is shown only once per device.
class WelcomeScreen extends StatefulWidget {
  final Widget destination;
  const WelcomeScreen({super.key, required this.destination});

  static Future<bool> shouldShow() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool('seen_welcome') ?? false);
  }

  static Future<void> markAsSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_welcome', true);
  }

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _pageCtrl = PageController();
  int _index = 0;

  static const _slides = [
    _Slide(
      icon: Icons.eco_rounded,
      iconColor: AppColors.primary3,
      title: 'Selamat datang di SawitKu',
      subtitle: 'Aplikasi Manajemen Kebun Sawit',
      body:
          'Pencatatan panen, analisa AI, dan diagnosa visual — semua dalam satu aplikasi yang dirancang khusus untuk petani Indonesia.',
    ),
    _Slide(
      icon: Icons.auto_awesome_rounded,
      iconColor: AppColors.accent,
      title: 'Diagnosa Tanaman dengan AI',
      subtitle: 'Foto · Tanya · Solusi',
      body:
          'Foto buah, batang, atau pelepah sawit Anda. AI akan analisa kondisinya dan kasih rekomendasi tindakan langsung.',
    ),
    _Slide(
      icon: Icons.shield_outlined,
      iconColor: AppColors.gold,
      title: 'Data Anda Aman',
      subtitle: 'Privasi Sesuai UU PDP',
      body:
          'Data kebun Anda terenkripsi dan tidak pernah dijual. Anda bisa hapus akun + semua data kapan saja.',
    ),
  ];

  void _next() {
    if (_index < _slides.length - 1) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    await WelcomeScreen.markAsSeen();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => widget.destination),
    );
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primary2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            const OrganicBackground(
              blobColor: Color(0xFF74C69D),
              particleColor: AppColors.goldLight,
              blobOpacity: 0.12,
              particleOpacity: 0.25,
              particleCount: 20,
            ),
            SafeArea(
              child: Column(
                children: [
                  // Top bar: logo + skip
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const SawitLogo(
                              size: 28,
                              primaryColor: Color(0xFF14532D),
                            ),
                            const SizedBox(width: 8),
                            Text('SawitKu',
                                style: AppTextStyles.hero(20,
                                    color: Colors.white)),
                          ],
                        ),
                        TextButton(
                          onPressed: _finish,
                          child: Text('Lewati',
                              style: AppTextStyles.body(13,
                                  color: Colors.white70,
                                  weight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageCtrl,
                      onPageChanged: (i) => setState(() => _index = i),
                      itemCount: _slides.length,
                      itemBuilder: (_, i) => _SlideView(slide: _slides[i]),
                    ),
                  ),
                  // Indicator dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _slides.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: i == _index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == _index
                              ? AppColors.gold
                              : Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: Spacing.xl),
                  // CTA
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: PrimaryButton(
                      label: _index == _slides.length - 1
                          ? 'Mulai Sekarang'
                          : 'Lanjut',
                      icon: _index == _slides.length - 1
                          ? Icons.check_rounded
                          : Icons.arrow_forward_rounded,
                      onTap: _next,
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

class _Slide {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String body;
  const _Slide({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.body,
  });
}

class _SlideView extends StatelessWidget {
  final _Slide slide;
  const _SlideView({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon hero
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  slide.iconColor.withOpacity(0.35),
                  slide.iconColor.withOpacity(0.10),
                ],
              ),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: slide.iconColor.withOpacity(0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: slide.iconColor.withOpacity(0.25),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(slide.icon, size: 56, color: Colors.white),
          ),
          const SizedBox(height: 36),
          Text(slide.subtitle.toUpperCase(),
              style: AppTextStyles.label(color: AppColors.goldLight)),
          const SizedBox(height: 8),
          Text(slide.title,
              textAlign: TextAlign.center,
              style: AppTextStyles.hero(28, color: Colors.white)),
          const SizedBox(height: 16),
          Text(slide.body,
              textAlign: TextAlign.center,
              style: AppTextStyles.body(14,
                  color: Colors.white.withOpacity(0.85))),
        ],
      ),
    );
  }
}
