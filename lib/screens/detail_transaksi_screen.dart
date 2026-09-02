import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/riwayat_item_model.dart';
import '../repositories/transaksi_repository.dart';
import '../repositories/hutang_repository.dart';
import '../repositories/piutang_repository.dart';
import '../theme/app_colors.dart';
import 'tambah_transaksi_screen.dart';
import '../utils/format.dart';
import '../providers/refresh.dart';

class DetailTransaksiScreen extends ConsumerStatefulWidget {
  final RiwayatItemModel item;

  const DetailTransaksiScreen({super.key, required this.item});

  @override
  ConsumerState<DetailTransaksiScreen> createState() =>
      _DetailTransaksiScreenState();
}

class _DetailTransaksiScreenState extends ConsumerState<DetailTransaksiScreen> {
  late RiwayatItemModel _currentItem;

  @override
  void initState() {
    super.initState();
    _currentItem = widget.item;
  }

  bool get _isPemasukan => _currentItem.tipe == TipeRiwayat.pemasukan;

  Color get _activeColor => switch (_currentItem.tipe) {
        TipeRiwayat.pemasukan => AppColors.success,
        TipeRiwayat.pengeluaran => AppColors.danger,
        TipeRiwayat.hutang => AppColors.danger,
        TipeRiwayat.piutang => AppColors.warning,
      };

  Color get _activeBgColor => switch (_currentItem.tipe) {
        TipeRiwayat.pemasukan => const Color(0xFFDCF7EC),
        TipeRiwayat.pengeluaran => const Color(0xFFFFE5E5),
        TipeRiwayat.hutang => const Color(0xFFFFE5E5),
        TipeRiwayat.piutang => const Color(0xFFFFF3DC),
      };

  String get _titleLabel => switch (_currentItem.tipe) {
        TipeRiwayat.pemasukan => 'Total Pemasukan',
        TipeRiwayat.pengeluaran => 'Total Pengeluaran',
        TipeRiwayat.hutang => 'Total Hutang',
        TipeRiwayat.piutang => 'Total Piutang',
      };



  Future<void> _konfirmasiHapus() async {
    final setuju = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Transaksi?'),
        content: const Text(
          'Transaksi ini akan dihapus secara permanen dari pembukuan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
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
      final id = _currentItem.id;
      switch (_currentItem.tipe) {
        case TipeRiwayat.pemasukan:
        case TipeRiwayat.pengeluaran:
          await ref.read(transaksiRepositoryProvider).hapus(id);
          break;
        case TipeRiwayat.hutang:
          await ref.read(hutangRepositoryProvider).hapus(id);
          break;
        case TipeRiwayat.piutang:
          await ref.read(piutangRepositoryProvider).hapus(id);
          break;
      }

      refreshDataUsaha(ref);

      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaksi berhasil dihapus'),
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

  Future<void> _editTransaksi() async {
    if (_currentItem.rawTransaksi != null) {
      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => TambahTransaksiScreen(
            transaksiToEdit: _currentItem.rawTransaksi,
          ),
        ),
      );

      if (result == true) {
        refreshDataUsaha(ref);
        if (!mounted) return;
        Navigator.of(context).pop(true);
      }
    } else if (_currentItem.rawHutang != null) {
      _showEditHutangDialog();
    } else if (_currentItem.rawPiutang != null) {
      _showEditPiutangDialog();
    }
  }

  void _showEditHutangDialog() {
    final controllerNama = TextEditingController(text: _currentItem.nama);
    final controllerNominal =
        TextEditingController(text: _currentItem.nominal.toInt().toString());
    final controllerKet =
        TextEditingController(text: _currentItem.keterangan ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Hutang'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controllerNama,
              decoration: const InputDecoration(labelText: 'Nama Toko / Pemberi'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controllerNominal,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Nominal (Rp)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controllerKet,
              decoration: const InputDecoration(labelText: 'Keterangan'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final nom = double.tryParse(controllerNominal.text) ?? 0;
              await ref.read(hutangRepositoryProvider).update(
                    id: _currentItem.id,
                    namaToko: controllerNama.text.trim(),
                    nominal: nom,
                    keterangan: controllerKet.text.trim(),
                  );
              refreshDataUsaha(ref);
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              if (!mounted) return;
              Navigator.pop(context, true);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showEditPiutangDialog() {
    final controllerNama = TextEditingController(text: _currentItem.nama);
    final controllerNominal =
        TextEditingController(text: _currentItem.nominal.toInt().toString());
    final controllerKet =
        TextEditingController(text: _currentItem.keterangan ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Piutang'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controllerNama,
              decoration: const InputDecoration(labelText: 'Nama Peminjam'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controllerNominal,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Nominal (Rp)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controllerKet,
              decoration: const InputDecoration(labelText: 'Keterangan'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final nom = double.tryParse(controllerNominal.text) ?? 0;
              await ref.read(piutangRepositoryProvider).update(
                    id: _currentItem.id,
                    namaOrang: controllerNama.text.trim(),
                    nominal: nom,
                    keterangan: controllerKet.text.trim(),
                  );
              refreshDataUsaha(ref);
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              if (!mounted) return;
              Navigator.pop(context, true);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final noteText = (_currentItem.keterangan != null &&
            _currentItem.keterangan!.isNotEmpty)
        ? _currentItem.keterangan!
        : _isPemasukan
            ? 'Pembayaran pesanan ${_currentItem.nama.toLowerCase()} telah dicatat secara otomatis via aplikasi.'
            : 'Transaksi ${_currentItem.nama.toLowerCase()} telah berhasil diverifikasi dan disimpan.';

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
                    _buildTopCard(),
                    const SizedBox(height: 20),

                    _buildDetailCard(noteText),
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
          const Expanded(
            child: Text(
              'Detail Transaksi',
              textAlign: TextAlign.center,
              style: TextStyle(
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

  Widget _buildTopCard() {
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
            decoration: BoxDecoration(
              color: _activeBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _currentItem.icon,
              size: 36,
              color: _activeColor,
            ),
          ),
          const SizedBox(height: 16),

          Text(
            _titleLabel,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),

          Text(
            formatRupiah(_currentItem.nominal),
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: _activeColor,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 12),

            Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: _activeBgColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_outline_rounded,
                  size: 15,
                  color: _activeColor,
                ),
                const SizedBox(width: 6),
                Text(
                  'Berhasil',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _activeColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(String noteText) {
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
            'Tanggal',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            formatTanggalJamIndo(_currentItem.tanggal),
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
            'Kategori',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _currentItem.nama,
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
            'Catatan AI',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F4FA),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              noteText,
              style: const TextStyle(
                fontSize: 13.5,
                color: AppColors.textPrimary,
                height: 1.45,
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
                  color: AppColors.danger,
                  size: 22,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _editTransaksi,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text(
                  'Edit Transaksi',
                  style: TextStyle(
                    fontSize: 15,
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
