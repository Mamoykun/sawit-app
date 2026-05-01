/// Privacy Policy + Terms of Service content (Bahasa Indonesia).
/// Disusun mengikuti UU 27/2022 PDP Indonesia + GDPR best practices.
///
/// IMPORTANT: Ini draft compliance. Sebelum production launch, sebaiknya
/// di-review oleh konsultan hukum yang familiar dengan UU PDP.
library;

class LegalContent {
  static const String version = '1.0';
  static const String effectiveDate = '29 April 2026';

  // ─── PRIVACY POLICY ────────────────────────────────────────────────────────
  static const List<LegalSection> privacyPolicy = [
    LegalSection(
      title: '1. Pendahuluan',
      body:
          'SawitKu ("kami") berkomitmen melindungi data pribadi Anda sebagai pengguna ("Anda"). Kebijakan ini menjelaskan bagaimana kami mengumpulkan, menggunakan, menyimpan, dan melindungi data Anda sesuai dengan Undang-Undang No. 27 Tahun 2022 tentang Pelindungan Data Pribadi (UU PDP).',
    ),
    LegalSection(
      title: '2. Data Yang Kami Kumpulkan',
      body: 'Kami mengumpulkan data berikut hanya untuk keperluan layanan:\n\n'
          '• Data Akun: nama, email, nomor telepon, password (terenkripsi)\n'
          '• Data Kebun: nama lahan, luas hektar, usia pohon, lokasi, jumlah pohon\n'
          '• Data Panen: tanggal, hasil ton, harga jual, catatan\n'
          '• Data Biaya: kategori, jumlah, periode, keterangan\n'
          '• Foto Tanaman: foto buah/batang/pelepah yang Anda upload untuk diagnosa AI\n'
          '• Data Penggunaan: aktivitas Anda dalam aplikasi (untuk peningkatan layanan)\n\n'
          'Kami TIDAK mengumpulkan: data biometrik, data finansial pribadi (rekening bank), kontak telepon Anda, atau lokasi GPS real-time.',
    ),
    LegalSection(
      title: '3. Tujuan Penggunaan',
      body:
          'Data Anda digunakan untuk:\n\n'
          '• Menyediakan fitur tracking panen dan analisa\n'
          '• Memproses foto tanaman dengan AI untuk diagnosa otomatis\n'
          '• Menghitung target produksi berdasarkan luas dan usia pohon\n'
          '• Menampilkan riwayat dan tren produksi Anda\n'
          '• Mengirim notifikasi terkait akun (login, perubahan paket)\n'
          '• Verifikasi pembayaran subscription\n'
          '• Peningkatan layanan secara agregat dan anonim\n\n'
          'Kami TIDAK pernah menjual data Anda kepada pihak ketiga untuk tujuan iklan.',
    ),
    LegalSection(
      title: '4. Pihak Ketiga',
      body:
          'Untuk fitur tertentu, kami berbagi data terbatas dengan:\n\n'
          '• Anthropic (Claude AI) — foto tanaman dikirim ke API Claude untuk diagnosa visual. Foto TIDAK disimpan di server Anthropic setelah diproses.\n'
          '• Penyedia hosting cloud — server kami berada di pusat data berstandar internasional.\n'
          '• Payment gateway (Midtrans) — hanya untuk proses pembayaran subscription. Kami TIDAK menyimpan nomor kartu Anda.\n\n'
          'Semua mitra ini terikat perjanjian menjaga kerahasiaan data Anda.',
    ),
    LegalSection(
      title: '5. Penyimpanan Data',
      body:
          'Data Anda disimpan dengan enkripsi at-rest dan in-transit (TLS 1.3). Server kami berada di Indonesia/regional Asia Tenggara untuk meminimalkan latensi.\n\n'
          'Data dipertahankan selama akun Anda aktif. Setelah Anda menghapus akun, data dihapus permanen dalam 30 hari (kecuali catatan transaksi keuangan yang wajib disimpan 5 tahun untuk audit pajak).',
    ),
    LegalSection(
      title: '6. Hak Anda (UU PDP Pasal 5-13)',
      body:
          'Sebagai pemilik data, Anda berhak untuk:\n\n'
          '✓ Akses — melihat semua data Anda di aplikasi\n'
          '✓ Koreksi — memperbarui data yang salah\n'
          '✓ Penghapusan — menghapus akun dan semua data ("right to be forgotten")\n'
          '✓ Portabilitas — mengekspor data Anda dalam format JSON\n'
          '✓ Penolakan — menolak pemrosesan data tertentu\n'
          '✓ Pencabutan persetujuan — kapan saja\n\n'
          'Untuk menggunakan hak ini, buka Profil → Hapus Akun atau Ekspor Data, atau email kami di privasi@sawitku.id.',
    ),
    LegalSection(
      title: '7. Keamanan',
      body:
          'Kami menerapkan keamanan berlapis:\n\n'
          '• Password di-hash dengan BCrypt (12 rounds)\n'
          '• Komunikasi terenkripsi TLS 1.3\n'
          '• Token JWT dengan masa berlaku terbatas\n'
          '• Akses database dibatasi role-based\n'
          '• Audit log untuk akses data sensitif\n\n'
          'Jika terjadi kebocoran data, kami akan memberitahu Anda dalam 72 jam sesuai UU PDP.',
    ),
    LegalSection(
      title: '8. Anak di Bawah Umur',
      body:
          'Layanan ini ditujukan untuk pengguna berusia 17 tahun ke atas. Kami tidak secara sadar mengumpulkan data dari anak di bawah umur tanpa persetujuan orang tua/wali.',
    ),
    LegalSection(
      title: '9. Perubahan Kebijakan',
      body:
          'Kami dapat memperbarui kebijakan ini sewaktu-waktu. Perubahan signifikan akan diberitahukan melalui aplikasi minimal 30 hari sebelum berlaku. Versi terbaru selalu tersedia di menu Profil → Privasi.',
    ),
    LegalSection(
      title: '10. Kontak',
      body:
          'Jika Anda punya pertanyaan, keluhan, atau permintaan terkait data pribadi:\n\n'
          'Email DPO: privasi@sawitku.id\n'
          'WhatsApp: +62 8xx-xxxx-xxxx\n'
          'Alamat: [Diisi alamat kantor]\n\n'
          'Anda juga dapat menghubungi Lembaga PDP atau Kementerian Komunikasi dan Informatika RI jika merasa hak Anda dilanggar.',
    ),
  ];

