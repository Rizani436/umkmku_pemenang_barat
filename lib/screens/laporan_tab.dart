import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/laporan_provider.dart';
import '../providers/usaha_provider.dart';
import '../theme/app_colors.dart';
import 'pratinjau_laporan_screen.dart';
import '../providers/refresh.dart';
import 'laporan/laporan_konten.dart';
import 'laporan/laporan_periode.dart';
import 'laporan/laporan_widgets.dart';

class LaporanTab extends ConsumerStatefulWidget {
  const LaporanTab({super.key});

  @override
  ConsumerState<LaporanTab> createState() => _LaporanTabState();
}

class _LaporanTabState extends ConsumerState<LaporanTab>
    with SingleTickerProviderStateMixin {
  TabLaporan _activeTab = TabLaporan.rugiLaba;

  Future<void> _cetakPdf() async {
    final usaha = ref.read(currentUsahaProvider).value;
    final namaUsaha = usaha?.namaUsaha ?? 'UMKM';
    final periode = ref.read(periodeLaporanProvider);

    final isRugiLaba = _activeTab == TabLaporan.rugiLaba;
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
          child: LaporanTabSelector(
            activeTab: _activeTab,
            onChanged: (tab) => setState(() => _activeTab = tab),
          ),
        ),

        const SizedBox(height: 12),

        LaporanPeriodeSelector(),

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
                child: _activeTab == TabLaporan.rugiLaba
                    ? const KontenRugiLaba(key: ValueKey('rugi'))
                    : const KontenNeraca(key: ValueKey('neraca')),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
