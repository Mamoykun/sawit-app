import 'dart:typed_data';
import 'package:excel/excel.dart';
import '../models/panen_model.dart';
import '../models/biaya_model.dart';
import '../services/analisa_service.dart';

class ImportRow<T> {
  final int rowNumber;
  final T? data;
  final List<String> errors;

  const ImportRow({
    required this.rowNumber,
    this.data,
    required this.errors,
  });

  bool get isValid => errors.isEmpty && data != null;
}

class ExcelImportService {
  static const List<String> _bulanList = [
    'januari', 'februari', 'maret', 'april', 'mei', 'juni',
    'juli', 'agustus', 'september', 'oktober', 'november', 'desember',
  ];

  static const List<String> _bulanDisplay = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];

  static const List<String> _panenHeaders = [
    'Bulan', 'Tahun', 'Tanggal', 'Ton Aktual', 'Harga/Ton', 'Catatan',
  ];

  static const List<String> _biayaHeaders = [
    'Bulan', 'Tahun', 'Kategori', 'Jumlah', 'Keterangan',
  ];

  static const List<String> _kategoriValid = [
    'PUPUK', 'TENAGA_KERJA', 'PESTISIDA', 'PERALATAN', 'LAINNYA',
  ];

  /// Parse a .xlsx file into rows of PanenModel.
  /// Expected columns (header row): Bulan | Tahun | Tanggal | Ton Aktual | Harga/Ton | Catatan
  Future<List<ImportRow<PanenModel>>> parsePanenExcel(
    Uint8List bytes,
    int lahanId,
    double luasHa,
    int usiaPohon,
  ) async {
    try {
      final excel = Excel.decodeBytes(bytes);
      final sheet = excel.tables.values.first;
      final rows = sheet.rows;

      if (rows.isEmpty) {
        return [
          ImportRow(
            rowNumber: 0,
            errors: ['File kosong atau tidak memiliki data'],
          )
        ];
      }

      // Validate header
      final headerRow = rows[0];
      if (!_validateHeaders(headerRow, _panenHeaders)) {
        return [
          ImportRow(
            rowNumber: 1,
            errors: ['Format file tidak sesuai template. Header harus: ${_panenHeaders.join(" | ")}'],
          )
        ];
      }

      final results = <ImportRow<PanenModel>>[];

      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];
        final rowNum = i + 1; // 1-indexed, matching Excel row number

        // Skip truly empty rows
        if (_isRowEmpty(row)) continue;

        final errors = <String>[];

        // Col 0: Bulan
        final bulanRaw = _cellStr(row, 0);
        final bulanIdx = _bulanList.indexOf(bulanRaw.toLowerCase().trim());
        if (bulanIdx < 0) {
          errors.add(
            'Bulan "$bulanRaw" tidak valid. Gunakan: Januari–Desember',
          );
        }
        final bulan = bulanIdx >= 0 ? _bulanDisplay[bulanIdx] : bulanRaw;
        final bulanAngka = bulanIdx >= 0 ? bulanIdx + 1 : 0;

        // Col 1: Tahun
        final tahunRaw = _cellStr(row, 1);
        final tahun = int.tryParse(tahunRaw.trim());
        if (tahun == null || tahun < 2020 || tahun > 2030) {
          errors.add('Tahun "$tahunRaw" tidak valid. Harus antara 2020–2030');
        }

        // Col 2: Tanggal (optional)
        final tanggalRaw = _cellStr(row, 2);
        int tanggal = 1;
        if (tanggalRaw.trim().isNotEmpty) {
          final t = int.tryParse(tanggalRaw.trim());
          if (t == null || t < 1 || t > 31) {
            errors.add('Tanggal "$tanggalRaw" tidak valid. Harus angka 1–31');
          } else {
            tanggal = t;
          }
        }

        // Col 3: Ton Aktual
        final tonRaw = _cellStr(row, 3);
        final ton = double.tryParse(tonRaw.replaceAll(',', '.').trim());
        if (ton == null || ton <= 0 || ton >= 10000) {
          errors.add(
            'Ton Aktual "$tonRaw" tidak valid. Harus angka > 0 dan < 10000',
          );
        }

        // Col 4: Harga/Ton (optional, default 2400000)
        final hargaRaw = _cellStr(row, 4);
        double harga = 2400000;
        if (hargaRaw.trim().isNotEmpty) {
          final h = double.tryParse(
            hargaRaw.replaceAll('.', '').replaceAll(',', '.').trim(),
          );
          if (h == null || h < 0) {
            errors.add('Harga/Ton "$hargaRaw" tidak valid. Harus angka >= 0');
          } else {
            harga = h;
          }
        }

        if (errors.isNotEmpty) {
          results.add(ImportRow(rowNumber: rowNum, errors: errors));
          continue;
        }

        final target = AnalisaService.getTarget(luasHa, usiaPohon);
        final persenKurang = ton! < target.min
            ? ((target.min - ton) / target.min * 100).clamp(0.0, 100.0)
            : 0.0;
        final status = ton >= target.min
            ? 'NORMAL'
            : persenKurang <= 20
                ? 'WARN'
                : 'DANGER';

        results.add(
          ImportRow(
            rowNumber: rowNum,
            data: PanenModel(
              lahanId: lahanId,
              luasHa: luasHa,
              usiaTahun: usiaPohon,
              tonAktual: ton,
              targetMin: target.min,
              targetMax: target.max,
              targetMid: target.mid,
              bulan: bulan,
              tahun: tahun,
              bulanAngka: bulanAngka,
              tanggal: tanggal,
              hargaPerTon: harga,
              persenKurang: persenKurang,
              statusPanen: status,
            ),
            errors: [],
          ),
        );
      }

      return results;
    } catch (e) {
      return [
        ImportRow(
          rowNumber: 0,
          errors: ['Gagal membaca file: $e'],
        )
      ];
    }
  }

  /// Parse a .xlsx file into rows of BiayaModel.
  /// Expected columns (header row): Bulan | Tahun | Kategori | Jumlah | Keterangan
  Future<List<ImportRow<BiayaModel>>> parseBiayaExcel(
    Uint8List bytes,
    int lahanId,
  ) async {
    try {
      final excel = Excel.decodeBytes(bytes);
      final sheet = excel.tables.values.first;
      final rows = sheet.rows;

      if (rows.isEmpty) {
        return [
          ImportRow(
            rowNumber: 0,
            errors: ['File kosong atau tidak memiliki data'],
          )
        ];
      }

      // Validate header
      final headerRow = rows[0];
      if (!_validateHeaders(headerRow, _biayaHeaders)) {
        return [
          ImportRow(
            rowNumber: 1,
            errors: ['Format file tidak sesuai template. Header harus: ${_biayaHeaders.join(" | ")}'],
          )
        ];
      }

      final results = <ImportRow<BiayaModel>>[];

      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];
        final rowNum = i + 1;

        if (_isRowEmpty(row)) continue;

        final errors = <String>[];

        // Col 0: Bulan
        final bulanRaw = _cellStr(row, 0);
        final bulanIdx = _bulanList.indexOf(bulanRaw.toLowerCase().trim());
        if (bulanIdx < 0) {
          errors.add(
            'Bulan "$bulanRaw" tidak valid. Gunakan: Januari–Desember',
          );
        }
        final bulan = bulanIdx >= 0 ? _bulanDisplay[bulanIdx] : bulanRaw;
        final bulanAngka = bulanIdx >= 0 ? bulanIdx + 1 : 0;

        // Col 1: Tahun
        final tahunRaw = _cellStr(row, 1);
        final tahun = int.tryParse(tahunRaw.trim());
        if (tahun == null || tahun < 2020 || tahun > 2030) {
          errors.add('Tahun "$tahunRaw" tidak valid. Harus antara 2020–2030');
        }

        // Col 2: Kategori
        final kategoriRaw = _cellStr(row, 2).toUpperCase().trim();
        if (!_kategoriValid.contains(kategoriRaw)) {
          errors.add(
            'Kategori "$kategoriRaw" tidak valid. Pilih: ${_kategoriValid.join(", ")}',
          );
        }

        // Col 3: Jumlah
        final jumlahRaw = _cellStr(row, 3);
        final jumlah = double.tryParse(
          jumlahRaw.replaceAll('.', '').replaceAll(',', '.').trim(),
        );
        if (jumlah == null || jumlah < 0) {
          errors.add('Jumlah "$jumlahRaw" tidak valid. Harus angka >= 0');
        }

        // Col 4: Keterangan (optional)
        final keterangan = _cellStr(row, 4);

        if (errors.isNotEmpty) {
          results.add(ImportRow(rowNumber: rowNum, errors: errors));
          continue;
        }

        results.add(
          ImportRow(
            rowNumber: rowNum,
            data: BiayaModel(
              id: 0,
              lahanId: lahanId,
              bulan: bulan,
              tahun: tahun!,
              bulanAngka: bulanAngka,
              kategori: KategoriBiaya.fromCode(kategoriRaw),
              jumlah: jumlah!,
              keterangan: keterangan.isNotEmpty ? keterangan : null,
            ),
            errors: [],
          ),
        );
      }

      return results;
    } catch (e) {
      return [
        ImportRow(
          rowNumber: 0,
          errors: ['Gagal membaca file: $e'],
        )
      ];
    }
  }

  /// Generate a downloadable Excel template for panen data.
  Future<Uint8List> generatePanenTemplate() async {
    final excel = Excel.createExcel();
    final sheet = excel['Data Panen'];

    // Header row with bold style
    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#2D6A4F'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
    );

    for (int i = 0; i < _panenHeaders.length; i++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = TextCellValue(_panenHeaders[i]);
      cell.cellStyle = headerStyle;
    }

    // Sample rows
    final sampleData = [
      ['Januari', '2025', '15', '22.5', '2400000', 'Panen normal'],
      ['Februari', '2025', '14', '21.0', '2500000', ''],
    ];

    for (int r = 0; r < sampleData.length; r++) {
      for (int c = 0; c < sampleData[r].length; c++) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r + 1))
            .value = TextCellValue(sampleData[r][c]);
      }
    }

    // Set column widths
    sheet.setColumnWidth(0, 14);
    sheet.setColumnWidth(1, 8);
    sheet.setColumnWidth(2, 10);
    sheet.setColumnWidth(3, 12);
    sheet.setColumnWidth(4, 14);
    sheet.setColumnWidth(5, 20);

    // Delete default Sheet1
    excel.delete('Sheet1');

    final encoded = excel.encode();
    return Uint8List.fromList(encoded!);
  }

  /// Generate a downloadable Excel template for biaya data.
  Future<Uint8List> generateBiayaTemplate() async {
    final excel = Excel.createExcel();
    final sheet = excel['Data Biaya'];

    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#1B4332'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
    );

    for (int i = 0; i < _biayaHeaders.length; i++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = TextCellValue(_biayaHeaders[i]);
      cell.cellStyle = headerStyle;
    }

    // Sample rows
    final sampleData = [
      ['Januari', '2025', 'PUPUK', '1500000', 'Pupuk NPK 25kg'],
      ['Januari', '2025', 'TENAGA_KERJA', '3000000', 'Upah pemanen'],
      ['Februari', '2025', 'PESTISIDA', '500000', ''],
    ];

    for (int r = 0; r < sampleData.length; r++) {
      for (int c = 0; c < sampleData[r].length; c++) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r + 1))
            .value = TextCellValue(sampleData[r][c]);
      }
    }

    // Kategori note
    final noteCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: sampleData.length + 2));
    noteCell.value = TextCellValue('Kategori valid: PUPUK, TENAGA_KERJA, PESTISIDA, PERALATAN, LAINNYA');

    sheet.setColumnWidth(0, 14);
    sheet.setColumnWidth(1, 8);
    sheet.setColumnWidth(2, 16);
    sheet.setColumnWidth(3, 14);
    sheet.setColumnWidth(4, 24);

    excel.delete('Sheet1');

    final encoded = excel.encode();
    return Uint8List.fromList(encoded!);
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  bool _validateHeaders(List<Data?> row, List<String> expected) {
    if (row.length < expected.length) return false;
    for (int i = 0; i < expected.length; i++) {
      final cell = _cellStr(row, i).trim().toLowerCase();
      if (cell != expected[i].toLowerCase()) return false;
    }
    return true;
  }

  bool _isRowEmpty(List<Data?> row) {
    return row.every((c) => c == null || c.value == null || c.value.toString().trim().isEmpty);
  }

  String _cellStr(List<Data?> row, int col) {
    if (col >= row.length) return '';
    final cell = row[col];
    if (cell == null || cell.value == null) return '';
    final v = cell.value;
    if (v is TextCellValue) return v.value.toString();
    if (v is IntCellValue) return v.value.toString();
    if (v is DoubleCellValue) return v.value.toString();
    if (v is FormulaCellValue) return v.formula;
    return v.toString();
  }
}
