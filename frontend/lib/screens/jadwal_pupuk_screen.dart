import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/lahan_model.dart';
import '../data/jadwal_pupuk_data.dart';
import '../database/app_database.dart';
import '../repositories/jadwal_pupuk_repository.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/empty_state.dart';
import '../widgets/help_tooltip.dart';
import '../main.dart';

class JadwalPupukScreen extends StatefulWidget {
  final LahanModel lahan;
  const JadwalPupukScreen({super.key, required this.lahan});

  @override
  State<JadwalPupukScreen> createState() => _JadwalPupukScreenState();
}

class _JadwalPupukScreenState extends State<JadwalPupukScreen> {
  late final JadwalPupukRepository _repo;
  JadwalPupuk? _jadwal;
  bool _loading = true;

  // Siklus options in days
  static const _siklusOptions = [60, 90, 120];

  @override
  void initState() {
    super.initState();
    _repo = JadwalPupukRepository(db: appDb);
    _load();
  }

  Future<void> _load() async {
    final j = await _repo.get(widget.lahan.id);
    if (mounted) setState(() { _jadwal = j; _loading = false; });
  }

  Future<void> _setSiklus(int days) async {
    setState(() => _loading = true);
    await _repo.setSiklus(widget.lahan.id, days);
    await _repo.rescheduleWithName(widget.lahan.id, widget.lahan.namaLahan);
    await _load();
    if (mounted) AppSnackbar.success(context, 'Siklus reminder diubah ke $days hari');
  }

  Future<void> _toggleActive(bool val) async {
    setState(() => _loading = true);
    await _repo.setActive(widget.lahan.id, active: val);
    await _load();
    if (mounted) {
      AppSnackbar.info(
        context,
        val ? 'Reminder pemupukan diaktifkan' : 'Reminder pemupukan dinonaktifkan',
      );
    }
  }

  Future<void> _markDoneToday() async {
    setState(() => _loading = true);
    await _repo.markPupukDone(widget.lahan.id);
    await _repo.rescheduleWithName(widget.lahan.id, widget.lahan.namaLahan);
    await _load();
    if (mounted) {
      AppSnackbar.success(
        context,
        'Pemupukan hari ini dicatat. Reminder berikutnya dijadwalkan.',
      );
    }
  }

  String _formatDate(int? ms) {
    if (ms == null) return '-';
    return DateFormat('d MMM yyyy', 'id_ID')
        .format(DateTime.fromMillisecondsSinceEpoch(ms));
  }

  int _daysUntil(int? ms) {
    if (ms == null) return 0;
    final target = DateTime.fromMillisecondsSinceEpoch(ms);
    return target.difference(DateTime.now()).inDays;
  }

