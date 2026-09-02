import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/usaha_provider.dart';
import '../theme/app_colors.dart';
import 'welcome_screen.dart';
import 'tambah_transaksi_screen.dart';
import 'riwayat_tab.dart';
import 'kasbon_tab.dart';
import 'laporan_tab.dart';
import '../providers/refresh.dart';
import 'dashboard/beranda_tab.dart';
import 'dashboard/dashboard_kerangka.dart';

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
      // Tanpa ini, Scaffold menyusut saat papan ketik muncul dan tombol
      // tambah di tengah ikut terangkat ke atas keyboard. Satu-satunya kolom
      // isian di tab-tab ini adalah pencarian di Riwayat, dan posisinya di
      // atas layar, jadi aman untuk tidak ikut menyusut.
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                if (_navIndex == 0)
                  DashboardTopBar(
                    namaUsaha: usahaAsync.value?.namaUsaha ?? '...',
                    onLogout: _logout,
                  ),
                Expanded(
                  child: switch (_navIndex) {
                    0 => BerandaTab(usahaAsync: usahaAsync),
                    1 => const RiwayatTab(),
                    2 => const KasbonTab(),
                    3 => const LaporanTab(),
                    _ => DashboardPlaceholderTab(label: _navLabel(_navIndex)),
                  },
                ),
              ],
            ),
          ),

        ],
      ),
      floatingActionButton: DashboardCenterFab(
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const TambahTransaksiScreen(),
            ),
          );
          refreshDataUsaha(ref);
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: DashboardBottomNav(
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
