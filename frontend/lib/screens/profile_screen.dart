import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/theme_service.dart';
import '../models/ai_usage_stats_model.dart';
import '../widgets/common_widgets.dart';
import 'legal_screen.dart';
import 'login_screen.dart';
import 'subscription_screen.dart';

class ProfileScreen extends StatefulWidget {
  final bool embedded;
  const ProfileScreen({super.key, this.embedded = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _loading = true;
  AiUsageStatsModel? _aiStats;

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _profileSaving = false;

  final _curPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _passSaving = false;
  bool _showCur = false;
  bool _showNew = false;
  bool _showConfirm = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _curPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final data = await ApiService().getProfile();
      _nameCtrl.text = data['name'] ?? '';
      _emailCtrl.text = data['email'] ?? '';
      _phoneCtrl.text = data['phone'] ?? '';
    } catch (_) {}
    // Load AI quota — fail silently so profile still shows on network error.
    try {
      final stats = await ApiService().getAiUsageStats();
      if (mounted) setState(() => _aiStats = stats);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _saveProfile() async {
    final name = _nameCtrl.text.trim();
    if (name.length < 2) {
      _showSnack('Nama minimal 2 karakter', isError: true);
      return;
    }
    setState(() => _profileSaving = true);
    try {
      await ApiService().updateProfile(name: name, phone: _phoneCtrl.text.trim());
      _showSnack('Profil berhasil diperbarui');
    } catch (e) {
      _showSnack(_parseError(e), isError: true);
    } finally {
      if (mounted) setState(() => _profileSaving = false);
    }
  }

  Future<void> _changePassword() async {
    final cur = _curPassCtrl.text;
    final neo = _newPassCtrl.text;
    final confirm = _confirmPassCtrl.text;

    if (cur.isEmpty || neo.isEmpty || confirm.isEmpty) {
      _showSnack('Semua kolom password harus diisi', isError: true);
      return;
    }
    if (neo.length < 6) {
      _showSnack('Password baru minimal 6 karakter', isError: true);
      return;
    }
    if (neo != confirm) {
      _showSnack('Konfirmasi password tidak cocok', isError: true);
      return;
    }
    setState(() => _passSaving = true);
    try {
      await ApiService().changePassword(currentPassword: cur, newPassword: neo);
      _curPassCtrl.clear();
      _newPassCtrl.clear();
      _confirmPassCtrl.clear();
      _showSnack('Password berhasil diubah');
    } catch (e) {
      _showSnack(_parseError(e), isError: true);
    } finally {
      if (mounted) setState(() => _passSaving = false);
    }
  }

  Future<void> _confirmDeleteAccount() async {
    final passCtrl = TextEditingController();
    bool obscure = true;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Radii.lg)),
          title: Row(
            children: [
              const Icon(Icons.warning_rounded,
                  color: AppColors.danger, size: 22),
              const SizedBox(width: 8),
              Text('Hapus Akun Permanen?',
                  style: AppTextStyles.display(16, color: AppColors.danger)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Aksi ini akan menghapus PERMANEN:',
                style:
                    AppTextStyles.body(13, weight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              ..._bullet('Akun, profil, dan password Anda'),
              ..._bullet('Semua data kebun (lahan, panen, biaya)'),
              ..._bullet('Riwayat diagnosa dan foto yang diupload'),
              ..._bullet('Subscription aktif (tidak ada refund)'),
              const SizedBox(height: 12),
              Text(
                'Data tidak dapat dikembalikan setelah dihapus.',
                style: AppTextStyles.body(12,
                    color: AppColors.danger, weight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              Text('Masukkan password untuk konfirmasi:',
                  style: AppTextStyles.body(12,
                      color: AppColors.textMid, weight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: passCtrl,
                obscureText: obscure,
                decoration: InputDecoration(
                  hintText: 'Password Anda',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(Radii.md)),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  suffixIcon: IconButton(
                    icon: Icon(obscure
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded),
                    onPressed: () => setLocal(() => obscure = !obscure),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Batal')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Radii.md)),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Hapus Permanen'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;
    if (passCtrl.text.isEmpty) {
      _showSnack('Password wajib diisi untuk konfirmasi', isError: true);
      return;
    }

    try {
      await ApiService().deleteAccount(confirmPassword: passCtrl.text);
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Akun berhasil dihapus permanen'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      if (!mounted) return;
      _showSnack(_parseError(e), isError: true);
    }
  }

  List<Widget> _bullet(String text) => [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Icon(Icons.fiber_manual_record,
                    size: 6, color: AppColors.textMuted),
              ),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(text,
                      style: AppTextStyles.body(12,
                          color: AppColors.textMid))),
            ],
          ),
        ),
      ];

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar'),
        content: const Text('Yakin ingin keluar dari akun ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Keluar',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ApiService().logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.danger : AppColors.primary,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
    ));
  }

  String _parseError(Object e) {
    final s = e.toString();
    if (s.contains('WRONG_PASSWORD')) return 'Password saat ini salah';
    if (s.contains('400') || s.contains('422')) return 'Data tidak valid';
    return 'Terjadi kesalahan, coba lagi';
  }

  @override
  Widget build(BuildContext context) {
    final body = _loading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Avatar ──────────────────────────────────────────────
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.primaryTint,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary3, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          _nameCtrl.text.isNotEmpty
                              ? _nameCtrl.text[0].toUpperCase()
                              : '?',
                          style: AppTextStyles.display(32, color: AppColors.primary),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Edit Profil ──────────────────────────────────────────
                  const _SectionHeader(title: 'Informasi Akun'),
                  const SizedBox(height: 16),
                  _ProfileField(
                    label: 'Nama Lengkap',
                    controller: _nameCtrl,
                    hint: 'Masukkan nama lengkap',
                  ),
                  const SizedBox(height: 14),
                  _ProfileField(
                    label: 'Email',
                    controller: _emailCtrl,
                    hint: 'email@contoh.com',
                    readOnly: true,
                  ),
                  const SizedBox(height: 14),
                  _ProfileField(
                    label: 'Nomor HP',
                    controller: _phoneCtrl,
                    hint: 'Opsional',
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 20),
                  PrimaryButton(
                    label: 'Simpan Perubahan',
                    onTap: _saveProfile,
                    loading: _profileSaving,
                  ),

                  const SizedBox(height: 32),
                  const Divider(color: AppColors.border),
                  const SizedBox(height: 28),

                  // ── Ganti Password ──────────────────────────────────────
                  const _SectionHeader(title: 'Ganti Password'),
                  const SizedBox(height: 16),
                  _ProfileField(
                    label: 'Password Saat Ini',
                    controller: _curPassCtrl,
                    hint: '••••••••',
                    obscureText: !_showCur,
                    suffix: IconButton(
                      icon: Icon(
                        _showCur ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                        size: 20,
                        color: AppColors.textLight,
                      ),
                      onPressed: () => setState(() => _showCur = !_showCur),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _ProfileField(
                    label: 'Password Baru',
                    controller: _newPassCtrl,
                    hint: 'Min. 6 karakter',
                    obscureText: !_showNew,
                    suffix: IconButton(
                      icon: Icon(
                        _showNew ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                        size: 20,
                        color: AppColors.textLight,
                      ),
                      onPressed: () => setState(() => _showNew = !_showNew),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _ProfileField(
                    label: 'Konfirmasi Password Baru',
                    controller: _confirmPassCtrl,
                    hint: 'Ulangi password baru',
                    obscureText: !_showConfirm,
                    suffix: IconButton(
                      icon: Icon(
                        _showConfirm ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                        size: 20,
                        color: AppColors.textLight,
                      ),
                      onPressed: () => setState(() => _showConfirm = !_showConfirm),
                    ),
                  ),
                  const SizedBox(height: 20),
                  PrimaryButton(
                    label: 'Ubah Password',
                    onTap: _changePassword,
                    loading: _passSaving,
                  ),
                  const SizedBox(height: 28),

                  // ── Subscription ────────────────────────────────────────
                  const _SectionHeader(title: 'Langganan'),
                  const SizedBox(height: 14),
                  _ProfileLink(
                    icon: Icons.workspace_premium_rounded,
                    label: 'Upgrade Paket',
                    color: AppColors.gold,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SubscriptionScreen()),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── AI Quota Card ────────────────────────────────────────
                  if (_aiStats != null)
                    _AiQuotaCard(
                      stats: _aiStats!,
                      onUpgrade: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SubscriptionScreen()),
                      ),
                    )
                  else
                    _AiQuotaCard(
                      stats: null,
                      onUpgrade: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SubscriptionScreen()),
                      ),
                    ),
                  const SizedBox(height: 28),

                  // ── Tampilan ────────────────────────────────────────────
                  const _SectionHeader(title: 'Tampilan'),
                  const SizedBox(height: 14),
                  _ThemePickerCard(),
                  const SizedBox(height: 28),

                  // ── Legal & Privacy ─────────────────────────────────────
                  const _SectionHeader(title: 'Privasi & Hukum'),
                  const SizedBox(height: 14),
                  _ProfileLink(
                    icon: Icons.shield_outlined,
                    label: 'Kebijakan Privasi',
                    color: AppColors.primary,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              const LegalScreen(initialTab: LegalTab.privacy)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _ProfileLink(
                    icon: Icons.description_outlined,
                    label: 'Syarat & Ketentuan',
                    color: AppColors.primary,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              const LegalScreen(initialTab: LegalTab.terms)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _ProfileLink(
                    icon: Icons.delete_forever_outlined,
                    label: 'Hapus Akun Permanen',
                    color: AppColors.danger,
                    destructive: true,
                    onTap: _confirmDeleteAccount,
                  ),
                  const SizedBox(height: 28),

                  // ── Keluar ──────────────────────────────────────────────
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.dangerTint,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.danger.withOpacity(0.3)),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        onTap: _confirmLogout,
                        borderRadius: BorderRadius.circular(14),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.logout_rounded,
                                  color: AppColors.danger, size: 20),
                              const SizedBox(width: 10),
                              Text('Keluar dari Akun',
                                  style: AppTextStyles.body(14,
                                      color: AppColors.danger,
                                      weight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );

    if (widget.embedded) return body;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text('Profil Saya',
            style: AppTextStyles.display(18, color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: body,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: AppTextStyles.display(16, color: AppColors.text),
  );
}

class _ProfileField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool readOnly;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffix;

  const _ProfileField({
    required this.label,
    required this.hint,
    required this.controller,
    this.readOnly = false,
    this.obscureText = false,
    this.keyboardType,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label.toUpperCase(), style: AppTextStyles.label()),
      const SizedBox(height: 8),
      Container(
        decoration: BoxDecoration(
          color: readOnly ? AppColors.surfaceAlt.withOpacity(0.5) : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: TextField(
          controller: controller,
          readOnly: readOnly,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: AppTextStyles.body(15, color: readOnly ? AppColors.textMuted : AppColors.text),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.body(14, color: AppColors.textLight),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            suffixIcon: suffix,
          ),
        ),
      ),
    ],
  );
}

// ─── AI Quota Card ────────────────────────────────────────────────────────────

class _AiQuotaCard extends StatelessWidget {
  final AiUsageStatsModel? stats;
  final VoidCallback onUpgrade;

  const _AiQuotaCard({required this.stats, required this.onUpgrade});

  Color _barColor(int pct) {
    if (pct >= 100) return AppColors.danger;
    if (pct >= 75) return AppColors.warn;
    if (pct >= 50) return AppColors.gold;
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    // Skeleton while loading
    if (stats == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(Radii.lg),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: AppColors.primaryTint,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.memory_rounded,
                  size: 18, color: AppColors.primary3),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Kuota AI Bulan Ini',
                  style: AppTextStyles.body(14,
                      color: AppColors.textMid, weight: FontWeight.w600)),
            ),
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.primary3),
            ),
          ],
        ),
      );
    }

    final s = stats!;
    final isPro = s.isPro;
    final pct = s.percentUsed.clamp(0, 100);
    final barColor = _barColor(pct);
    final capCount = s.capCount;

    // Paket badge color
    final paketColor = isPro
        ? AppColors.gold
        : s.paket == 'PETANI'
            ? AppColors.primary3
            : AppColors.textMuted;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: s.isExhausted
            ? AppColors.dangerTint
            : isPro
                ? AppColors.primaryTint
                : AppColors.surface,
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(
          color: s.isExhausted
              ? AppColors.danger.withOpacity(0.3)
              : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: s.isExhausted
                      ? AppColors.danger.withOpacity(0.12)
                      : AppColors.primaryTint,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.memory_rounded,
                    size: 18,
                    color: s.isExhausted
                        ? AppColors.danger
                        : AppColors.primary3),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Kuota AI Bulan Ini',
                    style: AppTextStyles.body(14,
                        color: AppColors.text, weight: FontWeight.w700)),
              ),
              // Paket badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: paketColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(Radii.pill),
                  border: Border.all(color: paketColor.withOpacity(0.3)),
                ),
                child: Text(
                  s.paket,
                  style: AppTextStyles.body(10,
                      color: paketColor, weight: FontWeight.w700),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // PRO → unlimited display
          if (isPro) ...[
            Row(
              children: [
                const Icon(Icons.all_inclusive_rounded,
                    size: 18, color: AppColors.gold),
                const SizedBox(width: 8),
                Text(
                  'Unlimited — PRO Plan',
                  style: AppTextStyles.body(13,
                      color: AppColors.gold, weight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${s.callCount} analisa diproses bulan ini',
              style: AppTextStyles.body(12, color: AppColors.textMuted),
            ),
          ] else ...[
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(Radii.pill),
              child: LinearProgressIndicator(
                value: pct / 100.0,
                minHeight: 8,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Terpakai: ${s.callCount} dari $capCount analisa',
                  style: AppTextStyles.body(12, color: AppColors.textMid),
                ),
                Text(
                  '$pct%',
                  style: AppTextStyles.body(12,
                      color: barColor, weight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Reset otomatis tanggal 1 bulan depan',
              style: AppTextStyles.body(11, color: AppColors.textMuted),
            ),

            // Exhausted badge
            if (s.isExhausted) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.danger.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(Radii.md),
                  border: Border.all(
                      color: AppColors.danger.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_rounded,
                        size: 14, color: AppColors.danger),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Kuota Habis — Analisa berikutnya pakai Rule-Based',
                        style: AppTextStyles.body(11,
                            color: AppColors.danger,
                            weight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Upgrade CTA for non-PRO
            const SizedBox(height: 12),
            GestureDetector(
              onTap: onUpgrade,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(Radii.md),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.workspace_premium_rounded,
                        size: 16, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      s.paket == 'PETANI'
                          ? 'Upgrade ke PRO untuk Unlimited →'
                          : 'Upgrade Paket untuk lebih banyak analisa →',
                      style: AppTextStyles.body(12,
                          color: Colors.white, weight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Theme Picker Card ────────────────────────────────────────────────────────

class _ThemePickerCard extends StatefulWidget {
  @override
  State<_ThemePickerCard> createState() => _ThemePickerCardState();
}

class _ThemePickerCardState extends State<_ThemePickerCard> {
  static const _options = [
    (mode: AppThemeMode.system, label: 'Mengikuti Sistem', icon: Icons.brightness_auto_rounded),
    (mode: AppThemeMode.light,  label: 'Mode Terang',      icon: Icons.light_mode_rounded),
    (mode: AppThemeMode.dark,   label: 'Mode Gelap',       icon: Icons.dark_mode_rounded),
  ];

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceOf(context),
          borderRadius: BorderRadius.circular(Radii.lg),
          border: Border.all(color: AppColors.borderOf(context)),
        ),
        child: Column(
          children: List.generate(_options.length, (i) {
            final opt = _options[i];
            final selected = themeService.mode == opt.mode;
            final isLast = i == _options.length - 1;
            return InkWell(
              onTap: () => setState(() => themeService.setMode(opt.mode)),
              borderRadius: BorderRadius.vertical(
                top: i == 0 ? const Radius.circular(Radii.lg) : Radius.zero,
                bottom: isLast ? const Radius.circular(Radii.lg) : Radius.zero,
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Icon(opt.icon,
                            size: 22,
                            color: selected
                                ? AppColors.primary3
                                : AppColors.textMutedOf(context)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            opt.label,
                            style: AppTextStyles.body(
                              15,
                              color: selected
                                  ? AppColors.textOf(context)
                                  : AppColors.textMutedOf(context),
                              weight: selected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                        if (selected)
                          const Icon(Icons.check_circle_rounded,
                              size: 20, color: AppColors.primary3)
                        else
                          Icon(Icons.radio_button_unchecked_rounded,
                              size: 20,
                              color: AppColors.textLightOf(context)),
                      ],
                    ),
                  ),
                  if (!isLast)
                    Divider(
                      height: 1,
                      indent: 52,
                      color: AppColors.borderOf(context),
                    ),
                ],
              ),
            );
          }),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────

class _ProfileLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool destructive;
  final VoidCallback onTap;

  const _ProfileLink({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(Radii.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Radii.md),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: destructive ? AppColors.dangerTint : AppColors.surface,
              borderRadius: BorderRadius.circular(Radii.md),
              border: Border.all(
                color: destructive
                    ? AppColors.danger.withOpacity(0.2)
                    : AppColors.border,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(label,
                      style: AppTextStyles.body(14,
                          color: destructive
                              ? AppColors.danger
                              : AppColors.text,
                          weight: FontWeight.w600)),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: destructive
                        ? AppColors.danger.withOpacity(0.6)
                        : AppColors.textLight),
              ],
            ),
          ),
        ),
      );
}
