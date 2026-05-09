import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../widgets/common_widgets.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  String _type = 'Saran Fitur';
  final _subjectCtrl = TextEditingController();
  final _detailCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  bool _submitting = false;

  static const _types = [
    'Saran Fitur',
    'Laporan Bug',
    'Pertanyaan',
    'Lainnya',
  ];

  @override
  void initState() {
    super.initState();
    _loadEmail();
  }

  Future<void> _loadEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('user_email') ?? '';
    if (email.isNotEmpty && mounted) {
      setState(() => _emailCtrl.text = email);
    }
  }

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _detailCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final subject = _subjectCtrl.text.trim();
    final detail = _detailCtrl.text.trim();

    if (subject.isEmpty) {
      _showSnack('Judul feedback wajib diisi', isError: true);
      return;
    }
    if (detail.length < 10) {
      _showSnack('Detail minimal 10 karakter', isError: true);
      return;
    }

    setState(() => _submitting = true);
    try {
      await ApiService().submitFeedback(
        type: _type,
        subject: subject,
        detail: detail,
        userEmail: _emailCtrl.text.trim().isNotEmpty ? _emailCtrl.text.trim() : null,
      );
      if (!mounted) return;
      _showSnack('Terima kasih! Feedback Anda sudah kami terima.');
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      _showSnack('Gagal mengirim feedback. Coba lagi nanti.', isError: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text('Kirim Feedback',
            style: AppTextStyles.display(18, color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Intro ──────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryTint,
                borderRadius: BorderRadius.circular(Radii.lg),
                border: Border.all(color: AppColors.primary3.withOpacity(0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.chat_bubble_outline_rounded,
                      color: AppColors.primary3, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Masukan Anda sangat berarti untuk kami. Ceritakan apa yang bisa kami perbaiki atau tambahkan.',
                      style: AppTextStyles.body(13,
                          color: AppColors.primary2, weight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Tipe ───────────────────────────────────────────────────────
            Text('JENIS FEEDBACK', style: AppTextStyles.label()),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _types.map((t) {
                final selected = _type == t;
                return GestureDetector(
                  onTap: () => setState(() => _type = t),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.circular(Radii.pill),
                      border: Border.all(
                        color: selected
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                    ),
                    child: Text(
                      t,
                      style: AppTextStyles.body(13,
                          color: selected ? Colors.white : AppColors.text,
                          weight: FontWeight.w600),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // ── Subject ────────────────────────────────────────────────────
            Text('JUDUL', style: AppTextStyles.label()),
            const SizedBox(height: 8),
            _InputBox(
              controller: _subjectCtrl,
              hint: 'Contoh: Tombol simpan tidak berfungsi',
              maxLines: 1,
            ),
            const SizedBox(height: 18),

            // ── Detail ─────────────────────────────────────────────────────
            Text('DETAIL', style: AppTextStyles.label()),
            const SizedBox(height: 8),
            _InputBox(
              controller: _detailCtrl,
              hint:
                  'Ceritakan lebih lengkap — apa yang terjadi, di layar apa, dan harapan Anda...',
              maxLines: 6,
            ),
            const SizedBox(height: 4),
            Text('Minimal 10 karakter',
                style: AppTextStyles.body(11, color: AppColors.textMuted)),
            const SizedBox(height: 18),

            // ── Email ──────────────────────────────────────────────────────
            Text('EMAIL (OPSIONAL)', style: AppTextStyles.label()),
            const SizedBox(height: 8),
            _InputBox(
              controller: _emailCtrl,
              hint: 'Isi jika ingin kami membalas feedback Anda',
              maxLines: 1,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 32),

            // ── Submit ─────────────────────────────────────────────────────
            PrimaryButton(
              label: 'Kirim Feedback',
              onTap: _submit,
              loading: _submitting,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Input Box ────────────────────────────────────────────────────────────────

class _InputBox extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final TextInputType? keyboardType;

  const _InputBox({
    required this.controller,
    required this.hint,
    required this.maxLines,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: AppTextStyles.body(15, color: AppColors.text),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTextStyles.body(14, color: AppColors.textLight),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}
