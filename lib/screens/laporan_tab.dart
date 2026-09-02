import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/laporan_provider.dart';
import '../providers/usaha_provider.dart';
import '../theme/app_colors.dart';
import 'pratinjau_laporan_screen.dart';
import 'edit_aset_usaha_screen.dart';
import '../utils/format.dart';
import '../providers/refresh.dart';




enum _TabLaporan { rugiLaba, neraca }


class LaporanTab extends ConsumerStatefulWidget {
  const LaporanTab({super.key});

  @override
  ConsumerState<LaporanTab> createState() => _LaporanTabState();
}

class _LaporanTabState extends ConsumerState<LaporanTab>
    with SingleTickerProviderStateMixin {
  _TabLaporan _activeTab = _TabLaporan.rugiLaba;

  Future<void> _cetakPdf() async {
    final usaha = ref.read(currentUsahaProvider).value;
    final namaUsaha = usaha?.namaUsaha ?? 'UMKM';
    final periode = ref.read(periodeLaporanProvider);

    final isRugiLaba = _activeTab == _TabLaporan.rugiLaba;
    final dataRugiLaba = ref.read(laporanRugiLabaProvider).value;
    final dataNeraca = ref.read(laporanNeracaProvider).value;

    if (isRugiLaba && dataRugiLaba == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data Rugi Laba belum siap')),
      );
      return;
    }

    if (!isRugiLaba && dataNeraca == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data Neraca belum siap')),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PratinjauLaporanScreen(
          isRugiLaba: isRugiLaba,
          namaUsaha: namaUsaha,
          periode: periode,
          dataRugiLaba: dataRugiLaba,
          dataNeraca: dataNeraca,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Laporan Keuangan',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              IconButton(
                onPressed: _cetakPdf,
                tooltip: 'Cetak PDF',
                icon: const Icon(
                  Icons.print_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _TabSelector(
            activeTab: _activeTab,
            onChanged: (tab) => setState(() => _activeTab = tab),
          ),
        ),

        const SizedBox(height: 12),

        _PeriodeSelector(),

        const SizedBox(height: 16),

        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              refreshDataUsaha(ref);
              ref.invalidate(periodeLaporanProvider);
            },
            color: AppColors.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.05, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: _activeTab == _TabLaporan.rugiLaba
                    ? const _KontenRugiLaba(key: ValueKey('rugi'))
                    : const _KontenNeraca(key: ValueKey('neraca')),
              ),
            ),
          ),
        ),
      ],
    );
  }
}


class _TabSelector extends StatelessWidget {
  final _TabLaporan activeTab;
  final void Function(_TabLaporan) onChanged;

