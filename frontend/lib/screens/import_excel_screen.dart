import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../theme/app_theme.dart';
import '../models/lahan_model.dart';
import '../models/panen_model.dart';
import '../models/biaya_model.dart';
import '../repositories/panen_repository.dart';
import '../repositories/biaya_repository.dart';
import '../services/excel_import_service.dart';
import '../services/api_service.dart';
import '../main.dart' show appDb;

enum _Step { selectType, selectFile, preview, importing, done }

enum _ImportType { panen, biaya }

class ImportExcelScreen extends StatefulWidget {
  final LahanModel lahan;

  const ImportExcelScreen({super.key, required this.lahan});

  @override
  State<ImportExcelScreen> createState() => _ImportExcelScreenState();
}

class _ImportExcelScreenState extends State<ImportExcelScreen> {
  _Step _step = _Step.selectType;
  _ImportType _type = _ImportType.panen;

  // File selection
  String? _fileName;
  int? _fileSize;
  Uint8List? _fileBytes;

  // Parse results
  List<ImportRow<PanenModel>> _panenRows = [];
  List<ImportRow<BiayaModel>> _biayaRows = [];
  bool _showErrorsOnly = false;
  bool _skipErrors = true;

  // Import progress
  int _importedCount = 0;
  int _totalToImport = 0;
  double _importProgress = 0;
  bool _isGeneratingTemplate = false;

  final ExcelImportService _service = ExcelImportService();
  late final PanenRepository _panenRepo;
  late final BiayaRepository _biayaRepo;

  @override
  void initState() {
    super.initState();
    _panenRepo = PanenRepository(db: appDb, api: ApiService());
    _biayaRepo = BiayaRepository(db: appDb, api: ApiService());
  }

  // ── Computed getters ─────────────────────────────────────────────────────────

  int get _validPanenCount => _panenRows.where((r) => r.isValid).length;
  int get _errorPanenCount => _panenRows.where((r) => !r.isValid).length;
  int get _validBiayaCount => _biayaRows.where((r) => r.isValid).length;
  int get _errorBiayaCount => _biayaRows.where((r) => !r.isValid).length;

  int get _validCount =>
      _type == _ImportType.panen ? _validPanenCount : _validBiayaCount;
  int get _errorCount =>
      _type == _ImportType.panen ? _errorPanenCount : _errorBiayaCount;

  // ── Actions ──────────────────────────────────────────────────────────────────

