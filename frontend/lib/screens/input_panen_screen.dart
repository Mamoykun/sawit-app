import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../theme/app_theme.dart';
import '../models/panen_model.dart';
import '../models/lahan_model.dart';
import '../models/diagnosa_model.dart';
import '../services/api_service.dart';
import '../services/analisa_service.dart';
import '../repositories/panen_repository.dart';
import '../main.dart' show appDb;
import '../widgets/common_widgets.dart';

class InputPanenScreen extends StatefulWidget {
  final LahanModel lahan;
  final ValueChanged<HasilAnalisa> onAnalisaDone;

  const InputPanenScreen({
    super.key,
    required this.lahan,
    required this.onAnalisaDone,
  });

  @override
  State<InputPanenScreen> createState() => _InputPanenScreenState();
}

class _InputPanenScreenState extends State<InputPanenScreen> {
  final _tonController = TextEditingController();
  final _hargaController = TextEditingController(text: '2400000');
  bool _loading = false;
  String _loadingLabel = '';

  late DateTime _selectedDate;

  // Optional photo
  List<int>? _imageBytes;
  String? _imageName;

  static const _bulanNames = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1280,
        imageQuality: 85,
      );
      if (picked == null) return;
      final original = await picked.readAsBytes();
      final compressed = await FlutterImageCompress.compressWithList(
        original,
        minWidth: 1024,
        minHeight: 1024,
        quality: 80,
      );
      if (mounted) {
        setState(() {
          _imageBytes = compressed;
          _imageName = picked.name;
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Gagal mengambil foto'),
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
                child: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
              ),
              title: Text('Kamera',
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
                child: const Icon(Icons.photo_library_rounded, color: AppColors.gold),
              ),
              title: Text('Galeri',
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

  bool get _canSubmit => _tonController.text.isNotEmpty;

  ({double min, double max, double mid, String fase}) get _targetPreview =>
      AnalisaService.getTarget(widget.lahan.luasHa, widget.lahan.usiaPohon);

  Future<void> _submit() async {
    final ton = double.tryParse(_tonController.text);
    if (ton == null || ton <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan hasil panen yang valid')),
      );
      return;
    }

    final harga = double.tryParse(_hargaController.text) ?? 2400000;

    setState(() {
      _loading = true;
      _loadingLabel = 'Menyimpan panen...';
    });
    try {
      final repo = PanenRepository(db: appDb, api: ApiService());
      final result = await repo.create(
        lahanId: widget.lahan.id,
        luasHa: widget.lahan.luasHa,
        usiaPohon: widget.lahan.usiaPohon,
        bulan: _bulanNames[_selectedDate.month - 1],
        tahun: _selectedDate.year,
        bulanAngka: _selectedDate.month,
        tanggal: _selectedDate.day,
        tonAktual: ton,
        hargaPerTon: harga,
      );

      // If photo attached, upload diagnosa visual in background
      if (_imageBytes != null) {
        if (mounted) {
          setState(() => _loadingLabel = 'Menganalisa foto kebun...');
        }
        try {
          await ApiService().analyzeDiagnosa(
            widget.lahan.id,
            imageBytes: _imageBytes!,
            filename: _imageName ?? 'panen.jpg',
            jenisCode: JenisDiagnosa.buah.code,
          );
        } catch (_) {
          // Photo analysis is optional, don't block panen submission
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Foto gagal dianalisa, tapi panen tersimpan.'),
              backgroundColor: AppColors.warn,
              duration: Duration(seconds: 3),
            ));
          }
        }
      }

      // Use analisa from backend; fall back to local calculation if missing
      final penyebab = result.analisa?.penyebab.isNotEmpty == true
          ? result.analisa!.penyebab
          : AnalisaService.getPenyebab(result.persenKurang);

      widget.onAnalisaDone(HasilAnalisa(panen: result, penyebab: penyebab));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_parseError(e)),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() { _loading = false; _loadingLabel = ''; });
    }
  }

  String _parseError(Object e) {
    if (e is Exception) {
      final s = e.toString();
      final msgMatch = RegExp(r'"message"\s*:\s*"([^"]+)"').firstMatch(s);
      if (msgMatch != null) return msgMatch.group(1)!;
      if (s.contains('Connection') || s.contains('timeout')) {
        return 'Tidak dapat terhubung ke server';
      }
    }
    return 'Gagal menyimpan data. Coba lagi.';
  }

  @override
  void dispose() {
    _tonController.dispose();
    _hargaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final preview = _targetPreview;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text('Input Panen',
            style: AppTextStyles.display(18, color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionTitle(
              title: 'Input Hasil Panen',
              subtitle: '${widget.lahan.namaLahan} · '
                  '${widget.lahan.luasHa.toStringAsFixed(1)} ha · '
                  'Usia ${widget.lahan.usiaPohon} thn',
            ),

            AppCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _buildPeriodePicker(),
                  const SizedBox(height: 22),
                  _TargetPreviewBox(preview: preview),
                  const SizedBox(height: 22),
                  AppInputField(
                    label: 'Hasil Panen Aktual',
                    hint: 'Contoh: ${preview.mid.toStringAsFixed(1)}',
                    suffix: 'Ton',
                    controller: _tonController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    highlight: true,
                  ),
                  const SizedBox(height: 16),
                  AppInputField(
                    label: 'Harga Per Ton',
                    hint: '2400000',
                    suffix: 'Rp',
                    controller: _hargaController,
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Optional photo section
            _PhotoSection(
              imageBytes: _imageBytes,
              onPick: _showImagePicker,
              onRemove: () => setState(() {
                _imageBytes = null;
                _imageName = null;
              }),
            ),
            const SizedBox(height: 20),

            if (_loading && _loadingLabel.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTint,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(_loadingLabel,
                          style: AppTextStyles.body(12,
                              color: AppColors.primary,
                              weight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),

            ValueListenableBuilder(
              valueListenable: _tonController,
              builder: (_, __, ___) => PrimaryButton(
                label: 'Analisa Sekarang →',
                onTap: _canSubmit ? _submit : null,
                loading: _loading,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodePicker() {
    final d = _selectedDate;
    final label = '${d.day} ${_bulanNames[d.month - 1]} ${d.year}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('TANGGAL PANEN', style: AppTextStyles.label()),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickDate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              border: Border.all(color: AppColors.border, width: 1.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 18, color: AppColors.primary3),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(label,
                      style: AppTextStyles.body(15, weight: FontWeight.w500)),
                ),
                const Icon(Icons.arrow_drop_down_rounded,
                    color: AppColors.textMuted),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PhotoSection extends StatelessWidget {
  final List<int>? imageBytes;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  const _PhotoSection({
    required this.imageBytes,
    required this.onPick,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.camera_alt_rounded,
                    color: Color(0xFF7C3AED), size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Foto Buah Sawit (Opsional)',
                        style: AppTextStyles.body(13,
                            color: AppColors.text, weight: FontWeight.w700)),
                    Text('AI akan analisa kondisi buah panen Anda',
                        style: AppTextStyles.body(11,
                            color: AppColors.textMuted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (imageBytes != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.memory(
                  Uint8List.fromList(imageBytes!),
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: onPick,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.refresh_rounded,
                              size: 16, color: AppColors.textMuted),
                          const SizedBox(width: 6),
                          Text('Ganti Foto',
                              style: AppTextStyles.body(12,
                                  color: AppColors.textMid,
                                  weight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.dangerTint,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.close_rounded,
                        size: 16, color: AppColors.danger),
                  ),
                ),
              ],
            ),
          ] else ...[
            GestureDetector(
              onTap: onPick,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.accent.withOpacity(0.3),
                    style: BorderStyle.solid,
                    width: 1.2,
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.add_a_photo_rounded,
                        color: Color(0xFF7C3AED), size: 26),
                    const SizedBox(height: 6),
                    Text('Tap untuk Tambah Foto',
                        style: AppTextStyles.body(12,
                            color: AppColors.accent,
                            weight: FontWeight.w700)),
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

class _TargetPreviewBox extends StatelessWidget {
  final ({double min, double max, double mid, String fase}) preview;
  const _TargetPreviewBox({required this.preview});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primaryTint,
          border: Border.all(color: AppColors.primary3.withOpacity(0.4)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ESTIMASI TARGET NORMAL',
                style: AppTextStyles.label(color: AppColors.primary3)),
            const SizedBox(height: 6),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text:
                        '${preview.min.toStringAsFixed(1)} – ${preview.max.toStringAsFixed(1)} ',
                    style: AppTextStyles.mono(20,
                        color: AppColors.primary, weight: FontWeight.w700),
                  ),
                  TextSpan(
                    text: 'ton/bulan',
                    style: AppTextStyles.body(13, color: AppColors.primary3),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text('Fase: ${preview.fase}',
                style: AppTextStyles.body(12, color: AppColors.primary3)),
          ],
        ),
      );
}
