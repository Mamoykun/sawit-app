import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/lahan_model.dart';
import '../models/panen_model.dart';
import '../models/biaya_model.dart';

// ─── Options ──────────────────────────────────────────────────────────────────

class LaporanOptions {
  final LahanModel lahan;
  final int tahun;
  final int bulanMulai;
  final int bulanSelesai;
  final bool includePanen;
  final bool includeBiaya;
  final bool includeProfitLoss;
  final bool includeAnalytics;
  final String userName;

  const LaporanOptions({
    required this.lahan,
    required this.tahun,
    this.bulanMulai = 1,
    this.bulanSelesai = 12,
    this.includePanen = true,
    this.includeBiaya = true,
    this.includeProfitLoss = true,
    this.includeAnalytics = true,
    this.userName = 'Petani',
  });
}

// ─── Service ──────────────────────────────────────────────────────────────────

class LaporanPdfService {
  static const double _hargaPerTon = 2400000;

  // ── colour palette ──────────────────────────────────────────────────────────
  static final _green       = PdfColor.fromHex('#1B4332');
  static final _green2      = PdfColor.fromHex('#2D6A4F');
  static final _green3      = PdfColor.fromHex('#40916C');
  static final _greenLight  = PdfColor.fromHex('#D8F3DC');
  static final _greenTint   = PdfColor.fromHex('#F0FDF4');
  static final _gold        = PdfColor.fromHex('#B7791F');
  static final _goldLight   = PdfColor.fromHex('#FEF3C7');
  static final _red         = PdfColor.fromHex('#DC2626');
  static final _redLight    = PdfColor.fromHex('#FEF2F2');
  static final _amber       = PdfColor.fromHex('#92400E');
  static final _amberLight  = PdfColor.fromHex('#FFFBEB');
  static final _textDark    = PdfColor.fromHex('#111714');
  static final _textMid     = PdfColor.fromHex('#2E3828');
  static final _textMuted   = PdfColor.fromHex('#72776A');
  static final _textLight   = PdfColor.fromHex('#ADB5A0');
  static final _border      = PdfColor.fromHex('#E4E1D8');
  static final _bg          = PdfColor.fromHex('#F5F6F2');
  static final _surface     = PdfColors.white;

  // ── font helpers ─────────────────────────────────────────────────────────────
  static pw.Font get _font     => pw.Font.helvetica();
  static pw.Font get _fontBold => pw.Font.helveticaBold();