  Future<void> _downloadTemplate(_ImportType type) async {
    setState(() => _isGeneratingTemplate = true);
    try {
      final bytes = type == _ImportType.panen
          ? await _service.generatePanenTemplate()
          : await _service.generateBiayaTemplate();

      final dir = await getTemporaryDirectory();
      final filename = type == _ImportType.panen
          ? 'template_panen.xlsx'
          : 'template_biaya.xlsx';
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: filename,
        text: 'Template import ${type == _ImportType.panen ? "data panen" : "data biaya"}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal generate template: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingTemplate = false);
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;

    setState(() {
      _fileName = file.name;
      _fileSize = file.size;
      _fileBytes = file.bytes;
    });
  }

  Future<void> _processFile() async {
    if (_fileBytes == null) return;

    setState(() {
      _panenRows = [];
      _biayaRows = [];
    });

    if (_type == _ImportType.panen) {
      final rows = await _service.parsePanenExcel(
        _fileBytes!,
        widget.lahan.id,
        widget.lahan.luasHa,
        widget.lahan.usiaPohon,
      );
      setState(() {
        _panenRows = rows;
        _step = _Step.preview;
      });
    } else {
      final rows = await _service.parseBiayaExcel(
        _fileBytes!,
        widget.lahan.id,
      );
      setState(() {
        _biayaRows = rows;
        _step = _Step.preview;
      });
    }
  }

  Future<void> _startImport() async {
    final validPanen = _panenRows.where((r) => r.isValid).toList();
    final validBiaya = _biayaRows.where((r) => r.isValid).toList();

    final total = _type == _ImportType.panen ? validPanen.length : validBiaya.length;
    setState(() {
      _step = _Step.importing;
      _totalToImport = total;
      _importedCount = 0;
      _importProgress = 0;
    });

    try {
      if (_type == _ImportType.panen) {
        for (final row in validPanen) {
          final m = row.data!;
          await _panenRepo.create(
            lahanId: widget.lahan.id,
            luasHa: m.luasHa,
            usiaPohon: m.usiaTahun,
            bulan: m.bulan,
            tahun: m.tahun!,
            bulanAngka: m.bulanAngka!,
            tanggal: m.tanggal ?? 1,
            tonAktual: m.tonAktual,
            hargaPerTon: m.hargaPerTon,
          );
          if (mounted) {
            setState(() {
              _importedCount++;
              _importProgress = _importedCount / total;
            });
          }
        }
      } else {
        for (final row in validBiaya) {
          final m = row.data!;
          await _biayaRepo.create(
            lahanId: widget.lahan.id,
            bulan: m.bulan,
            tahun: m.tahun,
            bulanAngka: m.bulanAngka,
            kategoriCode: m.kategori.code,
            jumlah: m.jumlah,
            keterangan: m.keterangan,
          );
          if (mounted) {
            setState(() {
              _importedCount++;
              _importProgress = _importedCount / total;
            });
          }
        }
      }

      if (mounted) {
        setState(() => _step = _Step.done);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Berhasil import $_importedCount data'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _step = _Step.preview);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import gagal: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: BackButton(color: AppColors.text),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Import Excel',
                style: AppTextStyles.display(18, color: AppColors.text)),
            Text(widget.lahan.namaLahan,
                style: AppTextStyles.body(12, color: AppColors.textMuted)),
          ],
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (_step) {
      case _Step.selectType:
        return _StepSelectType(
          selected: _type,
          isGenerating: _isGeneratingTemplate,
          onSelect: (t) => setState(() => _type = t),
          onDownloadTemplate: _downloadTemplate,
          onNext: () => setState(() => _step = _Step.selectFile),
        );
      case _Step.selectFile:
        return _StepSelectFile(
          type: _type,
          fileName: _fileName,
          fileSize: _fileSize,
          onPickFile: _pickFile,
          onProcess: _fileBytes != null ? _processFile : null,
          onBack: () => setState(() => _step = _Step.selectType),
        );
      case _Step.preview:
        return _StepPreview(
          type: _type,
          panenRows: _panenRows,
          biayaRows: _biayaRows,
          showErrorsOnly: _showErrorsOnly,
          skipErrors: _skipErrors,
          validCount: _validCount,
          errorCount: _errorCount,
          onToggleErrorsOnly: (v) => setState(() => _showErrorsOnly = v),
          onToggleSkipErrors: (v) => setState(() => _skipErrors = v),
          onBack: () => setState(() => _step = _Step.selectFile),
          onImport: _validCount > 0 ? _startImport : null,
        );
      case _Step.importing:
        return _StepImporting(
          progress: _importProgress,
          current: _importedCount,
          total: _totalToImport,
        );
      case _Step.done:
        return const Center(child: CircularProgressIndicator());
    }
  }
}

// ── Step 1: Select type ──────────────────────────────────────────────────────

class _StepSelectType extends StatelessWidget {
  final _ImportType selected;
  final bool isGenerating;
  final ValueChanged<_ImportType> onSelect;
  final ValueChanged<_ImportType> onDownloadTemplate;
  final VoidCallback onNext;

