// frontend/lib/screens/inventory_pupuk_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/lahan_model.dart';
import '../repositories/inventory_pupuk_repository.dart';
import '../main.dart' show appDb;
import '../widgets/empty_state.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/app_dialog.dart';
import '../widgets/common_widgets.dart';

final _numFmt = NumberFormat('#,##0.#', 'id_ID');

class InventoryPupukScreen extends StatefulWidget {
  final LahanModel lahan;
  const InventoryPupukScreen({super.key, required this.lahan});

  @override
  State<InventoryPupukScreen> createState() => _InventoryPupukScreenState();
}

class _InventoryPupukScreenState extends State<InventoryPupukScreen> {
  late final InventoryPupukRepository _repo;
  List<InventoryPupukModel> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _repo = InventoryPupukRepository(db: appDb);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final items = await _repo.getByLahan(widget.lahan.id);
      if (mounted) setState(() { _items = items; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openForm({InventoryPupukModel? edit}) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _InventoryForm(
        lahan: widget.lahan, edit: edit),
    );
    if (result == true) {
      _loadData();
      if (mounted) {
        AppSnackbar.success(context,
            edit == null ? 'Pupuk berhasil ditambahkan!' : 'Data diperbarui!');
      }
    }
  }

  Future<void> _openDetail(InventoryPupukModel item) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _InventoryDetailSheet(
        repo: _repo,
        item: item,
        onEdit: () async {
          Navigator.pop(context);
          await _openForm(edit: item);
        },
        onDelete: () async {
          Navigator.pop(context);
          await _confirmDelete(item);
        },
      ),
    );
    if (result == true) _loadData();
  }

  Future<void> _confirmDelete(InventoryPupukModel item) async {
    final ok = await AppDialog.confirm(
      context,
      title: 'Hapus Pupuk',
      message: 'Hapus "${item.namaPupuk}" dari inventori?',
      confirmLabel: 'Hapus',
      destructive: true,
      icon: Icons.delete_outline_rounded,
    );
    if (!ok || !mounted) return;
    await _repo.delete(item.id);
    _loadData();
    if (mounted) AppSnackbar.success(context, 'Pupuk dihapus.');
  }

  @override
  Widget build(BuildContext context) {
    final lowCount = _items.where((i) => i.isLowStock).length;
    final expCount = _items.where((i) => i.isExpiringSoon).length;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF065F46), Color(0xFF0D9488)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text('Stok Pupuk',
            style: AppTextStyles.display(18, color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF0D9488)))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: const Color(0xFF0D9488),
              child: _items.isEmpty
                  ? SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.7,
                        child: EmptyState.icon(
                          iconData: Icons.inventory_2_rounded,
                          title: 'Belum Ada Stok Pupuk',
                          message:
                              'Catat inventori pupuk untuk memantau sisa stok dan menghindari kehabisan saat jadwal pemupukan.',
                          accent: const Color(0xFF0D9488),
                          actionLabel: 'Tambah Pupuk Pertama',
                          onAction: () => _openForm(),
                        ),
                      ),
                    )
                  : ListView(
                      padding:
                          const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      children: [
                        // Alert summary
                        if (lowCount > 0 || expCount > 0) ...[
                          _AlertSummaryCard(
                              lowCount: lowCount, expCount: expCount),
                          const SizedBox(height: 14),
                        ],
                        Text('INVENTORI PUPUK', style: AppTextStyles.label()),
                        const SizedBox(height: 10),
                        ..._items.map((item) => _PupukCard(
                              item: item,
                              onTap: () => _openDetail(item),
                            )),
                      ],
                    ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: const Color(0xFF0D9488),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text('Tambah Pupuk',
            style: AppTextStyles.body(14,
                color: Colors.white, weight: FontWeight.w700)),
      ),
    );
  }
}

// ─── ALERT SUMMARY ────────────────────────────────────────────────────────────

