class TipKategori {
  final String nama;
  final List<TipItem> items;
  const TipKategori({required this.nama, required this.items});
}

class TipItem {
  final String judul;
  final List<String> poin;
  const TipItem({required this.judul, required this.poin});
}

class TipsData {
  static const List<TipKategori> kategori = [
    TipKategori(
      nama: 'Pemupukan',
      items: [
        TipItem(
          judul: 'Waktu Pemupukan Terbaik',
          poin: [
            'Aplikasikan saat tanah lembab (awal musim hujan atau setelah hujan).',
            'Hindari aplikasi saat musim kering ekstrem — pupuk tidak terserap optimal.',
            'Pagi hari (06.00-10.00) atau sore (15.00-17.30) untuk hindari penguapan.',
          ],
        ),
        TipItem(
          judul: 'Cara Aplikasi Pupuk Tepat',
          poin: [
            'Taburkan melingkar di area piringan pohon (radius 1-2 meter).',
            'Hindari aplikasi tepat di pangkal batang — bisa membakar akar.',
            'Tutup dengan tanah tipis atau mulsa pelepah agar pupuk tidak hilang.',
            'Bersihkan gulma di piringan dulu sebelum pupuk ditabur.',
          ],
        ),
        TipItem(
          judul: 'Tanda Defisiensi Nutrisi',
          poin: [
            'Daun menguning seluruh: kekurangan Nitrogen (N) — tambah Urea.',
            'Menguning antar tulang daun: kekurangan Magnesium (Mg) — tambah Dolomit.',
            'Bercak oranye pinggir daun: kekurangan Kalium (K) — tambah MOP/KCl.',
            'Daun pucat keseluruhan: kekurangan Fosfor (P) — tambah TSP atau RP.',
          ],
        ),
        TipItem(
          judul: 'Dosis Pupuk per Fase',
          poin: [
            'TBM (0-3 tahun): NPK 1 kg/pohon + Urea 0.3 kg, 4x/tahun.',
            'TM Muda (3-8 tahun): NPK 2 kg/pohon, 4x/tahun.',
            'TM Dewasa (>8 tahun): NPK 3 kg + MOP 2.5 kg, 2x/tahun.',
            'Sesuaikan dengan hasil analisa daun jika tersedia.',
          ],
        ),
        TipItem(
          judul: 'Pupuk Subsidi & Non-Subsidi',
          poin: [
            'Pupuk subsidi: NPK Phonska, Urea — harga lebih murah, butuh kartu tani.',
            'Non-subsidi: NPK Mahkota, MOP impor — kualitas spesifik untuk sawit.',
            'Untuk kebun produksi tinggi, kombinasi keduanya hasil terbaik.',
          ],
        ),
      ],
    ),
    TipKategori(
      nama: 'Panen & Kualitas',
      items: [
        TipItem(
          judul: 'Kriteria Tandan Matang Panen',
          poin: [
            'Brondolan (buah lepas) jatuh 5-10 buah per tandan di piringan.',
            'Warna buah luar oranye-kemerahan, mengkilap.',
            'Tandan terasa padat dan berat saat ditekan.',
            'Buah mentah = rendemen minyak rendah; buah lewat matang = busuk.',
          ],
        ),
        TipItem(
          judul: 'Rotasi Panen Optimal',
          poin: [
            'Rotasi 7-10 hari di musim panen raya.',
            'Rotasi 14-15 hari di musim panen kering.',
            'Tandai blok yang sudah dipanen dengan jelas (cat/papan).',
            'Catat hasil per blok untuk evaluasi produktivitas.',
          ],
        ),
        TipItem(
          judul: 'Teknik Memotong Tandan',
          poin: [
            'Gunakan dodos untuk pohon < 4 m, egrek untuk > 4 m.',
            'Potong pelepah lurus di bawah tandan (singkat & rapi).',
            'Hindari melukai pangkal batang — bisa jadi pintu masuk Ganoderma.',
            'Susun pelepah di gawangan antar pohon (mulsa alami).',
          ],
        ),
        TipItem(
          judul: 'Mengangkut TBS ke Pabrik',
          poin: [
            'Maksimal 24 jam dari panen sampai pabrik (asam lemak bebas naik 2-3% per hari).',
            'Tutup truk dengan terpal — hindari hujan & sinar langsung.',
            'Hindari tumpukan terlalu tinggi (buah memar).',
            'Catat berat & kualitas saat di pabrik untuk evaluasi.',
          ],
        ),
        TipItem(
          judul: 'Meningkatkan Rendemen Minyak',
          poin: [
            'Panen tepat matang — rendemen optimal di tingkat kematangan III.',
            'Hindari brondolan tertinggal di piringan — itu bagian dengan kandungan minyak tertinggi.',
            'Kumpulkan brondolan dalam keranjang khusus, bukan dicampur tandan.',
            'Pemupukan K (Kalium) cukup meningkatkan kandungan minyak.',
          ],
        ),
      ],
    ),
    TipKategori(
      nama: 'Hama & Penyakit',
      items: [
        TipItem(
          judul: 'Mengenali Penyakit Ganoderma',
          poin: [
            'Tanda awal: pelepah bagian bawah menguning, layu walaupun pupuk cukup.',
            'Pangkal batang muncul tubuh buah jamur seperti jamur kuping berwarna coklat-merah.',
            'Akar busuk berwarna coklat kehitaman, hancur saat dipegang.',
            'Tindakan: tebang pohon terinfeksi, bakar batang, bongkar tunggak.',
          ],
        ),
        TipItem(
          judul: 'Pengendalian Ulat Api',
          poin: [
            'Inspeksi bulanan — periksa daun untuk telur/larva di permukaan bawah.',
            'Pasang feromon trap untuk monitoring populasi.',
            'Jika ringan: aplikasi BT (Bacillus thuringiensis) atau pestisida nabati.',
            'Jika berat: insektisida sistemik (konsultasi penyuluh untuk dosis).',
          ],
        ),
        TipItem(
          judul: 'Kumbang Tanduk (Oryctes)',
          poin: [
            'Serangan terlihat dari pelepah muda (spear) yang berlubang segitiga.',
            'Pasang feromon agregat (etilen-4-metil) di kebun untuk perangkap.',
            'Bersihkan sisa batang tebang yang membusuk — itu tempat berkembangnya larva.',
            'Aplikasi insektisida sistemik di pucuk pohon yang terserang.',
          ],
        ),
        TipItem(
          judul: 'Pencegahan Penyakit Tular Tanah',
          poin: [
            'Drainase kebun harus baik — genangan air = jamur patogen berkembang.',
            'Buat parit drainase 50 cm setiap 4 baris pohon.',
            'Aplikasi Trichoderma sebagai biokontrol Ganoderma & Fusarium.',
            'Bersihkan piringan dari sisa pelepah lapuk yang menjadi sumber inokulum.',
          ],
        ),
        TipItem(
          judul: 'Tikus & Hama Vertebrata',
          poin: [
            'Tanda: brondolan banyak hilang, ada bekas gigitan di buah.',
            'Pasang Tyto alba (burung hantu) — 1 sangkar per 25-30 ha sangat efektif.',
            'Rodentisida hanya pilihan terakhir, gunakan dengan hati-hati.',
            'Bersihkan gulma tinggi yang jadi sarang tikus.',
          ],
        ),
      ],
    ),
  ];
}
