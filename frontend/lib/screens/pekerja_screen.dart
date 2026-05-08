// frontend/lib/screens/pekerja_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/lahan_model.dart';
import '../repositories/pekerja_repository.dart';
import '../main.dart' show appDb;
import '../widgets/empty_state.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/app_dialog.dart';
import '../widgets/common_widgets.dart';

final _rpFmt =
    NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

const _peranOptions = [
  'Pemanen',
  'Penyemprot',
  'Pemupuk',
  'Pengangkut',
  'Lainnya',
];

const _bulanNames = [
  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
];

class PekerjaScreen extends StatefulWidget {
  final LahanModel lahan;
  const PekerjaScreen({super.key, required this.lahan});

  @override
  State<PekerjaScreen> createState() => _PekerjaScreenState();
}

class _PekerjaScreenState extends State<PekerjaScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final PekerjaRepository _repo;

  List<PekerjaModel> _pekerjas = [];
  List<HariKerjaModel> _hariKerjas = [];
  bool _loading = true;

  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _repo = PekerjaRepository(db: appDb);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      final pekerjas = await _repo.getByLahan(widget.lahan.id);
      final hariKerjas = await _repo.getHariKerja(
          widget.lahan.id, _selectedYear, _selectedMonth);
      if (mounted) {
        setState(() {
          _pekerjas = pekerjas;
          _hariKerjas = hariKerjas;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadHariKerja() async {
    final hariKerjas = await _repo.getHariKerja(
        widget.lahan.id, _selectedYear, _selectedMonth);
    if (mounted) setState(() => _hariKerjas = hariKerjas);
  }

  Future<void> _openPekerjaForm({PekerjaModel? edit}) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PekerjaForm(lahan: widget.lahan, edit: edit),
    );
    if (result == true) {
      _loadAll();
      if (mounted) {
        AppSnackbar.success(
            context,
            edit == null
                ? 'Pekerja berhasil ditambahkan!'
                : 'Data pekerja diperbarui!');
      }
    }
  }

  Future<void> _confirmDeletePekerja(PekerjaModel p) async {
    final ok = await AppDialog.confirm(
      context,
      title: 'Hapus Pekerja',
      message:
          'Hapus "${p.nama}"? Riwayat hari kerja tetap tersimpan.',
      confirmLabel: 'Hapus',
      destructive: true,
      icon: Icons.person_remove_rounded,
    );
    if (!ok || !mounted) return;
    await _repo.delete(p.id);
    _loadAll();
    if (mounted) AppSnackbar.success(context, 'Pekerja dihapus.');
  }

  Future<void> _openHariKerjaInput(PekerjaModel p) async {
    final existing = _hariKerjas
        .where((h) => h.pekerjaId == p.id)
        .firstOrNull;
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _HariKerjaForm(
        lahan: widget.lahan,
        pekerja: p,
        bulan: _selectedMonth,
        tahun: _selectedYear,
        existing: existing,
      ),
    );
    if (result == true) {
      _loadHariKerja();
      if (mounted) {
        AppSnackbar.success(context, 'Hari kerja disimpan!');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1D4ED8), Color(0xFF2563EB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text('Tenaga Kerja',
            style: AppTextStyles.display(18, color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: AppTextStyles.body(13, weight: FontWeight.w700),
          tabs: const [
            Tab(text: 'Daftar Pekerja'),
            Tab(text: 'Hari Kerja Bulanan'),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2563EB)))
          : TabBarView(
              controller: _tabController,
              children: [
                _DaftarPekerjaTab(
                  pekerjas: _pekerjas,
                  onEdit: (p) => _openPekerjaForm(edit: p),
                  onDelete: _confirmDeletePekerja,
                  onAdd: () => _openPekerjaForm(),
                ),
                _HariKerjaTab(
                  lahan: widget.lahan,
                  pekerjas: _pekerjas,
                  hariKerjas: _hariKerjas,
                  selectedMonth: _selectedMonth,
                  selectedYear: _selectedYear,
                  onMonthChanged: (m, y) {
                    setState(() {
                      _selectedMonth = m;
                      _selectedYear = y;
                    });
                    _loadHariKerja();
                  },
                  onTapPekerja: _openHariKerjaInput,
                  onAdd: () => _openPekerjaForm(),
                ),
              ],
            ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: () => _openPekerjaForm(),
              backgroundColor: const Color(0xFF2563EB),
              icon: const Icon(Icons.person_add_rounded, color: Colors.white),
              label: Text('Tambah Pekerja',
                  style: AppTextStyles.body(14,
                      color: Colors.white, weight: FontWeight.w700)),
            )
          : null,
    );
  }
}

// ─── TAB 1: DAFTAR PEKERJA ────────────────────────────────────────────────────

