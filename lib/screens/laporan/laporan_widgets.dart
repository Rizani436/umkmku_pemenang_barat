import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../utils/format.dart';

/// Pemilih tab dan widget kecil yang dipakai bersama oleh isi laporan
/// rugi-laba maupun neraca.

enum TabLaporan { rugiLaba, neraca }

class LaporanTabSelector extends StatelessWidget {
  final TabLaporan activeTab;
  final void Function(TabLaporan) onChanged;

  const LaporanTabSelector({
    super.key,
    required this.activeTab,
    required this.onChanged,
  });

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
            active: activeTab == TabLaporan.rugiLaba,
            onTap: () => onChanged(TabLaporan.rugiLaba),
          ),
          _TabButton(
            label: 'Neraca',
            active: activeTab == TabLaporan.neraca,
            onTap: () => onChanged(TabLaporan.neraca),
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

class LaporanRowItem extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final double nilai;
  final Color nilaiColor;

  const LaporanRowItem({
    super.key,
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


class LaporanInfoBanner extends StatelessWidget {
  final bool isProfit;
  final double jumlah;

  const LaporanInfoBanner({
    super.key,
    required this.isProfit,
    required this.jumlah,
  });

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


class LaporanLoadingCard extends StatelessWidget {
  const LaporanLoadingCard({super.key});

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

class LaporanErrorCard extends StatelessWidget {
  final String pesan;

  const LaporanErrorCard({super.key, required this.pesan});

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
