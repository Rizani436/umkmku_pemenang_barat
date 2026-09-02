import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/hutang.dart';
import '../models/piutang.dart';
import '../providers/kasbon_provider.dart';
import '../theme/app_colors.dart';

import 'tambah_kasbon_screen.dart';
import 'detail_kasbon_screen.dart';
import 'kirim_tagihan_screen.dart';
import '../utils/format.dart';
import '../providers/refresh.dart';

const _colorHutang = AppColors.danger;
const _colorPiutang = AppColors.warning;

enum JatuhTempoStatus { overdue, dueSoon, normal, none }

class JatuhTempoInfo {
  final JatuhTempoStatus status;
  final String label;
  final Color color;

  const JatuhTempoInfo({
    required this.status,
    required this.label,
    required this.color,
  });
}

class KasbonTab extends ConsumerStatefulWidget {
  const KasbonTab({super.key});

  @override
  ConsumerState<KasbonTab> createState() => _KasbonTabState();
}

class _KasbonTabState extends ConsumerState<KasbonTab> {
  int _tabIndex = 0;


  JatuhTempoInfo _getJatuhTempoInfo(DateTime? tglJatuhTempo) {
    if (tglJatuhTempo == null) {
      return const JatuhTempoInfo(
        status: JatuhTempoStatus.none,
        label: '',
        color: Colors.transparent,
      );
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target =
        DateTime(tglJatuhTempo.year, tglJatuhTempo.month, tglJatuhTempo.day);

    final diffDays = target.difference(today).inDays;

    if (diffDays < 0) {
      final absDays = diffDays.abs();
      return JatuhTempoInfo(
        status: JatuhTempoStatus.overdue,
        label: '⚠️ Lewat $absDays hari',
        color: const Color(0xFFDC2626),
      );
    } else if (diffDays == 0) {
      return const JatuhTempoInfo(
        status: JatuhTempoStatus.dueSoon,
        label: '⚡ Jatuh Tempo Hari Ini!',
        color: Color(0xFFD97706),
      );
    } else if (diffDays <= 3) {
      return JatuhTempoInfo(
        status: JatuhTempoStatus.dueSoon,
        label: '⏳ $diffDays hari lagi',
        color: const Color(0xFFD97706),
      );
    } else {
      final dateStr =
          '${target.day} ${namaBulanIndoSingkat[target.month]} ${target.year}';
      return JatuhTempoInfo(
        status: JatuhTempoStatus.normal,
        label: 'Tempo: $dateStr',
        color: const Color(0xFF6B7280),
      );
    }
  }

  void _openTambahKasbon(int initialTab) async {
    final res = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => TambahKasbonScreen(initialTab: initialTab),
      ),
    );
    if (res == true) {
      refreshDataUsaha(ref);
    }
  }

  Widget _buildReminderBanner(
      List<Hutang> hutangList, List<Piutang> piutangList) {
    int overdueHutang = 0;
    int dueSoonHutang = 0;
    int overduePiutang = 0;
    int dueSoonPiutang = 0;

    for (var h in hutangList) {
      final info = _getJatuhTempoInfo(h.tglJatuhTempo);
      if (info.status == JatuhTempoStatus.overdue) overdueHutang++;
      if (info.status == JatuhTempoStatus.dueSoon) dueSoonHutang++;
    }

    for (var p in piutangList) {
      final info = _getJatuhTempoInfo(p.tglJatuhTempo);
      if (info.status == JatuhTempoStatus.overdue) overduePiutang++;
      if (info.status == JatuhTempoStatus.dueSoon) dueSoonPiutang++;
    }

    final totalOverdue = overdueHutang + overduePiutang;
    final totalDueSoon = dueSoonHutang + dueSoonPiutang;

    if (totalOverdue == 0 && totalDueSoon == 0) return const SizedBox.shrink();

    final isOverdue = totalOverdue > 0;
    final bg = isOverdue ? const Color(0xFFFEF2F2) : const Color(0xFFFFFBEB);
    final border =
        isOverdue ? const Color(0xFFFCA5A5) : const Color(0xFFFDE68A);
    final textCol =
        isOverdue ? const Color(0xFF991B1B) : const Color(0xFF92400E);
    final icon =
        isOverdue ? Icons.warning_amber_rounded : Icons.access_time_rounded;

    String textMsg = '';
    if (isOverdue) {
      textMsg =
          'Perhatian: Ada $totalOverdue catatan yang SUDAH LEWAT tanggal jatuh tempo!';
    } else {
      textMsg =
          'Pengingat: Ada $totalDueSoon catatan yang mendekati jatuh tempo dalam waktu dekat.';
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border, width: 1.2),
      ),
      child: Row(
        children: [
          Icon(icon, color: textCol, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              textMsg,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: textCol,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hutangAsync = ref.watch(hutangListProvider);
    final piutangAsync = ref.watch(piutangListProvider);

    final hutangList = hutangAsync.value ?? [];
    final piutangList = piutangAsync.value ?? [];

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
          child: RefreshIndicator(
            onRefresh: () async {
              refreshDataUsaha(ref);
            },
            color: AppColors.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
              children: [
                _buildReminderBanner(hutangList, piutangList),
                _buildTabSwitcher(),
                const SizedBox(height: 16),
                if (_tabIndex == 0)
                  _buildTotalCard(
                    title: 'Total Hutang',
                    amount: _hitungTotalHutang(hutangList),
                    color: _colorHutang,
                    isLoading: hutangAsync.isLoading,
                  )
                else
                  _buildTotalCard(
                    title: 'Total Piutang',
                    amount: _hitungTotalPiutang(piutangList),
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
                  label: _tabIndex == 0
                      ? 'Tambah Hutang Baru'
                      : 'Tambah Piutang Baru',
                  onTap: () => _openTambahKasbon(_tabIndex),
                ),
                const SizedBox(height: 24),
              ],
            ),
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
                  color:
                      _tabIndex == 0 ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Hutang Saya',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color:
                        _tabIndex == 0 ? Colors.white : AppColors.textPrimary,
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
                  color:
                      _tabIndex == 1 ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Orang Ngutang',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color:
                        _tabIndex == 1 ? Colors.white : AppColors.textPrimary,
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
                  formatRupiah(amount),
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

        final sortedList = List<Hutang>.from(list);
        sortedList.sort((a, b) {
          final infoA = _getJatuhTempoInfo(a.tglJatuhTempo);
          final infoB = _getJatuhTempoInfo(b.tglJatuhTempo);
          return infoA.status.index.compareTo(infoB.status.index);
        });

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sortedList.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final h = sortedList[index];
            final initial =
                h.namaToko.isNotEmpty ? h.namaToko[0].toUpperCase() : 'H';
            final tempoInfo = _getJatuhTempoInfo(h.tglJatuhTempo);

            return _buildKasbonItemTile(
              initial: initial,
              title: h.namaToko,
              amount: h.nominal,
              color: _colorHutang,
              tempoInfo: tempoInfo,
              onTap: () async {
                final res = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => DetailKasbonScreen(hutang: h),
                  ),
                );
                if (res == true) {
                  refreshDataUsaha(ref);
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

        final sortedList = List<Piutang>.from(list);
        sortedList.sort((a, b) {
          final infoA = _getJatuhTempoInfo(a.tglJatuhTempo);
          final infoB = _getJatuhTempoInfo(b.tglJatuhTempo);
          return infoA.status.index.compareTo(infoB.status.index);
        });

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sortedList.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final p = sortedList[index];
            final initial =
                p.namaOrang.isNotEmpty ? p.namaOrang[0].toUpperCase() : 'P';
            final hasPhone = p.nomorHP != null && p.nomorHP!.trim().isNotEmpty;
            final tempoInfo = _getJatuhTempoInfo(p.tglJatuhTempo);

            return _buildKasbonItemTile(
              initial: initial,
              title: p.namaOrang,
              amount: p.nominal,
              color: _colorPiutang,
              tempoInfo: tempoInfo,
              onTap: () async {
                final res = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => DetailKasbonScreen(piutang: p),
                  ),
                );
                if (res == true) {
                  refreshDataUsaha(ref);
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
    required JatuhTempoInfo tempoInfo,
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
                        formatRupiah(amount),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      if (tempoInfo.status != JatuhTempoStatus.none) ...[
                        const SizedBox(height: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: tempoInfo.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: tempoInfo.color.withValues(alpha: 0.3),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            tempoInfo.label,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: tempoInfo.color,
                            ),
                          ),
                        ),
                      ],
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
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.chat_rounded,
                              color: AppColors.success,
                              size: 20,
                            ),
                            SizedBox(width: 6),
                            Text(
                              "Tagih",
                              style: TextStyle(
                                color: AppColors.success,
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.add_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
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
