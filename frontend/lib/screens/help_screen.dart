import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text('Bantuan & FAQ',
            style: AppTextStyles.display(18, color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
        children: [
          Text(
            'Pertanyaan yang Sering Ditanyakan',
            style: AppTextStyles.body(14, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          ..._categories.map((cat) => _CategorySection(category: cat)),
        ],
      ),
    );
  }
}

// ─── Data ─────────────────────────────────────────────────────────────────────

class _FaqEntry {
  final String q;
  final String a;
  const _FaqEntry(this.q, this.a);
}

class _Category {
  final IconData icon;
  final String title;
  final List<_FaqEntry> entries;
  const _Category({required this.icon, required this.title, required this.entries});
}

const _categories = [
  _Category(
    icon: Icons.play_circle_outline_rounded,
    title: 'Mulai Pakai',
    entries: [
      _FaqEntry(
        'Bagaimana cara menambah kebun pertama saya?',
        'Tap menu di Beranda → tap tombol "Tambah Kebun" (ikon +). Isi nama kebun, luas lahan (hektar), dan lokasi. Setelah tersimpan, kebun langsung muncul di daftar dan siap diisi data panen.',
      ),
      _FaqEntry(
        'Apa beda paket GRATIS, PETANI, dan PRO?',
        'Paket GRATIS cocok untuk 1 lahan dengan fitur dasar. Paket PETANI memungkinkan beberapa lahan dan laporan PDF. Paket PRO menambahkan analisa AI tanpa batas, notifikasi pintar, dan prioritas dukungan. Semua paket bisa dicoba dulu — upgrade kapan saja dari menu Langganan.',
      ),
    ],
  ),
  _Category(
    icon: Icons.grass_rounded,
    title: 'Input Panen',
    entries: [
      _FaqEntry(
        'Saya panen 2x sebulan, bagaimana inputnya?',
        'Input dua kali dengan tanggal masing-masing. Misalnya tanggal 5 dan tanggal 20 di bulan yang sama. Aplikasi otomatis menjumlahkan dan menampilkan total panen bulan itu di laporan. Tidak ada batasan jumlah input per bulan.',
      ),
      _FaqEntry(
        'Kenapa hasil analisa AI berbeda untuk lahan yang sama?',
        'Karena AI mempertimbangkan tren panen beberapa bulan terakhir, riwayat pemupukan, kondisi cuaca, dan harga pasar terkini. Jadi meski lahannya sama, analisa bulan ini bisa berbeda dari bulan lalu — justru itu yang membuat rekomendasinya akurat dan up-to-date.',
      ),
    ],
  ),
  _Category(
    icon: Icons.account_balance_wallet_outlined,
    title: 'Biaya & Tenaga Kerja',
    entries: [
      _FaqEntry(
        'Bagaimana track gaji pekerja per bulan?',
        'Buka menu Tenaga Kerja → tab Hari Kerja → input jumlah hari kerja per pekerja bulan itu. Aplikasi otomatis menghitung total gaji berdasarkan upah harian yang sudah Anda atur, dan hasilnya langsung masuk ke laporan biaya bulan tersebut.',
      ),
      _FaqEntry(
        'Apa itu Inventory Pupuk?',
        'Fitur untuk mencatat stok pupuk yang Anda miliki — jenis pupuk, jumlah, dan tanggal pembelian. Anda bisa atur ambang batas (threshold) sehingga aplikasi otomatis mengingatkan lewat notifikasi kalau stok mau habis. Berguna agar tidak kehabisan pupuk saat jadwal pemupukan tiba.',
      ),
    ],
  ),
  _Category(
    icon: Icons.wifi_off_rounded,
    title: 'Mode Offline',
    entries: [
      _FaqEntry(
        'Bisakah saya input panen di kebun tanpa internet?',
        'Bisa. Data panen, biaya, dan catatan tersimpan dulu di memori HP Anda. Saat kembali online — entah di rumah atau di kota — data otomatis dikirim ke server. Anda tidak perlu melakukan apa-apa, proses sinkronisasi berjalan sendiri di latar belakang.',
      ),
      _FaqEntry(
        'Bagaimana saya tahu data sudah tersinkronisasi?',
        'Lihat banner di bagian atas layar. Kalau muncul banner kuning bertuliskan "Offline", artinya HP Anda sedang tidak terhubung internet dan ada data yang menunggu. Kalau banner itu hilang, semua data sudah berhasil tersinkronisasi ke server.',
      ),
    ],
  ),
  _Category(
    icon: Icons.picture_as_pdf_outlined,
    title: 'Laporan & Cetak',
    entries: [
      _FaqEntry(
        'Bagaimana cetak laporan untuk koperasi atau bank?',
        'Tap menu Laporan → Cetak Laporan → pilih lahan dan periode (bulan/tahun). Laporan otomatis dibuat dalam format PDF yang rapi dan profesional. Anda bisa langsung simpan ke HP, cetak lewat printer, atau kirim via WhatsApp ke koperasi atau bank.',
      ),
      _FaqEntry(
        'Bisa export data ke Excel?',
        'Saat ini aplikasi mendukung impor data dari Excel (untuk upload data panen secara massal). Fitur ekspor ke Excel sedang dalam pengerjaan dan akan hadir di versi mendatang. Untuk sementara, gunakan laporan PDF untuk berbagi data.',
      ),
    ],
  ),
  _Category(
    icon: Icons.memory_rounded,
    title: 'AI Analisa',
    entries: [
      _FaqEntry(
        'Apa beda Analisa AI dengan Analisa Cepat?',
        'Analisa AI (ditandai badge biru "AI Premium") menggunakan teknologi kecerdasan buatan canggih untuk memberikan insight mendalam tentang produktivitas, pola panen, dan rekomendasi khusus kebun Anda. Analisa Cepat (badge abu-abu) menggunakan aturan agronomi standar — hasilnya instan, gratis, dan cocok untuk pengecekan sehari-hari.',
      ),
      _FaqEntry(
        'Kenapa kuota AI saya sudah habis?',
        'Setiap paket punya jatah analisa AI per bulan — GRATIS dapat sedikit, PETANI lebih banyak, PRO tidak terbatas. Kuota reset otomatis setiap tanggal 1 bulan baru. Kalau kuota habis sebelum akhir bulan, Anda bisa tetap pakai Analisa Cepat, atau upgrade paket dari menu Profil → Langganan.',
      ),
    ],
  ),
  _Category(
    icon: Icons.lock_outline_rounded,
    title: 'Akun & Keamanan',
    entries: [
      _FaqEntry(
        'Lupa password, bagaimana cara resetnya?',
        'Di halaman Login, tap tombol "Lupa Password?" di bawah kolom password. Masukkan alamat email yang terdaftar, lalu cek inbox email Anda. Klik link yang dikirimkan — link berlaku 1 jam. Setelah klik, Anda bisa langsung buat password baru.',
      ),
      _FaqEntry(
        'Bagaimana cara hapus akun saya?',
        'Buka Profil → gulir ke bawah → tap "Hapus Akun Permanen". Anda akan diminta memasukkan password sebagai konfirmasi. Setelah dikonfirmasi, seluruh data Anda — akun, kebun, riwayat panen, foto, dan langganan aktif — akan dihapus permanen dan tidak bisa dikembalikan.',
      ),
    ],
  ),
];

// ─── Widgets ──────────────────────────────────────────────────────────────────

class _CategorySection extends StatelessWidget {
  final _Category category;
  const _CategorySection({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _CategoryHeader(icon: category.icon, title: category.title),
          ...category.entries.map((e) => _FaqTile(entry: e)),
        ],
      ),
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const _CategoryHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        color: AppColors.primaryTint,
        borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.lg)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary3, size: 20),
          const SizedBox(width: 10),
          Text(title,
              style: AppTextStyles.body(15,
                  color: AppColors.primary, weight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  final _FaqEntry entry;
  const _FaqTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      iconColor: AppColors.primary3,
      collapsedIconColor: AppColors.textMuted,
      title: Text(
        entry.q,
        style: AppTextStyles.body(14,
            color: AppColors.text, weight: FontWeight.w600),
      ),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.bg,
            borderRadius: BorderRadius.circular(Radii.md),
          ),
          child: Text(
            entry.a,
            style: AppTextStyles.body(14,
                color: AppColors.textMid, weight: FontWeight.w400),
          ),
        ),
      ],
    );
  }
}
