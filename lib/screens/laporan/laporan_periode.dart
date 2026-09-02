import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/laporan_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/format.dart';

/// Pemilih periode laporan beserta bottom sheet-nya.

class LaporanPeriodeSelector extends ConsumerWidget {
  const LaporanPeriodeSelector({super.key});

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
