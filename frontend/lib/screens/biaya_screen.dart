import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/biaya_model.dart';
import '../models/lahan_model.dart';
import '../services/api_service.dart';
import '../widgets/common_widgets.dart';
import '../widgets/empty_state.dart';

class BiayaScreen extends StatefulWidget {
  final LahanModel lahan;
  const BiayaScreen({super.key, required this.lahan});

  @override
  State<BiayaScreen> createState() => _BiayaScreenState();
}

class _BiayaScreenState extends State<BiayaScreen> {
  List<BiayaModel>? _data;
  bool _loading = true;
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final list = await ApiService().getBiaya(widget.lahan.id, tahun: _selectedYear);
      if (mounted) setState(() { _data = list; _loading = false; });
    } catch (_) {
      if (mounted) {
        setState(() { _loading = false; if (_data == null) _data = []; });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Gagal memuat biaya. Coba lagi.'),
          backgroundColor: AppColors.danger,
        ));
      }
    }
  }

  Future<void> _openForm({BiayaModel? edit}) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BiayaForm(lahan: widget.lahan, edit: edit),
    );
    if (result == true) _loadData();
  }

  Future<void> _confirmDelete(BiayaModel b) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Biaya'),
        content: Text('Hapus catatan biaya ${b.kategori.label} '
            'sebesar ${_formatRp(b.jumlah)}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ApiService().deleteBiaya(widget.lahan.id, b.id);
      _loadData();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Gagal menghapus biaya'),
          backgroundColor: AppColors.danger,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _data ?? [];
    final total = data.fold<double>(0, (sum, b) => sum + b.jumlah);
    final byCategory = _groupByCategory(data);
    final byMonth = _groupByMonth(data);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text('Biaya Operasional',
            style: AppTextStyles.display(18, color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.calendar_today_rounded, color: Colors.white),
            tooltip: 'Pilih tahun',
            onSelected: (y) {
              setState(() => _selectedYear = y);
              _loadData();
            },
            itemBuilder: (_) {
              final now = DateTime.now().year;
              return List.generate(5, (i) => now - i)
                  .map((y) => PopupMenuItem(value: y, child: Text('$y')))
                  .toList();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header info
                    Row(
                      children: [
                        Expanded(
                          child: Text(widget.lahan.namaLahan,
                              style: AppTextStyles.display(18)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text('Tahun $_selectedYear',
                              style: AppTextStyles.body(11,
                                  color: AppColors.primary,
                                  weight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Total card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.gold, AppColors.goldLight],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.gold.withOpacity(0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('TOTAL PENGELUARAN $_selectedYear',
                              style: AppTextStyles.body(11,
                                  color: Colors.white.withOpacity(0.85),
                                  weight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          Text(_formatRp(total),
                              style: AppTextStyles.mono(26,
                                  color: Colors.white,
                                  weight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text('${data.length} catatan biaya',
                              style: AppTextStyles.body(12,
                                  color: Colors.white.withOpacity(0.85))),
                        ],
                      ),
                    ),

                    if (byCategory.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Text('PER KATEGORI', style: AppTextStyles.label()),
                      const SizedBox(height: 10),
                      ...byCategory.entries.map((e) => _CategoryRow(
                            kategori: e.key,
                            jumlah: e.value,
                            persen: total > 0 ? (e.value / total * 100) : 0,
                          )),
                    ],

                    if (data.isEmpty) ...[
                      const SizedBox(height: 40),
                      EmptyState.icon(
                        iconData: Icons.receipt_long_rounded,
                        title: 'Belum Ada Catatan Biaya',
                        message:
                            'Tap tombol + untuk catat pengeluaran pertama Anda — pupuk, tenaga kerja, pestisida, dan lainnya.',
                        accent: AppColors.gold,
                      ),
                    ] else ...[
                      const SizedBox(height: 24),
                      Text('RIWAYAT BIAYA', style: AppTextStyles.label()),
                      const SizedBox(height: 10),
                      ...byMonth.entries.map((e) => _MonthSection(
                            label: e.key,
                            items: e.value,
                            onEdit: (b) => _openForm(edit: b),
                            onDelete: _confirmDelete,
                          )),
                    ],
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text('Tambah Biaya',
            style: AppTextStyles.body(14,
                color: Colors.white, weight: FontWeight.w700)),
      ),
    );
  }

  Map<KategoriBiaya, double> _groupByCategory(List<BiayaModel> data) {
    final map = <KategoriBiaya, double>{};
    for (final b in data) {
      map[b.kategori] = (map[b.kategori] ?? 0) + b.jumlah;
    }
    final sorted = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sorted);
  }

  Map<String, List<BiayaModel>> _groupByMonth(List<BiayaModel> data) {
    final map = <String, List<BiayaModel>>{};
    for (final b in data) {
      final key = '${b.bulan} ${b.tahun}';
      (map[key] ??= []).add(b);
    }
    return map;
  }
}

// ─── HELPERS ─────────────────────────────────────────────────────────────────

String _formatRp(num n) {
  final f = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  return f.format(n);
}

Color _kategoriColor(KategoriBiaya k) => switch (k) {
      KategoriBiaya.pupuk => const Color(0xFF059669),
      KategoriBiaya.tenagaKerja => const Color(0xFF2563EB),
      KategoriBiaya.pestisida => const Color(0xFFDC2626),
      KategoriBiaya.peralatan => AppColors.accent,
      KategoriBiaya.lainnya => AppColors.textMuted,
    };

IconData _kategoriIcon(KategoriBiaya k) => switch (k) {
      KategoriBiaya.pupuk => Icons.eco_rounded,
      KategoriBiaya.tenagaKerja => Icons.engineering_rounded,
      KategoriBiaya.pestisida => Icons.bug_report_rounded,
      KategoriBiaya.peralatan => Icons.handyman_rounded,
      KategoriBiaya.lainnya => Icons.more_horiz_rounded,
    };

// ─── SUB-WIDGETS ─────────────────────────────────────────────────────────────

class _CategoryRow extends StatelessWidget {
  final KategoriBiaya kategori;
  final double jumlah;
  final double persen;

  const _CategoryRow({
    required this.kategori,
    required this.jumlah,
    required this.persen,
  });

  @override
  Widget build(BuildContext context) {
    final color = _kategoriColor(kategori);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_kategoriIcon(kategori), color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(kategori.label,
                      style: AppTextStyles.body(13,
                          color: AppColors.text, weight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text('${persen.toStringAsFixed(0)}% dari total',
                      style: AppTextStyles.body(11,
                          color: AppColors.textMuted)),
                ],
              ),
            ),
            Text(_formatRp(jumlah),
                style: AppTextStyles.body(14,
                    color: AppColors.text, weight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _MonthSection extends StatelessWidget {
  final String label;
  final List<BiayaModel> items;
  final ValueChanged<BiayaModel> onEdit;
  final ValueChanged<BiayaModel> onDelete;

  const _MonthSection({
    required this.label,
    required this.items,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final total = items.fold<double>(0, (sum, b) => sum + b.jumlah);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label,
                    style: AppTextStyles.body(13,
                        color: AppColors.textMid, weight: FontWeight.w700)),
                Text(_formatRp(total),
                    style: AppTextStyles.body(13,
                        color: AppColors.gold, weight: FontWeight.w700)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ...items.map((b) => _BiayaItem(
                biaya: b,
                onEdit: () => onEdit(b),
                onDelete: () => onDelete(b),
              )),
        ],
      ),
    );
  }
}

class _BiayaItem extends StatelessWidget {
  final BiayaModel biaya;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _BiayaItem({
    required this.biaya,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = _kategoriColor(biaya.kategori);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(_kategoriIcon(biaya.kategori), color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(biaya.kategori.label,
                    style: AppTextStyles.body(13,
                        color: AppColors.text, weight: FontWeight.w600)),
                if (biaya.keterangan != null && biaya.keterangan!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(biaya.keterangan!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body(11, color: AppColors.textMuted)),
                ],
              ],
            ),
          ),
          Text(_formatRp(biaya.jumlah),
              style: AppTextStyles.body(13,
                  color: AppColors.text, weight: FontWeight.w700)),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded,
                color: AppColors.textMuted, size: 20),
            onSelected: (v) {
              if (v == 'edit') onEdit();
              if (v == 'delete') onDelete();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(
                  value: 'delete',
                  child: Text('Hapus', style: TextStyle(color: AppColors.danger))),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── FORM (Bottom Sheet) ─────────────────────────────────────────────────────

class _BiayaForm extends StatefulWidget {
  final LahanModel lahan;
  final BiayaModel? edit;
  const _BiayaForm({required this.lahan, this.edit});

  @override
  State<_BiayaForm> createState() => _BiayaFormState();
}

class _BiayaFormState extends State<_BiayaForm> {
  late KategoriBiaya _kategori;
  late DateTime _date;
  final _jumlahCtrl = TextEditingController();
  final _keteranganCtrl = TextEditingController();
  bool _saving = false;

  static const _bulanNames = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.edit;
    _kategori = e?.kategori ?? KategoriBiaya.pupuk;
    _date = e != null
        ? DateTime(e.tahun, e.bulanAngka)
        : DateTime.now();
    if (e != null) {
      _jumlahCtrl.text = e.jumlah.toStringAsFixed(0);
      _keteranganCtrl.text = e.keterangan ?? '';
    }
  }

  @override
  void dispose() {
    _jumlahCtrl.dispose();
    _keteranganCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    final jumlah = double.tryParse(_jumlahCtrl.text.replaceAll('.', ''));
    if (jumlah == null || jumlah <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Jumlah harus diisi dan lebih dari 0'),
        backgroundColor: AppColors.danger,
      ));
      return;
    }
    setState(() => _saving = true);
    try {
      final api = ApiService();
      if (widget.edit == null) {
        await api.createBiaya(widget.lahan.id,
          bulan: _bulanNames[_date.month - 1],
          tahun: _date.year,
          bulanAngka: _date.month,
          kategoriCode: _kategori.code,
          jumlah: jumlah,
          keterangan: _keteranganCtrl.text.trim().isEmpty
              ? null : _keteranganCtrl.text.trim(),
        );
      } else {
        await api.updateBiaya(widget.lahan.id, widget.edit!.id,
          bulan: _bulanNames[_date.month - 1],
          tahun: _date.year,
          bulanAngka: _date.month,
          kategoriCode: _kategori.code,
          jumlah: jumlah,
          keterangan: _keteranganCtrl.text.trim().isEmpty
              ? null : _keteranganCtrl.text.trim(),
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Gagal menyimpan biaya. Coba lagi.'),
          backgroundColor: AppColors.danger,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.edit != null;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(isEdit ? 'Edit Biaya' : 'Tambah Biaya',
                  style: AppTextStyles.display(20)),
              const SizedBox(height: 18),

              Text('KATEGORI', style: AppTextStyles.label()),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: KategoriBiaya.values.map((k) {
                  final isSel = _kategori == k;
                  final c = _kategoriColor(k);
                  return GestureDetector(
                    onTap: () => setState(() => _kategori = k),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSel ? c.withOpacity(0.15) : AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(
                          color: isSel ? c : AppColors.border,
                          width: isSel ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_kategoriIcon(k),
                              size: 14,
                              color: isSel ? c : AppColors.textMuted),
                          const SizedBox(width: 6),
                          Text(k.label,
                              style: AppTextStyles.body(12,
                                  color: isSel ? c : AppColors.textMid,
                                  weight: isSel
                                      ? FontWeight.w700
                                      : FontWeight.w500)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),

              Text('JUMLAH (Rp)', style: AppTextStyles.label()),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border, width: 1.5),
                ),
                child: TextField(
                  controller: _jumlahCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: AppTextStyles.body(16, color: AppColors.text),
                  decoration: const InputDecoration(
                    hintText: '0',
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              Text('PERIODE', style: AppTextStyles.label()),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickMonth,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded,
                          size: 18, color: AppColors.textMuted),
                      const SizedBox(width: 10),
                      Text('${_bulanNames[_date.month - 1]} ${_date.year}',
                          style: AppTextStyles.body(15, color: AppColors.text)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              Text('KETERANGAN (Opsional)', style: AppTextStyles.label()),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border, width: 1.5),
                ),
                child: TextField(
                  controller: _keteranganCtrl,
                  maxLines: 2,
                  style: AppTextStyles.body(14, color: AppColors.text),
                  decoration: const InputDecoration(
                    hintText: 'Contoh: NPK 50kg, harga subsidi',
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              PrimaryButton(
                label: isEdit ? 'Simpan Perubahan' : 'Simpan Biaya',
                onTap: _save,
                loading: _saving,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
