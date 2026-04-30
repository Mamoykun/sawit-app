import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/lahan_model.dart';
import '../data/jadwal_pupuk_data.dart';

class JadwalPupukScreen extends StatelessWidget {
  final LahanModel lahan;
  const JadwalPupukScreen({super.key, required this.lahan});

  @override
  Widget build(BuildContext context) {
    final fase = JadwalPupukData.getByUsia(lahan.usiaPohon);
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
            Text(lahan.namaLahan, style: AppTextStyles.display(22)),
            const SizedBox(height: 4),
            Row(
              children: [
                _InfoChip(
                    text: '${lahan.luasHa.toStringAsFixed(1)} ha',
                    color: AppColors.primary3),
                const SizedBox(width: 6),
                _InfoChip(
                    text: 'Usia ${lahan.usiaPohon} thn',
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
                      const Icon(Icons.eco_rounded,
                          color: Colors.white, size: 22),
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
            // Disclaimer
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
          ],
        ),
      ),
    );
  }

  _JadwalStatus _getStatus(int bulanAngkaItem, int currentMonth) {
    if (bulanAngkaItem == currentMonth) return _JadwalStatus.aktif;
    if (bulanAngkaItem < currentMonth) return _JadwalStatus.lewat;
    return _JadwalStatus.akanDatang;
  }
}

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
    final borderColor = isAktif
        ? const Color(0xFF059669)
        : (isLewat ? AppColors.border : AppColors.border);
    final textOpacity = isLewat ? 0.6 : 1.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: borderColor,
            width: isAktif ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: isAktif
                        ? const Color(0xFF059669)
                        : (isLewat ? AppColors.textLight : AppColors.primaryTint),
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
                                  color: AppColors.text
                                      .withOpacity(textOpacity))),
                          const SizedBox(width: 8),
                          if (isAktif)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF059669),
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text('BULAN INI',
                                  style: AppTextStyles.body(9,
                                      color: Colors.white,
                                      weight: FontWeight.w800)),
                            ),
                          if (isLewat)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.textLight.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text('SUDAH LEWAT',
                                  style: AppTextStyles.body(9,
                                      color: AppColors.textMuted,
                                      weight: FontWeight.w700)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(item.pupukUtama,
                          style: AppTextStyles.body(13,
                              color: AppColors.textMuted
                                  .withOpacity(textOpacity),
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
                        style: AppTextStyles.body(11,
                            color: AppColors.textMid)),
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
            style: AppTextStyles.body(11, color: color, weight: FontWeight.w600)),
      );
}
