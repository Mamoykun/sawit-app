import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../models/lahan_model.dart';
import '../services/api_service.dart';
import '../repositories/lahan_repository.dart';
import '../main.dart' show appDb;
import '../widgets/common_widgets.dart';
import '../widgets/sawit_logo.dart';
import 'main_screen.dart';
import 'login_screen.dart';

class LahanScreen extends StatefulWidget {
  const LahanScreen({super.key});

  @override
  State<LahanScreen> createState() => _LahanScreenState();
}

class _LahanScreenState extends State<LahanScreen> {
  late final LahanRepository _lahanRepo;
  List<LahanModel>? _lahanList;
  bool _loading = true;
  String? _error;
  String _userName = '';
  String _userPaket = 'GRATIS';

  @override
  void initState() {
    super.initState();
    _lahanRepo = LahanRepository(db: appDb, api: ApiService());
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final prefs = await SharedPreferences.getInstance();
      _userName = prefs.getString('user_name') ?? '';
      _userPaket = prefs.getString('user_paket') ?? 'GRATIS';
      final list = await _lahanRepo.getAll();
      setState(() { _lahanList = list; _loading = false; });
    } catch (e) {
      setState(() {
        _error = 'Gagal memuat data. Periksa koneksi internet.';
        _loading = false;
      });
    }
  }

  void _selectLahan(LahanModel lahan) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => MainScreen(lahan: lahan, userPaket: _userPaket),
      ),
    );
  }

  void _openAddLahan() async {
    final result = await Navigator.push<LahanModel>(
      context,
      MaterialPageRoute(builder: (_) => const LahanFormScreen()),
    );
    if (result != null) _selectLahan(result);
  }

  void _openEditLahan(LahanModel lahan) async {
    final result = await Navigator.push<LahanModel>(
      context,
      MaterialPageRoute(builder: (_) => LahanFormScreen(existing: lahan)),
    );
    if (result != null && mounted) _loadData();
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Keluar?', style: AppTextStyles.display(18)),
        content: Text('Yakin ingin keluar dari akun?',
            style: AppTextStyles.body(14, color: AppColors.textMid)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal', style: AppTextStyles.body(14, color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Keluar', style: AppTextStyles.body(14,
                color: AppColors.danger, weight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ApiService().logout();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SawitKu', style: AppTextStyles.display(18, color: Colors.white)),
          Text('PILIH KEBUN', style: AppTextStyles.body(9,
              color: const Color(0xFF74C69D), weight: FontWeight.w600)),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout_rounded, color: Colors.white70),
          onPressed: _logout,
          tooltip: 'Keluar',
        ),
      ],
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
        : _error != null
            ? _ErrorView(message: _error!, onRetry: _loadData)
            : _lahanList!.isEmpty
                ? _EmptyLahan(onAdd: _openAddLahan)
                : _LahanList(
                    lahanList: _lahanList!,
                    userName: _userName,
                    userPaket: _userPaket,
                    onSelect: _selectLahan,
                    onEdit: _openEditLahan,
                    onAdd: _openAddLahan,
                  ),
  );
}

class _LahanList extends StatelessWidget {
  final List<LahanModel> lahanList;
  final String userName;
  final String userPaket;
  final ValueChanged<LahanModel> onSelect;
  final ValueChanged<LahanModel> onEdit;
  final VoidCallback onAdd;

