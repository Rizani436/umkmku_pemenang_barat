import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/laporan_provider.dart';
import '../../providers/usaha_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/format.dart';
import '../edit_aset_usaha_screen.dart';
import 'laporan_widgets.dart';

/// Isi tab Rugi-Laba dan Neraca.

class KontenRugiLaba extends ConsumerWidget {
  const KontenRugiLaba({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final laporanAsync = ref.watch(laporanRugiLabaProvider);

    return laporanAsync.when(
      loading: () => const LaporanLoadingCard(),
      error: (e, _) => LaporanErrorCard(pesan: e.toString()),
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
              LaporanRowItem(
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
              LaporanRowItem(
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

        LaporanInfoBanner(
          isProfit: isProfit,
          jumlah: laporan.penghasilanKotor,
        ),
      ],
    );
  }
}


class KontenNeraca extends ConsumerWidget {
  const KontenNeraca({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final laporanAsync = ref.watch(laporanNeracaProvider);

    return laporanAsync.when(
      loading: () => const LaporanLoadingCard(),
      error: (e, _) => LaporanErrorCard(pesan: e.toString()),
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
