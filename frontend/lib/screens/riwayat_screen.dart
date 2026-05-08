import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../models/panen_model.dart';
import '../models/lahan_model.dart';
import '../services/api_service.dart';
import '../services/laporan_pdf_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'laporan_screen.dart';
import '../repositories/panen_repository.dart';
import '../main.dart' show appDb;
import '../widgets/common_widgets.dart';
import '../widgets/offline_banner.dart';
import '../widgets/app_dialog.dart';
import '../widgets/app_snackbar.dart';
import 'biaya_screen.dart';

// ─── Month aggregation ────────────────────────────────────────────────────────

class _MonthSummary {
  final String bulan;
  final int? tahun;
  final int bulanAngka;
  final double tonAktual;
  final double targetMin;
  final double targetMid;
  final double targetMax;
  final int count; // number of harvests this month

  _MonthSummary({
    required this.bulan,
    this.tahun,
    required this.bulanAngka,
    required this.tonAktual,
    required this.targetMin,
    required this.targetMid,
    required this.targetMax,
    required this.count,
  });

  bool get isNormal => tonAktual >= targetMin;
}

List<_MonthSummary> _groupByMonth(List<PanenModel> data) {
  final Map<String, _MonthSummary> map = {};
  for (final p in data) {
    final key = '${p.tahun ?? 0}_${p.bulanAngka}';
    if (map.containsKey(key)) {
      final e = map[key]!;
      map[key] = _MonthSummary(
        bulan: e.bulan,
        tahun: e.tahun,
        bulanAngka: e.bulanAngka,
        tonAktual: e.tonAktual + p.tonAktual,
        targetMin: e.targetMin,
        targetMid: e.targetMid,
        targetMax: e.targetMax,
        count: e.count + 1,
      );
    } else {
      map[key] = _MonthSummary(
        bulan: p.bulan,
        tahun: p.tahun,
        bulanAngka: p.bulanAngka!,
        tonAktual: p.tonAktual,
        targetMin: p.targetMin,
        targetMid: p.targetMid,
        targetMax: p.targetMax,
        count: 1,
      );
    }
  }
  return map.values.toList()
    ..sort((a, b) {
      if ((a.tahun ?? 0) != (b.tahun ?? 0)) {
        return (a.tahun ?? 0).compareTo(b.tahun ?? 0);
      }
      return a.bulanAngka.compareTo(b.bulanAngka);
    });
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class RiwayatScreen extends StatefulWidget {
  final LahanModel lahan;
  final HasilAnalisa? lastAnalisa;

  const RiwayatScreen({
    super.key,
    required this.lahan,
    this.lastAnalisa,
  });

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  late final PanenRepository _panenRepo;
  List<PanenModel>? _data;
  bool _loading = true;
  bool _exporting = false;

  // ── Selection mode state ───────────────────────────────────────────────────
  bool _selectionMode = false;
  final Set<int> _selectedIds = {};

  void _enterSelection(int firstId) {
    setState(() {
      _selectionMode = true;
      _selectedIds.add(firstId);
    });
  }

  void _toggleSelection(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
      if (_selectedIds.isEmpty) _selectionMode = false;
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _selectionMode = false;
      _selectedIds.clear();
    });
  }

  void _selectAll(List<PanenModel> displayed) {
    setState(() {
      for (final p in displayed) {
        if (p.id != null) _selectedIds.add(p.id!);
      }
    });
  }

  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty) return;
    final count = _selectedIds.length;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Hapus $count Data Panen?', style: AppTextStyles.display(16)),
        content: Text(
          'Menghapus $count data panen sekaligus. Tindakan ini tidak dapat dibatalkan.',
          style: AppTextStyles.body(13, color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal',
                style: AppTextStyles.body(13, color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Hapus',
                style: AppTextStyles.body(13,
                    color: AppColors.danger, weight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    // Sequential delete to avoid race conditions in sync_queue
    final ids = List<int>.from(_selectedIds);
    for (final id in ids) {
      try {
        await _panenRepo.delete(
            lahanId: widget.lahan.id, panenId: id);
      } catch (_) {}
    }
    setState(() {
      _selectionMode = false;
      _selectedIds.clear();
    });
    _loadData();
  }

  // ── Search / filter / sort state ──────────────────────────────────────────
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _selectedYear = DateTime.now().year;
  String? _statusFilter; // null = semua, 'normal' | 'warn' | 'danger'
  String _sortBy = 'newest'; // 'newest' | 'oldest' | 'ton_desc' | 'ton_asc'

  String get _sortLabel => {
        'newest': 'Terbaru',
        'oldest': 'Terlama',
        'ton_desc': 'Ton ↓',
        'ton_asc': 'Ton ↑',
      }[_sortBy]!;

  @override
  void initState() {
    super.initState();
    _panenRepo = PanenRepository(db: appDb, api: ApiService());
    _loadPrefs().then((_) => _loadData());
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _selectedYear = prefs.getInt('riwayat.year') ?? DateTime.now().year;
        _statusFilter = prefs.getString('riwayat.status');
        _sortBy = prefs.getString('riwayat.sort') ?? 'newest';
      });
    }
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('riwayat.year', _selectedYear);
    if (_statusFilter != null) {
      await prefs.setString('riwayat.status', _statusFilter!);
    } else {
      await prefs.remove('riwayat.status');
    }
    await prefs.setString('riwayat.sort', _sortBy);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(RiwayatScreen old) {
    super.didUpdateWidget(old);
    if (old.lahan.id != widget.lahan.id ||
        old.lastAnalisa != widget.lastAnalisa) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      // Fetch all available data so filter/sort can work across all years
      final list = await _panenRepo.getByLahan(widget.lahan.id, limit: 500);
      if (mounted) {
        setState(() {
          _data = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
        // Preserve existing data — only show empty when first load truly returns nothing
        if (_data == null) setState(() => _data = []);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Gagal memuat riwayat. Tarik ke bawah untuk coba lagi.'),
          backgroundColor: Color(0xFFEF4444),
          duration: Duration(seconds: 3),
        ));
      }
    }
  }

  // ── Filter & sort ──────────────────────────────────────────────────────────
  List<PanenModel> _applyFilters(List<PanenModel> data) {
    var filtered = data.where((p) {
      if (p.tahun != _selectedYear) return false;
      if (_statusFilter != null && p.status != _statusFilter) return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final inBulan = p.bulan.toLowerCase().contains(q);
        final inTahun = (p.tahun ?? 0).toString().contains(q);
        final inTon = p.tonAktual.toStringAsFixed(1).contains(q);
        return inBulan || inTahun || inTon;
      }
      return true;
    }).toList();

    switch (_sortBy) {
      case 'newest':
        filtered.sort((a, b) {
          final ay = a.tahun ?? 0, by = b.tahun ?? 0;
          if (ay != by) return by.compareTo(ay);
          return (b.bulanAngka ?? 0).compareTo(a.bulanAngka ?? 0);
        });
        break;
      case 'oldest':
        filtered.sort((a, b) {
          final ay = a.tahun ?? 0, by = b.tahun ?? 0;
          if (ay != by) return ay.compareTo(by);
          return (a.bulanAngka ?? 0).compareTo(b.bulanAngka ?? 0);
        });
        break;
      case 'ton_desc':
        filtered.sort((a, b) => b.tonAktual.compareTo(a.tonAktual));
        break;
      case 'ton_asc':
        filtered.sort((a, b) => a.tonAktual.compareTo(b.tonAktual));
        break;
    }
    return filtered;
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _searchQuery = '');
  }

  void _showYearPicker() {
    final years = <int>[];
    // Collect years from data
    final allYears = (_data ?? []).map((p) => p.tahun).whereType<int>().toSet().toList()..sort();
    final current = DateTime.now().year;
    if (allYears.isEmpty) {
      years.addAll([current - 2, current - 1, current, current + 1]);
    } else {
      for (int y = allYears.first - 1; y <= allYears.last + 1; y++) {
        years.add(y);
      }
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _PickerSheet(
        title: 'Pilih Tahun',
        options: years.map((y) => _PickerOption(label: '$y', value: '$y')).toList(),
        selectedValue: '$_selectedYear',
        onSelect: (v) {
          setState(() => _selectedYear = int.parse(v));
          _savePrefs();
        },
      ),
    );
  }

  static String _statusLabel(String value) {
    switch (value) {
      case 'normal': return 'Normal';
      case 'warn': return 'Sedikit Kurang';
      case 'danger': return 'Perlu Tindakan';
      default: return value[0].toUpperCase() + value.substring(1);
    }
  }

  void _showStatusPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _PickerSheet(
        title: 'Filter Status',
        options: [
          _PickerOption(label: 'Semua Status', value: ''),
          _PickerOption(label: 'Normal', value: 'normal', color: AppColors.primary3),
          _PickerOption(label: 'Sedikit Kurang', value: 'warn', color: AppColors.warn),
          _PickerOption(label: 'Perlu Tindakan', value: 'danger', color: AppColors.danger),
        ],
        selectedValue: _statusFilter ?? '',
        onSelect: (v) {
          setState(() => _statusFilter = v.isEmpty ? null : v);
          _savePrefs();
        },
      ),
    );
  }

  void _showSortPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _PickerSheet(
        title: 'Urutan',
        options: const [
          _PickerOption(label: 'Terbaru', value: 'newest'),
          _PickerOption(label: 'Terlama', value: 'oldest'),
          _PickerOption(label: 'Ton ↓ (terbesar)', value: 'ton_desc'),
          _PickerOption(label: 'Ton ↑ (terkecil)', value: 'ton_asc'),
        ],
        selectedValue: _sortBy,
        onSelect: (v) {
          setState(() => _sortBy = v);
          _savePrefs();
        },
      ),
    );
  }

  void _resetFilters() {
    setState(() {
      _selectedYear = DateTime.now().year;
      _statusFilter = null;
      _sortBy = 'newest';
      _searchQuery = '';
      _searchController.clear();
    });
    _savePrefs();
  }

  /// Quick "panen-only" PDF export for current filtered view.
  Future<void> _exportPdf() async {
    if (_data == null || _data!.isEmpty) return;
    setState(() => _exporting = true);
    try {
      final allData = await _panenRepo.getByLahan(widget.lahan.id, limit: 999);
      final opts = LaporanOptions(
        lahan: widget.lahan,
        tahun: _selectedYear,
        includePanen: true,
        includeBiaya: false,
        includeProfitLoss: false,
        includeAnalytics: false,
        userName: 'Petani',
      );
      final bytes = await LaporanPdfService().generate(
        opts,
        panenList: allData,
        biayaList: const [],
      );
      final dir = await getTemporaryDirectory();
      final slug = widget.lahan.namaLahan
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]'), '-');
      final file = File('${dir.path}/panen-$slug-$_selectedYear.pdf');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf')],
        subject: 'Laporan Panen ${widget.lahan.namaLahan} $_selectedYear',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Gagal membuat PDF: $e'),
          backgroundColor: AppColors.danger,
        ));
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  void _openFullLaporan() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LaporanScreen(lahan: widget.lahan)),
    );
  }

  void _openBiaya() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BiayaScreen(lahan: widget.lahan)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayedData = _selectionMode
        ? (_applyFilters(_data ?? []))
        : <PanenModel>[];

    return PopScope(
      canPop: !_selectionMode,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _selectionMode) _exitSelectionMode();
      },
      child: Scaffold(
        backgroundColor: AppColors.bg,
        appBar: _selectionMode
            ? AppBar(
                backgroundColor: AppColors.primary,
                leading: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  onPressed: _exitSelectionMode,
                ),
                title: Text(
                  '${_selectedIds.length} dipilih',
                  style: AppTextStyles.display(18, color: Colors.white),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.select_all_rounded,
                        color: Colors.white),
                    tooltip: 'Pilih semua',
                    onPressed: () => _selectAll(_applyFilters(_data ?? [])),
                  ),
                  IconButton(
                    icon:
                        const Icon(Icons.delete_rounded, color: Colors.white),
                    tooltip: 'Hapus dipilih',
                    onPressed:
                        _selectedIds.isEmpty ? null : _deleteSelected,
                  ),
                ],
              )
            : AppBar(
                title: Text('Riwayat Panen',
                    style: AppTextStyles.display(18, color: Colors.white)),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded,
                      color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  // Full laporan button
                  IconButton(
                    icon: const Icon(Icons.picture_as_pdf_rounded,
                        color: Colors.white),
                    tooltip: 'Laporan Lengkap',
                    onPressed: _openFullLaporan,
                  ),
                  GestureDetector(
                    onTap: _openBiaya,
                    child: Container(
                      margin: const EdgeInsets.only(right: 16),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppColors.gold.withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.receipt_long_rounded,
                              size: 14, color: Colors.white),
                          const SizedBox(width: 5),
                          Text('Biaya',
                              style: AppTextStyles.body(11,
                                  color: Colors.white,
                                  weight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
        body: Column(
          children: [
            const OfflineBanner(),
            Expanded(child: _buildBody()),
          ],
        ),
        // Selection mode bottom action bar
        bottomNavigationBar: _selectionMode
            ? _SelectionBottomBar(
                count: _selectedIds.length,
                onDelete: _selectedIds.isEmpty ? null : _deleteSelected,
                onCancel: _exitSelectionMode,
              )
            : null,
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }

    final allData = _data ?? [];

    if (allData.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primaryTint,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.bar_chart_rounded,
                    size: 36, color: AppColors.primary3),
              ),
              const SizedBox(height: 20),
              Text('Belum Ada Riwayat', style: AppTextStyles.display(20)),
              const SizedBox(height: 8),
              Text(
                'Input data panen untuk melihat riwayat produksi',
                style: AppTextStyles.body(13, color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final data = _applyFilters(allData);
    // Summary based on all data for selected year (unfiltered by status/search)
    final yearData = allData.where((p) => p.tahun == _selectedYear).toList();
    final yearGrouped = _groupByMonth(yearData);
    final total = yearData.fold(0.0, (a, b) => a + b.tonAktual);
    final avg = yearGrouped.isEmpty ? 0.0 : total / yearGrouped.length;
    final best = yearGrouped.isEmpty
        ? 0.0
        : yearGrouped.map((m) => m.tonAktual).reduce((a, b) => a > b ? a : b);
    final multipleEntries = yearData.length > yearGrouped.length;

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primary,
      child: SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(0, 24, 0, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Riwayat Panen', style: AppTextStyles.display(22)),
                    const SizedBox(height: 3),
                    Text(
                      '${yearGrouped.length} bulan · ${yearData.length} panen · ${widget.lahan.namaLahan}',
                      style: AppTextStyles.body(13, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: _exporting ? null : _exportPdf,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _exporting ? AppColors.surfaceAlt : AppColors.primaryTint,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _exporting ? AppColors.border : AppColors.primary3,
                    ),
                  ),
                  child: _exporting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.primary),
                        )
                      : Row(
                          children: [
                            const Icon(Icons.picture_as_pdf_rounded,
                                size: 16, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Text('PDF',
                                style: AppTextStyles.body(12,
                                    color: AppColors.primary,
                                    weight: FontWeight.w700)),
                          ],
                        ),
                ),
              ),
            ],
          ),
          ),
          const SizedBox(height: 20),

          // ── Search bar ──
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari bulan...',
                hintStyle: AppTextStyles.body(13, color: AppColors.textLight),
                prefixIcon:
                    const Icon(Icons.search_rounded, color: AppColors.textMuted),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded,
                            color: AppColors.textMuted, size: 20),
                        onPressed: _clearSearch,
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surface,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.primary3, width: 1.5),
                ),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          const SizedBox(height: 12),

          // ── Filter chips ──
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _FilterChipBtn(
                  label: 'Tahun: $_selectedYear',
                  selected: true,
                  onTap: _showYearPicker,
                ),
                const SizedBox(width: 8),
                _FilterChipBtn(
                  label: 'Status: ${_statusFilter == null ? 'Semua' : _statusLabel(_statusFilter!)}',
                  selected: _statusFilter != null,
                  onTap: _showStatusPicker,
                ),
                const SizedBox(width: 8),
                _FilterChipBtn(
                  label: 'Urut: $_sortLabel',
                  selected: _sortBy != 'newest',
                  onTap: _showSortPicker,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // ── Result count ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              data.length == allData.where((p) => p.tahun == _selectedYear).length
                  ? '${data.length} panen'
                  : '${data.length} dari ${allData.where((p) => p.tahun == _selectedYear).length} panen',
              style: AppTextStyles.body(12, color: AppColors.textMuted),
            ),
          ),
          const SizedBox(height: 16),

          // ── KPI row ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
            children: [
              Expanded(
                  child: MetricCard(
                      label: 'Total',
                      value: total.toStringAsFixed(1),
                      unit: 'ton',
                      color: AppColors.primary)),
              const SizedBox(width: 10),
              Expanded(
                  child: MetricCard(
                      label: 'Rata-rata',
                      value: avg.toStringAsFixed(1),
                      unit: 'ton/bln',
                      color: AppColors.textMid)),
              const SizedBox(width: 10),
              Expanded(
                  child: MetricCard(
                      label: 'Terbaik',
                      value: best.toStringAsFixed(1),
                      unit: 'ton',
                      color: AppColors.gold)),
            ],
          ),
          ),
          const SizedBox(height: 16),

          // ── Chart (uses year data for consistent view) ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: AppCard(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Produksi vs Target',
                        style: AppTextStyles.display(15)),
                    if (multipleEntries)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.goldTint,
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(
                              color: AppColors.goldLight.withOpacity(0.4)),
                        ),
                        child: Text('Beberapa panen/bulan digabung',
                            style: AppTextStyles.body(9,
                                color: AppColors.gold,
                                weight: FontWeight.w600)),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                _BarChart(grouped: yearGrouped),
                const SizedBox(height: 12),
                const Wrap(
                  spacing: 14,
                  runSpacing: 6,
                  children: [
                    _Legend(
                        color: AppColors.primary3,
                        label: 'Cukup',
                        isBar: true),
                    _Legend(
                        color: AppColors.danger,
                        label: 'Di bawah target',
                        isBar: true),
                    _Legend(
                        color: AppColors.gold,
                        label: 'Target',
                        isBar: false),
                  ],
                ),
              ],
            ),
          ),
          ),
          const SizedBox(height: 20),

          // ── Detail list ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('DETAIL PANEN', style: AppTextStyles.label()),
              Text('${data.length} entri',
                  style: AppTextStyles.body(11, color: AppColors.textLight)),
            ],
          ),
          ),
          const SizedBox(height: 12),

          if (data.isEmpty && allData.isNotEmpty) ...[
            // Filtered empty state
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  Center(
                    child: Column(
                      children: [
                        const Icon(Icons.search_off_rounded,
                            size: 48, color: AppColors.textLight),
                        const SizedBox(height: 12),
                        Text(
                          'Tidak ada panen yang cocok',
                          style:
                              AppTextStyles.display(16, color: AppColors.textMid),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Coba ubah filter atau kata kunci',
                          style: AppTextStyles.body(13,
                              color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: _resetFilters,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.primaryTint,
                              borderRadius: BorderRadius.circular(99),
                              border: Border.all(
                                  color: AppColors.primary3.withOpacity(0.4)),
                            ),
                            child: Text('Reset Filter',
                                style: AppTextStyles.body(13,
                                    color: AppColors.primary,
                                    weight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: data
                    .map((p) => _RiwayatItem(
                          panen: p,
                          onDeleted: _loadData,
                          selectionMode: _selectionMode,
                          isSelected:
                              p.id != null && _selectedIds.contains(p.id),
                          onLongPress: p.id != null
                              ? () => _enterSelection(p.id!)
                              : null,
                          onSelectionTap: p.id != null
                              ? () => _toggleSelection(p.id!)
                              : null,
                        ))
                    .toList(),
              ),
            ),
        ],
      ),
    ),
    );
  }
}