  const _TabSelector({required this.activeTab, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
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
      child: Row(
        children: [
          _TabButton(
            label: 'Rugi Laba',
            active: activeTab == _TabLaporan.rugiLaba,
            onTap: () => onChanged(_TabLaporan.rugiLaba),
          ),
          _TabButton(
            label: 'Neraca',
            active: activeTab == _TabLaporan.neraca,
            onTap: () => onChanged(_TabLaporan.neraca),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: active ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}


class _PeriodeSelector extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(periodeLaporanProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
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
            const Text(
              'Periode',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => _showPeriodePicker(context, ref, filter),
              child: Row(
                children: [
                  Text(
                    filter.label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPeriodePicker(
    BuildContext context,
    WidgetRef ref,
    FilterPeriodeState current,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _PeriodeBottomSheet(current: current),
    );
  }
}

class _PeriodeBottomSheet extends ConsumerStatefulWidget {
  final FilterPeriodeState current;

  const _PeriodeBottomSheet({required this.current});

  @override
  ConsumerState<_PeriodeBottomSheet> createState() => _PeriodeBottomSheetState();
}

class _PeriodeBottomSheetState extends ConsumerState<_PeriodeBottomSheet> {
  bool _isCustomMonthMode = false;
  late int _selectedMonth;
  late int _selectedYear;


  @override
  void initState() {
    super.initState();
    _selectedMonth = widget.current.month;
    _selectedYear = widget.current.year;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: AnimatedCrossFade(
        duration: const Duration(milliseconds: 250),
        crossFadeState: _isCustomMonthMode
            ? CrossFadeState.showSecond
            : CrossFadeState.showFirst,
        firstChild: _buildMainOptions(context),
        secondChild: _buildMonthYearPicker(context),
      ),
    );
  }

  Widget _buildMainOptions(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Pilih Periode Laporan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const Divider(height: 1),
        const SizedBox(height: 8),
        _itemTile(
          label: 'Bulan Ini',
          sublabel: 'Bulan berjalan saat ini',
          jenis: PeriodeLaporan.bulanIni,
          icon: Icons.calendar_today_rounded,
          onTap: () {
            ref
                .read(periodeLaporanProvider.notifier)
                .ubahJenis(PeriodeLaporan.bulanIni);
            Navigator.pop(context);
          },
        ),
        _itemTile(
          label: 'Bulan Lalu',
          sublabel: '1 bulan sebelum bulan ini',
          jenis: PeriodeLaporan.bulanLalu,
          icon: Icons.history_rounded,
          onTap: () {
            ref
                .read(periodeLaporanProvider.notifier)
                .ubahJenis(PeriodeLaporan.bulanLalu);
            Navigator.pop(context);
          },
        ),
        _itemTile(
          label: 'Pilih Bulan Spesifik',
          sublabel: widget.current.jenis == PeriodeLaporan.pilihBulan
              ? widget.current.detailLabel
              : 'Pilih bulan dan tahun tertentu',
          jenis: PeriodeLaporan.pilihBulan,
          icon: Icons.calendar_month_rounded,
          onTap: () {
            setState(() => _isCustomMonthMode = true);
          },
        ),
        _itemTile(
          label: 'Pilih Rentang Tanggal / Bulan',
          sublabel: widget.current.jenis == PeriodeLaporan.rentangTanggal
              ? widget.current.detailLabel
              : 'Pilih tanggal mulai & selesai bebas',
          jenis: PeriodeLaporan.rentangTanggal,
          icon: Icons.date_range_rounded,
          onTap: () async {
            Navigator.pop(context);
            await Future.delayed(const Duration(milliseconds: 150));
            if (!context.mounted) return;
            _showDateRangePicker(context);
          },
        ),
        _itemTile(
          label: '6 Bulan Terakhir',
          sublabel: 'Akumulasi 6 bulan ke belakang',
          jenis: PeriodeLaporan.enamBulanTerakhir,
          icon: Icons.view_week_rounded,
          onTap: () {
            ref
                .read(periodeLaporanProvider.notifier)
                .ubahJenis(PeriodeLaporan.enamBulanTerakhir);
            Navigator.pop(context);
          },
        ),
        _itemTile(
          label: 'Tahun Ini',
          sublabel: 'Akumulasi 1 tahun berjalan',
          jenis: PeriodeLaporan.tahunIni,
          icon: Icons.today_rounded,
          onTap: () {
            ref
                .read(periodeLaporanProvider.notifier)
                .ubahJenis(PeriodeLaporan.tahunIni);
            Navigator.pop(context);
          },
        ),
        _itemTile(
          label: 'Semua Periode',
          sublabel: 'Keseluruhan transaksi',
          jenis: PeriodeLaporan.semua,
          icon: Icons.all_inclusive_rounded,
          onTap: () {
            ref
                .read(periodeLaporanProvider.notifier)
                .ubahJenis(PeriodeLaporan.semua);
            Navigator.pop(context);
          },
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildMonthYearPicker(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => setState(() => _isCustomMonthMode = false),
              icon: const Icon(Icons.arrow_back_rounded,
                  color: AppColors.textPrimary),
            ),
            const Expanded(
              child: Text(
                'Pilih Bulan Spesifik',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Row(
              children: [
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.chevron_left_rounded),
                  onPressed: () => setState(() => _selectedYear--),
                ),
                Text(
                  '$_selectedYear',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.chevron_right_rounded),
                  onPressed: () => setState(() => _selectedYear++),
                ),
              ],
            ),
          ],
        ),
        const Divider(height: 1),
        const SizedBox(height: 16),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 12,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 2.3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemBuilder: (context, index) {
            final monthNum = index + 1;
            final isSelected = _selectedMonth == monthNum;

            return GestureDetector(
              onTap: () => setState(() => _selectedMonth = monthNum),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : const Color(0xFFF4F3FA),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                alignment: Alignment.center,
                child: Text(
                  namaBulanIndo[monthNum],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () {
              ref
                  .read(periodeLaporanProvider.notifier)
                  .setBulanSpesifik(_selectedMonth, _selectedYear);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Terapkan Periode',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _itemTile({
    required String label,
    required String sublabel,
    required PeriodeLaporan jenis,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final isSelected = widget.current.jenis == jenis;

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.12)
              : const Color(0xFFF4F3FA),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isSelected ? AppColors.primary : AppColors.textSecondary,
        ),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? AppColors.primary : AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        sublabel,
        style: const TextStyle(
          fontSize: 11,
          color: AppColors.textSecondary,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle_rounded,
              color: AppColors.primary, size: 22)
          : const Icon(Icons.chevron_right_rounded,
              color: AppColors.textSecondary, size: 20),
      onTap: onTap,
    );
  }

  Future<void> _showDateRangePicker(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 2),
      initialDateRange:
          widget.current.customStart != null && widget.current.customEnd != null
              ? DateTimeRange(
                  start: widget.current.customStart!,
                  end: widget.current.customEnd!)
              : DateTimeRange(
                  start: DateTime(now.year, now.month, 1),
                  end: now,
                ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      ref
          .read(periodeLaporanProvider.notifier)
          .setRentangTanggal(picked.start, picked.end);
    }
  }
}



class _KontenRugiLaba extends ConsumerWidget {
  const _KontenRugiLaba({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final laporanAsync = ref.watch(laporanRugiLabaProvider);

    return laporanAsync.when(
      loading: () => const _LoadingCard(),
      error: (e, _) => _ErrorCard(pesan: e.toString()),
      data: (laporan) => _RugiLabaCard(laporan: laporan),
    );
  }
}

class _RugiLabaCard extends StatelessWidget {
  final LaporanRugiLaba laporan;

  const _RugiLabaCard({required this.laporan});

  @override
  Widget build(BuildContext context) {
    final isProfit = laporan.penghasilanKotor >= 0;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _RowItem(
                icon: Icons.arrow_downward_rounded,
                iconBg: const Color(0xFFD6F5EB),
                iconColor: AppColors.success,
                label: 'Total Pendapatan',
                nilai: laporan.totalPendapatan,
                nilaiColor: AppColors.success,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Divider(height: 1, color: Color(0xFFEEEDF5)),
              ),
              _RowItem(
                icon: Icons.arrow_upward_rounded,
                iconBg: const Color(0xFFFFE5E5),
                iconColor: AppColors.danger,
                label: 'Total Pengeluaran',
                nilai: laporan.totalPengeluaran,
                nilaiColor: AppColors.danger,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(height: 1, color: Color(0xFFEEEDF5)),
              ),

              Align(
  alignment: Alignment.centerRight,
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      const Text(
        'PENGHASILAN KOTOR',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
          letterSpacing: 0.5,
        ),
        textAlign: TextAlign.right,
      ),
      const SizedBox(height: 6),
      Text(
        formatRupiah(laporan.penghasilanKotor),
        textAlign: TextAlign.right,
        style: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.bold,
          color: isProfit
              ? AppColors.primary
              : AppColors.danger,
          letterSpacing: -0.5,
        ),
      ),
    ],
  ),
)
            ],
          ),
        ),

