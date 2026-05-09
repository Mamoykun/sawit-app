import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ChangelogScreen extends StatelessWidget {
  const ChangelogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text('Apa yang Baru',
            style: AppTextStyles.display(18, color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
        children: [
          Row(
            children: [
              const Icon(Icons.new_releases_outlined,
                  color: AppColors.primary3, size: 20),
              const SizedBox(width: 8),
              Text('Riwayat Pembaruan Aplikasi',
                  style: AppTextStyles.body(14, color: AppColors.textMuted)),
            ],
          ),
          const SizedBox(height: 20),
          ..._versions.map((v) => _VersionCard(version: v)),
        ],
      ),
    );
  }
}

// ─── Data ─────────────────────────────────────────────────────────────────────

class _Change {
  final String text;
  final bool isNew;
  const _Change(this.text, {this.isNew = false});
}

class _VersionEntry {
  final String version;
  final String date;
  final String headline;
  final List<_Change> changes;
  const _VersionEntry({
    required this.version,
    required this.date,
    required this.headline,
    required this.changes,
  });
}

const _versions = [
  _VersionEntry(
    version: 'v1.5.0',
    date: 'Mei 2026',
    headline: 'Tenaga Kerja & Manajemen Pupuk',
    changes: [
      _Change('Manajemen tenaga kerja dengan tracking hari kerja dan gaji otomatis', isNew: true),
      _Change('Inventory pupuk dengan notifikasi alert stok menipis', isNew: true),
      _Change('Deteksi anomali otomatis saat hasil panen turun signifikan', isNew: true),
      _Change('Reminder jadwal pemupukan via notifikasi HP', isNew: true),
      _Change('Halaman Bantuan & FAQ dalam aplikasi'),
      _Change('Form kirim feedback dan laporan bug'),
    ],
  ),
  _VersionEntry(
    version: 'v1.4.0',
    date: 'April 2026',
    headline: 'Pengalaman Pakai yang Lebih Nyaman',
    changes: [
      _Change('Tutorial onboarding interaktif saat pertama kali buka aplikasi', isNew: true),
      _Change('Mode Gelap — atur di Profil → Tampilan', isNew: true),
      _Change('Empty state lebih informatif dengan panduan langkah selanjutnya'),
      _Change('Tooltip bantuan di kolom input data agronomi'),
      _Change('Pesan error lebih jelas dan ramah'),
    ],
  ),
  _VersionEntry(
    version: 'v1.3.0',
    date: 'Maret 2026',
    headline: 'Analitik Produksi & Laporan',
    changes: [
      _Change('Grafik analitik produksi multi-lahan', isNew: true),
      _Change('Laporan PDF yang bisa langsung dibagikan ke koperasi atau bank', isNew: true),
      _Change('Perbandingan produktivitas antar lahan', isNew: true),
      _Change('Import data panen dari Excel', isNew: true),
      _Change('Perbaikan tampilan grafik di layar kecil'),
    ],
  ),
  _VersionEntry(
    version: 'v1.2.0',
    date: 'Februari 2026',
    headline: 'Diagnosa Visual & AI Premium',
    changes: [
      _Change('Diagnosa penyakit daun via foto menggunakan AI', isNew: true),
      _Change('Analisa AI Premium dengan insight mendalam per kebun', isNew: true),
      _Change('Badge paket (GRATIS/PETANI/PRO) dengan indikator kuota AI'),
      _Change('Mode offline — input panen tanpa internet, sync otomatis'),
      _Change('Perbaikan performa loading data riwayat panen'),
    ],
  ),
  _VersionEntry(
    version: 'v1.1.0',
    date: 'Januari 2026',
    headline: 'Multi-Lahan & Biaya Operasional',
    changes: [
      _Change('Dukungan beberapa lahan dalam satu akun', isNew: true),
      _Change('Pencatatan biaya operasional (pupuk, perawatan, lainnya)', isNew: true),
      _Change('Laporan Laba/Rugi bulanan otomatis', isNew: true),
      _Change('Filter riwayat panen berdasarkan bulan dan lahan'),
    ],
  ),
  _VersionEntry(
    version: 'v1.0.0',
    date: 'Desember 2025',
    headline: 'Peluncuran Perdana Sawitku',
    changes: [
      _Change('Input dan riwayat data panen TBS', isNew: true),
      _Change('Kalkulasi otomatis pendapatan berdasarkan harga pasar'),
      _Change('Analisa Cepat berbasis aturan agronomi standar'),
      _Change('Profil dan pengaturan akun'),
      _Change('Sistem langganan GRATIS / PETANI / PRO'),
    ],
  ),
];

// ─── Widgets ──────────────────────────────────────────────────────────────────

class _VersionCard extends StatelessWidget {
  final _VersionEntry version;
  const _VersionCard({required this.version});

  @override
  Widget build(BuildContext context) {
    final isLatest = version == _versions.first;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(
          color: isLatest ? AppColors.primary3.withOpacity(0.4) : AppColors.border,
          width: isLatest ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              color: isLatest ? AppColors.primaryTint : AppColors.surfaceAlt,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(Radii.lg)),
            ),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isLatest ? AppColors.primary : AppColors.textMuted,
                    borderRadius: BorderRadius.circular(Radii.pill),
                  ),
                  child: Text(
                    version.version,
                    style: AppTextStyles.body(12,
                        color: Colors.white, weight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        version.headline,
                        style: AppTextStyles.body(13,
                            color: isLatest
                                ? AppColors.primary
                                : AppColors.text,
                            weight: FontWeight.w700),
                      ),
                      Text(
                        version.date,
                        style: AppTextStyles.body(11,
                            color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                if (isLatest)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.circular(Radii.pill),
                    ),
                    child: Text('Terbaru',
                        style: AppTextStyles.body(10,
                            color: Colors.white, weight: FontWeight.w700)),
                  ),
              ],
            ),
          ),
          // Changes
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              children: version.changes
                  .map((c) => _ChangeItem(change: c))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChangeItem extends StatelessWidget {
  final _Change change;
  const _ChangeItem({required this.change});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Icon(
              change.isNew
                  ? Icons.add_circle_outline_rounded
                  : Icons.build_circle_outlined,
              size: 14,
              color: change.isNew ? AppColors.primary3 : AppColors.textMuted,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              change.text,
              style: AppTextStyles.body(13,
                  color: AppColors.textMid, weight: FontWeight.w400),
            ),
          ),
        ],
      ),
    );
  }
}
