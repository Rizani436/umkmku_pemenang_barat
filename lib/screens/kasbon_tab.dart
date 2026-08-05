import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/hutang.dart';
import '../models/piutang.dart';
import '../providers/kasbon_provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/riwayat_provider.dart';
import '../theme/app_colors.dart';

import 'tambah_kasbon_screen.dart';
import 'detail_kasbon_screen.dart';
import 'kirim_tagihan_screen.dart';

const _colorHutang = Color(0xFFFF5A5A);
const _colorPiutang = Color(0xFFF5A623);

class KasbonTab extends ConsumerStatefulWidget {
  const KasbonTab({super.key});

  @override
  ConsumerState<KasbonTab> createState() => _KasbonTabState();
}

class _KasbonTabState extends ConsumerState<KasbonTab> {
  int _tabIndex = 0;

  String _formatRupiah(double nilai) {
    if (nilai == 0) return 'Rp 0';
    final s = nilai.toInt().toString();
    final buf = StringBuffer('Rp ');
    final off = s.length % 3;
    for (int i = 0; i < s.length; i++) {
      if (i != 0 && (i - off) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  void _openTambahKasbon(int initialTab) async {
    final res = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => TambahKasbonScreen(initialTab: initialTab),
      ),
    );
    if (res == true) {
      ref.invalidate(hutangListProvider);
      ref.invalidate(piutangListProvider);
      ref.invalidate(dashboardSummaryProvider);
      ref.invalidate(riwayatProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hutangAsync = ref.watch(hutangListProvider);
    final piutangAsync = ref.watch(piutangListProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Buku Kasbon',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                _buildTabSwitcher(),
                const SizedBox(height: 16),
                if (_tabIndex == 0)
                  _buildTotalCard(
                    title: 'Total Hutang',
                    amount: _hitungTotalHutang(hutangAsync.value ?? []),
                    color: _colorHutang,
                    isLoading: hutangAsync.isLoading,
                  )
                else
                  _buildTotalCard(
                    title: 'Total Piutang',
                    amount: _hitungTotalPiutang(piutangAsync.value ?? []),
                    color: _colorPiutang,
                    isLoading: piutangAsync.isLoading,
                  ),
                const SizedBox(height: 16),
                if (_tabIndex == 0)
                  _buildHutangList(hutangAsync)
                else
                  _buildPiutangList(piutangAsync),
                const SizedBox(height: 12),
                _buildDashedAddButton(
                  label: _tabIndex == 0 ? 'Tambah Hutang Baru' : 'Tambah Piutang Baru',
                  onTap: () => _openTambahKasbon(_tabIndex),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
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
                  'Hutang Saya',
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

  Widget _buildTotalCard({
    required String title,
    required double amount,
    required Color color,
    bool isLoading = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          isLoading
              ? const SizedBox(
                  height: 32,
                  width: 120,
                  child: Center(child: CircularProgressIndicator()),
                )
              : Text(
                  _formatRupiah(amount),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: color,
                    letterSpacing: 0.3,
                  ),
                ),
        ],
      ),
    );
  }

  double _hitungTotalHutang(List<Hutang> list) {
    return list.fold(0, (sum, item) => sum + item.nominal);
  }

  double _hitungTotalPiutang(List<Piutang> list) {
    return list.fold(0, (sum, item) => sum + item.nominal);
  }

  Widget _buildHutangList(AsyncValue<List<Hutang>> hutangAsync) {
    return hutangAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: CircularProgressIndicator(),
      ),
      error: (e, _) => Text('Error: $e'),
      data: (list) {
        if (list.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text(
              'Belum ada hutang tercatat',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          );
        }
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: list.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final h = list[index];
            final initial = h.namaToko.isNotEmpty ? h.namaToko[0].toUpperCase() : 'H';
            return _buildKasbonItemTile(
              initial: initial,
              title: h.namaToko,
              amount: h.nominal,
              color: _colorHutang,
              onTap: () async {
                final res = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => DetailKasbonScreen(hutang: h),
                  ),
                );
                if (res == true) {
                  ref.invalidate(hutangListProvider);
                  ref.invalidate(dashboardSummaryProvider);
                  ref.invalidate(riwayatProvider);
                }
              },
            );
          },
        );
      },
    );
  }

  Widget _buildPiutangList(AsyncValue<List<Piutang>> piutangAsync) {
    return piutangAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: CircularProgressIndicator(),
      ),
      error: (e, _) => Text('Error: $e'),
      data: (list) {
        if (list.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text(
              'Belum ada piutang tercatat',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          );
        }
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: list.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final p = list[index];
            final initial = p.namaOrang.isNotEmpty ? p.namaOrang[0].toUpperCase() : 'P';
            final hasPhone = p.nomorHP != null && p.nomorHP!.trim().isNotEmpty;
            return _buildKasbonItemTile(
              initial: initial,
              title: p.namaOrang,
              amount: p.nominal,
              color: _colorPiutang,
              onTap: () async {
                final res = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => DetailKasbonScreen(piutang: p),
                  ),
                );
                if (res == true) {
                  ref.invalidate(piutangListProvider);
                  ref.invalidate(dashboardSummaryProvider);
                  ref.invalidate(riwayatProvider);
                }
              },
              onWhatsAppTap: hasPhone
                  ? () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => KirimTagihanScreen(piutang: p),
                        ),
                      );
                    }
                  : null,
            );
          },
        );
      },
    );
  }

  Widget _buildKasbonItemTile({
    required String initial,
    required String title,
    required double amount,
    required Color color,
    required VoidCallback onTap,
    VoidCallback? onWhatsAppTap,
  }) {
    return Container(
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initial,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _formatRupiah(amount),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onWhatsAppTap != null) ...[
                  const SizedBox(width: 8),
                  Material(
                    color: const Color(0xFFDCF7EC),
                    shape: const StadiumBorder(),
                    child: InkWell(
                      onTap: onWhatsAppTap,
                      customBorder: const StadiumBorder(),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.chat_rounded,
                              color: Color(0xFF1DB57A),
                              size: 20,
                            ),
                            SizedBox(width: 6),
                            Text(
                              "Tagih",
                              style: TextStyle(
                                color: Color(0xFF1DB57A),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDashedAddButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: const Color(0xFFC8C4EC),
          strokeWidth: 1.5,
          gap: 5,
          dash: 6,
          radius: 16,
        ),
        child: Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.add_circle_rounded,
                color: AppColors.textSecondary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double dash;
  final double radius;

  _DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1.5,
    this.gap = 5,
    this.dash = 6,
    this.radius = 16,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();

    for (final metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        final extractPath = metric.extractPath(distance, distance + dash);
        canvas.drawPath(extractPath, paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      color != oldDelegate.color || strokeWidth != oldDelegate.strokeWidth;
}