  Future<Uint8List> generate(
    LaporanOptions opts, {
    required List<PanenModel> panenList,
    required List<BiayaModel> biayaList,
  }) async {
    final doc = pw.Document();

    // Filter by bulan range
    final panen = panenList
        .where((p) =>
            (p.tahun == opts.tahun) &&
            (p.bulanAngka != null) &&
            (p.bulanAngka! >= opts.bulanMulai) &&
            (p.bulanAngka! <= opts.bulanSelesai))
        .toList()
      ..sort((a, b) => (a.bulanAngka ?? 0).compareTo(b.bulanAngka ?? 0));

    final biaya = biayaList
        .where((b) =>
            (b.tahun == opts.tahun) &&
            (b.bulanAngka >= opts.bulanMulai) &&
            (b.bulanAngka <= opts.bulanSelesai))
        .toList()
      ..sort((a, b) => a.bulanAngka.compareTo(b.bulanAngka));

    final now = DateTime.now();
    final dateStr = DateFormat('d MMMM yyyy', 'id_ID').format(now);

    final periodeStr = _periodeLabel(opts);

    // Pre-compute aggregates
    final totalPanen = panen.fold(0.0, (s, p) => s + p.tonAktual);
    final totalBiaya = biaya.fold(0.0, (s, b) => s + b.jumlah);
    final pendapatan = totalPanen * _hargaPerTon;
    final profit = pendapatan - totalBiaya;
    final margin = pendapatan > 0 ? (profit / pendapatan * 100) : 0.0;
    final avgPanen = panen.isEmpty ? 0.0 : totalPanen / panen.length;

    // ── Build document ────────────────────────────────────────────────────────
    doc.addPage(_buildCoverPage(opts, periodeStr, dateStr));

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(36, 36, 36, 48),
      theme: pw.ThemeData.withFont(base: _font, bold: _fontBold),
      header: _pageHeader,
      footer: (ctx) => _pageFooter(ctx, dateStr),
      build: (ctx) {
        final widgets = <pw.Widget>[];

        // ── Section 1: Ringkasan Eksekutif ─────────────────────────────────
        widgets.addAll(_sectionRingkasan(
          totalPanen: totalPanen,
          avgPanen: avgPanen,
          totalBiaya: totalBiaya,
          pendapatan: pendapatan,
          profit: profit,
          margin: margin,
          panenCount: panen.length,
          biayaCount: biaya.length,
        ));

        // ── Section 2: Detail Panen ─────────────────────────────────────────
        if (opts.includePanen && panen.isNotEmpty) {
          widgets.addAll(_sectionPanen(panen));
        }

        // ── Section 3: Detail Biaya ─────────────────────────────────────────
        if (opts.includeBiaya && biaya.isNotEmpty) {
          widgets.addAll(_sectionBiaya(biaya));
        }

        // ── Section 4: Profit & Loss Bulanan ───────────────────────────────
        if (opts.includeProfitLoss && (panen.isNotEmpty || biaya.isNotEmpty)) {
          widgets.addAll(_sectionProfitLoss(panen, biaya, opts));
        }

        // ── Section 5: Analytics ───────────────────────────────────────────
        if (opts.includeAnalytics && panen.isNotEmpty) {
          widgets.addAll(_sectionAnalytics(panen, opts.lahan));
        }

        // ── Footer note ─────────────────────────────────────────────────────
        widgets.addAll(_footerNote(dateStr, opts.userName));

        return widgets;
      },
    ));

    return doc.save();
  }

  // ── Cover page ──────────────────────────────────────────────────────────────

  pw.Page _buildCoverPage(
      LaporanOptions opts, String periodeStr, String dateStr) {
    final lahan = opts.lahan;
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(48),
      theme: pw.ThemeData.withFont(base: _font, bold: _fontBold),
      build: (ctx) => pw.Container(
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: _green, width: 2),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        ),
        child: pw.Column(
          children: [
            // Green header block
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(32),
              decoration: pw.BoxDecoration(
                color: _green,
                borderRadius: const pw.BorderRadius.only(
                  topLeft: pw.Radius.circular(6),
                  topRight: pw.Radius.circular(6),
                ),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text('SawitKu',
                      style: pw.TextStyle(
                          font: _fontBold,
                          fontSize: 14,
                          color: PdfColor.fromHex('#74C69D'))),
                  pw.SizedBox(height: 16),
                  pw.Text('LAPORAN KEBUN SAWIT',
                      style: pw.TextStyle(
                          font: _fontBold, fontSize: 28, color: _surface),
                      textAlign: pw.TextAlign.center),
                  pw.SizedBox(height: 8),
                  pw.Text(periodeStr,
                      style: pw.TextStyle(
                          font: _font,
                          fontSize: 14,
                          color: PdfColor.fromHex('#B7E4C7')),
                      textAlign: pw.TextAlign.center),
                ],
              ),
            ),

            // Lahan info
            pw.Expanded(
              child: pw.Padding(
                padding: const pw.EdgeInsets.all(36),
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _coverInfoRow('Nama Kebun', lahan.namaLahan),
                    if (lahan.lokasi != null && lahan.lokasi!.isNotEmpty)
                      _coverInfoRow('Lokasi', lahan.lokasi!),
                    _coverInfoRow(
                        'Luas Lahan', '${lahan.luasHa.toStringAsFixed(2)} ha'),
                    _coverInfoRow(
                        'Usia Pohon', '${lahan.usiaPohon} tahun'),
                    if (lahan.faseProduksi != null)
                      _coverInfoRow('Fase Produksi', lahan.faseProduksi!),
                    pw.SizedBox(height: 24),
                    pw.Divider(color: _border),
                    pw.SizedBox(height: 16),
                    _coverInfoRow('Dicetak oleh', opts.userName),
                    _coverInfoRow('Tanggal Cetak', dateStr),
                  ],
                ),
              ),
            ),

            // Footer strip
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(vertical: 12),
              decoration: pw.BoxDecoration(
                color: _greenTint,
                borderRadius: const pw.BorderRadius.only(
                  bottomLeft: pw.Radius.circular(6),
                  bottomRight: pw.Radius.circular(6),
                ),
              ),
              child: pw.Text(
                'Dokumen ini dihasilkan otomatis oleh aplikasi SawitKu',
                style: pw.TextStyle(font: _font, fontSize: 9, color: _textMuted),
                textAlign: pw.TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _coverInfoRow(String label, String value) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 5),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 120,
              child: pw.Text(label,
                  style: pw.TextStyle(
                      font: _font, fontSize: 11, color: _textMuted)),
            ),
            pw.Text(': ',
                style:
                    pw.TextStyle(font: _font, fontSize: 11, color: _textMuted)),
            pw.Expanded(
              child: pw.Text(value,
                  style: pw.TextStyle(
                      font: _fontBold, fontSize: 11, color: _textDark)),
            ),
          ],
        ),
      );

  // ── Page header / footer ────────────────────────────────────────────────────

  pw.Widget _pageHeader(pw.Context ctx) => pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 12),
        padding: const pw.EdgeInsets.fromLTRB(0, 0, 0, 8),
        decoration: pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: _border))),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('LAPORAN KEBUN SAWIT',
                style: pw.TextStyle(
                    font: _fontBold, fontSize: 8, color: _green2,
                    letterSpacing: 1)),
            pw.Text('SawitKu',
                style: pw.TextStyle(
                    font: _fontBold, fontSize: 10, color: _green)),
          ],
        ),
      );

  pw.Widget _pageFooter(pw.Context ctx, String dateStr) => pw.Container(
        margin: const pw.EdgeInsets.only(top: 8),
        padding: const pw.EdgeInsets.only(top: 8),
        decoration: pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(color: _border))),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Dicetak: $dateStr',
                style: pw.TextStyle(
                    font: _font, fontSize: 7.5, color: _textLight)),
            pw.Text(
                'Halaman ${ctx.pageNumber} dari ${ctx.pagesCount}',
                style: pw.TextStyle(
                    font: _font, fontSize: 7.5, color: _textLight)),
          ],
        ),
      );

  // ── Section 1: Ringkasan Eksekutif ─────────────────────────────────────────

  List<pw.Widget> _sectionRingkasan({
    required double totalPanen,
    required double avgPanen,
    required double totalBiaya,
    required double pendapatan,
    required double profit,
    required double margin,
    required int panenCount,
    required int biayaCount,
  }) {
    final isProfit = profit >= 0;
    return [
      _sectionHeader('RINGKASAN EKSEKUTIF'),
      pw.SizedBox(height: 10),
      pw.Row(children: [
        _statBox(
          label: 'Total Panen',
          value: '${totalPanen.toStringAsFixed(2)} ton',
          sub: 'dari $panenCount catatan',
          color: _green,
          bg: _greenLight,
        ),
        pw.SizedBox(width: 8),
        _statBox(
          label: 'Total Biaya',
          value: _fmtRp(totalBiaya),
          sub: 'dari $biayaCount catatan',
          color: _gold,
          bg: _goldLight,
        ),
        pw.SizedBox(width: 8),
        _statBox(
          label: 'Pendapatan Est.',
          value: _fmtRp(pendapatan),
          sub: 'Harga Rp ${_fmtRp(_hargaPerTon)}/ton',
          color: _green3,
          bg: _greenTint,
        ),
        pw.SizedBox(width: 8),
        _statBox(
          label: isProfit ? 'Profit Estimasi' : 'Rugi Estimasi',
          value: _fmtRp(profit.abs()),
          sub: 'Margin ${margin.toStringAsFixed(1)}%',
          color: isProfit ? _green : _red,
          bg: isProfit ? _greenLight : _redLight,
        ),
      ]),
      pw.SizedBox(height: 8),
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: pw.BoxDecoration(
          color: isProfit ? _greenTint : _redLight,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
          border: pw.Border.all(color: isProfit ? _green3 : _red),
        ),
        child: pw.Row(children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: pw.BoxDecoration(
              color: isProfit ? _green : _red,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Text(
              isProfit ? 'STATUS: NORMAL' : 'STATUS: PERLU PERHATIAN',
              style: pw.TextStyle(
                  font: _fontBold, fontSize: 8, color: _surface),
            ),
          ),
          pw.SizedBox(width: 12),
          pw.Expanded(
            child: pw.Text(
              isProfit
                  ? 'Kebun menghasilkan profit estimasi ${margin.toStringAsFixed(1)}% untuk periode ini.'
                  : 'Total biaya melebihi pendapatan estimasi. Tinjau pengeluaran dan optimalkan panen.',
              style: pw.TextStyle(font: _font, fontSize: 8.5, color: _textMid),
            ),
          ),
        ]),
      ),
      pw.SizedBox(height: 20),
    ];
  }

  // ── Section 2: Detail Panen ─────────────────────────────────────────────────

  List<pw.Widget> _sectionPanen(List<PanenModel> panen) {
    final normalMonths =
        panen.where((p) => p.tonAktual >= p.targetMin).length;
    final bestMonth =
        panen.reduce((a, b) => a.tonAktual > b.tonAktual ? a : b);
    final worstMonth =
        panen.reduce((a, b) => a.tonAktual < b.tonAktual ? a : b);
    final konsistensi = panen.isEmpty
        ? 0.0
        : normalMonths / panen.length * 100;

    final rows = panen.asMap().entries.map((e) {
      final i = e.key;
      final p = e.value;
      final isEven = i % 2 == 0;
      final selisih = p.tonAktual - p.targetMid;
      final ok = p.tonAktual >= p.targetMin;
      final statusLabel = p.status == 'normal'
          ? 'Normal'
          : p.status == 'warn'
              ? 'Kurang'
              : 'Defisit';
      final statusColor = p.status == 'normal'
          ? _green
          : p.status == 'warn'
              ? _amber
              : _red;

      return pw.TableRow(
        decoration: pw.BoxDecoration(color: isEven ? _surface : _bg),
        children: [
          _td('${_shortMonth(p.bulanAngka ?? 0)} ${p.tahun ?? ''}',
              _font, _textMid),
          _td(
              p.tanggal != null
                  ? '${p.tanggal} ${_shortMonth(p.bulanAngka ?? 0)}'
                  : '-',
              _font, _textMuted),
          _td(p.tonAktual.toStringAsFixed(2), _fontBold, _textDark,
              align: pw.TextAlign.right),
          _td(p.targetMid.toStringAsFixed(2), _font, _textMuted,
              align: pw.TextAlign.right),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: pw.Container(
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: pw.BoxDecoration(
                color: statusColor,
                borderRadius:
                    const pw.BorderRadius.all(pw.Radius.circular(3)),
              ),
              child: pw.Text(statusLabel,
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                      font: _fontBold, fontSize: 7, color: _surface)),
            ),
          ),
          _td(
              '${selisih >= 0 ? '+' : ''}${selisih.toStringAsFixed(2)}',
              _fontBold,
              ok ? _green : _red,
              align: pw.TextAlign.right),
        ],
      );
    }).toList();

    return [
      _sectionHeader('DETAIL PANEN'),
      pw.SizedBox(height: 10),
      pw.Table(
        border: pw.TableBorder.all(color: _border, width: 0.5),
        columnWidths: {
          0: const pw.FixedColumnWidth(64),
          1: const pw.FixedColumnWidth(52),
          2: const pw.FlexColumnWidth(1),
          3: const pw.FlexColumnWidth(1),
          4: const pw.FixedColumnWidth(50),
          5: const pw.FlexColumnWidth(0.9),
        },
        children: [
          pw.TableRow(
            decoration: pw.BoxDecoration(color: _green),
            children: [
              'Bulan',
              'Tanggal',
              'Hasil (ton)',
              'Target (ton)',
              'Status',
              'Selisih (ton)'
            ].map((h) => _th(h)).toList(),
          ),
          ...rows,
        ],
      ),
      pw.SizedBox(height: 10),
      // Sub-stats
      pw.Row(children: [
        _miniStatBox('Bulan Terbaik',
            '${bestMonth.bulan}: ${bestMonth.tonAktual.toStringAsFixed(2)} ton',
            _green, _greenLight),
        pw.SizedBox(width: 8),
        _miniStatBox('Bulan Terburuk',
            '${worstMonth.bulan}: ${worstMonth.tonAktual.toStringAsFixed(2)} ton',
            _red, _redLight),
        pw.SizedBox(width: 8),
        _miniStatBox('Konsistensi Normal',
            '${konsistensi.toStringAsFixed(0)}% ($normalMonths/${panen.length} bln)',
            _gold, _goldLight),
      ]),
      pw.SizedBox(height: 20),
    ];
  }

  // ── Section 3: Detail Biaya ─────────────────────────────────────────────────

  List<pw.Widget> _sectionBiaya(List<BiayaModel> biaya) {
    final total = biaya.fold(0.0, (s, b) => s + b.jumlah);

    // Group by kategori
    final byKat = <KategoriBiaya, List<BiayaModel>>{};
    for (final b in biaya) {
      (byKat[b.kategori] ??= []).add(b);
    }

    final tableRows = <pw.TableRow>[];
    int rowIdx = 0;
    for (final entry in byKat.entries) {
      final katTotal = entry.value.fold(0.0, (s, b) => s + b.jumlah);
      // Kategori header row
      tableRows.add(pw.TableRow(
        decoration: pw.BoxDecoration(color: _greenTint),
        children: [
          _td(entry.key.label.toUpperCase(), _fontBold, _green2),
          _td('', _font, _textMuted),
          _td('', _font, _textMuted),
          _td(_fmtRp(katTotal), _fontBold, _green2,
              align: pw.TextAlign.right),
        ],
      ));
      // Individual items
      for (final b in entry.value) {
        final isEven = rowIdx % 2 == 0;
        tableRows.add(pw.TableRow(
          decoration: pw.BoxDecoration(color: isEven ? _surface : _bg),
          children: [
            _td('  ${b.bulan} ${b.tahun}', _font, _textMuted),
            _td(b.keterangan ?? '-', _font, _textMuted),
            _td('', _font, _textMuted),
            _td(_fmtRp(b.jumlah), _font, _textDark,
                align: pw.TextAlign.right),
          ],
        ));
        rowIdx++;
      }
    }
    // Total row
    tableRows.add(pw.TableRow(
      decoration: pw.BoxDecoration(color: _greenLight),
      children: [
        _td('TOTAL BIAYA', _fontBold, _green),
        _td('', _fontBold, _green),
        _td('', _fontBold, _green),
        _td(_fmtRp(total), _fontBold, _green, align: pw.TextAlign.right),
      ],
    ));

    return [
      _sectionHeader('DETAIL BIAYA'),
      pw.SizedBox(height: 10),
      pw.Table(
        border: pw.TableBorder.all(color: _border, width: 0.5),
        columnWidths: {
          0: const pw.FlexColumnWidth(1.2),
          1: const pw.FlexColumnWidth(2),
          2: const pw.FlexColumnWidth(0.5),
          3: const pw.FlexColumnWidth(1.3),
        },
        children: [
          pw.TableRow(
            decoration: pw.BoxDecoration(color: _green),
            children: ['Kategori / Bulan', 'Keterangan', '', 'Jumlah']
                .map((h) => _th(h))
                .toList(),
          ),
          ...tableRows,
        ],
      ),
      pw.SizedBox(height: 20),
    ];
  }

  // ── Section 4: Profit & Loss Bulanan ───────────────────────────────────────

  List<pw.Widget> _sectionProfitLoss(
    List<PanenModel> panen,
    List<BiayaModel> biaya,
    LaporanOptions opts,
  ) {
    // Build per-month P&L
    final months = <int>{};
    for (final p in panen) {
      if (p.bulanAngka != null) months.add(p.bulanAngka!);
    }
    for (final b in biaya) {
      months.add(b.bulanAngka);
    }
    final sortedMonths = months.toList()..sort();

    double totalPend = 0, totalBiaya = 0;

    final tableRows = <pw.TableRow>[];
    for (final m in sortedMonths) {
      final mPanen = panen
          .where((p) => p.bulanAngka == m)
          .fold(0.0, (s, p) => s + p.tonAktual);
      final mBiaya = biaya
          .where((b) => b.bulanAngka == m)
          .fold(0.0, (s, b) => s + b.jumlah);
      final mPend = mPanen * _hargaPerTon;
      final mProfit = mPend - mBiaya;
      final mMargin = mPend > 0 ? (mProfit / mPend * 100) : 0.0;
      totalPend += mPend;
      totalBiaya += mBiaya;

      final isPos = mProfit >= 0;
      final idx = sortedMonths.indexOf(m);
      final isEven = idx % 2 == 0;

      tableRows.add(pw.TableRow(
        decoration: pw.BoxDecoration(color: isEven ? _surface : _bg),
        children: [
          _td(_bulanName(m), _font, _textMid),
          _td(_fmtRp(mPend), _font, _textMid, align: pw.TextAlign.right),
          _td(_fmtRp(mBiaya), _font, _textMid, align: pw.TextAlign.right),
          _td(_fmtRp(mProfit.abs()), _fontBold, isPos ? _green : _red,
              align: pw.TextAlign.right),
          _td(
            '${isPos ? '+' : '-'}${mMargin.abs().toStringAsFixed(1)}%',
            _fontBold,
            isPos ? _green : _red,
            align: pw.TextAlign.right,
          ),
        ],
      ));
    }

    final totalProfit = totalPend - totalBiaya;
    final totalMargin = totalPend > 0 ? (totalProfit / totalPend * 100) : 0.0;
    final isPosTotal = totalProfit >= 0;

    tableRows.add(pw.TableRow(
      decoration: pw.BoxDecoration(color: _greenLight),
      children: [
        _td('TOTAL', _fontBold, _green),
        _td(_fmtRp(totalPend), _fontBold, _green, align: pw.TextAlign.right),
        _td(_fmtRp(totalBiaya), _fontBold, _green, align: pw.TextAlign.right),
        _td(_fmtRp(totalProfit.abs()), _fontBold,
            isPosTotal ? _green : _red, align: pw.TextAlign.right),
        _td(
          '${isPosTotal ? '+' : '-'}${totalMargin.abs().toStringAsFixed(1)}%',
          _fontBold,
          isPosTotal ? _green : _red,
          align: pw.TextAlign.right,
        ),
      ],
    ));

    return [
      _sectionHeader('PROFIT & LOSS BULANAN'),
      pw.SizedBox(height: 10),
      pw.Table(
        border: pw.TableBorder.all(color: _border, width: 0.5),
        columnWidths: {
          0: const pw.FlexColumnWidth(1.2),
          1: const pw.FlexColumnWidth(1.4),
          2: const pw.FlexColumnWidth(1.4),
          3: const pw.FlexColumnWidth(1.4),
          4: const pw.FixedColumnWidth(56),
        },
        children: [
          pw.TableRow(
            decoration: pw.BoxDecoration(color: _green),
            children: ['Bulan', 'Pendapatan', 'Biaya', 'Profit', 'Margin']
                .map((h) => _th(h))
                .toList(),
          ),
          ...tableRows,
        ],
      ),
      pw.SizedBox(height: 20),
    ];
  }

  // ── Section 5: Analytics ────────────────────────────────────────────────────

  List<pw.Widget> _sectionAnalytics(
      List<PanenModel> panen, LahanModel lahan) {
    final normalCount =
        panen.where((p) => p.status == 'normal').length;
    final warnCount = panen.where((p) => p.status == 'warn').length;
    final dangerCount =
        panen.where((p) => p.status == 'danger').length;

    final totalTon = panen.fold(0.0, (s, p) => s + p.tonAktual);
    final avgTon = panen.isEmpty ? 0.0 : totalTon / panen.length;
    final avgYieldHa =
        lahan.luasHa > 0 ? avgTon / lahan.luasHa : 0.0;

    // Generate a simple text insight
    String insight;
    if (normalCount == panen.length) {
      insight =
          'Semua bulan dalam periode ini mencapai target produksi. Kebun dalam kondisi sangat baik.';
    } else if (normalCount >= panen.length * 0.75) {
      insight =
          '${normalCount}/${panen.length} bulan normal. Yield rata-rata ${avgYieldHa.toStringAsFixed(2)} t/ha. '
          'Perlu optimasi pada $warnCount bulan kurang dan $dangerCount bulan defisit.';
    } else {
      insight =
          'Hanya $normalCount/${panen.length} bulan normal. Yield rata-rata ${avgYieldHa.toStringAsFixed(2)} t/ha. '
          'Disarankan evaluasi jadwal pemupukan dan pengendalian hama segera.';
    }

    // Per-month yield table
    final yieldRows = panen.asMap().entries.map((e) {
      final i = e.key;
      final p = e.value;
      final isEven = i % 2 == 0;
      final yieldHa = lahan.luasHa > 0 ? p.tonAktual / lahan.luasHa : 0.0;
      final ok = p.tonAktual >= p.targetMin;
      return pw.TableRow(
        decoration: pw.BoxDecoration(color: isEven ? _surface : _bg),
        children: [
          _td(_bulanName(p.bulanAngka ?? 0), _font, _textMid),
          _td(p.tonAktual.toStringAsFixed(2), _fontBold, _textDark,
              align: pw.TextAlign.right),
          _td(yieldHa.toStringAsFixed(3), _font, _textMid,
              align: pw.TextAlign.right),
          _td(p.targetMid.toStringAsFixed(2), _font, _textMuted,
              align: pw.TextAlign.right),
          pw.Padding(
            padding:
                const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: pw.Container(
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: pw.BoxDecoration(
                color: ok ? _green : (p.status == 'warn' ? _amber : _red),
                borderRadius:
                    const pw.BorderRadius.all(pw.Radius.circular(3)),
              ),
              child: pw.Text(
                ok
                    ? 'Normal'
                    : (p.status == 'warn' ? 'Kurang' : 'Defisit'),
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                    font: _fontBold, fontSize: 7, color: _surface),
              ),
            ),
          ),
        ],
      );
    }).toList();

    return [
      _sectionHeader('ANALYTICS & KPI'),
      pw.SizedBox(height: 10),
      // Distribution row
      pw.Row(children: [
        _statBox(
          label: 'Bulan Normal',
          value: '$normalCount',
          sub: '${(normalCount / panen.length * 100).toStringAsFixed(0)}% dari total',
          color: _green,
          bg: _greenLight,
        ),
        pw.SizedBox(width: 8),
        _statBox(
          label: 'Bulan Kurang',
          value: '$warnCount',
          sub: '${(warnCount / panen.length * 100).toStringAsFixed(0)}% dari total',
          color: _amber,
          bg: _amberLight,
        ),
        pw.SizedBox(width: 8),
        _statBox(
          label: 'Bulan Defisit',
          value: '$dangerCount',
          sub: '${(dangerCount / panen.length * 100).toStringAsFixed(0)}% dari total',
          color: _red,
          bg: _redLight,
        ),
        pw.SizedBox(width: 8),
        _statBox(
          label: 'Avg Yield',
          value: '${avgYieldHa.toStringAsFixed(2)} t/ha',
          sub: 'per bulan per hektar',
          color: _green3,
          bg: _greenTint,
        ),
      ]),
      pw.SizedBox(height: 10),
      // Insight box
      pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: _bg,
          border: pw.Border.all(color: _border),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        ),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Insight: ',
                style: pw.TextStyle(
                    font: _fontBold, fontSize: 9, color: _green2)),
            pw.Expanded(
              child: pw.Text(insight,
                  style: pw.TextStyle(font: _font, fontSize: 9, color: _textMid)),
            ),
          ],
        ),
      ),
      pw.SizedBox(height: 10),
      pw.Table(
        border: pw.TableBorder.all(color: _border, width: 0.5),
        columnWidths: {
          0: const pw.FlexColumnWidth(1.2),
          1: const pw.FlexColumnWidth(1),
          2: const pw.FlexColumnWidth(1),
          3: const pw.FlexColumnWidth(1),
          4: const pw.FixedColumnWidth(50),
        },
        children: [
          pw.TableRow(
            decoration: pw.BoxDecoration(color: _green),
            children: [
              'Bulan',
              'Aktual (ton)',
              'Yield (t/ha)',
              'Target (ton)',
              'Status'
            ].map((h) => _th(h)).toList(),
          ),
          ...yieldRows,
        ],
      ),
      pw.SizedBox(height: 20),
    ];
  }

  // ── Footer note ─────────────────────────────────────────────────────────────

  List<pw.Widget> _footerNote(String dateStr, String userName) => [
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: _bg,
            border: pw.Border.all(color: _border),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Laporan ini dihasilkan otomatis oleh aplikasi SawitKu pada $dateStr.',
                style:
                    pw.TextStyle(font: _font, fontSize: 8, color: _textMuted),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Untuk konfirmasi data, hubungi pemilik kebun: $userName.',
                style:
                    pw.TextStyle(font: _font, fontSize: 8, color: _textMuted),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Estimasi pendapatan dihitung berdasarkan harga Rp ${_fmtRp(_hargaPerTon)}/ton. '
                'Target produksi dihitung berdasarkan luas lahan dan usia pohon.',
                style: pw.TextStyle(
                    font: _font, fontSize: 7.5, color: _textLight),
              ),
            ],
          ),
        ),
      ];

  // ── Shared widgets ──────────────────────────────────────────────────────────

  pw.Widget _sectionHeader(String title) => pw.Container(
        margin: const pw.EdgeInsets.only(top: 4),
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: pw.BoxDecoration(
          color: _green,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        ),
        child: pw.Text(title,
            style: pw.TextStyle(
                font: _fontBold, fontSize: 9, color: _surface,
                letterSpacing: 0.8)),
      );

  pw.Widget _statBox({
    required String label,
    required String value,
    required String sub,
    required PdfColor color,
    required PdfColor bg,
  }) =>
      pw.Expanded(
        child: pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: bg,
            border: pw.Border.all(color: color),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(label,
                  style: pw.TextStyle(
                      font: _font, fontSize: 7.5, color: color)),
              pw.SizedBox(height: 3),
              pw.Text(value,
                  style: pw.TextStyle(
                      font: _fontBold, fontSize: 12, color: color)),
              pw.SizedBox(height: 2),
              pw.Text(sub,
                  style: pw.TextStyle(
                      font: _font, fontSize: 7, color: _textMuted)),
            ],
          ),
        ),
      );

  pw.Widget _miniStatBox(String label, String value, PdfColor color, PdfColor bg) =>
      pw.Expanded(
        child: pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            color: bg,
            border: pw.Border.all(color: color),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(label,
                  style: pw.TextStyle(
                      font: _font, fontSize: 7, color: color)),
              pw.SizedBox(height: 3),
              pw.Text(value,
                  style: pw.TextStyle(
                      font: _fontBold, fontSize: 8.5, color: color)),
            ],
          ),
        ),
      );

  pw.Widget _th(String text) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 7),
        child: pw.Text(text,
            style: pw.TextStyle(
                font: _fontBold, fontSize: 8, color: _surface)),
      );

  pw.Widget _td(String text, pw.Font font, PdfColor color,
          {pw.TextAlign align = pw.TextAlign.left}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: pw.Text(text,
            textAlign: align,
            style: pw.TextStyle(font: font, fontSize: 8.5, color: color)),
      );

  // ── Formatting helpers ──────────────────────────────────────────────────────

  static String _fmtRp(num n) {
    final f = NumberFormat.currency(
        locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return f.format(n);
  }

  static String _periodeLabel(LaporanOptions opts) {
    const months = [
      '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    if (opts.bulanMulai == 1 && opts.bulanSelesai == 12) {
      return 'Januari – Desember ${opts.tahun}';
    }
    final mStart = opts.bulanMulai >= 1 && opts.bulanMulai <= 12
        ? months[opts.bulanMulai]
        : '';
    final mEnd = opts.bulanSelesai >= 1 && opts.bulanSelesai <= 12
        ? months[opts.bulanSelesai]
        : '';
    return '$mStart – $mEnd ${opts.tahun}';
  }

  static String _shortMonth(int m) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return m >= 1 && m <= 12 ? months[m] : '';
  }

  static String _bulanName(int m) {
    const months = [
      '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return m >= 1 && m <= 12 ? months[m] : '-';
  }
}