        const SizedBox(height: 16),

        _InfoBanner(
          isProfit: isProfit,
          jumlah: laporan.penghasilanKotor,
        ),
      ],
    );
  }
}


class _KontenNeraca extends ConsumerWidget {
  const _KontenNeraca({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final laporanAsync = ref.watch(laporanNeracaProvider);

    return laporanAsync.when(
      loading: () => const _LoadingCard(),
      error: (e, _) => _ErrorCard(pesan: e.toString()),
      data: (laporan) => _NeracaCard(laporan: laporan),
    );
  }
}

class _NeracaCard extends ConsumerWidget {
  final LaporanNeraca laporan;

  const _NeracaCard({required this.laporan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        _SeksiNeraca(
          headerIcon: Icons.account_balance_wallet_outlined,
          headerIconBg: const Color(0xFFE8E6FF),
          headerIconColor: AppColors.primary,
          headerLabel: 'HARTA (Aktiva)',
          action: GestureDetector(
            onTap: () {
              final usaha = ref.read(currentUsahaProvider).value;
              if (usaha != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditAsetUsahaScreen(
                      idUsaha: usaha.id,
                      currentPersediaan: laporan.persediaan,
                      currentMesinPeralatan: laporan.mesinPeralatan,
                      currentGedung: laporan.gedung,
                    ),
                  ),
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit_note_rounded, size: 14, color: AppColors.primary),
                  SizedBox(width: 4),
                  Text(
                    'Edit Aset',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          rows: [
            _NeracaRow(label: 'Kas', nilai: laporan.kas),
            _NeracaRow(label: 'Persediaan', nilai: laporan.persediaan),
            _NeracaRow(label: 'Piutang', nilai: laporan.piutang),
            _NeracaRow(label: 'Mesin & Peralatan', nilai: laporan.mesinPeralatan),
            _NeracaRow(label: 'Gedung', nilai: laporan.gedung),
          ],
          totalLabel: 'Total Harta',
          totalNilai: laporan.totalHarta,
          totalColor: AppColors.primary,
        ),

        const SizedBox(height: 14),

        _SeksiNeraca(
          headerIcon: Icons.savings_outlined,
          headerIconBg: const Color(0xFFFFF3DC),
          headerIconColor: AppColors.warning,
          headerLabel: 'SUMBER DANA (Pasiva)',
          rows: [
            _NeracaRow(label: 'Hutang', nilai: laporan.hutang),
            _NeracaRow(label: 'Modal', nilai: laporan.modal),
            _NeracaRow(
              label: 'Penghasilan Kotor',
              nilai: laporan.penghasilanKotor,
            ),
          ],
          totalLabel: 'Total Dana',
          totalNilai: laporan.totalDana,
          totalColor: AppColors.warning,
        ),

        const SizedBox(height: 14),

        _NeracaStatusBanner(seimbang: laporan.seimbang),
      ],
    );
  }
}


class _SeksiNeraca extends StatelessWidget {
  final IconData headerIcon;
  final Color headerIconBg;
  final Color headerIconColor;
  final String headerLabel;
  final Widget? action;
  final List<_NeracaRow> rows;
  final String totalLabel;
  final double totalNilai;
  final Color totalColor;

