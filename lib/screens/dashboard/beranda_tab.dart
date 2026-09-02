import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/usaha.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/usaha_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/format.dart';
import '../samakan_uang_laci_screen.dart';

/// Isi tab Beranda: ringkasan keuangan, saldo kas, dan jatuh tempo.

class BerandaTab extends ConsumerWidget {
  final AsyncValue<Usaha?> usahaAsync;

  const BerandaTab({super.key, required this.usahaAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    final summary = summaryAsync.value ?? DashboardSummary.kosong;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          _FinanceCard(
            summary: summary,
            isLoading: summaryAsync.isLoading,
          ),
          const SizedBox(height: 12),

          _SaldoKasCard(
            nilai: summary.saldoKas,
            isLoading: summaryAsync.isLoading,
          ),
          const SizedBox(height: 12),


          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  label: 'Uang Masuk',
                  nilai: summary.uangMasukHariIni,
                  iconBg: const Color(0xFFD6F5EB),
                  iconColor: AppColors.success,
                  iconData: Icons.arrow_downward_rounded,
                  nilaiColor: AppColors.success,
                  isLoading: summaryAsync.isLoading,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryCard(
                  label: 'Uang Keluar',
                  nilai: summary.uangKeluarHariIni,
                  iconBg: const Color(0xFFFFE5E5),
                  iconColor: AppColors.danger,
                  iconData: Icons.arrow_upward_rounded,
                  nilaiColor: AppColors.danger,
                  isLoading: summaryAsync.isLoading,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),


          Row(
            children: [
              Expanded(
                child: _TotalCard(
                  label: 'Total Piutang',
                  nilai: summary.totalPiutang,
                  nilaiColor: AppColors.warning,
                  isLoading: summaryAsync.isLoading,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TotalCard(
                  label: 'Total Hutang',
                  nilai: summary.totalHutang,
                  nilaiColor: AppColors.textPrimary,
                  isLoading: summaryAsync.isLoading,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),


          const Text(
            'Jatuh Tempo Terdekat',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          if (summaryAsync.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: CircularProgressIndicator(),
              ),
            )
          else if (summary.jatuhTempoTerdekat.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Belum ada hutang/piutang jatuh tempo',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            )
          else
            ...summary.jatuhTempoTerdekat.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _JatuhTempoCard(item: item),
              ),
            ),
        ],
      ),
    );
  }
}



class _FinanceCard extends ConsumerWidget {
  final DashboardSummary summary;
  final bool isLoading;

  const _FinanceCard({required this.summary, this.isLoading = false});