  @override
  Widget build(BuildContext context) {
    final fase = JadwalPupukData.getByUsia(widget.lahan.usiaPohon);
    final currentMonth = DateTime.now().month;
    final tahun = DateTime.now().year;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text('Jadwal Pemupukan',
            style: AppTextStyles.display(18, color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Lahan info
            Text(widget.lahan.namaLahan, style: AppTextStyles.display(22)),
            const SizedBox(height: 4),
            Row(
              children: [
                _InfoChip(
                    text: '${widget.lahan.luasHa.toStringAsFixed(1)} ha',
                    color: AppColors.primary3),
                const SizedBox(width: 6),
                _InfoChip(
                    text: 'Usia ${widget.lahan.usiaPohon} thn',
                    color: AppColors.gold),
              ],
            ),
            const SizedBox(height: 20),

            // Fase card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF059669), Color(0xFF10B981)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF059669).withOpacity(0.3),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.eco_rounded, color: Colors.white, size: 22),
                      const SizedBox(width: 8),
                      Text('FASE PRODUKSI',
                          style: AppTextStyles.body(11,
                              color: Colors.white.withOpacity(0.85),
                              weight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(fase.fase,
                      style: AppTextStyles.display(18, color: Colors.white)),
                  const SizedBox(height: 8),
                  Text(fase.deskripsi,
                      style: AppTextStyles.body(12,
                          color: Colors.white.withOpacity(0.9))),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text('JADWAL TAHUN $tahun', style: AppTextStyles.label()),
            const SizedBox(height: 12),

            ...fase.jadwal.map((item) => _JadwalCard(
                  item: item,
                  status: _getStatus(item.bulanAngka, currentMonth),
                )),

            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.warnTint,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.warn.withOpacity(0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: AppColors.warn, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Jadwal mengikuti standar PPKS. Sesuaikan dengan kondisi tanah, '
                      'cuaca, dan hasil analisa daun jika tersedia.',
                      style: AppTextStyles.body(11,
                          color: AppColors.warn, weight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ─── REMINDER SECTION ─────────────────────────────────────────
            _buildReminderSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderSection() {
    if (_loading && _jadwal == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      );
    }

    final j = _jadwal;
    final hasHistory = j?.lastPemupukanAt != null;
    final daysLeft = _daysUntil(j?.nextReminderAt);
    final isOverdue = hasHistory && daysLeft < 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('REMINDER PEMUPUKAN', style: AppTextStyles.label()),
            const SizedBox(width: 6),
            HelpTooltip(
              term: 'Siklus Hari',
              explanation:
                  'Siklus pemupukan sawit normal: 90 hari (3 bulan). '
                  'Bisa lebih singkat di musim hujan, lebih panjang di musim kering. '
                  'Aplikasi akan mengirim notifikasi di tanggal yang ditentukan.',
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Status card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isOverdue
                  ? AppColors.danger.withOpacity(0.4)
                  : AppColors.border,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isOverdue
                          ? AppColors.dangerTint
                          : AppColors.primaryTint,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isOverdue
                          ? Icons.warning_amber_rounded
                          : Icons.notifications_active_rounded,
                      color: isOverdue ? AppColors.danger : AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasHistory
                              ? (isOverdue
                                  ? 'Sudah lewat ${daysLeft.abs()} hari!'
                                  : 'Pupuk berikutnya $daysLeft hari lagi')
                              : 'Belum ada riwayat pemupukan',
                          style: AppTextStyles.display(
                            15,
                            color: isOverdue
                                ? AppColors.danger
                                : AppColors.text,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          hasHistory
                              ? 'Terakhir: ${_formatDate(j?.lastPemupukanAt)}  •  Jadwal: ${_formatDate(j?.nextReminderAt)}'
                              : 'Input biaya PUPUK pertama untuk memulai tracking',
                          style: AppTextStyles.body(11,
                              color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (j?.jenisPupuk != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.grass_rounded,
                        size: 14, color: AppColors.textLight),
                    const SizedBox(width: 6),
                    Text('Pupuk terakhir: ${j!.jenisPupuk}',
                        style:
                            AppTextStyles.body(11, color: AppColors.textMid)),
                  ],
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 16),

        if (!hasHistory)
          EmptyState.icon(
            iconData: Icons.notifications_none_rounded,
            title: 'Atur Reminder Pemupukan',
            message:
                'Atur siklus di bawah lalu input biaya pupuk pertama untuk '
                'mengaktifkan reminder otomatis.',
            accent: AppColors.primary3,
          )
        else
          const SizedBox.shrink(),

        // Siklus hari selector
        const SizedBox(height: 8),
        _SiklusSelector(
          current: j?.siklusHari ?? 90,
          options: _siklusOptions,
          onSelect: _setSiklus,
          loading: _loading,
        ),

        const SizedBox(height: 14),

        // Active toggle
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Icon(Icons.alarm_rounded,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Aktifkan Notifikasi',
                    style:
                        AppTextStyles.body(14, weight: FontWeight.w600)),
              ),
              Switch.adaptive(
                value: j?.isActive ?? true,
                onChanged: _loading ? null : _toggleActive,
                activeColor: AppColors.primary,
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Manual mark done button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _loading ? null : _markDoneToday,
            icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
            label: const Text('Tandai Sudah Pupuk Hari Ini'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary3,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
              textStyle: AppTextStyles.body(
                14,
                weight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),
        Text(
          'Gunakan tombol ini jika pembelian pupuk tidak diinput melalui biaya di aplikasi.',
          style: AppTextStyles.body(11, color: AppColors.textMuted),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  _JadwalStatus _getStatus(int bulanAngkaItem, int currentMonth) {
    if (bulanAngkaItem == currentMonth) return _JadwalStatus.aktif;
    if (bulanAngkaItem < currentMonth) return _JadwalStatus.lewat;
    return _JadwalStatus.akanDatang;
  }
}

// ─── SIKLUS SELECTOR ─────────────────────────────────────────────────────────

class _SiklusSelector extends StatelessWidget {
  final int current;
  final List<int> options;
  final void Function(int) onSelect;
  final bool loading;

  const _SiklusSelector({
    required this.current,
    required this.options,
    required this.onSelect,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Siklus Reminder',
                style: AppTextStyles.body(13,
                    color: AppColors.textMid, weight: FontWeight.w600)),
            const SizedBox(width: 4),
            HelpTooltip(
              term: 'Siklus Hari',
              explanation:
                  'Siklus pemupukan sawit normal: 90 hari (3 bulan). '
                  'Bisa lebih singkat di musim hujan, lebih panjang di musim kering.',
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: options
              .map((d) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _SiklusChip(
                      days: d,
                      selected: current == d,
                      onTap: loading ? null : () => onSelect(d),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

class _SiklusChip extends StatelessWidget {
  final int days;
  final bool selected;
  final VoidCallback? onTap;

  const _SiklusChip(
      {required this.days, required this.selected, this.onTap});

  String get _label {
    if (days == 60) return '60 hari';
    if (days == 90) return '90 hari';
    if (days == 120) return '120 hari';
    return '$days hari';
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Text(
            _label,
            style: AppTextStyles.body(
              12,
              color: selected ? Colors.white : AppColors.textMid,
              weight: FontWeight.w600,
            ),
          ),
        ),
      );
}

// ─── SHARED PRIVATE WIDGETS (carried over from original) ────────────────────

enum _JadwalStatus { aktif, akanDatang, lewat }

class _JadwalCard extends StatelessWidget {
  final JadwalPupukItem item;
  final _JadwalStatus status;

  const _JadwalCard({required this.item, required this.status});

  @override
  Widget build(BuildContext context) {
    final isAktif = status == _JadwalStatus.aktif;
    final isLewat = status == _JadwalStatus.lewat;
    final bgColor = isAktif
        ? const Color(0xFF059669).withOpacity(0.08)
        : (isLewat ? AppColors.surfaceAlt : AppColors.surface);
    final borderColor =
        isAktif ? const Color(0xFF059669) : AppColors.border;
    final textOpacity = isLewat ? 0.6 : 1.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: isAktif ? 1.5 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isAktif
                        ? const Color(0xFF059669)
                        : (isLewat
                            ? AppColors.textLight
                            : AppColors.primaryTint),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Center(
                    child: Text(
                      item.bulanAngka.toString().padLeft(2, '0'),
                      style: AppTextStyles.mono(18,
                          color: (isAktif || isLewat)
                              ? Colors.white
                              : AppColors.primary,
                          weight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(item.bulan,
                              style: AppTextStyles.display(16,
                                  color:
                                      AppColors.text.withOpacity(textOpacity))),
                          const SizedBox(width: 8),
                          if (isAktif)
                            _StatusBadge(
                                label: 'BULAN INI',
                                color: const Color(0xFF059669)),
                          if (isLewat)
                            _StatusBadge(
                                label: 'SUDAH LEWAT',
                                color: AppColors.textLight.withOpacity(0.5),
                                textColor: AppColors.textMuted),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(item.pupukUtama,
                          style: AppTextStyles.body(13,
                              color: AppColors.textMuted.withOpacity(textOpacity),
                              weight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _DetailRow(label: 'Pupuk Tambahan', value: item.pupukTambahan),
            const SizedBox(height: 6),
            _DetailRow(label: 'Dosis', value: item.dosisPerHa),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_outline_rounded,
                      size: 14, color: AppColors.gold),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(item.catatan,
                        style: AppTextStyles.body(11, color: AppColors.textMid)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  const _StatusBadge(
      {required this.label,
      required this.color,
      this.textColor = Colors.white});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(label,
            style: AppTextStyles.body(9,
                color: textColor, weight: FontWeight.w800)),
      );
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: AppTextStyles.body(11, color: AppColors.textMuted)),
          ),
          Expanded(
            child: Text(value,
                style: AppTextStyles.body(12,
                    color: AppColors.text, weight: FontWeight.w600)),
          ),
        ],
      );
}

class _InfoChip extends StatelessWidget {
  final String text;
  final Color color;
  const _InfoChip({required this.text, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Text(text,
            style: AppTextStyles.body(11,
                color: color, weight: FontWeight.w600)),
      );
}
