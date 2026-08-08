import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/kategori_transaksi.dart';
import '../providers/usaha_provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/laporan_provider.dart';
import '../repositories/transaksi_repository.dart';
import '../theme/app_colors.dart';
import 'transaksi_sukses_screen.dart';

import '../models/transaksi.dart';
import '../providers/riwayat_provider.dart';

const _colorMasuk = Color(0xFF1DB57A);
const _colorKeluar = Color(0xFFFF5A5A);

class TambahTransaksiScreen extends ConsumerStatefulWidget {
  final Transaksi? transaksiToEdit;

  const TambahTransaksiScreen({super.key, this.transaksiToEdit});

  @override
  ConsumerState<TambahTransaksiScreen> createState() =>
      _TambahTransaksiScreenState();
}

class _TambahTransaksiScreenState
    extends ConsumerState<TambahTransaksiScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _tabIndex = 0;

  int _masukSelected = 0;
  int _keluarSelected = 0;

  String _angka = '';
  int get _nilai => _angka.isEmpty ? 0 : int.tryParse(_angka) ?? 0;

  bool _isSaving = false;
  bool _isCategoryPreselected = false;

  @override
  void initState() {
    super.initState();
    final edit = widget.transaksiToEdit;
    if (edit != null) {
      _tabIndex = edit.jenisTransaksi == 'pemasukan' ? 0 : 1;
      _angka = edit.total.toInt().toString();
    }
    _tabController = TabController(length: 2, vsync: this, initialIndex: _tabIndex)
      ..addListener(() {
        if (!_tabController.indexIsChanging) return;
        setState(() => _tabIndex = _tabController.index);
      });
  }

  void _preselectCategoryIfNeeded(SektorUsaha sektor) {
    if (_isCategoryPreselected || widget.transaksiToEdit == null) return;
    _isCategoryPreselected = true;

    final edit = widget.transaksiToEdit!;
    if (edit.jenisTransaksi == 'pemasukan') {
      final kategoris = KategoriTransaksi.masuk(sektor);
      final idx = kategoris.indexWhere(
        (k) => k.label.toLowerCase() == edit.kategori.toLowerCase(),
      );
      if (idx != -1) _masukSelected = idx;
    } else {
      final kategoris = KategoriTransaksi.keluar(sektor);
      final idx = kategoris.indexWhere(
        (k) => k.label.toLowerCase() == edit.kategori.toLowerCase(),
      );
      if (idx != -1) _keluarSelected = idx;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatRupiah(int nilai) {
    if (nilai == 0) return 'Rp 0';
    final s = nilai.toString();
    final buf = StringBuffer('Rp ');
    final off = s.length % 3;
    for (int i = 0; i < s.length; i++) {
      if (i != 0 && (i - off) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  void _onDigit(String d) {
    if (_angka.length >= 13) return;
    if (_angka.isEmpty && d == '0') return;
    setState(() => _angka += d);
    HapticFeedback.lightImpact();
  }

  void _onRibu() {
    if (_angka.isEmpty) return;
    if (_angka.length + 3 > 13) return;
    setState(() => _angka += '000');
    HapticFeedback.lightImpact();
  }

  void _onBackspace() {
    if (_angka.isEmpty) return;
    setState(() => _angka = _angka.substring(0, _angka.length - 1));
  }

  Future<void> _simpan() async {
    if (_isSaving) return;
    if (_nilai == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan jumlah transaksi terlebih dahulu')),
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

    final sektor = sektorFromString(usaha.jenisUsaha);
    final kategoris = _tabIndex == 0
        ? KategoriTransaksi.masuk(sektor)
        : KategoriTransaksi.keluar(sektor);
    final selected = _tabIndex == 0 ? _masukSelected : _keluarSelected;
    final kategori = kategoris[selected].label;

    setState(() => _isSaving = true);
    try {
      if (widget.transaksiToEdit != null) {
        await ref.read(transaksiRepositoryProvider).update(
              id: widget.transaksiToEdit!.id,
              jenisTransaksi: _tabIndex == 0 ? 'pemasukan' : 'pengeluaran',
              kategori: kategori,
              total: _nilai.toDouble(),
            );
        ref.invalidate(dashboardSummaryProvider);
        ref.invalidate(riwayatProvider);
        ref.invalidate(laporanNeracaProvider);
        if (!mounted) return;
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaksi berhasil diperbarui'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        await ref.read(transaksiRepositoryProvider).tambah(
              idUsaha: usaha.id,
              jenisTransaksi: _tabIndex == 0 ? 'pemasukan' : 'pengeluaran',
              kategori: kategori,
              total: _nilai.toDouble(),
            );

        ref.invalidate(dashboardSummaryProvider);
        ref.invalidate(laporanNeracaProvider);

        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => TransaksiSuksesScreen(
              jenisTransaksi: _tabIndex == 0 ? 'pemasukan' : 'pengeluaran',
              kategori: kategori,
              total: _nilai.toDouble(),
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final usahaAsync = ref.watch(currentUsahaProvider);
    final sektor = sektorFromString(
      usahaAsync.value?.jenisUsaha ?? 'Perdagangan',
    );
    _preselectCategoryIfNeeded(sektor);

    final kategoris = _tabIndex == 0
        ? KategoriTransaksi.masuk(sektor)
        : KategoriTransaksi.keluar(sektor);
    final selectedIndex = _tabIndex == 0 ? _masukSelected : _keluarSelected;
    final activeColor = _tabIndex == 0 ? _colorMasuk : _colorKeluar;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    _buildTabSwitcher(),
                    const SizedBox(height: 14),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'Pilih Kategori',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    _buildKategoriGrid(
                      kategoris: kategoris,
                      selected: selectedIndex,
                      activeColor: activeColor,
                    ),
                    const SizedBox(height: 10),

                    _buildTotalCard(activeColor),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            _buildKeypad(),

            _buildSimpanButton(activeColor),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    final title = widget.transaksiToEdit != null
        ? 'Edit Transaksi'
        : 'Tambah Transaksi';
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            color: AppColors.textPrimary,
          ),
          Expanded(
            child: Text(
              title,
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

  Widget _buildTabSwitcher() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: TabBar(
          controller: _tabController,
          dividerColor: Colors.transparent,
          indicator: BoxDecoration(
            color: _tabIndex == 0
                ? _colorMasuk.withValues(alpha: 0.13)
                : _colorKeluar.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          labelPadding: EdgeInsets.zero,
          tabs: [
            _buildTab('UANG MASUK', _tabIndex == 0, _colorMasuk),
            _buildTab('UANG KELUAR', _tabIndex == 1, _colorKeluar),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String label, bool active, Color color) {
    return Tab(
      child: AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 200),
        style: TextStyle(
          fontSize: 13,
          fontWeight: active ? FontWeight.bold : FontWeight.w500,
          color: active ? color : AppColors.textSecondary,
          letterSpacing: 0.5,
        ),
        child: Text(label),
      ),
    );
  }

  Widget _buildKategoriGrid({
    required List<KategoriItem> kategoris,
    required int selected,
    required Color activeColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1.15,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: kategoris.length,
        itemBuilder: (context, index) {
          final item = kategoris[index];
          final isSelected = selected == index;
          return _KategoriTile(
            item: item,
            isSelected: isSelected,
            activeColor: activeColor,
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                if (_tabIndex == 0) {
                  _masukSelected = index;
                } else {
                  _keluarSelected = index;
                }
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildTotalCard(Color activeColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: activeColor.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            const Text(
              'Total Transaksi',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              transitionBuilder: (child, anim) =>
                  FadeTransition(opacity: anim, child: child),
              child: Text(
                _formatRupiah(_nilai),
                key: ValueKey(_nilai),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: activeColor,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          for (final row in [
            ['1', '2', '3'],
            ['4', '5', '6'],
            ['7', '8', '9'],
          ])
            SizedBox(
              height: 54,
              child: Row(
                children: row
                    .map(
                      (d) => _KeypadBtn(
                        label: d,
                        onTap: () => _onDigit(d),
                      ),
                    )
                    .toList(),
              ),
            ),
          SizedBox(
            height: 54,
            child: Row(
              children: [
                _KeypadBtn(
                  label: '000',
                  labelStyle: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  onTap: _onRibu,
                ),
                _KeypadBtn(
                  label: '0',
                  onTap: () => _onDigit('0'),
                ),
                _KeypadBtn(
                  icon: Icons.backspace_outlined,
                  onTap: _onBackspace,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpanButton(Color activeColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: _isSaving ? null : _simpan,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
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
                      'Simpan Transaksi',
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
}

class _KategoriTile extends StatelessWidget {
  final KategoriItem item;
  final bool isSelected;
  final Color activeColor;
  final VoidCallback onTap;

  const _KategoriTile({
    required this.item,
    required this.isSelected,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.09)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? activeColor : Colors.transparent,
            width: 1.8,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? activeColor.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: isSelected ? 12 : 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: isSelected
                    ? activeColor.withValues(alpha: 0.15)
                    : AppColors.background,
                shape: BoxShape.circle,
              ),
              child: Icon(
                item.icon,
                size: 18,
                color: isSelected ? activeColor : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              item.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                height: 1.3,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? activeColor : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KeypadBtn extends StatelessWidget {
  final String? label;
  final TextStyle? labelStyle;
  final IconData? icon;
  final VoidCallback onTap;

  const _KeypadBtn({
    this.label,
    this.labelStyle,
    this.icon,
    required this.onTap,
  }) : assert(label != null || icon != null);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            splashColor: AppColors.primary.withValues(alpha: 0.08),
            highlightColor: AppColors.primary.withValues(alpha: 0.04),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: icon != null
                    ? Icon(icon, size: 20, color: AppColors.textPrimary)
                    : Text(
                        label!,
                        style: labelStyle ??
                            const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
