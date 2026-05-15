import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../widgets/common_widgets.dart';
import 'lahan_screen.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  Future<void> _register() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    final phone = _phoneCtrl.text.trim();

    if (name.isEmpty || email.isEmpty || pass.isEmpty) {
      setState(() => _error = 'Nama, email, dan password wajib diisi');
      return;
    }
    if (!RegExp(r'^[\w.+\-]+@[\w\-]+\.[a-zA-Z]{2,}$').hasMatch(email)) {
      setState(() => _error = 'Format email tidak valid');
      return;
    }
    if (pass.length < 8) {
      setState(() => _error = 'Password minimal 8 karakter');
      return;
    }
    if (phone.isNotEmpty) {
      final phoneRegex = RegExp(r'^(08|\+62)[0-9]{8,12}$');
      if (!phoneRegex.hasMatch(phone)) {
        setState(() => _error = 'Format nomor HP tidak valid (contoh: 081234567890)');
        return;
      }
    }

    setState(() { _loading = true; _error = null; });
    try {
      await ApiService().register(name, email, pass, _phoneCtrl.text.trim());
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LahanScreen()),
          (_) => false,
        );
      }
    } catch (e) {
      setState(() => _error = _parseError(e));
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
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
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
          colors: [AppColors.primary2, AppColors.primary3],
          stops: [0.0, 0.5],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_back_ios_rounded,
                          color: Colors.white, size: 18),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Buat Akun Baru',
                          style: AppTextStyles.display(22, color: Colors.white)),
                      Text('Gratis selamanya untuk paket dasar',
                          style: AppTextStyles.body(12,
                              color: const Color(0xFF74C69D))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

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
                      if (_error != null) ...[
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.dangerTint,
                            border: Border.all(color: const Color(0xFFFCA5A5)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(children: [
                            const Icon(Icons.error_outline_rounded,
                                size: 18, color: AppColors.danger),
                            const SizedBox(width: 10),
                            Expanded(child: Text(_error!,
                                style: AppTextStyles.body(13, color: AppColors.danger))),
                          ]),
                        ),
                        const SizedBox(height: 20),
                      ],

                      _buildLabel('NAMA LENGKAP'),
                      _buildInput(_nameCtrl, 'Contoh: Budi Santoso'),
                      const SizedBox(height: 18),

                      _buildLabel('EMAIL'),
                      _buildInput(_emailCtrl, 'nama@email.com',
                          type: TextInputType.emailAddress),
                      const SizedBox(height: 18),

                      _buildLabel('NO. HP (OPSIONAL)'),
                      _buildInput(_phoneCtrl, '08xxxxxxxxxx',
                          type: TextInputType.phone),
                      const SizedBox(height: 18),

                      _buildLabel('PASSWORD'),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border, width: 1.5),
                        ),
                        child: Row(children: [
                          Expanded(
                            child: TextField(
                              controller: _passCtrl,
                              obscureText: _obscure,
                              style: AppTextStyles.body(15),
                              decoration: InputDecoration(
                                hintText: 'Minimal 8 karakter',
                                hintStyle: AppTextStyles.body(15, color: AppColors.textLight),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: AppColors.textMuted, size: 20,
                            ),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                        ]),
                      ),
                      const SizedBox(height: 32),

                      PrimaryButton(
                        label: 'Daftar Sekarang',
                        onTap: _loading ? null : _register,
                        loading: _loading,
                      ),
                      const SizedBox(height: 20),

                      Center(
                        child: GestureDetector(
                          onTap: () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                          ),
                          child: RichText(
                            text: TextSpan(children: [
                              TextSpan(
                                text: 'Sudah punya akun? ',
                                style: AppTextStyles.body(14, color: AppColors.textMuted),
                              ),
                              TextSpan(
                                text: 'Masuk',
                                style: AppTextStyles.body(14,
                                    color: AppColors.primary, weight: FontWeight.w700),
                              ),
                            ]),
                          ),
                        ),
                      ),
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

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: AppTextStyles.label()),
  );

  Widget _buildInput(TextEditingController ctrl, String hint,
      {TextInputType? type}) =>
      Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: TextField(
          controller: ctrl,
          keyboardType: type,
          style: AppTextStyles.body(15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.body(15, color: AppColors.textLight),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      );
}