class _DaftarPekerjaTab extends StatelessWidget {
  final List<PekerjaModel> pekerjas;
  final ValueChanged<PekerjaModel> onEdit;
  final ValueChanged<PekerjaModel> onDelete;
  final VoidCallback onAdd;

  const _DaftarPekerjaTab({
    required this.pekerjas,
    required this.onEdit,
    required this.onDelete,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    if (pekerjas.isEmpty) {
      return EmptyState.icon(
        iconData: Icons.groups_rounded,
        title: 'Belum Ada Pekerja',
        message:
            'Tambah pekerja kebun untuk memantau hari kerja dan pengeluaran tenaga kerja secara akurat.',
        accent: const Color(0xFF2563EB),
        actionLabel: 'Tambah Pekerja Pertama',
        onAction: onAdd,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: pekerjas.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _PekerjaCard(
        pekerja: pekerjas[i],
        onEdit: () => onEdit(pekerjas[i]),
        onDelete: () => onDelete(pekerjas[i]),
      ),
    );
  }
}

class _PekerjaCard extends StatelessWidget {
  final PekerjaModel pekerja;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PekerjaCard({
    required this.pekerja,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: Elevations.level1,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.person_rounded,
                color: Color(0xFF2563EB), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pekerja.nama,
                    style: AppTextStyles.body(14,
                        color: AppColors.text, weight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(pekerja.peran,
                    style:
                        AppTextStyles.body(12, color: AppColors.textMuted)),
                const SizedBox(height: 2),
                Text(_rpFmt.format(pekerja.gajiHarian) + '/hari',
                    style: AppTextStyles.mono(12,
                        color: const Color(0xFF2563EB),
                        weight: FontWeight.w600)),
              ],
            ),
          ),
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
                child: Text('Hapus', style: TextStyle(color: AppColors.danger)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── TAB 2: HARI KERJA BULANAN ────────────────────────────────────────────────

class _HariKerjaTab extends StatelessWidget {
  final LahanModel lahan;
  final List<PekerjaModel> pekerjas;
  final List<HariKerjaModel> hariKerjas;
  final int selectedMonth;
  final int selectedYear;
  final void Function(int month, int year) onMonthChanged;
  final ValueChanged<PekerjaModel> onTapPekerja;
  final VoidCallback onAdd;

  const _HariKerjaTab({
    required this.lahan,
    required this.pekerjas,
    required this.hariKerjas,
    required this.selectedMonth,
    required this.selectedYear,
    required this.onMonthChanged,
    required this.onTapPekerja,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final totalGaji =
        hariKerjas.fold<double>(0, (s, h) => s + h.totalGaji);
    final hariMap = {for (final h in hariKerjas) h.pekerjaId: h};

    return Column(
      children: [
        // Month selector bar
        Container(
          color: AppColors.surface,
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded,
                    color: AppColors.primary),
                onPressed: () {
                  int m = selectedMonth - 1;
                  int y = selectedYear;
                  if (m < 1) {
                    m = 12;
                    y--;
                  }
                  onMonthChanged(m, y);
                },
              ),
              Expanded(
                child: Text(
                  '${_bulanNames[selectedMonth - 1]} $selectedYear',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.display(16),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded,
                    color: AppColors.primary),
                onPressed: () {
                  int m = selectedMonth + 1;
                  int y = selectedYear;
                  if (m > 12) {
                    m = 1;
                    y++;
                  }
                  onMonthChanged(m, y);
                },
              ),
            ],
          ),
        ),
        if (pekerjas.isEmpty)
          Expanded(
            child: EmptyState.icon(
              iconData: Icons.groups_rounded,
              title: 'Belum Ada Pekerja',
              message: 'Tambah pekerja di tab "Daftar Pekerja" terlebih dahulu.',
              accent: const Color(0xFF2563EB),
              actionLabel: 'Tambah Pekerja',
              onAction: onAdd,
            ),
          )
        else
          Expanded(
            child: ListView(
              padding:
                  const EdgeInsets.fromLTRB(16, 12, 16, 80),
              children: [
                // Summary card
                if (totalGaji > 0)
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: const Color(0xFF2563EB).withOpacity(0.25)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Gaji Bulan Ini',
                            style: AppTextStyles.body(13,
                                color: const Color(0xFF1D4ED8),
                                weight: FontWeight.w600)),
                        Text(_rpFmt.format(totalGaji),
                            style: AppTextStyles.mono(15,
                                color: const Color(0xFF1D4ED8),
                                weight: FontWeight.w700)),
                      ],
                    ),
                  ),
                Text('KETUK NAMA PEKERJA UNTUK INPUT HARI KERJA',
                    style: AppTextStyles.label()),
                const SizedBox(height: 10),
                ...pekerjas.map((p) {
                  final h = hariMap[p.id];
                  return _HariKerjaRow(
                    pekerja: p,
                    hariKerja: h,
                    onTap: () => onTapPekerja(p),
                  );
                }),
              ],
            ),
          ),
      ],
    );
  }
}