// ─── Bar chart (grouped by month) ────────────────────────────────────────────

class _BarChart extends StatelessWidget {
  final List<_MonthSummary> grouped;
  const _BarChart({required this.grouped});

  @override
  Widget build(BuildContext context) {
    const chartHeight = 160.0;
    final allMax = grouped
        .map((m) => m.targetMax > m.tonAktual ? m.targetMax : m.tonAktual)
        .reduce((a, b) => a > b ? a : b);
    final maxVal = allMax * 1.30;
    final multiYear = grouped.map((m) => m.tahun ?? 0).toSet().length > 1;
    final targetMid = grouped.last.targetMid;
    final tgtFraction = (targetMid / maxVal).clamp(0.0, 1.0);

    return SizedBox(
      height: chartHeight + 76,
      child: Stack(
        children: [
          // Dotted target line spanning full width
          Positioned(
            left: 0,
            right: 0,
            bottom: 36 + (chartHeight * tgtFraction) - 1,
            child: _DottedTargetLine(color: AppColors.gold),
          ),
          // Target label badge
          Positioned(
            right: 0,
            bottom: 36 + (chartHeight * tgtFraction) + 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.gold,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                'Target ${targetMid.toStringAsFixed(1)}t',
                style: AppTextStyles.mono(10,
                    color: Colors.white, weight: FontWeight.w700),
              ),
            ),
          ),
          // Bars
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: grouped.map((m) {
              final barH =
                  ((m.tonAktual / maxVal) * chartHeight).clamp(14.0, chartHeight);
              final abbr = m.bulan.length > 3 ? m.bulan.substring(0, 3) : m.bulan;
              final showYear =
                  multiYear && (m.bulanAngka == 1 || m == grouped.first);
              final color = m.isNormal ? AppColors.primary3 : AppColors.danger;

              return Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Count badge when multiple harvests
                    if (m.count > 1)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          color: AppColors.gold,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text('${m.count}×',
                            style: AppTextStyles.body(8,
                                color: Colors.white,
                                weight: FontWeight.w700)),
                      ),
                    // Bar + value label inside
                    SizedBox(
                      height: chartHeight,
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: FractionallySizedBox(
                              widthFactor: 0.7,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 700),
                                curve: Curves.easeOutCubic,
                                height: barH,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      color,
                                      color.withOpacity(0.55),
                                    ],
                                  ),
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(6)),
                                ),
                                // Value label inside bar
                                child: Align(
                                  alignment: Alignment.topCenter,
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 5),
                                    child: Text(
                                      m.tonAktual.toStringAsFixed(1),
                                      style: AppTextStyles.mono(
                                        barH > 36 ? 11 : 9,
                                        color: Colors.white,
                                        weight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Month label
                    Text(
                      abbr,
                      style: AppTextStyles.body(11,
                          color: AppColors.textMid,
                          weight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                    if (showYear)
                      Text(
                        "'${(m.tahun ?? 0) % 100}",
                        style: AppTextStyles.body(9,
                            color: AppColors.textLight),
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// Dotted horizontal line for target reference
class _DottedTargetLine extends StatelessWidget {
  final Color color;
  const _DottedTargetLine({required this.color});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          const dashWidth = 5.0;
          const dashGap = 4.0;
          final count =
              (constraints.maxWidth / (dashWidth + dashGap)).floor();
          return SizedBox(
            height: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                count,
                (_) => SizedBox(
                  width: dashWidth,
                  height: 2,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
}

// ─── Riwayat list item ────────────────────────────────────────────────────────

class _RiwayatItem extends StatelessWidget {
  final PanenModel panen;
  final VoidCallback onDeleted;
  final bool selectionMode;
  final bool isSelected;
  final VoidCallback? onLongPress;
  final VoidCallback? onSelectionTap;

  const _RiwayatItem({
    required this.panen,
    required this.onDeleted,
    this.selectionMode = false,
    this.isSelected = false,
    this.onLongPress,
    this.onSelectionTap,
  });

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PanenDetailSheet(panen: panen, onDeleted: onDeleted),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ok = panen.tonAktual >= panen.targetMin;
    final pct = panen.persenKurang;
    final accentColor = isSelected
        ? AppColors.primary
        : ok
            ? AppColors.primary3
            : pct > 20
                ? AppColors.danger
                : AppColors.goldLight;

    return GestureDetector(
      onTap: selectionMode
          ? onSelectionTap
          : () => _showDetail(context),
      onLongPress: selectionMode ? null : onLongPress,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryTint
              : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary3 : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Checkbox in selection mode
              if (selectionMode)
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 0),
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textLight,
                          width: 1.5,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check_rounded,
                              color: Colors.white, size: 14)
                          : null,
                    ),
                  ),
                ),
              // Left accent bar
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius:
                      const BorderRadius.horizontal(left: Radius.circular(16)),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                panen.tanggal != null
                                    ? '${panen.tanggal} ${panen.bulan} ${panen.tahun ?? ''}'
                                    : '${panen.bulan} ${panen.tahun ?? ''}',
                                style: AppTextStyles.display(14),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Target ${panen.targetMid.toStringAsFixed(1)} ton',
                                style: AppTextStyles.body(11,
                                    color: AppColors.textMuted),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${panen.tonAktual.toStringAsFixed(1)} ton',
                                    style: AppTextStyles.display(18,
                                        color: ok
                                            ? AppColors.primary
                                            : AppColors.danger),
                                  ),
                                  const SizedBox(height: 2),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: ok
                                          ? AppColors.successTint
                                          : AppColors.dangerTint,
                                      borderRadius: BorderRadius.circular(99),
                                    ),
                                    child: Text(
                                      ok
                                          ? 'Normal'
                                          : '−${pct.toStringAsFixed(0)}%',
                                      style: AppTextStyles.body(10,
                                          color: ok
                                              ? AppColors.success
                                              : AppColors.danger,
                                          weight: FontWeight.w700),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 8),
                              if (!selectionMode)
                                const Icon(Icons.chevron_right_rounded,
                                    color: AppColors.textLight, size: 20),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      MiniProgressBar(
                        value: (panen.tonAktual / (panen.targetMax * 1.2))
                            .clamp(0.0, 1.0),
                        color:
                            ok ? AppColors.primary3 : const Color(0xFFEF4444),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Panen detail bottom sheet ────────────────────────────────────────────────

class _PanenDetailSheet extends StatefulWidget {
  final PanenModel panen;
  final VoidCallback onDeleted;
  const _PanenDetailSheet({required this.panen, required this.onDeleted});

  @override
  State<_PanenDetailSheet> createState() => _PanenDetailSheetState();
}

class _PanenDetailSheetState extends State<_PanenDetailSheet> {
  late final PanenRepository _panenRepo;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _panenRepo = PanenRepository(db: appDb, api: ApiService());
  }

  Future<void> _confirmDelete() async {
    final confirm = await AppDialog.confirm(
      context,
      title: 'Hapus Data Panen?',
      message:
          'Data panen ${widget.panen.bulan} ${widget.panen.tahun ?? ''} akan dihapus permanen.',
      confirmLabel: 'Hapus',
      destructive: true,
      icon: Icons.warning_rounded,
    );
    if (!confirm || !mounted) return;

    setState(() => _deleting = true);
    try {
      await _panenRepo.delete(lahanId: widget.panen.lahanId!, panenId: widget.panen.id!);
      if (mounted) {
        Navigator.pop(context);
        widget.onDeleted();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _deleting = false);
        final msg = e.toString().contains('404')
            ? 'Data sudah tidak ada'
            : 'Gagal menghapus data. Coba lagi.';
        AppSnackbar.error(context, msg);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final panen = widget.panen;
    final ok = panen.tonAktual >= panen.targetMin;
    final pct = panen.persenKurang;
    final statusColor = ok
        ? AppColors.primary
        : pct > 20
            ? AppColors.danger
            : AppColors.warn;
    final statusBg = ok
        ? AppColors.primaryTint
        : pct > 20
            ? AppColors.dangerTint
            : AppColors.warnTint;
    final statusLabel = ok
        ? 'Panen Normal'
        : pct > 20
            ? 'Defisit ${pct.toStringAsFixed(0)}%'
            : 'Kurang ${pct.toStringAsFixed(0)}%';

    final analisaReady = panen.analisa?.penyebab.isNotEmpty == true;
    final penyebab = analisaReady ? panen.analisa!.penyebab : _localPenyebab(pct);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            panen.tanggal != null
                                ? '${panen.tanggal} ${panen.bulan} ${panen.tahun ?? ''}'
                                : '${panen.bulan} ${panen.tahun ?? ''}',
                            style: AppTextStyles.display(20),
                          ),
                          const SizedBox(height: 2),
                          Text('Detail Panen',
                              style: AppTextStyles.body(13,
                                  color: AppColors.textMuted)),
                        ],
                      ),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () async {
                              final nav = Navigator.of(context);
                              final refreshed = await showModalBottomSheet<bool>(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) => _EditPanenSheet(panen: widget.panen),
                              );
                              if (refreshed == true) {
                                nav.pop();
                                widget.onDeleted();
                              }
                            },
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppColors.primaryTint,
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: const Icon(Icons.edit_outlined,
                                  size: 17, color: AppColors.primary3),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _deleting ? null : _confirmDelete,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppColors.dangerTint,
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: _deleting
                                  ? const Padding(
                                      padding: EdgeInsets.all(8),
                                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.danger),
                                    )
                                  : const Icon(Icons.delete_outline_rounded,
                                      size: 18, color: AppColors.danger),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceAlt,
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: const Icon(Icons.close_rounded,
                                  size: 18, color: AppColors.textMuted),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Status banner
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: statusBg,
                      border: Border.all(
                          color: statusColor.withOpacity(0.3), width: 1.5),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            RichText(
                              text: TextSpan(children: [
                                TextSpan(
                                  text: panen.tonAktual.toStringAsFixed(1),
                                  style: AppTextStyles.display(38,
                                      color: AppColors.text),
                                ),
                                TextSpan(
                                  text: ' ton',
                                  style: AppTextStyles.body(16,
                                      color: AppColors.textMid),
                                ),
                              ]),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: statusColor,
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(statusLabel,
                                  style: AppTextStyles.body(12,
                                      color: Colors.white,
                                      weight: FontWeight.w700)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        MiniProgressBar(
                          value: (panen.tonAktual / (panen.targetMax * 1.2))
                              .clamp(0.0, 1.0),
                          color: ok
                              ? AppColors.primary3
                              : const Color(0xFFEF4444),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Target normal: ${panen.targetMin.toStringAsFixed(1)} – ${panen.targetMax.toStringAsFixed(1)} ton',
                          style:
                              AppTextStyles.body(12, color: AppColors.textMid),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Metrics row
                  Row(
                    children: [
                      Expanded(
                          child: MetricCard(
                              label: 'Selisih',
                              value:
                                  '${panen.selisih >= 0 ? "+" : ""}${panen.selisih.toStringAsFixed(1)}',
                              unit: 'ton',
                              color: panen.selisih >= 0
                                  ? AppColors.primary
                                  : AppColors.danger)),
                      const SizedBox(width: 10),
                      Expanded(
                          child: MetricCard(
                              label: 'Per Hektar',
                              value: (panen.tonAktual / panen.luasHa)
                                  .toStringAsFixed(2),
                              unit: 't/ha',
                              color: AppColors.textMid)),
                      const SizedBox(width: 10),
                      Expanded(
                          child: MetricCard(
                              label: 'Est. Nilai',
                              value:
                                  'Rp ${(panen.nilaiEstimasi / 1000000).toStringAsFixed(0)}jt',
                              unit: 'estimasi',
                              color: AppColors.gold)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Analisa penyebab
                  if (!ok && penyebab.isNotEmpty) ...[
                    Row(
                      children: [
                        Text('Analisa Penyebab',
                            style: AppTextStyles.display(16)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: analisaReady ? AppColors.gold : AppColors.textLight,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(analisaReady ? 'AI' : 'Lokal',
                              style: AppTextStyles.body(10,
                                  color: Colors.white,
                                  weight: FontWeight.w700)),
                        ),
                      ],
                    ),
                    if (!analisaReady) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.goldTint,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.goldLight.withOpacity(0.4)),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 10, height: 10,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold)),
                            const SizedBox(width: 10),
                            Text('Analisa AI sedang diproses...',
                                style: AppTextStyles.body(12, color: AppColors.gold)),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    ...penyebab.map((c) => _PenyebabTile(penyebab: c)),
                  ],

                  if (ok)
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.primaryTint,
                        border: Border.all(
                            color: AppColors.primary3.withOpacity(0.35)),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Panen Sesuai Target!',
                              style: AppTextStyles.display(15,
                                  color: AppColors.primary)),
                          const SizedBox(height: 6),
                          Text(
                            'Pertahankan jadwal pemupukan dan pastikan panen tepat waktu '
                            'agar kualitas TBS tetap optimal.',
                            style: AppTextStyles.body(13,
                                color: AppColors.primary3),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<AnalisaPenyebab> _localPenyebab(double pct) {
    final list = <AnalisaPenyebab>[];
    if (pct > 8) {
      list.add(AnalisaPenyebab(
          icon: 'eco',
          title: 'Defisiensi Kalium (K)',
          detail:
              'Aplikasikan pupuk MOP 0.5–1 kg per pohon untuk meningkatkan bobot tandan.',
          severity: 'high'));
    }
    if (pct > 15) {
      list.add(AnalisaPenyebab(
          icon: 'water',
          title: 'Stres Kekeringan',
          detail:
              'Pasang mulsa pelepah di piringan pohon untuk menjaga kelembaban tanah.',
          severity: 'high'));
    }
    if (pct > 20) {
      list.add(AnalisaPenyebab(
          icon: 'bug',
          title: 'Serangan Hama / Penyakit',
          detail:
              'Periksa tanda ulat api, kumbang badak, atau gejala Ganoderma di pangkal batang.',
          severity: 'medium'));
    }
    if (pct > 0 && list.isEmpty) {
      list.add(AnalisaPenyebab(
          icon: 'thermostat',
          title: 'Faktor Musiman Normal',
          detail:
              'Fluktuasi 1–8% masih dalam batas wajar akibat perubahan cuaca dan siklus alami sawit.',
          severity: 'low'));
    }
    return list;
  }
}

// ─── Edit panen sheet ─────────────────────────────────────────────────────────

class _EditPanenSheet extends StatefulWidget {
  final PanenModel panen;
  const _EditPanenSheet({required this.panen});

  @override
  State<_EditPanenSheet> createState() => _EditPanenSheetState();
}

class _EditPanenSheetState extends State<_EditPanenSheet> {
  late final PanenRepository _panenRepo;
  late TextEditingController _tonCtrl;
  late TextEditingController _hargaCtrl;
  late DateTime _selectedDate;
  bool _loading = false;

  static const _bulanNames = [
    'Januari','Februari','Maret','April','Mei','Juni',
    'Juli','Agustus','September','Oktober','November','Desember',
  ];

  @override
  void initState() {
    super.initState();
    _panenRepo = PanenRepository(db: appDb, api: ApiService());
    _tonCtrl = TextEditingController(
        text: widget.panen.tonAktual.toStringAsFixed(2));
    _hargaCtrl = TextEditingController(
        text: widget.panen.hargaPerTon.toStringAsFixed(0));
    final p = widget.panen;
    _selectedDate = DateTime(
      p.tahun ?? DateTime.now().year,
      p.bulanAngka ?? DateTime.now().month,
      p.tanggal ?? 1,
    );
  }

  @override
  void dispose() {
    _tonCtrl.dispose();
    _hargaCtrl.dispose();
    super.dispose();
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

  Future<void> _submit() async {
    final ton = double.tryParse(_tonCtrl.text);
    if (ton == null || ton <= 0) return;
    final harga = double.tryParse(_hargaCtrl.text) ?? 2400000;

    setState(() => _loading = true);
    try {
      await _panenRepo.update(
        lahanId: widget.panen.lahanId!,
        panenId: widget.panen.id!,
        luasHa: widget.panen.luasHa,
        usiaPohon: widget.panen.usiaTahun,
        bulan: _bulanNames[_selectedDate.month - 1],
        tahun: _selectedDate.year,
        bulanAngka: _selectedDate.month,
        tanggal: _selectedDate.day,
        tonAktual: ton,
        hargaPerTon: harga,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = _selectedDate;
    final dateLabel = '${d.day} ${_bulanNames[d.month - 1]} ${d.year}';

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Edit Panen', style: AppTextStyles.display(18)),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Date picker
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
                      child: Text(dateLabel,
                          style: AppTextStyles.body(15, weight: FontWeight.w500)),
                    ),
                    const Icon(Icons.arrow_drop_down_rounded,
                        color: AppColors.textMuted),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            AppInputField(
              label: 'Hasil Panen Aktual',
              hint: '0.0',
              suffix: 'Ton',
              controller: _tonCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              highlight: true,
            ),
            const SizedBox(height: 14),
            AppInputField(
              label: 'Harga Per Ton',
              hint: '2400000',
              suffix: 'Rp',
              controller: _hargaCtrl,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),

            ValueListenableBuilder(
              valueListenable: _tonCtrl,
              builder: (_, __, ___) => PrimaryButton(
                label: 'Simpan Perubahan',
                onTap: _tonCtrl.text.isNotEmpty ? _submit : null,
                loading: _loading,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Penyebab tile ────────────────────────────────────────────────────────────

class _PenyebabTile extends StatelessWidget {
  final AnalisaPenyebab penyebab;
  const _PenyebabTile({required this.penyebab});

  Color get _accent => penyebab.severity == 'high'
      ? AppColors.danger
      : penyebab.severity == 'medium'
          ? AppColors.goldLight
          : AppColors.primary3;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(
            left: BorderSide(color: _accent, width: 4),
            top: const BorderSide(color: AppColors.border),
            right: const BorderSide(color: AppColors.border),
            bottom: const BorderSide(color: AppColors.border),
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primary3.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(penyebabIconData(penyebab.iconKey),
                      color: AppColors.primary3, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(penyebab.title,
                        style: AppTextStyles.body(13,
                            color: AppColors.textMid,
                            weight: FontWeight.w700))),
                StatusBadge(label: penyebab.severity, severity: penyebab.severity),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(8)),
              child: Text(penyebab.detail,
                  style: AppTextStyles.body(12, color: AppColors.textMid)),
            ),
          ],
        ),
      );
}

// ─── Legend ───────────────────────────────────────────────────────────────────

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  final bool isBar;

  const _Legend(
      {required this.color, required this.label, required this.isBar});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          isBar
              ? Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                      color: color, borderRadius: BorderRadius.circular(3)))
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    3,
                    (i) => Container(
                      width: 4,
                      height: 2,
                      margin: EdgeInsets.only(right: i < 2 ? 2 : 0),
                      decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(1)),
                    ),
                  ),
                ),
          const SizedBox(width: 6),
          Text(label,
              style: AppTextStyles.body(11,
                  color: AppColors.textMid, weight: FontWeight.w500)),
        ],
      );
}

