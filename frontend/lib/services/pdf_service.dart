import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/panen_model.dart';
import '../models/lahan_model.dart';

class PdfService {
  static Future<void> exportLaporan({
    required LahanModel lahan,
    required List<PanenModel> data,
  }) async {
    final doc = pw.Document();
    final font = await PdfGoogleFonts.nunitoRegular();
    final fontBold = await PdfGoogleFonts.nunitoBold();
    final fontSemiBold = await PdfGoogleFonts.nunitoSemiBold();

    final green = PdfColor.fromHex('#2D6A4F');
    final greenLight = PdfColor.fromHex('#D8F3DC');
    final amber = PdfColor.fromHex('#E9A83E');
    final red = PdfColor.fromHex('#EF4444');
    final textMid = PdfColor.fromHex('#4B5563');
    final textLight = PdfColor.fromHex('#9CA3AF');
    final border = PdfColor.fromHex('#E5E7EB');
    final bg = PdfColor.fromHex('#F9FAFB');

    final sorted = List<PanenModel>.from(data)
      ..sort((a, b) {
        final ya = a.tahun ?? 0, yb = b.tahun ?? 0;
        if (ya != yb) return ya.compareTo(yb);
        final ma = a.bulanAngka ?? 0, mb = b.bulanAngka ?? 0;
        if (ma != mb) return ma.compareTo(mb);
        return (a.tanggal ?? 0).compareTo(b.tanggal ?? 0);
      });

    final total = sorted.fold(0.0, (s, p) => s + p.tonAktual);
    final avg = sorted.isEmpty ? 0.0 : total / sorted.length;
    final best = sorted.isEmpty
        ? 0.0
        : sorted.map((p) => p.tonAktual).reduce((a, b) => a > b ? a : b);
    final normalCount = sorted.where((p) => p.status == 'normal').length;

    final now = DateTime.now();
    final dateStr = '${now.day}/${now.month}/${now.year}';

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        header: (ctx) => _buildHeader(
          lahan: lahan,
          green: green,
          greenLight: greenLight,
          textMid: textMid,
          fontBold: fontBold,
          font: font,
          dateStr: dateStr,
        ),
        footer: (ctx) => pw.Padding(
          padding: const pw.EdgeInsets.only(top: 12),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('SawitKu — Laporan Panen',
                  style: pw.TextStyle(font: font, fontSize: 8, color: textLight)),
              pw.Text('Halaman ${ctx.pageNumber} dari ${ctx.pagesCount}',
                  style: pw.TextStyle(font: font, fontSize: 8, color: textLight)),
            ],
          ),
        ),
        build: (ctx) => [
          pw.SizedBox(height: 20),

          // ── KPI row ──────────────────────────────────────────────────────
          pw.Row(children: [
            _kpiCard('Total Panen', '${total.toStringAsFixed(1)} ton', green, greenLight, fontBold, font),
            pw.SizedBox(width: 10),
            _kpiCard('Rata-rata/Panen', '${avg.toStringAsFixed(1)} ton', amber, const PdfColor(1, 0.97, 0.88), fontBold, font),
            pw.SizedBox(width: 10),
            _kpiCard('Panen Terbaik', '${best.toStringAsFixed(1)} ton', textMid, bg, fontBold, font),
            pw.SizedBox(width: 10),
            _kpiCard('Sesuai Target', '$normalCount/${sorted.length}', green, greenLight, fontBold, font),
          ]),

          pw.SizedBox(height: 24),

          // ── Section label ─────────────────────────────────────────────────
          pw.Text('DETAIL PANEN',
              style: pw.TextStyle(
                  font: fontBold, fontSize: 8, color: textLight,
                  letterSpacing: 1)),
          pw.SizedBox(height: 10),

          // ── Table ─────────────────────────────────────────────────────────
          pw.Table(
            border: pw.TableBorder.all(color: border, width: 0.5),
            columnWidths: {
              0: const pw.FixedColumnWidth(24),
              1: const pw.FixedColumnWidth(56),
              2: const pw.FlexColumnWidth(1.2),
              3: const pw.FlexColumnWidth(1),
              4: const pw.FlexColumnWidth(1),
              5: const pw.FlexColumnWidth(0.9),
              6: const pw.FixedColumnWidth(46),
              7: const pw.FlexColumnWidth(1.2),
            },
            children: [
              // Header row
              pw.TableRow(
                decoration: pw.BoxDecoration(color: green),
                children: ['#', 'Tanggal', 'Bulan', 'Aktual (t)', 'Target (t)', 'Selisih (t)', 'Status', 'Estimasi']
                    .map((h) => _th(h, fontBold))
                    .toList(),
              ),
              // Data rows
              ...sorted.asMap().entries.map((e) {
                final i = e.key;
                final p = e.value;
                final isEven = i % 2 == 0;
                final selisih = p.tonAktual - p.targetMid;
                final statusColor = p.status == 'normal'
                    ? green
                    : p.status == 'warn'
                        ? amber
                        : red;
                final statusLabel = p.status == 'normal'
                    ? 'Normal'
                    : p.status == 'warn'
                        ? 'Kurang'
                        : 'Defisit';
                return pw.TableRow(
                  decoration: pw.BoxDecoration(
                      color: isEven ? PdfColors.white : bg),
                  children: [
                    _td('${i + 1}', font, textMid, align: pw.TextAlign.center),
                    _td(
                      p.tanggal != null
                          ? '${p.tanggal} ${_shortMonth(p.bulanAngka ?? 0)} ${p.tahun ?? ''}'
                          : '${_shortMonth(p.bulanAngka ?? 0)} ${p.tahun ?? ''}',
                      font, textMid,
                    ),
                    _td(p.bulan, font, textMid),
                    _td(p.tonAktual.toStringAsFixed(2), fontSemiBold, textMid,
                        align: pw.TextAlign.right),
                    _td(
                      '${p.targetMin.toStringAsFixed(1)}–${p.targetMax.toStringAsFixed(1)}',
                      font, textLight,
                      align: pw.TextAlign.right,
                    ),
                    _td(
                      '${selisih >= 0 ? '+' : ''}${selisih.toStringAsFixed(2)}',
                      fontSemiBold,
                      selisih >= 0 ? green : red,
                      align: pw.TextAlign.right,
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                      child: pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: pw.BoxDecoration(
                          color: statusColor,
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                        ),
                        child: pw.Text(statusLabel,
                            textAlign: pw.TextAlign.center,
                            style: pw.TextStyle(
                                font: fontBold, fontSize: 7.5, color: PdfColors.white)),
                      ),
                    ),
                    _td(
                      'Rp ${(p.nilaiEstimasi / 1000000).toStringAsFixed(1)}jt',
                      font, textMid,
                      align: pw.TextAlign.right,
                    ),
                  ],
                );
              }),
              // Total row
              pw.TableRow(
                decoration: pw.BoxDecoration(color: greenLight),
                children: [
                  _td('', fontBold, green),
                  _td('', fontBold, green),
                  _td('TOTAL', fontBold, green),
                  _td(total.toStringAsFixed(2), fontBold, green,
                      align: pw.TextAlign.right),
                  _td('', fontBold, green),
                  _td('', fontBold, green),
                  _td('', fontBold, green),
                  _td(
                    'Rp ${(sorted.fold(0.0, (s, p) => s + p.nilaiEstimasi) / 1000000).toStringAsFixed(1)}jt',
                    fontBold, green,
                    align: pw.TextAlign.right,
                  ),
                ],
              ),
            ],
          ),

          pw.SizedBox(height: 28),

          // ── Note ──────────────────────────────────────────────────────────
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: bg,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              border: pw.Border.all(color: border),
            ),
            child: pw.Text(
              'Laporan ini dibuat secara otomatis oleh SawitKu pada $dateStr. '
              'Estimasi nilai menggunakan harga jual yang diinput pengguna. '
              'Target produksi dihitung berdasarkan luas lahan dan usia pohon.',
              style: pw.TextStyle(font: font, fontSize: 8, color: textLight),
            ),
          ),
        ],
      ),
    );

    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: 'laporan-panen-${lahan.namaLahan.replaceAll(' ', '-').toLowerCase()}-${dateStr.replaceAll('/', '-')}.pdf',
    );
  }

  static pw.Widget _buildHeader({
    required LahanModel lahan,
    required PdfColor green,
    required PdfColor greenLight,
    required PdfColor textMid,
    required pw.Font fontBold,
    required pw.Font font,
    required String dateStr,
  }) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 16),
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: green,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('SawitKu',
                  style: pw.TextStyle(font: fontBold, fontSize: 22, color: PdfColors.white)),
              pw.SizedBox(height: 4),
              pw.Text('Laporan Produksi Panen Kelapa Sawit',
                  style: pw.TextStyle(font: font, fontSize: 10, color: PdfColor.fromHex('#B7E4C7'))),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(lahan.namaLahan,
                  style: pw.TextStyle(font: fontBold, fontSize: 13, color: PdfColors.white)),
              pw.SizedBox(height: 3),
              pw.Text(
                '${lahan.luasHa.toStringAsFixed(1)} ha  ·  Usia ${lahan.usiaPohon} tahun'
                '${lahan.lokasi != null ? '  ·  ${lahan.lokasi}' : ''}',
                style: pw.TextStyle(font: font, fontSize: 9, color: PdfColor.fromHex('#B7E4C7')),
              ),
              pw.SizedBox(height: 3),
              pw.Text('Dicetak: $dateStr',
                  style: pw.TextStyle(font: font, fontSize: 8, color: PdfColor.fromHex('#74C69D'))),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _kpiCard(String label, String value, PdfColor color,
      PdfColor bg, pw.Font fontBold, pw.Font font) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: bg,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          border: pw.Border.all(color: color),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label,
                style: pw.TextStyle(font: font, fontSize: 7.5, color: color)),
            pw.SizedBox(height: 4),
            pw.Text(value,
                style: pw.TextStyle(font: fontBold, fontSize: 13, color: color)),
          ],
        ),
      ),
    );
  }

  static pw.Widget _th(String text, pw.Font fontBold) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 7),
    child: pw.Text(text,
        style: pw.TextStyle(
            font: fontBold, fontSize: 8, color: PdfColors.white)),
  );

  static pw.Widget _td(String text, pw.Font font, PdfColor color,
      {pw.TextAlign align = pw.TextAlign.left}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: pw.Text(text,
            textAlign: align,
            style: pw.TextStyle(font: font, fontSize: 8.5, color: color)),
      );

  static String _shortMonth(int m) {
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return m >= 1 && m <= 12 ? months[m] : '';
  }
}
