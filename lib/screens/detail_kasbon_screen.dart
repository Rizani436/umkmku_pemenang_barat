import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/hutang.dart';
import '../models/piutang.dart';
import '../providers/kasbon_provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/riwayat_provider.dart';
import '../repositories/hutang_repository.dart';
import '../repositories/piutang_repository.dart';
import '../theme/app_colors.dart';

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

  String _formatRupiah(double nilai) {
    if (nilai == 0) return 'Rp 0';
    final s = nilai.toInt().toString();
    final buf = StringBuffer('Rp ');
    final off = s.length % 3;
    for (int i = 0; i < s.length; i++) {
      if (i != 0 && (i - off) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  String _formatTanggalIndo(DateTime dt) {
    const bulan = [
      '',
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember'
    ];
    final dd = dt.day.toString().padLeft(2, '0');
    return '$dd ${bulan[dt.month]} ${dt.year}';
  }

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
          const SizedBox(width: 48),
        ],
      ),
    );
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
            _formatRupiah(_nominal),
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
        ? _formatTanggalIndo(_tglJatuhTempo!)
        : _formatTanggalIndo(_createdAt);

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
                width: 54,
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
          const SizedBox(width: 12),

          Expanded(
            child: SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _tandaiLunas,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1DB57A),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Lunas',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
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
