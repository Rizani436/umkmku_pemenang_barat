import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/usaha_provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/riwayat_provider.dart';
import '../providers/kasbon_provider.dart';
import '../providers/laporan_provider.dart';
import '../repositories/hutang_repository.dart';
import '../repositories/piutang_repository.dart';
import '../theme/app_colors.dart';
import '../utils/rupiah_formatter.dart';

class TambahKasbonScreen extends ConsumerStatefulWidget {
  final int initialTab;

  const TambahKasbonScreen({super.key, this.initialTab = 0});

  @override
  ConsumerState<TambahKasbonScreen> createState() => _TambahKasbonScreenState();
}

class _TambahKasbonScreenState extends ConsumerState<TambahKasbonScreen> {
  late int _tabIndex;

  final _namaController = TextEditingController();
  final _nomorHpController = TextEditingController();
  final _nominalController = TextEditingController();
  final _keteranganController = TextEditingController();
  DateTime? _tglJatuhTempo;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tabIndex = widget.initialTab;
  }

  @override
  void dispose() {
    _namaController.dispose();
    _nomorHpController.dispose();
    _nominalController.dispose();
    _keteranganController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime dt) {
    final mm = dt.month.toString().padLeft(2, '0');
    final dd = dt.day.toString().padLeft(2, '0');
    final yyyy = dt.year.toString();
    return '$mm/$dd/$yyyy';
  }

  Future<void> _pilihTanggalJatuhTempo() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _tglJatuhTempo ?? now.add(const Duration(days: 7)),
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _tglJatuhTempo = picked);
    }
  }

  Future<void> _simpan() async {
    if (_isSaving) return;

    final nama = _namaController.text.trim();
    final rawNominal = _nominalController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final nominal = double.tryParse(rawNominal) ?? 0;

    if (nama.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _tabIndex == 0 ? 'Nama Toko wajib diisi' : 'Nama Orang wajib diisi',
          ),
        ),
      );
      return;
    }

    if (nominal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nominal wajib diisi dan harus lebih dari 0')),
      );
      return;
    }

    final usaha = ref.read(currentUsahaProvider).value;
    if (usaha == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data usaha tidak ditemukan')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      if (_tabIndex == 0) {
        await ref.read(hutangRepositoryProvider).tambah(
              idUsaha: usaha.id,
              namaToko: nama,
              nominal: nominal,
              keterangan: _keteranganController.text.trim(),
              tglJatuhTempo: _tglJatuhTempo,
            );
      } else {
        await ref.read(piutangRepositoryProvider).tambah(
              idUsaha: usaha.id,
              namaOrang: nama,
              nominal: nominal,
              nomorHP: _nomorHpController.text.trim(),
              keterangan: _keteranganController.text.trim(),
              tglJatuhTempo: _tglJatuhTempo,
            );
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
          content: Text(
            _tabIndex == 0
                ? 'Hutang "$nama" berhasil dicatat'
                : 'Piutang "$nama" berhasil dicatat',
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan kasbon: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  children: [
                    _buildTabSwitcher(),
                    const SizedBox(height: 16),
                    _buildFormCard(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            _buildSimpanButton(),
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
              'Catat Kasbon Hutang',
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

  Widget _buildTabSwitcher() {
    return Container(
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _tabIndex = 0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: _tabIndex == 0 ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Saya Ngutang',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _tabIndex == 0 ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _tabIndex = 1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: _tabIndex == 1 ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Orang Ngutang',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _tabIndex == 1 ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    final namaLabel = _tabIndex == 0 ? 'Nama Toko' : 'Nama Orang';
    final namaHint = _tabIndex == 0 ? 'Cari atau tambah baru...' : 'Nama peminjam...';

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
          Text(
            namaLabel,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _namaController,
            style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
            decoration: _inputDecoration(namaHint),
          ),
          if (_tabIndex == 1) ...[
            const SizedBox(height: 18),
            const Text(
              'Nomor HP / WhatsApp',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nomorHpController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
              decoration: _inputDecoration('Contoh: 08123456789').copyWith(
                prefixIcon: const Icon(
                  Icons.phone_android_rounded,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),

          const Text(
            'Nominal',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _nominalController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              CurrencyInputFormatter(),
            ],
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            decoration: _inputDecoration('Rp 0').copyWith(
              prefixText: _nominalController.text.startsWith('Rp') ? '' : 'Rp ',
              prefixStyle: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 18),

          const Text(
            'Keterangan / Beli Apa',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _keteranganController,
            maxLines: 3,
            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
            decoration: _inputDecoration('Opsional'),
          ),
          const SizedBox(height: 18),

          const Text(
            'Tanggal Jatuh Tempo',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: _pilihTanggalJatuhTempo,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.inputBorder),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _tglJatuhTempo != null
                        ? _formatDate(_tglJatuhTempo!)
                        : 'mm/dd/yyyy',
                    style: TextStyle(
                      fontSize: 15,
                      color: _tglJatuhTempo != null
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpanButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: _isSaving ? null : _simpan,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline_rounded, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Simpan Kasbon',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textSecondary),
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.inputBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.inputBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }
}