class _HariKerjaRow extends StatelessWidget {
  final PekerjaModel pekerja;
  final HariKerjaModel? hariKerja;
  final VoidCallback onTap;

  const _HariKerjaRow({
    required this.pekerja,
    this.hariKerja,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasData = hariKerja != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasData
                ? const Color(0xFF2563EB).withOpacity(0.4)
                : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: hasData
                    ? const Color(0xFF2563EB).withOpacity(0.1)
                    : AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                hasData
                    ? Icons.check_circle_rounded
                    : Icons.pending_rounded,
                color: hasData
                    ? const Color(0xFF2563EB)
                    : AppColors.textLight,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pekerja.nama,
                      style: AppTextStyles.body(13,
                          color: AppColors.text, weight: FontWeight.w600)),
                  Text(pekerja.peran,
                      style: AppTextStyles.body(11,
                          color: AppColors.textMuted)),
                ],
              ),
            ),
            if (hasData) ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${hariKerja!.jumlahHari} hari',
                      style: AppTextStyles.mono(13,
                          color: const Color(0xFF2563EB),
                          weight: FontWeight.w700)),
                  Text(_rpFmt.format(hariKerja!.totalGaji),
                      style: AppTextStyles.body(11,
                          color: AppColors.textMuted)),
                ],
              ),
            ] else
              Text('Belum diisi',
                  style: AppTextStyles.body(12,
                      color: AppColors.textLight)),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded,
                size: 16, color: AppColors.textLight),
          ],
        ),
      ),
    );
  }
}

// ─── FORM: Tambah/Edit Pekerja ────────────────────────────────────────────────

class _PekerjaForm extends StatefulWidget {
  final LahanModel lahan;
  final PekerjaModel? edit;
  const _PekerjaForm({required this.lahan, this.edit});

  @override
  State<_PekerjaForm> createState() => _PekerjaFormState();
}