  const _SeksiNeraca({
    required this.headerIcon,
    required this.headerIconBg,
    required this.headerIconColor,
    required this.headerLabel,
    this.action,
    required this.rows,
    required this.totalLabel,
    required this.totalNilai,
    required this.totalColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: headerIconBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(headerIcon, color: headerIconColor, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    headerLabel,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              ?action,
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFEEEDF5)),
          const SizedBox(height: 12),

          ...rows.map((row) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Text(
                      row.label,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      formatRupiah(row.nilai),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )),

          const Divider(height: 1, color: Color(0xFFEEEDF5)),
          const SizedBox(height: 12),

          Row(
            children: [
              Text(
                totalLabel,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                formatRupiah(totalNilai),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: totalColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


class _NeracaRow {
  final String label;
  final double nilai;
  const _NeracaRow({required this.label, required this.nilai});
}


class _NeracaStatusBanner extends StatelessWidget {
  final bool seimbang;
  const _NeracaStatusBanner({required this.seimbang});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: seimbang
            ? const Color(0xFFE6F9F0)
            : const Color(0xFFFFECEC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: seimbang
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.danger.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: seimbang
                  ? AppColors.success
                  : AppColors.danger,
              shape: BoxShape.circle,
            ),
            child: Icon(
              seimbang
                  ? Icons.check_rounded
                  : Icons.close_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            seimbang ? 'Neraca Seimbang' : 'Neraca Tidak Seimbang',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: seimbang
                  ? AppColors.success
                  : AppColors.danger,
            ),
          ),
        ],
      ),
    );
  }
}




class _RowItem extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final double nilai;
  final Color nilaiColor;

  const _RowItem({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.nilai,
    required this.nilaiColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Text(
          formatRupiah(nilai),
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: nilaiColor,
          ),
        ),
      ],
    );
  }
}


class _InfoBanner extends StatelessWidget {
  final bool isProfit;
  final double jumlah;

  const _InfoBanner({required this.isProfit, required this.jumlah});

  @override
  Widget build(BuildContext context) {
    final bg = isProfit
        ? const Color(0xFFD6F5EB)
        : const Color(0xFFFFE5E5);
    final iconColor = isProfit
        ? AppColors.success
        : AppColors.danger;
    final icon = isProfit
        ? Icons.trending_up_rounded
        : Icons.trending_down_rounded;
    final text = isProfit
        ? 'Usaha Anda sedang untung pada periode ini.'
        : 'Pengeluaran melebihi pendapatan pada periode ini.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: iconColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String pesan;

  const _ErrorCard({required this.pesan});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE5E5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.danger, size: 36),
          const SizedBox(height: 8),
          Text(
            'Gagal memuat laporan:\n$pesan',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.danger,
            ),
          ),
        ],
      ),
    );
  }
}
