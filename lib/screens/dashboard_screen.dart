import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/usaha.dart';
import '../providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/usaha_provider.dart';
import '../theme/app_colors.dart';
import 'welcome_screen.dart';
import 'tambah_transaksi_screen.dart';
import 'riwayat_tab.dart';
import 'kasbon_tab.dart';
import 'laporan_tab.dart';
import 'notifikasi_screen.dart';
import 'profil_usaha_screen.dart';
import 'samakan_uang_laci_screen.dart';
import '../providers/riwayat_provider.dart';
import '../providers/kasbon_provider.dart';

String _rupiah(double nilai, {bool spasi = false}) {
  if (nilai == 0) return 'Rp${spasi ? ' ' : ''}0';
  final isNegative = nilai < 0;
  final s = nilai.toInt().abs().toString();
  final buffer = StringBuffer('${isNegative ? '- ' : ''}Rp${spasi ? ' ' : ''}');
  final offset = s.length % 3;
  for (int i = 0; i < s.length; i++) {
    if (i != 0 && (i - offset) % 3 == 0) buffer.write('.');
    buffer.write(s[i]);
  }
  return buffer.toString();
}

String _tanggalIndo(DateTime dt) {
  const bln = [
    '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];
  return '${dt.day} ${bln[dt.month]} ${dt.year}';
}





class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _navIndex = 0;

  Future<void> _logout() async {
    await ref.read(authControllerProvider.notifier).keluar();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final usahaAsync = ref.watch(currentUsahaProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                if (_navIndex == 0)
                  _TopBar(
                    namaUsaha: usahaAsync.value?.namaUsaha ?? '...',
                    onLogout: _logout,
                  ),
                Expanded(
                  child: switch (_navIndex) {
                    0 => _BerandaTab(usahaAsync: usahaAsync),
                    1 => const RiwayatTab(),
                    2 => const KasbonTab(),
                    3 => const LaporanTab(),
                    _ => _PlaceholderTab(label: _navLabel(_navIndex)),
                  },
                ),
              ],
            ),
          ),

        ],
      ),
      floatingActionButton: _CenterFab(
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const TambahTransaksiScreen(),
            ),
          );
          ref.invalidate(riwayatProvider);
          ref.invalidate(hutangListProvider);
          ref.invalidate(piutangListProvider);
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _BottomNav(
        currentIndex: _navIndex,
        onTap: (i) => setState(() => _navIndex = i),
      ),
    );
  }

  String _navLabel(int i) {
    const labels = ['Beranda', 'Riwayat', 'Kasbon', 'Laporan'];
    return labels[i];
  }
}



class _BerandaTab extends ConsumerWidget {
  final AsyncValue<Usaha?> usahaAsync;

  const _BerandaTab({required this.usahaAsync});

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
                  iconColor: const Color(0xFF1DB57A),
                  iconData: Icons.arrow_downward_rounded,
                  nilaiColor: const Color(0xFF1DB57A),
                  isLoading: summaryAsync.isLoading,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryCard(
                  label: 'Uang Keluar',
                  nilai: summary.uangKeluarHariIni,
                  iconBg: const Color(0xFFFFE5E5),
                  iconColor: const Color(0xFFFF5A5A),
                  iconData: Icons.arrow_upward_rounded,
                  nilaiColor: const Color(0xFFFF5A5A),
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
                  nilaiColor: const Color(0xFFF5A623),
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
          colors: [Color(0xFF5B4FDD), Color(0xFF7B6FF0), Color(0xFF6B5FE8)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5B4FDD).withValues(alpha: 0.35),
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
              Text(
                keuntungan < 0
                    ? (isToday
                        ? 'Defisit / Rugi Hari Ini'
                        : 'Defisit / Rugi Tanggal Ini')
                    : (isToday
                        ? 'Keuntungan Hari Ini'
                        : 'Keuntungan Tanggal Ini'),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
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
                        _tanggalIndo(selectedDate),
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
                        _rupiah(keuntungan),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
              ),
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
                Text(
                  trendText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
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
              color: Color(0xFF5B4FDD),
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
                        _rupiah(nilai, spasi: true),
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
                      color: Color(0xFF5B4FDD),
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
                  _rupiah(nilai),
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
                  _rupiah(nilai),
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
    if (item.jenis == JatuhTempoJenis.hutang) return const Color(0xFFFF5A5A);
    return const Color(0xFFF5A623);
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
    if (diff <= 1) return const Color(0xFFFF5A5A);
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
                  _rupiah(item.nominal, spasi: true),
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



class _TopBar extends StatelessWidget {
  final String namaUsaha;
  final VoidCallback onLogout;

  const _TopBar({required this.namaUsaha, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Padding(
  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
  child: SizedBox(
    height: 40,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfilUsahaScreen()),
                );
              },
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
            ),

            const Spacer(),

            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const NotifikasiScreen(),
                  ),
                );
              },
              child: Stack(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.notifications_outlined,
                      color: AppColors.textPrimary,
                      size: 20,
                    ),
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 60),
          child: Text(
            namaUsaha,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    ),
  ),
);
  }
}



class _CenterFab extends StatelessWidget {
  final VoidCallback onTap;

  const _CenterFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0x445B4FDD),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
      ),
    );
  }
}








class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onTap;

  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: AppColors.surface,
      elevation: 8,
      notchMargin: 6,
      shape: const CircularNotchedRectangle(),
      child: SizedBox(
        height: 56,
        child: Row(
          children: [
            _NavItem(
              icon: Icons.home_rounded,
              label: 'Beranda',
              active: currentIndex == 0,
              onTap: () => onTap(0),
            ),
            _NavItem(
              icon: Icons.history_rounded,
              label: 'Riwayat',
              active: currentIndex == 1,
              onTap: () => onTap(1),
            ),

            const Expanded(child: SizedBox()),
            _NavItem(
              icon: Icons.receipt_long_rounded,
              label: 'Kasbon',
              active: currentIndex == 2,
              onTap: () => onTap(2),
            ),
            _NavItem(
              icon: Icons.bar_chart_rounded,
              label: 'Laporan',
              active: currentIndex == 3,
              onTap: () => onTap(3),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: active
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 22,
                color: active ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                color: active ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}



class _PlaceholderTab extends StatelessWidget {
  final String label;

  const _PlaceholderTab({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '$label — coming soon',
        style: const TextStyle(
          fontSize: 16,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