  bool _isToday(DateTime dt) {
    final now = DateTime.now();
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(dashboardDateProvider);
    final isToday = _isToday(selectedDate);
    final keuntungan = summary.keuntunganHariIni;
    final trend = summary.trend;

    final (IconData trendIcon, Color trendColor, String trendText) = switch (trend) {
      TrendKeuntungan.naik => (
          Icons.trending_up_rounded,
          const Color(0xFF4EFFA0),
          isToday
              ? 'Keuntungan lebih tinggi dari kemarin'
              : 'Keuntungan lebih tinggi dari hari sebelumnya',
        ),
      TrendKeuntungan.turun => (
          Icons.trending_down_rounded,
          const Color(0xFFFFB3B3),
          isToday
              ? 'Keuntungan lebih rendah dari kemarin'
              : 'Keuntungan lebih rendah dari hari sebelumnya',
        ),
      TrendKeuntungan.netral => (
          Icons.trending_flat_rounded,
          const Color(0xFFFFE08A),
          'Sama seperti hari sebelumnya',
        ),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, Color(0xFF7B6FF0), Color(0xFF6B5FE8)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Label dan chip tanggal sama-sama melebar saat tanggal selain
              // hari ini dipilih ("Keuntungan Tanggal Ini" + tanggal penuh),
              // dan di layar sempit jumlahnya melewati lebar kartu. Expanded
              // memberi label sisa ruang yang ada, chip tetap seukuran isinya.
              Expanded(
                child: Text(
                  keuntungan < 0
                      ? (isToday
                          ? 'Defisit / Rugi Hari Ini'
                          : 'Defisit / Rugi Tanggal Ini')
                      : (isToday
                          ? 'Keuntungan Hari Ini'
                          : 'Keuntungan Tanggal Ini'),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
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
                    ref.read(dashboardDateProvider.notifier).setTanggal(picked);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        color: Colors.white,
                        size: 12,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        formatTanggalIndo(selectedDate),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Colors.white70,
                        size: 14,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: isLoading
                    ? const SizedBox(
                        height: 44,
                        width: 140,
                        child: LinearProgressIndicator(
                          color: Colors.white54,
                          backgroundColor: Colors.white24,
                          borderRadius: BorderRadius.all(Radius.circular(4)),
                        ),
                      )
                    : Text(
                        formatRupiah(keuntungan),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
              ),
              if (!isToday) const SizedBox(width: 8),
              if (!isToday)
                GestureDetector(
                  onTap: () {
                    ref.read(dashboardDateProvider.notifier).resetToday();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text(
                      'Kembali ke Hari Ini',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(trendIcon, color: trendColor, size: 14),
                const SizedBox(width: 6),
                // Kalimat tren bisa sepanjang "Keuntungan lebih rendah dari
                // hari sebelumnya" dan tidak muat di layar sempit. Flexible
                // membiarkannya turun ke baris berikutnya, bukan meluber.
                Flexible(
                  child: Text(
                    trendText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SaldoKasCard extends ConsumerWidget {
  final double nilai;
  final bool isLoading;

  const _SaldoKasCard({
    required this.nilai,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usaha = ref.watch(currentUsahaProvider).value;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFFEBE7FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Saldo Kas Tunai (Laci)',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 100,
                        child: LinearProgressIndicator(
                            borderRadius:
                                BorderRadius.all(Radius.circular(4))),
                      )
                    : Text(
                        formatRupiah(nilai),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: nilai < 0
                              ? const Color(0xFFE53935)
                              : const Color(0xFF212936),
                        ),
                      ),
                if (!isLoading && nilai < 0)
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Text(
                      'Saldo minus — periksa kembali catatan Anda',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFFE53935),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (usaha != null)
            Material(
              color: const Color(0xFFF3F0FF),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SamakanUangLaciScreen(
                        idUsaha: usaha.id,
                        currentKas: nilai,
                      ),
                    ),
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  child: Text(
                    'Samakan Laci',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
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



class _SummaryCard extends StatelessWidget {
  final String label;
  final double nilai;
  final Color iconBg;
  final Color iconColor;
  final IconData iconData;
  final Color nilaiColor;
  final bool isLoading;

  const _SummaryCard({
    required this.label,
    required this.nilai,
    required this.iconBg,
    required this.iconColor,
    required this.iconData,
    required this.nilaiColor,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(iconData, color: iconColor, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          isLoading
              ? const SizedBox(
                  height: 16,
                  width: 60,
                  child: LinearProgressIndicator(borderRadius: BorderRadius.all(Radius.circular(4))),
                )
              : Text(
                  formatRupiah(nilai),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: nilaiColor,
                  ),
                ),
        ],
      ),
    );
  }
}



class _TotalCard extends StatelessWidget {
  final String label;
  final double nilai;
  final Color nilaiColor;
  final bool isLoading;

  const _TotalCard({
    required this.label,
    required this.nilai,
    required this.nilaiColor,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          isLoading
              ? const SizedBox(
                  height: 16,
                  width: 80,
                  child: LinearProgressIndicator(borderRadius: BorderRadius.all(Radius.circular(4))),
                )
              : Text(
                  formatRupiah(nilai),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: nilaiColor,
                  ),
                ),
        ],
      ),
    );
  }
}



class _JatuhTempoCard extends StatelessWidget {
  final JatuhTempoItem item;

  const _JatuhTempoCard({required this.item});


  Color get _warnaBorder {
    if (item.jenis == JatuhTempoJenis.hutang) return AppColors.danger;
    return AppColors.warning;
  }

  Color get _warnaBadgeBg {
    final diff = item.selisihHari;
    if (diff < 0) return const Color(0xFFFFDDDD);
    if (diff <= 1) return const Color(0xFFFFEBEB);
    if (diff <= 2) return const Color(0xFFFFF4DE);
    return const Color(0xFFE8F5FF);
  }

  Color get _warnaBadgeText {
    final diff = item.selisihHari;
    if (diff < 0) return const Color(0xFFCC2222);
    if (diff <= 1) return AppColors.danger;
    if (diff <= 2) return const Color(0xFFBB7A00);
    return const Color(0xFF1A6FA0);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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

          Container(
            width: 4,
            height: 64,
            decoration: BoxDecoration(
              color: _warnaBorder,
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(14),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(  
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.nama,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatRupiah(item.nominal),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: _warnaBorder,
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            margin: const EdgeInsets.only(right: 14),
            decoration: BoxDecoration(
              color: _warnaBadgeBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              item.labelJatuhTempo,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _warnaBadgeText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
