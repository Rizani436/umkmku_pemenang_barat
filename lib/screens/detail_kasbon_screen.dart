import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/hutang.dart';
import '../models/piutang.dart';
import '../providers/kasbon_provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/laporan_provider.dart';
import '../providers/riwayat_provider.dart';
import '../providers/usaha_provider.dart';
import '../repositories/hutang_repository.dart';
import '../repositories/piutang_repository.dart';
import '../repositories/transaksi_repository.dart';
import '../theme/app_colors.dart';
import '../utils/rupiah_formatter.dart';
import 'edit_kasbon_screen.dart';
import '../utils/format.dart';

class DetailKasbonScreen extends ConsumerStatefulWidget {
  final Hutang? hutang;
  final Piutang? piutang;

  const DetailKasbonScreen({
    super.key,
    this.hutang,
    this.piutang,
  }) : assert(hutang != null || piutang != null, 'Salah satu hutang atau piutang harus diisi');

  @override
  ConsumerState<DetailKasbonScreen> createState() => _DetailKasbonScreenState();
}

class _DetailKasbonScreenState extends ConsumerState<DetailKasbonScreen> {
  bool get _isPiutang => widget.piutang != null;

  String get _title => _isPiutang ? 'Detail Piutang' : 'Detail Hutang';
  String get _totalLabel => _isPiutang ? 'Total Piutang' : 'Total Hutang';

  String get _nama => _isPiutang ? widget.piutang!.namaOrang : widget.hutang!.namaToko;
  String? get _nomorHP => _isPiutang ? widget.piutang!.nomorHP : null;
  double get _nominal => _isPiutang ? widget.piutang!.nominal : widget.hutang!.nominal;
  String? get _keterangan => _isPiutang ? widget.piutang!.keterangan : widget.hutang!.keterangan;
  DateTime? get _tglJatuhTempo =>
      _isPiutang ? widget.piutang!.tglJatuhTempo : widget.hutang!.tglJatuhTempo;
  DateTime get _createdAt => _isPiutang ? widget.piutang!.createdAt : widget.hutang!.createdAt;



