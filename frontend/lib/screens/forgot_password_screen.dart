import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../widgets/common_widgets.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  bool _sent = false;
  String? _error;

  bool _isValidEmail(String v) =>
      RegExp(r'^[\w.+\-]+@[\w\-]+\.[a-zA-Z]{2,}$').hasMatch(v);

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Email wajib diisi');
      return;
    }
    if (!_isValidEmail(email)) {
      setState(() => _error = 'Format email tidak valid');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await ApiService().forgotPassword(email);
      if (mounted) setState(() { _sent = true; _loading = false; });
    } catch (_) {
      // Always show success to prevent email enumeration
      if (mounted) setState(() { _sent = true; _loading = false; });
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text('Lupa Password',
            style: AppTextStyles.display(16, color: Colors.white)),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _sent ? _SuccessView() : _FormView(
            emailCtrl: _emailCtrl,
            loading: _loading,
            error: _error,
            onSubmit: _submit,
          ),
        ),
      ),
    );
  }
}

class _FormView extends StatelessWidget {
  final TextEditingController emailCtrl;
  final bool loading;
  final String? error;
  final VoidCallback onSubmit;

  const _FormView({
    required this.emailCtrl,
    required this.loading,
    required this.error,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primaryTint,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Masukkan email yang terdaftar. Kami akan mengirim link untuk reset password.',
                  style: AppTextStyles.body(13, color: AppColors.primary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        if (error != null) ...[
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
                  child: Text(error!,
                      style: AppTextStyles.body(13, color: AppColors.danger)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        Text('EMAIL', style: AppTextStyles.label()),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border, width: 1.5),
          ),
          child: TextField(
            controller: emailCtrl,
            keyboardType: TextInputType.emailAddress,
            autofocus: true,
            style: AppTextStyles.body(15),
            decoration: InputDecoration(
              hintText: 'nama@email.com',
              hintStyle: AppTextStyles.body(15, color: AppColors.textLight),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 28),

        PrimaryButton(
          label: 'Kirim Link Reset',
          onTap: loading ? null : onSubmit,
          loading: loading,
        ),
      ],
    );
  }
}

class _SuccessView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 40),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFDCFCE7),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.mark_email_read_rounded,
              size: 48, color: AppColors.primary),
        ),
        const SizedBox(height: 24),
        Text('Email Terkirim!',
            style: AppTextStyles.display(22, color: AppColors.textDark)),
        const SizedBox(height: 12),
        Text(
          'Jika email Anda terdaftar, link reset password sudah dikirim. Cek inbox atau folder spam Anda.',
          textAlign: TextAlign.center,
          style: AppTextStyles.body(14, color: AppColors.textMuted),
        ),
        const SizedBox(height: 8),
        Text(
          'Link berlaku selama 1 jam.',
          textAlign: TextAlign.center,
          style: AppTextStyles.body(13, color: AppColors.textLight),
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Kembali ke Login',
                style: AppTextStyles.body(15,
                    color: AppColors.primary, weight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}