  const _StepSelectType({
    required this.selected,
    required this.isGenerating,
    required this.onSelect,
    required this.onDownloadTemplate,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepIndicator(current: 1, total: 3),
          const SizedBox(height: 20),
          Text('Pilih Jenis Data', style: AppTextStyles.display(20)),
          const SizedBox(height: 6),
          Text(
            'Pilih jenis data yang akan diimport dari Excel',
            style: AppTextStyles.body(13, color: AppColors.textMuted),
          ),
          const SizedBox(height: 24),
          _TypeCard(
            icon: Icons.grass_rounded,
            title: 'Data Panen',
            subtitle: 'Import riwayat hasil panen (ton, harga, bulan)',
            color: AppColors.primary,
            selected: selected == _ImportType.panen,
            onTap: () => onSelect(_ImportType.panen),
          ),
          const SizedBox(height: 14),
          _TypeCard(
            icon: Icons.receipt_long_rounded,
            title: 'Data Biaya',
            subtitle: 'Import riwayat biaya operasional (pupuk, TK, dll)',
            color: AppColors.gold,
            selected: selected == _ImportType.biaya,
            onTap: () => onSelect(_ImportType.biaya),
          ),
          const Spacer(),
          // Download template link
          Center(
            child: TextButton.icon(
              onPressed: isGenerating ? null : () => onDownloadTemplate(selected),
              icon: isGenerating
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.download_rounded, size: 18),
              label: Text(isGenerating ? 'Generating...' : 'Download Template Excel'),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Lanjut', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step 2: Select file ──────────────────────────────────────────────────────

class _StepSelectFile extends StatelessWidget {
  final _ImportType type;
  final String? fileName;
  final int? fileSize;
  final VoidCallback onPickFile;
  final VoidCallback? onProcess;
  final VoidCallback onBack;

  const _StepSelectFile({
    required this.type,
    required this.fileName,
    required this.fileSize,
    required this.onPickFile,
    required this.onProcess,
    required this.onBack,
  });

  String _formatSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepIndicator(current: 2, total: 3),
          const SizedBox(height: 20),
          Text('Pilih File Excel', style: AppTextStyles.display(20)),
          const SizedBox(height: 6),
          Text(
            'Pilih file .xlsx ${type == _ImportType.panen ? "data panen" : "data biaya"}',
            style: AppTextStyles.body(13, color: AppColors.textMuted),
          ),
          const SizedBox(height: 32),
          // Drop zone / pick button
          GestureDetector(
            onTap: onPickFile,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
              decoration: BoxDecoration(
                color: AppColors.primaryTint.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary3.withOpacity(0.4),
                  strokeAlign: BorderSide.strokeAlignInside,
                ),
              ),
              child: Column(
                children: [
                  Icon(Icons.upload_file_rounded,
                      size: 48, color: AppColors.primary3.withOpacity(0.7)),
                  const SizedBox(height: 12),
                  Text(
                    fileName ?? 'Tap untuk pilih file .xlsx',
                    style: AppTextStyles.body(
                      14,
                      color: fileName != null ? AppColors.primary : AppColors.textMuted,
                      weight: fileName != null ? FontWeight.w600 : FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (fileSize != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _formatSize(fileSize!),
                      style: AppTextStyles.body(12, color: AppColors.textMuted),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (fileName != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.success.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_rounded,
                      color: AppColors.success, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('File siap diproses',
                        style: AppTextStyles.body(13, color: AppColors.success,
                            weight: FontWeight.w600)),
                  ),
                  TextButton(
                    onPressed: onPickFile,
                    child: const Text('Ganti'),
                  ),
                ],
              ),
            ),
          ],
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onBack,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    side: BorderSide(color: AppColors.border),
                  ),
                  child: const Text('Kembali'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: onProcess,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.border,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Proses File',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Step 3: Preview ──────────────────────────────────────────────────────────

class _StepPreview extends StatefulWidget {
  final _ImportType type;
  final List<ImportRow<PanenModel>> panenRows;
  final List<ImportRow<BiayaModel>> biayaRows;
  final bool showErrorsOnly;
  final bool skipErrors;
  final int validCount;
  final int errorCount;
  final ValueChanged<bool> onToggleErrorsOnly;
  final ValueChanged<bool> onToggleSkipErrors;
  final VoidCallback onBack;
  final VoidCallback? onImport;

  const _StepPreview({
    required this.type,
    required this.panenRows,
    required this.biayaRows,
    required this.showErrorsOnly,
    required this.skipErrors,
    required this.validCount,
    required this.errorCount,
    required this.onToggleErrorsOnly,
    required this.onToggleSkipErrors,
    required this.onBack,
    required this.onImport,
  });

  @override
  State<_StepPreview> createState() => _StepPreviewState();
}

class _StepPreviewState extends State<_StepPreview> {
  final Set<int> _expanded = {};

  @override
  Widget build(BuildContext context) {
    final panenToShow = widget.showErrorsOnly
        ? widget.panenRows.where((r) => !r.isValid).toList()
        : widget.panenRows;
    final biayaToShow = widget.showErrorsOnly
        ? widget.biayaRows.where((r) => !r.isValid).toList()
        : widget.biayaRows;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StepIndicator(current: 3, total: 3),
              const SizedBox(height: 14),
              Text('Preview Data', style: AppTextStyles.display(20)),
              const SizedBox(height: 8),
              // Summary badges
              Row(
                children: [
                  _SummaryBadge(
                    label: 'Valid: ${widget.validCount}',
                    color: AppColors.success,
                    icon: Icons.check_circle_rounded,
                  ),
                  const SizedBox(width: 10),
                  _SummaryBadge(
                    label: 'Error: ${widget.errorCount}',
                    color: AppColors.danger,
                    icon: Icons.error_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Filter toggle
              Row(
                children: [
                  const Text('Tampilkan error saja'),
                  const Spacer(),
                  Switch(
                    value: widget.showErrorsOnly,
                    onChanged: widget.onToggleErrorsOnly,
                    activeColor: AppColors.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              if (widget.type == _ImportType.panen)
                ...panenToShow.map((row) => _PanenRowTile(
                      row: row,
                      expanded: _expanded.contains(row.rowNumber),
                      onToggle: () => setState(() {
                        if (_expanded.contains(row.rowNumber)) {
                          _expanded.remove(row.rowNumber);
                        } else {
                          _expanded.add(row.rowNumber);
                        }
                      }),
                    ))
              else
                ...biayaToShow.map((row) => _BiayaRowTile(
                      row: row,
                      expanded: _expanded.contains(row.rowNumber),
                      onToggle: () => setState(() {
                        if (_expanded.contains(row.rowNumber)) {
                          _expanded.remove(row.rowNumber);
                        } else {
                          _expanded.add(row.rowNumber);
                        }
                      }),
                    )),
              const SizedBox(height: 16),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            children: [
              if (widget.errorCount > 0) ...[
                Row(
                  children: [
                    Checkbox(
                      value: widget.skipErrors,
                      onChanged: (v) => widget.onToggleSkipErrors(v ?? true),
                      activeColor: AppColors.primary,
                    ),
                    Text(
                      'Skip ${widget.errorCount} row error',
                      style: AppTextStyles.body(13, color: AppColors.textMid),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.onBack,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: AppColors.border),
                      ),
                      child: const Text('Kembali'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: widget.onImport,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppColors.border,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        'Import ${widget.validCount} data valid',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Step 4: Importing ────────────────────────────────────────────────────────

class _StepImporting extends StatelessWidget {
  final double progress;
  final int current;
  final int total;

  const _StepImporting({
    required this.progress,
    required this.current,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primaryTint,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.upload_rounded,
                  color: AppColors.primary, size: 36),
            ),
            const SizedBox(height: 24),
            Text('Mengimport data...',
                style: AppTextStyles.display(18, color: AppColors.text)),
            const SizedBox(height: 8),
            Text('$current / $total',
                style: AppTextStyles.mono(14, color: AppColors.textMuted)),
            const SizedBox(height: 24),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: AppColors.border,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text('${(progress * 100).toStringAsFixed(0)}%',
                style: AppTextStyles.body(13, color: AppColors.textMid)),
          ],
        ),
      ),
    );
  }
}

// ── Row tiles ────────────────────────────────────────────────────────────────

class _PanenRowTile extends StatelessWidget {
  final ImportRow<PanenModel> row;
  final bool expanded;
  final VoidCallback onToggle;

  const _PanenRowTile({
    required this.row,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final m = row.data;
    return _RowTile(
      rowNumber: row.rowNumber,
      isValid: row.isValid,
      summary: m != null
          ? '${m.bulan} ${m.tahun} — ${m.tonAktual.toStringAsFixed(1)} ton'
          : 'Baris ${row.rowNumber}',
      errors: row.errors,
      expanded: expanded,
      onToggle: row.isValid ? null : onToggle,
    );
  }
}

class _BiayaRowTile extends StatelessWidget {
  final ImportRow<BiayaModel> row;
  final bool expanded;
  final VoidCallback onToggle;

  const _BiayaRowTile({
    required this.row,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final m = row.data;
    return _RowTile(
      rowNumber: row.rowNumber,
      isValid: row.isValid,
      summary: m != null
          ? '${m.bulan} ${m.tahun} — ${m.kategori.label} — Rp ${m.jumlah.toStringAsFixed(0)}'
          : 'Baris ${row.rowNumber}',
      errors: row.errors,
      expanded: expanded,
      onToggle: row.isValid ? null : onToggle,
    );
  }
}

class _RowTile extends StatelessWidget {
  final int rowNumber;
  final bool isValid;
  final String summary;
  final List<String> errors;
  final bool expanded;
  final VoidCallback? onToggle;

  const _RowTile({
    required this.rowNumber,
    required this.isValid,
    required this.summary,
    required this.errors,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: isValid
            ? AppColors.success.withOpacity(0.05)
            : AppColors.danger.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isValid
              ? AppColors.success.withOpacity(0.2)
              : AppColors.danger.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: isValid
                          ? AppColors.success.withOpacity(0.1)
                          : AppColors.danger.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        '$rowNumber',
                        style: AppTextStyles.mono(
                          11,
                          color: isValid ? AppColors.success : AppColors.danger,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      summary,
                      style: AppTextStyles.body(13, color: AppColors.text),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isValid)
                    Icon(Icons.check_circle_rounded,
                        color: AppColors.success, size: 18)
                  else ...[
                    Text(
                      '${errors.length} error',
                      style: AppTextStyles.body(11,
                          color: AppColors.danger, weight: FontWeight.w600),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      expanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      color: AppColors.danger,
                      size: 18,
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (expanded && errors.isNotEmpty) ...[
            const Divider(height: 1, indent: 12, endIndent: 12),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: errors
                    .map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.error_outline_rounded,
                                  size: 14, color: AppColors.danger),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  e,
                                  style: AppTextStyles.body(12,
                                      color: AppColors.danger),
                                ),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Shared helper widgets ────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int current;
  final int total;

  const _StepIndicator({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(total, (i) {
        final step = i + 1;
        final isActive = step == current;
        final isDone = step < current;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: isDone || isActive ? 28 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: isDone || isActive
                    ? AppColors.primary
                    : AppColors.border,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            if (i < total - 1) const SizedBox(width: 4),
          ],
        );
      }),
    );
  }
}

class _TypeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _TypeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.08) : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? color : AppColors.border,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTextStyles.display(15, color: AppColors.text)),
                  const SizedBox(height: 3),
                  Text(subtitle,
                      style: AppTextStyles.body(12, color: AppColors.textMuted)),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle_rounded, color: color, size: 22),
          ],
        ),
      ),
    );
  }
}

class _SummaryBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _SummaryBadge({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 5),
            Text(label,
                style: AppTextStyles.body(12,
                    color: color, weight: FontWeight.w700)),
          ],
        ),
      );
}