  // ─── TERMS OF SERVICE ──────────────────────────────────────────────────────
  static const List<LegalSection> termsOfService = [
    LegalSection(
      title: '1. Penerimaan Syarat',
      body:
          'Dengan mendaftar dan menggunakan SawitKu, Anda menyetujui Syarat & Ketentuan ini. Jika tidak setuju, mohon tidak menggunakan layanan.',
    ),
    LegalSection(
      title: '2. Layanan Yang Disediakan',
      body:
          'SawitKu adalah aplikasi manajemen kebun sawit yang menyediakan:\n\n'
          '• Pencatatan panen dan biaya operasional\n'
          '• Analisa hasil panen dengan AI (Claude)\n'
          '• Diagnosa kondisi tanaman dari foto\n'
          '• Jadwal pemupukan PPKS\n'
          '• Tips dan informasi pertanian sawit\n\n'
          'Layanan disediakan "as is" — kami berusaha akurat tapi tidak menjamin 100%. Selalu konsultasikan dengan penyuluh pertanian untuk keputusan penting.',
    ),
    LegalSection(
      title: '3. Akun Pengguna',
      body:
          'Anda bertanggung jawab atas:\n'
          '• Kerahasiaan password Anda\n'
          '• Aktivitas yang terjadi di akun Anda\n'
          '• Memberikan informasi yang benar dan akurat\n\n'
          'Satu pengguna hanya boleh memiliki satu akun. Akun ganda dapat diblokir tanpa pemberitahuan.',
    ),
    LegalSection(
      title: '4. Subscription & Pembayaran',
      body:
          'SawitKu menawarkan 3 paket: GRATIS, PETANI, dan PRO.\n\n'
          '• Pembayaran melalui Midtrans (kartu kredit, transfer bank, e-wallet)\n'
          '• Subscription otomatis perpanjangan setiap bulan\n'
          '• Anda dapat membatalkan kapan saja\n'
          '• Refund: layanan yang sudah dipakai tidak dapat di-refund. Sisa periode yang belum dipakai dapat di-refund jika diminta dalam 7 hari sejak pembayaran.\n'
          '• Harga dapat berubah dengan pemberitahuan 30 hari sebelumnya.',
    ),
    LegalSection(
      title: '5. Larangan Penggunaan',
      body:
          'Anda dilarang:\n\n'
          '• Mengupload konten ilegal, pornografi, atau kekerasan\n'
          '• Mengupload foto yang BUKAN tanaman sawit untuk menghemat kuota AI\n'
          '• Reverse engineering atau mengakses sistem secara tidak sah\n'
          '• Membuat akun palsu atau menggunakan identitas orang lain\n'
          '• Menggunakan layanan untuk tujuan komersial yang merugikan kami\n'
          '• Mengganggu operasional layanan (DDoS, scraping massal)\n\n'
          'Pelanggaran dapat menyebabkan akun di-suspend atau ditutup permanen tanpa refund.',
    ),
    LegalSection(
      title: '6. Hak Kekayaan Intelektual',
      body:
          'Logo, desain, kode, dan konten SawitKu adalah milik kami. Foto dan data yang Anda upload tetap milik Anda — Anda hanya memberi kami lisensi terbatas untuk memproses data tersebut demi memberikan layanan kepada Anda.',
    ),
    LegalSection(
      title: '7. Batasan Tanggung Jawab',
      body:
          'Analisa AI dan rekomendasi yang diberikan adalah panduan berbasis data agronomi umum. Kami TIDAK bertanggung jawab atas:\n\n'
          '• Kerugian akibat keputusan tani berdasarkan rekomendasi aplikasi\n'
          '• Gagal panen, serangan hama, atau kerugian finansial\n'
          '• Downtime layanan akibat force majeure (bencana, gangguan internet, dll)\n\n'
          'Tanggung jawab maksimal kami terbatas pada biaya subscription yang Anda bayarkan dalam 1 bulan terakhir.',
    ),
    LegalSection(
      title: '8. Pengakhiran Layanan',
      body:
          'Kami berhak menghentikan layanan kepada Anda jika:\n\n'
          '• Anda melanggar Syarat & Ketentuan\n'
          '• Pembayaran subscription gagal lebih dari 30 hari\n'
          '• Akun tidak aktif lebih dari 12 bulan (notifikasi 30 hari sebelum penghapusan)\n\n'
          'Anda dapat menghentikan akun kapan saja melalui Profil → Hapus Akun.',
    ),
    LegalSection(
      title: '9. Hukum Yang Berlaku',
      body:
          'Syarat & Ketentuan ini tunduk pada hukum Republik Indonesia. Sengketa diselesaikan secara musyawarah, atau melalui Pengadilan Negeri Jakarta Pusat jika tidak tercapai kesepakatan.',
    ),
    LegalSection(
      title: '10. Kontak',
      body:
          'Pertanyaan atau keluhan terkait layanan:\n\n'
          'Email: support@sawitku.id\n'
          'WhatsApp: +62 8xx-xxxx-xxxx\n'
          'Jam operasional: Senin-Jumat, 08.00-17.00 WIB',
    ),
  ];
}

class LegalSection {
  final String title;
  final String body;
  const LegalSection({required this.title, required this.body});
}
