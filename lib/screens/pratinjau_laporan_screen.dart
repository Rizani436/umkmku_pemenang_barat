import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../providers/laporan_provider.dart';
import '../theme/app_colors.dart';
import '../utils/format.dart';

class PratinjauLaporanScreen extends StatefulWidget {
  final bool isRugiLaba;
  final String namaUsaha;
  final FilterPeriodeState periode;
  final LaporanRugiLaba? dataRugiLaba;
  final LaporanNeraca? dataNeraca;

  const PratinjauLaporanScreen({
    super.key,
    required this.isRugiLaba,
    required this.namaUsaha,
    required this.periode,
    this.dataRugiLaba,
    this.dataNeraca,
  });

  @override
  State<PratinjauLaporanScreen> createState() => _PratinjauLaporanScreenState();
}

class _PratinjauLaporanScreenState extends State<PratinjauLaporanScreen> {
  bool _isSharing = false;
  bool _isDownloading = false;



  Future<Uint8List> _generatePdfBytes() async {
    final pdf = pw.Document();
    final primaryColor = PdfColor.fromHex('#5B4FDD');
    final greenColor = PdfColor.fromHex('#1DB57A');
    final redColor = PdfColor.fromHex('#FF5A5A');
    final accentColor = PdfColor.fromHex('#F5A623');

    if (widget.isRugiLaba && widget.dataRugiLaba != null) {
      final data = widget.dataRugiLaba!;
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
                        widget.namaUsaha.toUpperCase(),
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
                        'Periode: ${widget.periode.detailLabel} | Dicetak: ${formatTanggalIndo(DateTime.now())}',
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
                            pw.Text('Total Pemasukan',
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
                    pw.Text('Dihasilkan otomatis oleh Bisnis-Ku',
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
    } else if (!widget.isRugiLaba && widget.dataNeraca != null) {
      final data = widget.dataNeraca!;
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
                        widget.namaUsaha.toUpperCase(),
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
                        'Periode: ${widget.periode.detailLabel} | Dicetak: ${formatTanggalIndo(DateTime.now())}',
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
                            pw.Text('Kas', style: const pw.TextStyle(fontSize: 11)),
                            pw.Text(formatRupiah(data.kas), style: const pw.TextStyle(fontSize: 11)),
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
                            pw.Text('Piutang', style: const pw.TextStyle(fontSize: 11)),
                            pw.Text(formatRupiah(data.piutang), style: const pw.TextStyle(fontSize: 11)),
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
                            pw.Text('Persediaan', style: const pw.TextStyle(fontSize: 11)),
                            pw.Text(formatRupiah(data.persediaan), style: const pw.TextStyle(fontSize: 11)),
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
                            pw.Text('Mesin & Peralatan', style: const pw.TextStyle(fontSize: 11)),
                            pw.Text(formatRupiah(data.mesinPeralatan), style: const pw.TextStyle(fontSize: 11)),
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
                            pw.Text('Gedung', style: const pw.TextStyle(fontSize: 11)),
                            pw.Text(formatRupiah(data.gedung), style: const pw.TextStyle(fontSize: 11)),
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
                            pw.Text('Total Harta', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                            pw.Text(formatRupiah(data.totalHarta), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: primaryColor)),
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
                            pw.Text('Hutang', style: const pw.TextStyle(fontSize: 11)),
                            pw.Text(formatRupiah(data.hutang), style: const pw.TextStyle(fontSize: 11)),
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
                            pw.Text('Modal', style: const pw.TextStyle(fontSize: 11)),
                            pw.Text(formatRupiah(data.modal), style: const pw.TextStyle(fontSize: 11)),
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
                            pw.Text('Penghasilan Kotor', style: const pw.TextStyle(fontSize: 11)),
                            pw.Text(formatRupiah(data.penghasilanKotor), style: const pw.TextStyle(fontSize: 11)),
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
                            pw.Text('Total Dana', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                            pw.Text(formatRupiah(data.totalDana), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: accentColor)),
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
                    pw.Text('Dihasilkan otomatis oleh Bisnis-Ku',
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
    }

    return pdf.save();
  }

  Future<void> _bagikan() async {
    if (_isSharing || _isDownloading) return;
    setState(() => _isSharing = true);

    try {
      final pdfBytes = await _generatePdfBytes();
      final filename = widget.isRugiLaba
          ? 'Laporan_Rugi_Laba_${widget.namaUsaha.replaceAll(' ', '_')}.pdf'
          : 'Laporan_Neraca_${widget.namaUsaha.replaceAll(' ', '_')}.pdf';

      try {
        await Printing.sharePdf(bytes: pdfBytes, filename: filename);
      } catch (_) {
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdfBytes,
          name: filename,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Perlu Restart Aplikasi! Hentikan flutter run dan jalankan ulang agar plugin PDF terdaftar.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  Future<void> _unduhPdf() async {
    if (_isSharing || _isDownloading) return;
    setState(() => _isDownloading = true);

    try {
      final pdfBytes = await _generatePdfBytes();
      final filename = widget.isRugiLaba
          ? 'Laporan_Rugi_Laba_${widget.namaUsaha.replaceAll(' ', '_')}.pdf'
          : 'Laporan_Neraca_${widget.namaUsaha.replaceAll(' ', '_')}.pdf';

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
        name: filename,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Perlu Restart Aplikasi! Hentikan flutter run dan jalankan ulang agar plugin PDF terdaftar.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isRugiLaba
        ? 'Pratinjau Laporan Rugi Laba'
        : 'Pratinjau Laporan Neraca';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.textPrimary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        widget.isRugiLaba ? 'LAPORAN RUGI LABA' : 'LAPORAN NERACA',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.namaUsaha,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Periode: ${widget.periode.detailLabel}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1, color: Color(0xFFE5E7EB)),
                      const SizedBox(height: 16),

                      if (widget.isRugiLaba && widget.dataRugiLaba != null)
                        _buildRugiLabaPreviewContent(widget.dataRugiLaba!)
                      else if (!widget.isRugiLaba && widget.dataNeraca != null)
                        _buildNeracaPreviewContent(widget.dataNeraca!),

                      const SizedBox(height: 24),
                      const Divider(height: 1, color: Color(0xFFE5E7EB)),
                      const SizedBox(height: 16),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Dihasilkan otomatis oleh Bisnis-Ku',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: _isSharing || _isDownloading ? null : _bagikan,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: _isSharing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              )
                            : const Icon(Icons.share_outlined, size: 18),
                        label: Text(
                          _isSharing ? 'Membagikan...' : 'Bagikan',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _isSharing || _isDownloading ? null : _unduhPdf,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: _isDownloading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.download_rounded, size: 18),
                        label: Text(
                          _isDownloading ? 'Menyiapkan...' : 'Unduh PDF',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
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

  Widget _buildRugiLabaPreviewContent(LaporanRugiLaba data) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Pemasukan',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                formatRupiah(data.totalPendapatan),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1DB57A),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFF3F4F6)),

        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Pengeluaran',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                formatRupiah(data.totalPengeluaran),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFF5A5A),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F0FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Penghasilan Kotor',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                formatRupiah(data.penghasilanKotor),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: data.penghasilanKotor >= 0
                      ? AppColors.primary
                      : const Color(0xFFFF5A5A),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNeracaPreviewContent(LaporanNeraca data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'HARTA (Aktiva)',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Kas', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            Text(formatRupiah(data.kas), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Piutang', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            Text(formatRupiah(data.piutang), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Persediaan', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            Text(formatRupiah(data.persediaan), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Mesin & Peralatan', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            Text(formatRupiah(data.mesinPeralatan), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Gedung', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            Text(formatRupiah(data.gedung), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Total Harta', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            Text(formatRupiah(data.totalHarta), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary)),
          ],
        ),
        const SizedBox(height: 16),

        const Text(
          'SUMBER DANA (Pasiva)',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFFF5A623),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Hutang', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            Text(formatRupiah(data.hutang), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Modal', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            Text(formatRupiah(data.modal), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Penghasilan Kotor', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            Text(formatRupiah(data.penghasilanKotor), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Total Dana', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            Text(formatRupiah(data.totalDana), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFF5A623))),
          ],
        ),
        const SizedBox(height: 16),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: data.seimbang
                ? const Color(0xFFE6F9F0)
                : const Color(0xFFFFECEC),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                data.seimbang ? Icons.check_circle_outline_rounded : Icons.highlight_off_rounded,
                color: data.seimbang ? const Color(0xFF1DB57A) : const Color(0xFFFF5A5A),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                data.seimbang ? 'Neraca Seimbang' : 'Neraca Tidak Seimbang',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: data.seimbang ? const Color(0xFF1DB57A) : const Color(0xFFFF5A5A),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
