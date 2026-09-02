import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../providers/laporan_provider.dart';
import '../utils/format.dart';

class PdfLaporanService {


  static Future<void> cetakRugiLaba({
    required String namaUsaha,
    required FilterPeriodeState periode,
    required LaporanRugiLaba data,
  }) async {
    final pdf = pw.Document();
    final primaryColor = PdfColor.fromHex('#5B4FDD');
    final greenColor = PdfColor.fromHex('#1DB57A');
    final redColor = PdfColor.fromHex('#FF5A5A');
    final isProfit = data.penghasilanKotor >= 0;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: primaryColor,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      namaUsaha.toUpperCase(),
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'LAPORAN RUGI LABA',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Periode: ${periode.detailLabel} | Dicetak: ${formatTanggalIndo(DateTime.now())}',
                      style: const pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 24),

              pw.Text(
                'Ringkasan Pendapatan & Pengeluaran',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 12),

              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Total Pendapatan',
                              style: const pw.TextStyle(fontSize: 12)),
                          pw.Text(
                            formatRupiah(data.totalPendapatan),
                            style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                              color: greenColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    pw.Divider(height: 1, color: PdfColors.grey300),

                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Total Pengeluaran',
                              style: const pw.TextStyle(fontSize: 12)),
                          pw.Text(
                            formatRupiah(data.totalPengeluaran),
                            style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                              color: redColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    pw.Divider(height: 1, color: PdfColors.grey300),

                    pw.Container(
                      color: PdfColors.grey100,
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'PENGHASILAN KOTOR',
                            style: pw.TextStyle(
                              fontSize: 13,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Text(
                            formatRupiah(data.penghasilanKotor),
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              color: isProfit ? primaryColor : redColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: isProfit
                      ? PdfColor.fromHex('#D6F5EB')
                      : PdfColor.fromHex('#FFE5E5'),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Text(
                  isProfit
                      ? 'Status: Usaha Anda sedang untung pada periode ini.'
                      : 'Status: Pengeluaran melebihi pendapatan pada periode ini.',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: isProfit ? greenColor : redColor,
                  ),
                ),
              ),

              pw.Spacer(),

              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('UMKMKu Pemenang Barat',
                      style: const pw.TextStyle(
                          fontSize: 9, color: PdfColors.grey600)),
                  pw.Text('Halaman 1 dari 1',
                      style: const pw.TextStyle(
                          fontSize: 9, color: PdfColors.grey600)),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name:
          'Laporan_Rugi_Laba_${namaUsaha.replaceAll(' ', '_')}_${periode.jenis.name}.pdf',
    );
  }

  static Future<void> cetakNeraca({
    required String namaUsaha,
    required FilterPeriodeState periode,
    required LaporanNeraca data,
  }) async {
    final pdf = pw.Document();
    final primaryColor = PdfColor.fromHex('#5B4FDD');
    final accentColor = PdfColor.fromHex('#F5A623');
    final greenColor = PdfColor.fromHex('#1DB57A');
    final redColor = PdfColor.fromHex('#FF5A5A');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: primaryColor,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      namaUsaha.toUpperCase(),
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'LAPORAN NERACA',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Periode: ${periode.detailLabel} | Dicetak: ${formatTanggalIndo(DateTime.now())}',
                      style: const pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              pw.Text(
                'HARTA (Aktiva)',
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Column(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Kas',
                              style: const pw.TextStyle(fontSize: 11)),
                          pw.Text(formatRupiah(data.kas),
                              style: const pw.TextStyle(fontSize: 11)),
                        ],
                      ),
                    ),
                    pw.Divider(height: 1, color: PdfColors.grey300),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Piutang',
                              style: const pw.TextStyle(fontSize: 11)),
                          pw.Text(formatRupiah(data.piutang),
                              style: const pw.TextStyle(fontSize: 11)),
                        ],
                      ),
                    ),
                    pw.Divider(height: 1, color: PdfColors.grey300),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Persediaan',
                              style: const pw.TextStyle(fontSize: 11)),
                          pw.Text(formatRupiah(data.persediaan),
                              style: const pw.TextStyle(fontSize: 11)),
                        ],
                      ),
                    ),
                    pw.Divider(height: 1, color: PdfColors.grey300),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Mesin & Peralatan',
                              style: const pw.TextStyle(fontSize: 11)),
                          pw.Text(formatRupiah(data.mesinPeralatan),
                              style: const pw.TextStyle(fontSize: 11)),
                        ],
                      ),
                    ),
                    pw.Divider(height: 1, color: PdfColors.grey300),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Gedung',
                              style: const pw.TextStyle(fontSize: 11)),
                          pw.Text(formatRupiah(data.gedung),
                              style: const pw.TextStyle(fontSize: 11)),
                        ],
                      ),
                    ),
                    pw.Divider(height: 1, color: PdfColors.grey300),
                    pw.Container(
                      color: PdfColors.grey100,
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 14, vertical: 11),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'Total Harta',
                            style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Text(
                            formatRupiah(data.totalHarta),
                            style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 16),

              pw.Text(
                'SUMBER DANA (Pasiva)',
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: accentColor,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Column(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Hutang',
                              style: const pw.TextStyle(fontSize: 11)),
                          pw.Text(formatRupiah(data.hutang),
                              style: const pw.TextStyle(fontSize: 11)),
                        ],
                      ),
                    ),
                    pw.Divider(height: 1, color: PdfColors.grey300),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Modal',
                              style: const pw.TextStyle(fontSize: 11)),
                          pw.Text(formatRupiah(data.modal),
                              style: const pw.TextStyle(fontSize: 11)),
                        ],
                      ),
                    ),
                    pw.Divider(height: 1, color: PdfColors.grey300),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Penghasilan Kotor',
                              style: const pw.TextStyle(fontSize: 11)),
                          pw.Text(formatRupiah(data.penghasilanKotor),
                              style: const pw.TextStyle(fontSize: 11)),
                        ],
                      ),
                    ),
                    pw.Divider(height: 1, color: PdfColors.grey300),
                    pw.Container(
                      color: PdfColors.grey100,
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 14, vertical: 11),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'Total Dana',
                            style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Text(
                            formatRupiah(data.totalDana),
                            style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                              color: accentColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 16),

              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: data.seimbang
                      ? PdfColor.fromHex('#D6F5EB')
                      : PdfColor.fromHex('#FFE5E5'),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Text(
                  data.seimbang ? 'Neraca Seimbang' : 'Neraca Tidak Seimbang',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: data.seimbang ? greenColor : redColor,
                  ),
                ),
              ),

              pw.Spacer(),

              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('UMKMKu Pemenang Barat',
                      style: const pw.TextStyle(
                          fontSize: 9, color: PdfColors.grey600)),
                  pw.Text('Halaman 1 dari 1',
                      style: const pw.TextStyle(
                          fontSize: 9, color: PdfColors.grey600)),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name:
          'Laporan_Neraca_${namaUsaha.replaceAll(' ', '_')}_${periode.jenis.name}.pdf',
    );
  }
}
