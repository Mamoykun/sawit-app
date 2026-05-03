import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../models/lahan_model.dart';
import '../services/api_service.dart';
import '../services/laporan_pdf_service.dart';
import '../repositories/panen_repository.dart';
import '../repositories/biaya_repository.dart';
import '../main.dart' show appDb;
import '../widgets/common_widgets.dart';
import '../widgets/offline_banner.dart';

class LaporanScreen extends StatefulWidget {
  final LahanModel lahan;

  const LaporanScreen({super.key, required this.lahan});

  @override
  State<LaporanScreen> createState() => _LaporanScreenState();
}

class _LaporanScreenState extends State<LaporanScreen> {
  late final PanenRepository _panenRepo;
  late final BiayaRepository _biayaRepo;

  int _selectedTahun = DateTime.now().year;
  int _bulanMulai = 1;
  int _bulanSelesai = 12;
  bool _includePanen = true;
  bool _includeBiaya = true;
  bool _includeProfitLoss = true;
  bool _includeAnalytics = true;

  bool _generating = false;
  String? _userName;

  static const _bulanNames = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];

  @override
  void initState() {
    super.initState();
    _panenRepo = PanenRepository(db: appDb, api: ApiService());
    _biayaRepo = BiayaRepository(db: appDb, api: ApiService());
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _userName = prefs.getString('user_name') ??
            prefs.getString('userName') ??
            'Petani';
      });
    }
  }

  Future<LaporanOptions> _buildOptions() async {
    return LaporanOptions(
      lahan: widget.lahan,
      tahun: _selectedTahun,
      bulanMulai: _bulanMulai,
      bulanSelesai: _bulanSelesai,
      includePanen: _includePanen,
      includeBiaya: _includeBiaya,
      includeProfitLoss: _includeProfitLoss,
      includeAnalytics: _includeAnalytics,
      userName: _userName ?? 'Petani',
    );
  }

  Future<({List panenList, List biayaList})> _fetchData() async {
    final panenList =
        await _panenRepo.getByLahan(widget.lahan.id, limit: 200);
    final biayaList =
        await _biayaRepo.getByLahan(widget.lahan.id, tahun: _selectedTahun);
    return (panenList: panenList, biayaList: biayaList);
  }

  Future<void> _preview() async {
    if (_generating) return;
    setState(() => _generating = true);
    try {
      final opts = await _buildOptions();
      final data = await _fetchData();
      final service = LaporanPdfService();
      await Printing.layoutPdf(
        onLayout: (_) => service.generate(
          opts,
          panenList: data.panenList.cast(),
          biayaList: data.biayaList.cast(),
        ),
        name: _fileName(widget.lahan.namaLahan),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Gagal membuat preview: $e'),
          backgroundColor: AppColors.danger,
        ));
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _share() async {
    if (_generating) return;
    setState(() => _generating = true);
    try {
      final opts = await _buildOptions();
      final data = await _fetchData();
      final service = LaporanPdfService();
      final bytes = await service.generate(
        opts,
        panenList: data.panenList.cast(),
        biayaList: data.biayaList.cast(),
      );

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${_fileName(widget.lahan.namaLahan)}');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf')],
        subject: 'Laporan SawitKu — ${widget.lahan.namaLahan}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Gagal membagikan laporan: $e'),
          backgroundColor: AppColors.danger,
        ));
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  static String _fileName(String namaLahan) {
    final now = DateTime.now();
    final slug = namaLahan.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '-');
    return 'laporan-$slug-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}.pdf';
  }

  void _showTahunPicker() {
    final current = DateTime.now().year;
    final years =
        List.generate(6, (i) => current - i).reversed.toList();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _BottomPickerSheet<int>(
        title: 'Pilih Tahun',
        options: years.map((y) => (label: '$y', value: y)).toList(),
        selected: _selectedTahun,
        onSelect: (y) => setState(() => _selectedTahun = y),
      ),
    );
  }

  void _showBulanMulaiPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _BottomPickerSheet<int>(
        title: 'Bulan Mulai',
        options: List.generate(
          12,
          (i) => (label: _bulanNames[i], value: i + 1),
        ),
        selected: _bulanMulai,
        onSelect: (m) => setState(() {
          _bulanMulai = m;
          if (_bulanSelesai < m) _bulanSelesai = m;
        }),
      ),
    );
  }

  void _showBulanSelesaiPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _BottomPickerSheet<int>(
        title: 'Bulan Selesai',
        options: List.generate(
          12,
          (i) => (label: _bulanNames[i], value: i + 1),
        ),
        selected: _bulanSelesai,
        onSelect: (m) => setState(() {
          _bulanSelesai = m;
          if (_bulanMulai > m) _bulanMulai = m;
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text('Cetak Laporan',
            style: AppTextStyles.display(18, color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Lahan info header ──
                  _LahanInfoCard(lahan: widget.lahan),
                  const SizedBox(height: 20),

                  // ── Periode ──
                  Text('PERIODE', style: AppTextStyles.label()),
                  const SizedBox(height: 10),
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Tahun
                        _PickerRow(
                          label: 'Tahun',
                          icon: Icons.calendar_today_rounded,
                          value: '$_selectedTahun',
                          onTap: _showTahunPicker,
                        ),
                        const Divider(height: 24),
                        // Bulan range
                        Row(
                          children: [
                            Expanded(
                              child: _PickerRow(
                                label: 'Dari',
                                icon: Icons.first_page_rounded,
                                value: _bulanNames[_bulanMulai - 1],
                                onTap: _showBulanMulaiPicker,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _PickerRow(
                                label: 'Sampai',
                                icon: Icons.last_page_rounded,
                                value: _bulanNames[_bulanSelesai - 1],
                                onTap: _showBulanSelesaiPicker,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Sections ──
                  Text('KONTEN LAPORAN', style: AppTextStyles.label()),
                  const SizedBox(height: 10),
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _SectionToggle(
                          icon: Icons.agriculture_rounded,
                          iconColor: AppColors.primary3,
                          title: 'Detail Panen',
                          subtitle: 'Tabel panen per bulan + sub-statistik',
                          value: _includePanen,
                          onChanged: (v) =>
                              setState(() => _includePanen = v),
                        ),
                        _Divider(),
                        _SectionToggle(
                          icon: Icons.receipt_long_rounded,
                          iconColor: AppColors.gold,
                          title: 'Detail Biaya',
                          subtitle: 'Tabel biaya per kategori & bulan',
                          value: _includeBiaya,
                          onChanged: (v) =>
                              setState(() => _includeBiaya = v),
                        ),
                        _Divider(),
                        _SectionToggle(
                          icon: Icons.account_balance_wallet_rounded,
                          iconColor: const Color(0xFF059669),
                          title: 'Profit & Loss Bulanan',
                          subtitle: 'Tabel pendapatan, biaya, profit per bulan',
                          value: _includeProfitLoss,
                          onChanged: (v) =>
                              setState(() => _includeProfitLoss = v),
                        ),
                        _Divider(),
                        _SectionToggle(
                          icon: Icons.show_chart_rounded,
                          iconColor: const Color(0xFF2563EB),
                          title: 'Analytics & KPI',
                          subtitle: 'Yield t/ha, distribusi status, insight',
                          value: _includeAnalytics,
                          onChanged: (v) =>
                              setState(() => _includeAnalytics = v),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ringkasan Eksekutif selalu disertakan.',
                    style: AppTextStyles.body(12, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _BottomActionBar(
        generating: _generating,
        onPreview: _preview,
        onShare: _share,
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _LahanInfoCard extends StatelessWidget {
  final LahanModel lahan;
  const _LahanInfoCard({required this.lahan});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primary2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(Radii.lg),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.landscape_rounded,
                  color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lahan.namaLahan,
                      style: AppTextStyles.display(15, color: Colors.white)),
                  const SizedBox(height: 3),
                  Text(
                    '${lahan.luasHa.toStringAsFixed(1)} ha  ·  Usia ${lahan.usiaPohon} thn'
                    '${lahan.lokasi != null ? '  ·  ${lahan.lokasi}' : ''}',
                    style: AppTextStyles.body(11,
                        color: Colors.white.withOpacity(0.75)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _PickerRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final String value;
  final VoidCallback onTap;

  const _PickerRow({
    required this.label,
    required this.icon,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primary3),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: AppTextStyles.body(11, color: AppColors.textMuted)),
                  const SizedBox(height: 2),
                  Text(value,
                      style: AppTextStyles.body(14,
                          color: AppColors.text, weight: FontWeight.w600)),
                ],
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded,
                color: AppColors.textMuted, size: 20),
          ],
        ),
      );
}

class _SectionToggle extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SectionToggle({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: SwitchListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          secondary: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          title: Text(title,
              style: AppTextStyles.body(13,
                  color: AppColors.text, weight: FontWeight.w600)),
          subtitle: Text(subtitle,
              style: AppTextStyles.body(11, color: AppColors.textMuted)),
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.primary,
        ),
      );
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Divider(
        height: 1,
        thickness: 1,
        color: AppColors.border,
        indent: 16,
        endIndent: 16,
      );
}

class _BottomActionBar extends StatelessWidget {
  final bool generating;
  final VoidCallback onPreview;
  final VoidCallback onShare;

  const _BottomActionBar({
    required this.generating,
    required this.onPreview,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.fromLTRB(
            20, 16, 20, 16 + MediaQuery.of(context).padding.bottom),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: const Border(top: BorderSide(color: AppColors.border)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: generating
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.primary),
                  ),
                  SizedBox(width: 12),
                  Text('Membuat laporan...'),
                ],
              )
            : Row(
                children: [
                  // Preview button
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onPreview,
                      icon: const Icon(Icons.preview_rounded, size: 18),
                      label: const Text('Preview'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary3),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Share button
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: onShare,
                      icon: const Icon(Icons.share_rounded,
                          size: 18, color: Colors.white),
                      label: const Text('Bagikan PDF',
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
      );
}

// ─── Generic bottom picker sheet ─────────────────────────────────────────────

class _BottomPickerSheet<T> extends StatelessWidget {
  final String title;
  final List<({String label, T value})> options;
  final T selected;
  final ValueChanged<T> onSelect;

  const _BottomPickerSheet({
    required this.title,
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(title, style: AppTextStyles.display(18)),
            const SizedBox(height: 8),
            ...options.map((opt) {
              final isSel = opt.value == selected;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(opt.label,
                    style: AppTextStyles.body(14,
                        color: isSel ? AppColors.primary : AppColors.text,
                        weight: isSel ? FontWeight.w700 : FontWeight.w400)),
                trailing: isSel
                    ? const Icon(Icons.check_rounded,
                        color: AppColors.primary, size: 20)
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  onSelect(opt.value);
                },
              );
            }),
          ],
        ),
      );
}