class _PekerjaFormState extends State<_PekerjaForm> {
  late final PekerjaRepository _repo;
  final _namaCtrl = TextEditingController();
  final _kontakCtrl = TextEditingController();
  final _gajiCtrl = TextEditingController();
  String _peran = _peranOptions.first;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _repo = PekerjaRepository(db: appDb);
    final e = widget.edit;
    if (e != null) {
      _namaCtrl.text = e.nama;
      _kontakCtrl.text = e.kontak ?? '';
      _gajiCtrl.text = e.gajiHarian.toStringAsFixed(0);
      _peran = _peranOptions.contains(e.peran) ? e.peran : _peranOptions.last;
    } else {
      _gajiCtrl.text = '150000';
    }
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _kontakCtrl.dispose();
    _gajiCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final nama = _namaCtrl.text.trim();
    if (nama.isEmpty) {
      AppSnackbar.error(context, 'Nama pekerja wajib diisi.');
      return;
    }
    final gaji = double.tryParse(_gajiCtrl.text.replaceAll('.', '')) ?? 0;
    if (gaji <= 0) {
      AppSnackbar.error(context, 'Gaji harian harus lebih dari 0.');
      return;
    }
    setState(() => _saving = true);
    try {
      final kontak = _kontakCtrl.text.trim().isEmpty
          ? null
          : _kontakCtrl.text.trim();
      if (widget.edit == null) {
        await _repo.create(
          lahanId: widget.lahan.id,
          nama: nama,
          peran: _peran,
          kontak: kontak,
          gajiHarian: gaji,
        );
      } else {
        await _repo.update(
          id: widget.edit!.id,
          nama: nama,
          peran: _peran,
          kontak: kontak,
          gajiHarian: gaji,
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
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
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
              Text(isEdit ? 'Edit Pekerja' : 'Tambah Pekerja',
                  style: AppTextStyles.display(20)),
              const SizedBox(height: 18),
              Text('NAMA LENGKAP', style: AppTextStyles.label()),
              const SizedBox(height: 8),
              _buildTextField(_namaCtrl, 'Contoh: Budi Santoso'),
              const SizedBox(height: 16),
              Text('PERAN / JABATAN', style: AppTextStyles.label()),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _peranOptions.map((opt) {
                  final sel = _peran == opt;
                  return GestureDetector(
                    onTap: () => setState(() => _peran = opt),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: sel
                            ? const Color(0xFF2563EB).withOpacity(0.12)
                            : AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(
                          color: sel
                              ? const Color(0xFF2563EB)
                              : AppColors.border,
                          width: sel ? 1.5 : 1,
                        ),
                      ),
                      child: Text(opt,
                          style: AppTextStyles.body(12,
                              color: sel
                                  ? const Color(0xFF2563EB)
                                  : AppColors.textMid,
                              weight: sel
                                  ? FontWeight.w700
                                  : FontWeight.w500)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Text('GAJI HARIAN (Rp)', style: AppTextStyles.label()),
              const SizedBox(height: 8),
              _buildTextField(
                _gajiCtrl,
                '150000',
                keyboardType: TextInputType.number,
                formatter: FilteringTextInputFormatter.digitsOnly,
              ),
              const SizedBox(height: 16),
              Text('KONTAK (Opsional)', style: AppTextStyles.label()),
              const SizedBox(height: 8),
              _buildTextField(_kontakCtrl, 'No. HP atau alamat'),
              const SizedBox(height: 24),
              PrimaryButton(
                label: isEdit ? 'Simpan Perubahan' : 'Tambah Pekerja',
                onTap: _save,
                loading: _saving,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController ctrl,
    String hint, {
    TextInputType keyboardType = TextInputType.text,
    TextInputFormatter? formatter,
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
          inputFormatters: formatter != null ? [formatter] : null,
          style: AppTextStyles.body(15, color: AppColors.text),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.body(15, color: AppColors.textLight),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      );
}

// ─── FORM: Input Hari Kerja ───────────────────────────────────────────────────

class _HariKerjaForm extends StatefulWidget {
  final LahanModel lahan;
  final PekerjaModel pekerja;
  final int bulan;
  final int tahun;
  final HariKerjaModel? existing;

  const _HariKerjaForm({
    required this.lahan,
    required this.pekerja,
    required this.bulan,
    required this.tahun,
    this.existing,
  });

  @override
  State<_HariKerjaForm> createState() => _HariKerjaFormState();
}

class _HariKerjaFormState extends State<_HariKerjaForm> {
  late final PekerjaRepository _repo;
  final _hariCtrl = TextEditingController();
  final _catatanCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _repo = PekerjaRepository(db: appDb);
    if (widget.existing != null) {
      _hariCtrl.text = widget.existing!.jumlahHari.toString();
      _catatanCtrl.text = widget.existing!.catatan ?? '';
    }
  }

  @override
  void dispose() {
    _hariCtrl.dispose();
    _catatanCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final hari = int.tryParse(_hariCtrl.text) ?? 0;
    if (hari <= 0) {
      AppSnackbar.error(context, 'Jumlah hari harus lebih dari 0.');
      return;
    }
    if (hari > 31) {
      AppSnackbar.error(context, 'Jumlah hari tidak boleh lebih dari 31.');
      return;
    }
    setState(() => _saving = true);
    try {
      await _repo.recordHariKerja(
        pekerjaId: widget.pekerja.id,
        lahanId: widget.lahan.id,
        tahun: widget.tahun,
        bulanAngka: widget.bulan,
        jumlahHari: hari,
        gajiHarian: widget.pekerja.gajiHarian,
        catatan: _catatanCtrl.text.trim().isEmpty
            ? null
            : _catatanCtrl.text.trim(),
        namaPekerja: widget.pekerja.nama,
      );
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
    final totalPreview = (int.tryParse(_hariCtrl.text) ?? 0) *
        widget.pekerja.gajiHarian;
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
            Text('Hari Kerja — ${widget.pekerja.nama}',
                style: AppTextStyles.display(18)),
            const SizedBox(height: 4),
            Text(
              '${_bulanNames[widget.bulan - 1]} ${widget.tahun} · '
              '${_rpFmt.format(widget.pekerja.gajiHarian)}/hari',
              style: AppTextStyles.body(12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 18),
            Text('JUMLAH HARI KERJA', style: AppTextStyles.label()),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border, width: 1.5),
              ),
              child: TextField(
                controller: _hariCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => setState(() {}),
                style: AppTextStyles.display(24),
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  hintText: '0',
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
            if (totalPreview > 0) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total gaji bulan ini:',
                        style: AppTextStyles.body(13,
                            color: AppColors.textMid)),
                    Text(_rpFmt.format(totalPreview),
                        style: AppTextStyles.mono(15,
                            color: const Color(0xFF2563EB),
                            weight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text('CATATAN (Opsional)', style: AppTextStyles.label()),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border, width: 1.5),
              ),
              child: TextField(
                controller: _catatanCtrl,
                maxLines: 2,
                style: AppTextStyles.body(14, color: AppColors.text),
                decoration: const InputDecoration(
                  hintText: 'Contoh: termasuk lembur 2 hari',
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Simpan Hari Kerja',
              onTap: _save,
              loading: _saving,
            ),
          ],
        ),
      ),
    );
  }
}
