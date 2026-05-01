import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../widgets/common_widgets.dart';
import '../widgets/sawit_logo.dart';
import 'legal_screen.dart';
import 'register_screen.dart';
import 'lahan_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  bool _isValidEmail(String email) =>
      RegExp(r'^[\w.+\-]+@[\w\-]+\.[a-zA-Z]{2,}$').hasMatch(email);

  Future<void> _login() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    if (email.isEmpty || pass.isEmpty) {
      setState(() => _error = 'Email dan password wajib diisi');
      return;
    }
    if (!_isValidEmail(email)) {
      setState(() => _error = 'Format email tidak valid');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await ApiService().login(email, pass);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LahanScreen()),
        );
      }
    } catch (e) {
      final msg = _parseError(e);
      setState(() => _error = msg);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _parseError(Object e) {
    final s = e.toString();
    final msgMatch = RegExp(r'"message"\s*:\s*"([^"]+)"').firstMatch(s);
    if (msgMatch != null) return msgMatch.group(1)!;
    if (s.contains('Connection') || s.contains('timeout')) {
      return 'Tidak dapat terhubung ke server';
    }
    return 'Terjadi kesalahan, coba lagi';
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primary2],
          stops: [0.0, 0.6],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 32, 28, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SawitLogo(
                    size: 64,
                    primaryColor: Color(0xFF14532D),
                  ),
                  const SizedBox(height: 18),
                  Text('SawitKu',
                      style: AppTextStyles.hero(40, color: Colors.white)),
                  const SizedBox(height: 6),
                  Text('Masuk ke akun Anda',
                      style: AppTextStyles.body(15, color: const Color(0xFF74C69D))),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Form card
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Error
                      if (_error != null) ...[
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.dangerTint,
                            border: Border.all(color: const Color(0xFFFCA5A5)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded,
                                  size: 18, color: AppColors.danger),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(_error!,
                                    style: AppTextStyles.body(13, color: AppColors.danger)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      Text('EMAIL', style: AppTextStyles.label()),
                      const SizedBox(height: 8),
                      _TextField(
                        controller: _emailCtrl,
                        hint: 'nama@email.com',
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 20),

                      Text('PASSWORD', style: AppTextStyles.label()),
                      const SizedBox(height: 8),
                      _TextField(
                        controller: _passCtrl,
                        hint: 'Minimal 6 karakter',
                        obscure: _obscure,
                        suffix: IconButton(
                          icon: Icon(
                            _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: AppColors.textMuted,
                            size: 20,
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      const SizedBox(height: 32),

                      PrimaryButton(
                        label: 'Masuk',
                        onTap: _loading ? null : _login,
                        loading: _loading,
                      ),
                      const SizedBox(height: 20),

                      Center(
                        child: GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const RegisterScreen()),
                          ),
                          child: RichText(
                            text: TextSpan(children: [
                              TextSpan(
                                text: 'Belum punya akun? ',
                                style: AppTextStyles.body(14, color: AppColors.textMuted),
                              ),
                              TextSpan(
                                text: 'Daftar sekarang',
                                style: AppTextStyles.body(14,
                                    color: AppColors.primary, weight: FontWeight.w700),
                              ),
                            ]),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _LegalFooter(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _TextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final TextInputType? keyboardType;
  final Widget? suffix;

  const _TextField({
    required this.controller,
    required this.hint,
    this.obscure = false,
    this.keyboardType,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.border, width: 1.5),
    ),
    child: Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            obscureText: obscure,
            keyboardType: keyboardType,
            style: AppTextStyles.body(15),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTextStyles.body(15, color: AppColors.textLight),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
        if (suffix != null) suffix!,
      ],
    ),
  );
}

class _LegalFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('Dengan masuk Anda menyetujui ',
              style: AppTextStyles.body(11, color: AppColors.textMuted)),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      const LegalScreen(initialTab: LegalTab.terms)),
            ),
            child: Text('Syarat & Ketentuan',
                style: AppTextStyles.body(11,
                    color: AppColors.primary,
                    weight: FontWeight.w700)),
          ),
          Text(' dan ',
              style: AppTextStyles.body(11, color: AppColors.textMuted)),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      const LegalScreen(initialTab: LegalTab.privacy)),
            ),
            child: Text('Kebijakan Privasi',
                style: AppTextStyles.body(11,
                    color: AppColors.primary,
                    weight: FontWeight.w700)),
          ),
          Text('.',
              style: AppTextStyles.body(11, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}
