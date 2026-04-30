import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../theme/app_theme.dart';
import '../models/diagnosa_model.dart';
import '../models/lahan_model.dart';
import '../services/api_service.dart';
import '../widgets/common_widgets.dart';
import 'diagnosa_history_screen.dart';

class DiagnosaScreen extends StatefulWidget {
  final LahanModel lahan;
  const DiagnosaScreen({super.key, required this.lahan});

  @override
  State<DiagnosaScreen> createState() => _DiagnosaScreenState();
}

class _DiagnosaScreenState extends State<DiagnosaScreen> {
  JenisDiagnosa _jenis = JenisDiagnosa.buah;
  File? _imageFile;
  List<int>? _imageBytes;
  String? _imageName;
  bool _analyzing = false;
  DiagnosaModel? _result;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1280,
        imageQuality: 85,
      );
      if (picked == null) return;

      // Compress to ~500KB max
      final original = await picked.readAsBytes();
      final compressed = await FlutterImageCompress.compressWithList(
        original,
        minWidth: 1024,
        minHeight: 1024,
        quality: 80,
      );

      if (mounted) {
        setState(() {
          _imageFile = File(picked.path);
          _imageBytes = compressed;
          _imageName = picked.name;
          _result = null; // reset previous result
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Gagal mengambil foto: $e'),
          backgroundColor: AppColors.danger,
        ));
      }
    }
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),
            ListTile(
              leading: Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.camera_alt_rounded,
                    color: AppColors.primary),
              ),
              title: Text('Ambil Foto Kamera',
                  style: AppTextStyles.body(15, weight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child:
                    const Icon(Icons.photo_library_rounded, color: AppColors.gold),
              ),
              title: Text('Pilih dari Galeri',
                  style: AppTextStyles.body(15, weight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _analyze() async {
    if (_imageBytes == null) return;
    setState(() {
      _analyzing = true;
      _result = null;
    });
    try {
      final result = await ApiService().analyzeDiagnosa(
        widget.lahan.id,
        imageBytes: _imageBytes!,
        filename: _imageName ?? 'photo.jpg',
        jenisCode: _jenis.code,
      );
      if (mounted) setState(() { _result = result; _analyzing = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _analyzing = false);
        final msg = e.toString().contains('DIAGNOSA_LIMIT_EXCEEDED')
            ? 'Kuota diagnosa AI bulan ini sudah habis. Upgrade paket untuk diagnosa lebih banyak.'
            : 'Gagal menganalisa foto. Coba lagi.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg),
          backgroundColor: AppColors.danger,
          duration: const Duration(seconds: 4),
        ));
      }
    }
  }

  void _reset() {
    setState(() {
      _imageFile = null;
      _imageBytes = null;
      _imageName = null;
      _result = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text('Diagnosa Visual AI',
            style: AppTextStyles.display(18, color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded, color: Colors.white),
            tooltip: 'Riwayat Diagnosa',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DiagnosaHistoryScreen(lahan: widget.lahan),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: AppColors.accent.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.auto_awesome_rounded,
                        color: Color(0xFF7C3AED), size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Foto buah, batang, atau pelepah sawit untuk diagnosa otomatis dari AI.',
                      style: AppTextStyles.body(12, color: AppColors.textMid),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Text('JENIS YANG DIFOTO', style: AppTextStyles.label()),
            const SizedBox(height: 10),
            Row(
              children: JenisDiagnosa.values.map((j) {
                final isSel = _jenis == j;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _jenis = j),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: isSel
                              ? AppColors.accent.withOpacity(0.1)
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSel
                                ? AppColors.accent
                                : AppColors.border,
                            width: isSel ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(_iconForJenis(j),
                                size: 22,
                                color: isSel
                                    ? AppColors.accent
                                    : AppColors.textMuted),
                            const SizedBox(height: 6),
                            Text(j.label,
                                textAlign: TextAlign.center,
                                style: AppTextStyles.body(11,
                                    color: isSel
                                        ? AppColors.accent
                                        : AppColors.textMid,
                                    weight: isSel
                                        ? FontWeight.w700
                                        : FontWeight.w500)),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Image area
            Text('FOTO', style: AppTextStyles.label()),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _analyzing ? null : _showImagePicker,
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border, width: 1.5),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _imageFile != null
                      ? Stack(
                          children: [
                            Positioned.fill(
                              child: Image.file(_imageFile!, fit: BoxFit.cover),
                            ),
                            Positioned(
                              top: 10,
                              right: 10,
                              child: GestureDetector(
                                onTap: _reset,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Icon(Icons.close_rounded,
                                      color: Colors.white, size: 18),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 56, height: 56,
                              decoration: BoxDecoration(
                                color: AppColors.primaryTint,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.add_a_photo_rounded,
                                color: AppColors.primary,
                                size: 28,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text('Tap untuk Ambil Foto',
                                style: AppTextStyles.body(14,
                                    color: AppColors.text,
                                    weight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text('Kamera atau Galeri',
                                style: AppTextStyles.body(11,
                                    color: AppColors.textMuted)),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Analyze button
            PrimaryButton(
              label: _result != null ? 'Analisa Lagi' : 'Analisa Sekarang',
              onTap: _imageBytes == null ? null : _analyze,
              loading: _analyzing,
            ),

            if (_analyzing) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Color(0xFF7C3AED),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'AI sedang menganalisa foto Anda...',
                        style: AppTextStyles.body(13,
                            color: AppColors.accent,
                            weight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (_result != null) ...[
              const SizedBox(height: 24),
              _DiagnosaResultCard(result: _result!),
            ],
          ],
        ),
      ),
    );
  }
}

IconData _iconForJenis(JenisDiagnosa j) => switch (j) {
      JenisDiagnosa.buah => Icons.eco_rounded,
      JenisDiagnosa.batang => Icons.park_rounded,
      JenisDiagnosa.pelepah => Icons.spa_rounded,
    };

class _DiagnosaResultCard extends StatelessWidget {
  final DiagnosaModel result;
  const _DiagnosaResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final sevColor = _severityColor(result.severity);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Hasil Diagnosa', style: AppTextStyles.display(17)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: sevColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: sevColor.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_severityIcon(result.severity),
                        size: 12, color: sevColor),
                    const SizedBox(width: 4),
                    Text(result.severity.label,
                        style: AppTextStyles.body(11,
                            color: sevColor, weight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
          if (result.isFallback) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.warnTint,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 14, color: AppColors.warn),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'AI sedang sibuk — saran umum ditampilkan',
                      style: AppTextStyles.body(11,
                          color: AppColors.warn, weight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (result.kondisi != null && result.kondisi!.isNotEmpty)
            _ResultSection(
              icon: Icons.visibility_rounded,
              title: 'Kondisi Terlihat',
              body: result.kondisi!,
              color: AppColors.primary,
            ),
          if (result.penyebab != null && result.penyebab!.isNotEmpty)
            _ResultSection(
              icon: Icons.search_rounded,
              title: 'Penyebab',
              body: result.penyebab!,
              color: AppColors.gold,
            ),
          if (result.rekomendasi != null && result.rekomendasi!.isNotEmpty)
            _ResultSection(
              icon: Icons.lightbulb_outline_rounded,
              title: 'Rekomendasi Tindakan',
              body: result.rekomendasi!,
              color: AppColors.accent,
            ),
        ],
      ),
    );
  }
}

class _ResultSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final Color color;

  const _ResultSection({
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTextStyles.body(12,
                          color: color, weight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(body,
                      style: AppTextStyles.body(13,
                          color: AppColors.text)),
                ],
              ),
            ),
          ],
        ),
      );
}

Color _severityColor(SeverityDiagnosa s) => switch (s) {
      SeverityDiagnosa.normal => AppColors.success,
      SeverityDiagnosa.perhatian => AppColors.gold,
      SeverityDiagnosa.kritis => AppColors.danger,
    };

IconData _severityIcon(SeverityDiagnosa s) => switch (s) {
      SeverityDiagnosa.normal => Icons.check_circle_rounded,
      SeverityDiagnosa.perhatian => Icons.warning_amber_rounded,
      SeverityDiagnosa.kritis => Icons.error_rounded,
    };
