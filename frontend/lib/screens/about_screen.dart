import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/sawit_logo.dart';

// TODO: Add package_info_plus to pubspec.yaml for dynamic version reading.
// Run: flutter pub add package_info_plus
// Then replace the hardcoded version constants below with:
//   final info = await PackageInfo.fromPlatform();
//   info.version, info.buildNumber

const _kAppVersion = '1.5.0';
const _kBuildNumber = '105';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text('Tentang Aplikasi',
            style: AppTextStyles.display(18, color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 32, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Logo ────────────────────────────────────────────────────────
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.primaryTint,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary3.withOpacity(0.4), width: 2),
              ),
              child: const Center(
                child: SawitLogo(size: 56),
              ),
            ),
            const SizedBox(height: 16),

            // ── App Name ─────────────────────────────────────────────────────
            Text('Sawitku',
                style: AppTextStyles.hero(32, color: AppColors.primary)),
            const SizedBox(height: 6),
            Text(
              'Aplikasi manajemen kebun sawit\nuntuk petani Indonesia',
              textAlign: TextAlign.center,
              style: AppTextStyles.body(14, color: AppColors.textMuted),
            ),
            const SizedBox(height: 14),

            // ── Version Badge ─────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(Radii.pill),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                'Versi $_kAppVersion (Build $_kBuildNumber)',
                style: AppTextStyles.body(13,
                    color: AppColors.textMid, weight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 32),

            // ── Heart message ─────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFDCF0E3), Color(0xFFB7E4C7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(Radii.lg),
              ),
              child: Column(
                children: [
                  const Icon(Icons.favorite_rounded,
                      color: AppColors.primary, size: 28),
                  const SizedBox(height: 8),
                  Text(
                    'Dibuat dengan sepenuh hati untuk\npetani sawit Indonesia',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body(14,
                        color: AppColors.primary, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Kami percaya teknologi bisa membantu setiap petani\nmengelola kebunnya lebih baik dan lebih menguntungkan.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body(12, color: AppColors.primary2),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Links ────────────────────────────────────────────────────────
            _AboutSection(
              title: 'Informasi Hukum',
              children: [
                _AboutLink(
                  icon: Icons.privacy_tip_outlined,
                  label: 'Kebijakan Privasi',
                  onTap: () => _openUrl(
                    context,
                    'https://sawitku.id/privacy',
                  ),
                ),
                _AboutLink(
                  icon: Icons.description_outlined,
                  label: 'Syarat & Ketentuan',
                  onTap: () => _openUrl(
                    context,
                    'https://sawitku.id/terms',
                  ),
                ),
                _AboutLink(
                  icon: Icons.code_rounded,
                  label: 'Lisensi Open Source',
                  onTap: () => showLicensePage(
                    context: context,
                    applicationName: 'Sawitku',
                    applicationVersion: _kAppVersion,
                    applicationLegalese: '© 2026 Sawitku Team',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _AboutSection(
              title: 'Hubungi Kami',
              children: [
                _AboutLink(
                  icon: Icons.email_outlined,
                  label: 'support@sawitku.id',
                  onTap: () => _openUrl(
                    context,
                    'mailto:support@sawitku.id',
                  ),
                ),
                _AboutLink(
                  icon: Icons.language_rounded,
                  label: 'www.sawitku.id',
                  onTap: () => _openUrl(context, 'https://sawitku.id'),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // ── Footer ────────────────────────────────────────────────────────
            Text(
              '© 2026 Sawitku Team\nHak cipta dilindungi undang-undang',
              textAlign: TextAlign.center,
              style: AppTextStyles.body(11, color: AppColors.textLight),
            ),
          ],
        ),
      ),
    );
  }

  void _openUrl(BuildContext context, String url) {
    // TODO: Replace with url_launcher once added to pubspec.yaml:
    //   flutter pub add url_launcher
    //   import 'package:url_launcher/url_launcher.dart';
    //   launchUrl(Uri.parse(url));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Membuka: $url'),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ));
  }
}

// ─── Widgets ──────────────────────────────────────────────────────────────────

class _AboutSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _AboutSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title.toUpperCase(), style: AppTextStyles.label()),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(Radii.lg),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: List.generate(children.length, (i) {
              final isLast = i == children.length - 1;
              return Column(
                children: [
                  children[i],
                  if (!isLast)
                    const Divider(height: 1, indent: 52, color: AppColors.border),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _AboutLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AboutLink({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Radii.lg),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primaryTint,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primary3, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: AppTextStyles.body(14,
                      color: AppColors.text, weight: FontWeight.w500)),
            ),
            const Icon(Icons.open_in_new_rounded,
                size: 16, color: AppColors.textLight),
          ],
        ),
      ),
    );
  }
}