// ─── Filter chip button ───────────────────────────────────────────────────────

class _FilterChipBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChipBtn({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryTint : AppColors.surface,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
              color: selected
                  ? AppColors.primary3.withOpacity(0.6)
                  : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTextStyles.body(
                  12,
                  color: selected ? AppColors.primary : AppColors.textMid,
                  weight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: selected ? AppColors.primary : AppColors.textMuted,
              ),
            ],
          ),
        ),
      );
}

// ─── Picker option model ──────────────────────────────────────────────────────

class _PickerOption {
  final String label;
  final String value;
  final Color? color;

  const _PickerOption({required this.label, required this.value, this.color});
}

// ─── Bottom sheet picker ──────────────────────────────────────────────────────

class _PickerSheet extends StatelessWidget {
  final String title;
  final List<_PickerOption> options;
  final String selectedValue;
  final ValueChanged<String> onSelect;

  const _PickerSheet({
    required this.title,
    required this.options,
    required this.selectedValue,
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
            // Handle
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
            const SizedBox(height: 12),
            ...options.map((opt) {
              final isSelected = opt.value == selectedValue;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: opt.color != null
                    ? Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: opt.color,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      )
                    : null,
                title: Text(
                  opt.label,
                  style: AppTextStyles.body(
                    14,
                    color: isSelected ? AppColors.primary : AppColors.text,
                    weight: isSelected ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
                trailing: isSelected
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

// ─── Selection mode bottom action bar ────────────────────────────────────────

class _SelectionBottomBar extends StatelessWidget {
  final int count;
  final VoidCallback? onDelete;
  final VoidCallback onCancel;

  const _SelectionBottomBar({
    required this.count,
    required this.onDelete,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.fromLTRB(
            20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onCancel,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textMid,
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Batal'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_rounded,
                    color: Colors.white, size: 18),
                label: Text(
                  'Hapus $count Data',
                  style: const TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  padding: const EdgeInsets.symmetric(vertical: 13),
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
