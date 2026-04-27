import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/panen_model.dart';
import '../services/analisa_service.dart';
import '../widgets/common_widgets.dart';

class InputPanenScreen extends StatefulWidget {
  final ValueChanged<HasilAnalisa> onAnalisaDone;
  const InputPanenScreen({super.key, required this.onAnalisaDone});

  @override
  State<InputPanenScreen> createState() => _InputPanenScreenState();
}

class _InputPanenScreenState extends State<InputPanenScreen> {
  final _haController = TextEditingController();
  final _usiaController = TextEditingController();
  final _tonController = TextEditingController();
  String _bulan = 'April 2025';
  bool _loading = false;

  final _bulanList = [
    'April 2025', 'Maret 2025', 'Februari 2025',
    'Januari 2025', 'Desember 2024',
  ];

  bool get _canSubmit =>
      _haController.text.isNotEmpty &&
      _usiaController.text.isNotEmpty &&
      _tonController.text.isNotEmpty;

  // Preview target saat user isi luas & usia
  ({double min, double max, double mid, String fase})? get _targetPreview {
    final ha = double.tryParse(_haController.text);
    final usia = int.tryParse(_usiaController.text);
    if (ha == null || usia == null) return null;
    return AnalisaService.getTarget(ha, usia);
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      final ha = double.parse(_haController.text);
      final usia = int.parse(_usiaController.text);
      final ton = double.parse(_tonController.text);

      final panen = AnalisaService.buildPanen(
        ha: ha, usia: usia, ton: ton, bulan: _bulan,
      );
      final penyebab = AnalisaService.getPenyebab(panen.persenKurang);
      final hasil = HasilAnalisa(panen: panen, penyebab: penyebab);

      // TODO: kirim ke Spring Boot API
      // final hasil = await ApiService().inputPanen(panen);

      widget.onAnalisaDone(hasil);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _haController.dispose();
    _usiaController.dispose();
    _tonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final preview = _targetPreview;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(
            title: 'Input Hasil Panen',
            subtitle: 'Isi data kebun untuk mendapatkan analisa lengkap',
          ),

          AppCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Periode
                _buildDropdown(),
                const SizedBox(height: 22),

                // Luas
                AppInputField(
                  label: '📐  Luas Kebun',
                  hint: 'Contoh: 14',
                  suffix: 'Hektar',
                  controller: _haController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 22),

                // Usia
                AppInputField(
                  label: '🌳  Usia Pohon',
                  hint: 'Contoh: 8',
                  suffix: 'Tahun',
                  controller: _usiaController,
                ),
                const SizedBox(height: 22),

                // Preview target
                if (preview != null) ...[
                  _TargetPreviewBox(preview: preview),
                  const SizedBox(height: 22),
                ],

                // Hasil aktual
                AppInputField(
                  label: '⚖️  Hasil Panen Aktual',
                  hint: 'Contoh: 18.5',
                  suffix: 'Ton',
                  controller: _tonController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  highlight: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Listen to controller changes to rebuild button state
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
    );
  }

  Widget _buildDropdown() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('📅  PERIODE PANEN', style: AppTextStyles.label()),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          border: Border.all(color: AppColors.border, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _bulan,
            isExpanded: true,
            style: AppTextStyles.body(14),
            items: _bulanList.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
            onChanged: (v) => setState(() => _bulan = v!),
          ),
        ),
      ),
    ],
  );
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
                text: '${preview.min.toStringAsFixed(1)} – ${preview.max.toStringAsFixed(1)} ',
                style: AppTextStyles.display(20, color: AppColors.primary),
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