  Future<void> _konfirmasiHapus() async {
    final setuju = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Hapus $_title?'),
        content: const Text(
          'Catatan kasbon ini akan dihapus secara permanen dari pembukuan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5A5A),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (setuju != true) return;

    try {
      if (_isPiutang) {
        await ref.read(piutangRepositoryProvider).hapus(widget.piutang!.id);
      } else {
        await ref.read(hutangRepositoryProvider).hapus(widget.hutang!.id);
      }

      ref.invalidate(hutangListProvider);
      ref.invalidate(piutangListProvider);
      ref.invalidate(dashboardSummaryProvider);
      ref.invalidate(riwayatProvider);

      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Catatan $_title berhasil dihapus'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus: $e')),
      );
    }
  }

  Future<void> _bukaDialogCicil() async {
    final sisaPiutang = _nominal;
    final cicilCtrl = TextEditingController();

    final nominalCicilan = await showDialog<double>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final inputClean = cicilCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
            final inputVal = double.tryParse(inputClean) ?? 0;
            final sisaSetelahCicil = (sisaPiutang - inputVal).clamp(0, double.infinity).toDouble();

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3DC),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.payments_outlined, color: Color(0xFFF5A623)),
                  ),
                  const SizedBox(width: 10),
                  Text(_isPiutang ? 'Cicil Piutang' : 'Cicil Hutang',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Nama: $_nama', style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('Sisa Saat Ini: ${formatRupiah(sisaPiutang)}',
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    const SizedBox(height: 16),
                    const Text('Nominal Pembayaran / Cicilan:',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: cicilCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        CurrencyInputFormatter(),
                      ],
                      autofocus: true,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        prefixText: 'Rp ',
                        hintText: '0',
                        filled: true,
                        fillColor: const Color(0xFFF8F7FD),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE5E0FF)),
                        ),
                      ),
                      onChanged: (_) => setModalState(() {}),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: inputVal >= sisaPiutang
                            ? const Color(0xFFE6F9F0)
                            : const Color(0xFFF0EFFF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            inputVal >= sisaPiutang
                                ? Icons.check_circle_rounded
                                : Icons.info_outline_rounded,
                            size: 18,
                            color: inputVal >= sisaPiutang
                                ? const Color(0xFF1DB57A)
                                : AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              inputVal >= sisaPiutang
                                  ? 'Akan LUNAS sepenuhnya!'
                                  : 'Sisa setelah cicil: ${formatRupiah(sisaSetelahCicil)}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: inputVal >= sisaPiutang
                                    ? const Color(0xFF1DB57A)
                                    : AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, null),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: (inputVal <= 0) ? null : () => Navigator.pop(ctx, inputVal),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1DB57A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Simpan Cicilan'),
                ),
              ],
            );
          },
        );
      },
    );

    if (nominalCicilan == null || nominalCicilan <= 0) return;

    try {
      final usaha = ref.read(currentUsahaProvider).value;
      if (usaha != null) {
        final nominalBayar = (nominalCicilan >= sisaPiutang) ? sisaPiutang : nominalCicilan;
        if (!_isPiutang) {
          final ketLabel = nominalCicilan >= sisaPiutang ? 'Pelunasan Hutang' : 'Cicilan Hutang';
          await ref.read(transaksiRepositoryProvider).tambah(
                idUsaha: usaha.id,
                jenisTransaksi: 'pengeluaran',
                kategori: '$ketLabel ($_nama)',
                total: nominalBayar,
              );
        } else {
          final ketLabel = nominalCicilan >= sisaPiutang ? 'Pelunasan Piutang' : 'Cicilan Piutang';
          await ref.read(transaksiRepositoryProvider).tambah(
                idUsaha: usaha.id,
                jenisTransaksi: 'pemasukan',
                kategori: '$ketLabel ($_nama)',
                total: nominalBayar,
              );
        }
      }

      if (nominalCicilan >= sisaPiutang) {
        if (_isPiutang) {
          await ref.read(piutangRepositoryProvider).hapus(widget.piutang!.id);
        } else {
          await ref.read(hutangRepositoryProvider).hapus(widget.hutang!.id);
        }
      } else {
        final sisaBaru = sisaPiutang - nominalCicilan;
        if (_isPiutang) {
          await ref.read(piutangRepositoryProvider).update(
                id: widget.piutang!.id,
                namaOrang: widget.piutang!.namaOrang,
                nominal: sisaBaru,
                nomorHP: widget.piutang!.nomorHP,
                keterangan: widget.piutang!.keterangan,
                tglJatuhTempo: widget.piutang!.tglJatuhTempo,
              );
        } else {
          await ref.read(hutangRepositoryProvider).update(
                id: widget.hutang!.id,
                namaToko: widget.hutang!.namaToko,
                nominal: sisaBaru,
                keterangan: widget.hutang!.keterangan,
                tglJatuhTempo: widget.hutang!.tglJatuhTempo,
              );
        }
      }

      ref.invalidate(hutangListProvider);
      ref.invalidate(piutangListProvider);
      ref.invalidate(dashboardSummaryProvider);
      ref.invalidate(laporanNeracaProvider);
      ref.invalidate(laporanRugiLabaProvider);
      ref.invalidate(riwayatProvider);

      if (!mounted) return;
      Navigator.of(context).pop(true);

      final msg = nominalCicilan >= sisaPiutang
          ? '$_title atas nama "$_nama" berhasil LUNAS! 🎉'
          : 'Cicilan ${formatRupiah(nominalCicilan)} berhasil dicatat! Sisa: ${formatRupiah(sisaPiutang - nominalCicilan)}';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: const Color(0xFF1DB57A),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mencatat cicilan: $e')),
      );
    }
  }

  Future<void> _tandaiLunas() async {
    final setuju = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Tandai Lunas?'),
        content: Text('Apakah kasbon atas nama "$_nama" sudah lunas dibayar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1DB57A),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Ya, Lunas'),
          ),
        ],
      ),
    );

    if (setuju != true) return;

    try {
      final usaha = ref.read(currentUsahaProvider).value;
      if (usaha != null) {
        if (!_isPiutang) {
          await ref.read(transaksiRepositoryProvider).tambah(
                idUsaha: usaha.id,
                jenisTransaksi: 'pengeluaran',
                kategori: 'Pelunasan Hutang ($_nama)',
                total: _nominal,
              );
        } else {
          await ref.read(transaksiRepositoryProvider).tambah(
                idUsaha: usaha.id,
                jenisTransaksi: 'pemasukan',
                kategori: 'Pelunasan Piutang ($_nama)',
                total: _nominal,
              );
        }
      }

      if (_isPiutang) {
        await ref.read(piutangRepositoryProvider).hapus(widget.piutang!.id);
      } else {
        await ref.read(hutangRepositoryProvider).hapus(widget.hutang!.id);
      }

      ref.invalidate(hutangListProvider);
      ref.invalidate(piutangListProvider);
      ref.invalidate(dashboardSummaryProvider);
      ref.invalidate(laporanNeracaProvider);
      ref.invalidate(laporanRugiLabaProvider);
      ref.invalidate(riwayatProvider);

      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$_title atas nama "$_nama" berhasil dilunasi! 🎉'),
          backgroundColor: const Color(0xFF1DB57A),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memperbarui status: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  children: [
                    _buildTopSummaryCard(),
                    const SizedBox(height: 20),

                    _buildDetailInfoCard(),
                  ],
                ),
              ),
            ),

            _buildBottomActionBar(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            color: AppColors.textPrimary,
          ),
          Expanded(
            child: Text(
              _title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          IconButton(
            onPressed: _bukaEdit,
            icon: const Icon(Icons.edit_rounded, size: 22),
            color: AppColors.primary,
            tooltip: 'Edit Data',
          ),
        ],
      ),
    );
  }

  Future<void> _bukaEdit() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EditKasbonScreen(
          hutang: widget.hutang,
          piutang: widget.piutang,
        ),
      ),
    );
    if (result == true && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  Widget _buildTopSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: const BoxDecoration(
              color: Color(0xFFFFE5E5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shopping_bag_rounded,
              size: 36,
              color: Color(0xFFFF5A5A),
            ),
          ),
          const SizedBox(height: 16),

          Text(
            _totalLabel,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),

          Text(
            formatRupiah(_nominal),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFF5A5A),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailInfoCard() {
    final tglJatuhTempoStr = _tglJatuhTempo != null
        ? formatTanggalIndo(_tglJatuhTempo!, padHari: true)
        : formatTanggalIndo(_createdAt, padHari: true);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nama',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _nama,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),

          Divider(
            height: 28,
            color: AppColors.inputBorder.withValues(alpha: 0.5),
          ),

          if (_nomorHP != null && _nomorHP!.trim().isNotEmpty) ...[
            const Text(
              'No. HP',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _nomorHP!,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Divider(
              height: 28,
              color: AppColors.inputBorder.withValues(alpha: 0.5),
            ),
          ],

          const Text(
            'Keterangan',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            (_keterangan != null && _keterangan!.trim().isNotEmpty)
                ? _keterangan!
                : '-',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),

          Divider(
            height: 28,
            color: AppColors.inputBorder.withValues(alpha: 0.5),
          ),

          const Text(
            'Tanggal Jatuh Tempo',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFDCF7EC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              tglJatuhTempoStr,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Material(
            color: const Color(0xFFFFEBEB),
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: _konfirmasiHapus,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 46,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFFFC1C1),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFFF5A5A),
                  size: 22,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          Material(
            color: const Color(0xFFEBE7FF),
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: _bukaEdit,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 46,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFC7BDFF),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.edit_outlined,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          Expanded(
            child: SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _bukaDialogCicil,
                icon: const Icon(Icons.payments_outlined, size: 18),
                label: const Text(
                  'Cicil',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF5A623),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          Expanded(
            child: SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _tandaiLunas,
                icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                label: const Text(
                  'Lunas',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1DB57A),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