  const _LahanList({
    required this.lahanList,
    required this.userName,
    required this.userPaket,
    required this.onSelect,
    required this.onEdit,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Welcome
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(userName.isEmpty ? 'Selamat datang' : 'Halo, ${userName.split(' ').first}',
                    style: AppTextStyles.body(13, color: AppColors.textMuted)),
                const SizedBox(height: 2),
                Text('Kebun Anda', style: AppTextStyles.display(24)),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: userPaket == 'GRATIS' ? AppColors.surfaceAlt : AppColors.gold,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(userPaket,
                  style: AppTextStyles.body(11,
                      color: userPaket == 'GRATIS' ? AppColors.textMuted : Colors.white,
                      weight: FontWeight.w700)),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Lahan cards
        ...lahanList.map((l) => _LahanCard(
            lahan: l,
            onTap: () => onSelect(l),
            onEdit: () => onEdit(l),
          )),
        const SizedBox(height: 8),

        // Add button
        GestureDetector(
          onTap: onAdd,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.border, width: 1.5, style: BorderStyle.solid),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add_circle_outline_rounded,
                    color: AppColors.primary3, size: 22),
                const SizedBox(width: 10),
                Text('Tambah Kebun Baru',
                    style: AppTextStyles.body(14,
                        color: AppColors.primary3, weight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _LahanCard extends StatelessWidget {
  final LahanModel lahan;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  const _LahanCard({required this.lahan, required this.onTap, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final p = lahan.panenTerakhir;
    final ok = p == null || p.statusPanen == 'NORMAL';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.primary2],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(lahan.namaLahan,
                      style: AppTextStyles.display(18, color: Colors.white)),
                ),
                GestureDetector(
                  onTap: onEdit,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.edit_outlined, color: Colors.white70, size: 16),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: ok
                        ? const Color(0xFF52B788)
                        : const Color(0xFFEF4444).withOpacity(0.9),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    ok ? '✓ Normal' : '⚠ Kurang',
                    style: AppTextStyles.body(11, color: Colors.white, weight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${lahan.luasHa.toStringAsFixed(1)} ha · Usia ${lahan.usiaPohon} thn'
              '${lahan.faseProduksi != null ? ' · ${lahan.faseProduksi}' : ''}',
              style: AppTextStyles.body(12, color: const Color(0xFF74C69D)),
            ),
            if (p != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Panen Terakhir · ${p.bulan}',
                            style: AppTextStyles.body(10, color: const Color(0xff74c69d99))),
                        const SizedBox(height: 2),
                        Text('${p.tonAktual.toStringAsFixed(1)} ton',
                            style: AppTextStyles.display(16, color: Colors.white)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Target',
                            style: AppTextStyles.body(10, color: const Color(0xff74c69d99))),
                        const SizedBox(height: 2),
                        Text('${p.targetMid.toStringAsFixed(1)} ton',
                            style: AppTextStyles.body(13, color: const Color(0xFF74C69D),
                                weight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyLahan extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyLahan({required this.onAdd});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SawitLogo(size: 80),
          const SizedBox(height: 20),
          Text('Belum Ada Kebun', style: AppTextStyles.display(20)),
          const SizedBox(height: 8),
          Text(
            'Tambahkan data kebun sawit pertama Anda untuk mulai memantau produksi',
            style: AppTextStyles.body(13, color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          PrimaryButton(label: '+ Tambah Kebun', onTap: onAdd),
        ],
      ),
    ),
  );
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('😕', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(message,
              style: AppTextStyles.body(14, color: AppColors.textMid),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          PrimaryButton(label: 'Coba Lagi', onTap: onRetry),
        ],
      ),
    ),
  );
}

// ─── LAHAN FORM (Tambah/Edit Kebun) ──────────────────────────────────────────

class LahanFormScreen extends StatefulWidget {
  final LahanModel? existing;
  const LahanFormScreen({super.key, this.existing});

  @override
  State<LahanFormScreen> createState() => _LahanFormScreenState();
}

class _LahanFormScreenState extends State<LahanFormScreen> {
  late final LahanRepository _lahanRepo;
  final _namaCtrl = TextEditingController();
  final _luasCtrl = TextEditingController();
  final _tahunCtrl = TextEditingController();
  final _pohonCtrl = TextEditingController();
  final _lokasiCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  bool get _isEdit => widget.existing != null;

  int get _currentYear => DateTime.now().year;

  int? get _calculatedUsia {
    final t = int.tryParse(_tahunCtrl.text);
    if (t == null) return null;
    return _currentYear - t;
  }

  @override
  void initState() {
    super.initState();
    _lahanRepo = LahanRepository(db: appDb, api: ApiService());
    if (_isEdit) {
      final e = widget.existing!;
      _namaCtrl.text = e.namaLahan;
      _luasCtrl.text = e.luasHa.toString();
      // Prefer tahunTanam; fall back to deriving from usiaPohon
      final tahun = e.tahunTanam ?? (_currentYear - e.usiaPohon);
      _tahunCtrl.text = tahun.toString();
      if (e.jumlahPohon != null) _pohonCtrl.text = e.jumlahPohon.toString();
      if (e.lokasi != null) _lokasiCtrl.text = e.lokasi!;
    }
  }

  Future<void> _submit() async {
    final nama = _namaCtrl.text.trim();
    final luas = double.tryParse(_luasCtrl.text);
    final tahun = int.tryParse(_tahunCtrl.text);

    if (nama.isEmpty) { setState(() => _error = 'Nama kebun wajib diisi'); return; }
    if (luas == null || luas <= 0) { setState(() => _error = 'Luas kebun tidak valid'); return; }
    if (tahun == null || tahun < 1980 || tahun > _currentYear) {
      setState(() => _error = 'Tahun tanam tidak valid (1980–$_currentYear)');
      return;
    }

    setState(() { _loading = true; _error = null; });
    try {
      final jumlahPohon = int.tryParse(_pohonCtrl.text);
      final lokasi = _lokasiCtrl.text.trim();

      LahanModel result;
      if (_isEdit) {
        result = await _lahanRepo.update(
          widget.existing!.id,
          namaLahan: nama,
          luasHa: luas,
          tahunTanam: tahun,
          jumlahPohon: jumlahPohon,
          lokasi: lokasi.isEmpty ? null : lokasi,
        );
      } else {
        result = await _lahanRepo.create(
          namaLahan: nama,
          luasHa: luas,
          tahunTanam: tahun,
          jumlahPohon: jumlahPohon,
          lokasi: lokasi.isEmpty ? null : lokasi,
        );
      }
      if (mounted) Navigator.pop(context, result);
    } catch (e) {
      setState(() => _error = 'Gagal menyimpan data. Coba lagi.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _luasCtrl.dispose();
    _tahunCtrl.dispose();
    _pohonCtrl.dispose();
    _lokasiCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(_isEdit ? 'Edit Kebun' : 'Tambah Kebun',
          style: AppTextStyles.display(18, color: Colors.white)),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(
            title: _isEdit ? 'Edit Data Kebun' : 'Data Kebun Baru',
            subtitle: 'Isi informasi kebun sawit Anda',
          ),

          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.dangerTint,
                border: Border.all(color: const Color(0xFFFCA5A5)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(_error!,
                  style: AppTextStyles.body(13, color: AppColors.danger)),
            ),
            const SizedBox(height: 16),
          ],

          AppCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                AppInputField(
                  label: 'Nama Kebun',
                  hint: 'Contoh: Kebun Blok A',
                  suffix: '',
                  controller: _namaCtrl,
                  keyboardType: TextInputType.text,
                ),
                const SizedBox(height: 20),
                AppInputField(
                  label: 'Luas Kebun',
                  hint: 'Contoh: 14',
                  suffix: 'Hektar',
                  controller: _luasCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 20),
                ValueListenableBuilder(
                  valueListenable: _tahunCtrl,
                  builder: (_, __, ___) {
                    final usia = _calculatedUsia;
                    final hint = usia != null && usia > 0
                        ? '= Usia $usia tahun'
                        : 'Tahun';
                    return AppInputField(
                      label: 'Tahun Tanam',
                      hint: 'Contoh: ${_currentYear - 8}',
                      suffix: hint,
                      controller: _tahunCtrl,
                      keyboardType: TextInputType.number,
                    );
                  },
                ),
                const SizedBox(height: 20),
                AppInputField(
                  label: 'Jumlah Pohon (Opsional)',
                  hint: 'Contoh: 140',
                  suffix: 'Pohon',
                  controller: _pohonCtrl,
                ),
                const SizedBox(height: 20),
                AppInputField(
                  label: 'Lokasi (Opsional)',
                  hint: 'Contoh: Kab. Pelalawan, Riau',
                  suffix: '',
                  controller: _lokasiCtrl,
                  keyboardType: TextInputType.text,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          PrimaryButton(
            label: _isEdit ? 'Simpan Perubahan' : 'Tambah Kebun',
            onTap: _loading ? null : _submit,
            loading: _loading,
          ),
        ],
      ),
    ),
  );
}