class _AlertSummaryCard extends StatelessWidget {
  final int lowCount;
  final int expCount;
  const _AlertSummaryCard({required this.lowCount, required this.expCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.dangerTint,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.danger.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.danger.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.warning_amber_rounded,
                color: AppColors.danger, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (lowCount > 0)
                  Text(
                    '$lowCount pupuk stok menipis',
                    style: AppTextStyles.body(13,
                        color: AppColors.danger, weight: FontWeight.w700),
                  ),
                if (expCount > 0)
                  Text(
                    '$expCount pupuk mendekati kedaluwarsa (30 hari)',
                    style: AppTextStyles.body(12,
                        color: AppColors.warn),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── PUPUK CARD ───────────────────────────────────────────────────────────────

class _PupukCard extends StatelessWidget {
  final InventoryPupukModel item;
  final VoidCallback onTap;

  const _PupukCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final progressVal = item.thresholdAlert > 0
        ? (item.stokKg / (item.thresholdAlert * 3)).clamp(0.0, 1.0)
        : 0.0;
    final isLow = item.isLowStock;
    final isExp = item.isExpiringSoon;
    final isExpired = item.isExpired;

    final accentColor = isExpired
        ? AppColors.danger
        : isLow
            ? const Color(0xFFDC2626)
            : const Color(0xFF0D9488);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isLow
                ? AppColors.danger.withOpacity(0.4)
                : AppColors.border,
          ),
          boxShadow: Elevations.level1,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.inventory_2_rounded,
                      color: accentColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.namaPupuk,
                          style: AppTextStyles.body(14,
                              color: AppColors.text,
                              weight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(
                        'Sisa: ${_numFmt.format(item.stokKg)} kg',
                        style: AppTextStyles.mono(13,
                            color: accentColor,
                            weight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (isExpired)
                      _Badge('Kedaluwarsa', AppColors.danger)
                    else if (isLow)
                      _Badge('Stok Tipis', AppColors.danger)
                    else if (isExp)
                      _Badge('Exp. Dekat', AppColors.warn),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Progress bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Ambang batas: ${_numFmt.format(item.thresholdAlert)} kg',
                        style: AppTextStyles.body(10,
                            color: AppColors.textMuted)),
                    Text('${(progressVal * 100).toStringAsFixed(0)}%',
                        style: AppTextStyles.mono(10,
                            color: accentColor)),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progressVal,
                    backgroundColor: AppColors.border,
                    valueColor:
                        AlwaysStoppedAnimation(accentColor.withOpacity(0.7)),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge(this.label, this.color);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Text(label,
            style: AppTextStyles.body(10,
                color: color, weight: FontWeight.w700)),
      );
}

// ─── DETAIL SHEET ─────────────────────────────────────────────────────────────

class _InventoryDetailSheet extends StatefulWidget {
  final InventoryPupukRepository repo;
  final InventoryPupukModel item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _InventoryDetailSheet({
    required this.repo,
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_InventoryDetailSheet> createState() =>
      _InventoryDetailSheetState();
}

class _InventoryDetailSheetState extends State<_InventoryDetailSheet> {
  final _addCtrl = TextEditingController();
  final _consumeCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _addCtrl.dispose();
    _consumeCtrl.dispose();
    super.dispose();
  }

  Future<void> _addStock() async {
    final kg = double.tryParse(_addCtrl.text.replaceAll(',', '.')) ?? 0;
    if (kg <= 0) {
      AppSnackbar.error(context, 'Jumlah kg harus lebih dari 0.');
      return;
    }
    setState(() => _saving = true);
    await widget.repo.addStock(widget.item.id, kg);
    if (mounted) {
      Navigator.pop(context, true);
      AppSnackbar.success(context,
          'Stok bertambah ${_numFmt.format(kg)} kg.');
    }
  }

  Future<void> _consumeStock() async {
    final kg =
        double.tryParse(_consumeCtrl.text.replaceAll(',', '.')) ?? 0;
    if (kg <= 0) {
      AppSnackbar.error(context, 'Jumlah kg harus lebih dari 0.');
      return;
    }
    setState(() => _saving = true);
    await widget.repo.consumeStock(widget.item.id, kg);
    if (mounted) {
      Navigator.pop(context, true);
      AppSnackbar.success(context,
          'Stok berkurang ${_numFmt.format(kg)} kg.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(item.namaPupuk,
                      style: AppTextStyles.display(20)),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded,
                      color: AppColors.textMuted),
                  onSelected: (v) {
                    if (v == 'edit') widget.onEdit();
                    if (v == 'delete') widget.onDelete();
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(
                        value: 'delete',
                        child: Text('Hapus',
                            style: TextStyle(color: AppColors.danger))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Sisa stok: ${_numFmt.format(item.stokKg)} kg  ·  '
              'Ambang: ${_numFmt.format(item.thresholdAlert)} kg',
              style: AppTextStyles.body(12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 20),
            // Tambah stok
            Text('TAMBAH STOK (kg)', style: AppTextStyles.label()),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border, width: 1.5),
                    ),
                    child: TextField(
                      controller: _addCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      style: AppTextStyles.body(15, color: AppColors.text),
                      decoration: const InputDecoration(
                        hintText: 'Kg masuk',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _saving ? null : _addStock,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D9488),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text('Tambah',
                      style: AppTextStyles.body(13,
                          color: Colors.white, weight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Kurangi stok
            Text('PAKAI STOK (kg)', style: AppTextStyles.label()),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border, width: 1.5),
                    ),
                    child: TextField(
                      controller: _consumeCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      style: AppTextStyles.body(15, color: AppColors.text),
                      decoration: const InputDecoration(
                        hintText: 'Kg terpakai',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _saving ? null : _consumeStock,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text('Pakai',
                      style: AppTextStyles.body(13,
                          color: Colors.white, weight: FontWeight.w700)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── ADD/EDIT FORM ────────────────────────────────────────────────────────────

class _InventoryForm extends StatefulWidget {
  final LahanModel lahan;
  final InventoryPupukModel? edit;
  const _InventoryForm({required this.lahan, this.edit});

  @override
  State<_InventoryForm> createState() => _InventoryFormState();
}

class _InventoryFormState extends State<_InventoryForm> {
  late final InventoryPupukRepository _repo;
  final _namaCtrl = TextEditingController();
  final _stokCtrl = TextEditingController();
  final _thresholdCtrl = TextEditingController();
  final _catatanCtrl = TextEditingController();
  DateTime? _expiredDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _repo = InventoryPupukRepository(db: appDb);
    final e = widget.edit;
    if (e != null) {
      _namaCtrl.text = e.namaPupuk;
      _stokCtrl.text = e.stokKg.toStringAsFixed(1);
      _thresholdCtrl.text = e.thresholdAlert.toStringAsFixed(1);
      _catatanCtrl.text = e.catatan ?? '';
      if (e.expiredAt != null) {
        _expiredDate = DateTime.fromMillisecondsSinceEpoch(e.expiredAt!);
      }
    } else {
      _stokCtrl.text = '0';
      _thresholdCtrl.text = '50';
    }
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _stokCtrl.dispose();
    _thresholdCtrl.dispose();
    _catatanCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickExpiredDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiredDate ?? DateTime.now().add(const Duration(days: 90)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _expiredDate = picked);
  }

  Future<void> _save() async {
    final nama = _namaCtrl.text.trim();
    if (nama.isEmpty) {
      AppSnackbar.error(context, 'Nama pupuk wajib diisi.');
      return;
    }
    final stok = double.tryParse(_stokCtrl.text.replaceAll(',', '.')) ?? 0;
    final threshold =
        double.tryParse(_thresholdCtrl.text.replaceAll(',', '.')) ?? 50;
    setState(() => _saving = true);
    try {
      final expMs = _expiredDate?.millisecondsSinceEpoch;
      final catatan = _catatanCtrl.text.trim().isEmpty
          ? null
          : _catatanCtrl.text.trim();
      if (widget.edit == null) {
        await _repo.create(
          lahanId: widget.lahan.id,
          namaPupuk: nama,
          stokKg: stok,
          thresholdAlert: threshold,
          expiredAt: expMs,
          catatan: catatan,
        );
      } else {
        await _repo.update(
          id: widget.edit!.id,
          namaPupuk: nama,
          stokKg: stok,
          thresholdAlert: threshold,
          expiredAt: expMs,
          catatan: catatan,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        AppSnackbar.error(context, 'Gagal menyimpan. Coba lagi.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.edit != null;
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(isEdit ? 'Edit Pupuk' : 'Tambah Pupuk',
                  style: AppTextStyles.display(20)),
              const SizedBox(height: 18),
              Text('NAMA PUPUK', style: AppTextStyles.label()),
              const SizedBox(height: 8),
              _field(_namaCtrl, 'Contoh: NPK, Urea, Dolomit'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('STOK AWAL (kg)', style: AppTextStyles.label()),
                        const SizedBox(height: 8),
                        _field(_stokCtrl, '0',
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('AMBANG ALERT (kg)', style: AppTextStyles.label()),
                        const SizedBox(height: 8),
                        _field(_thresholdCtrl, '50',
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('TANGGAL KEDALUWARSA (Opsional)',
                  style: AppTextStyles.label()),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickExpiredDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.event_rounded,
                          size: 18, color: AppColors.textMuted),
                      const SizedBox(width: 10),
                      Text(
                        _expiredDate != null
                            ? DateFormat('dd MMMM yyyy', 'id_ID')
                                .format(_expiredDate!)
                            : 'Pilih tanggal (opsional)',
                        style: AppTextStyles.body(14,
                            color: _expiredDate != null
                                ? AppColors.text
                                : AppColors.textLight),
                      ),
                      if (_expiredDate != null) ...[
                        const Spacer(),
                        GestureDetector(
                          onTap: () =>
                              setState(() => _expiredDate = null),
                          child: const Icon(Icons.close_rounded,
                              size: 16, color: AppColors.textMuted),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('CATATAN (Opsional)', style: AppTextStyles.label()),
              const SizedBox(height: 8),
              _field(_catatanCtrl, 'Contoh: subsidi, grade A',
                  maxLines: 2),
              const SizedBox(height: 24),
              PrimaryButton(
                label: isEdit ? 'Simpan Perubahan' : 'Tambah Pupuk',
                onTap: _save,
                loading: _saving,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String hint, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) =>
      Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: TextField(
          controller: ctrl,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: AppTextStyles.body(15, color: AppColors.text),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                AppTextStyles.body(15, color: AppColors.textLight),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
          ),
        ),
      );
}
