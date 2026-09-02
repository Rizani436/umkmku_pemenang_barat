import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaksi.dart';
import '../models/hutang.dart';
import '../models/piutang.dart';
import '../models/kategori_transaksi.dart';
import '../models/riwayat_item_model.dart';
import '../providers/riwayat_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../repositories/hutang_repository.dart';
import '../repositories/piutang_repository.dart';
import '../repositories/usaha_repository.dart';
import '../theme/app_colors.dart';
import 'detail_transaksi_screen.dart';
import '../utils/format.dart';

final riwayatHutangProvider = FutureProvider<List<Hutang>>((ref) async {
  final akun = ref.watch(authControllerProvider).value;
  if (akun == null) return [];
  final usaha = await ref.read(usahaRepositoryProvider).getUsahaByAkun(akun.id);
  if (usaha == null) return [];
  return ref.read(hutangRepositoryProvider).getByUsaha(usaha.id);
});

final riwayatPiutangProvider = FutureProvider<List<Piutang>>((ref) async {
  final akun = ref.watch(authControllerProvider).value;
  if (akun == null) return [];
  final usaha = await ref.read(usahaRepositoryProvider).getUsahaByAkun(akun.id);
  if (usaha == null) return [];
  return ref.read(piutangRepositoryProvider).getByUsaha(usaha.id);
});

const _colorMasuk   = Color(0xFF1DB57A);
const _colorKeluar  = Color(0xFFFF5A5A);
const _colorHutang  = Color(0xFFFF5A5A);
const _colorPiutang = Color(0xFFF5A623);
IconData _iconDariKategori(String label) {
  for (final sektor in SektorUsaha.values) {
    for (final item in KategoriTransaksi.masuk(sektor)) {
      if (item.label.toLowerCase() == label.toLowerCase()) return item.icon;
    }
    for (final item in KategoriTransaksi.keluar(sektor)) {
      if (item.label.toLowerCase() == label.toLowerCase()) return item.icon;
    }
  }
  return Icons.receipt_long_outlined;
}


String _labelGrup(DateTime tgl) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final d = DateTime(tgl.year, tgl.month, tgl.day);
  final diff = today.difference(d).inDays;
  final tanggal =
      '${d.day} ${namaBulanIndoSingkat[d.month]} ${d.year}';
  if (diff == 0) return 'Hari Ini, $tanggal';
  if (diff == 1) return 'Kemarin, $tanggal';
  return tanggal;
}

enum _Filter { semua, pemasukan, pengeluaran, hutang, piutang }

enum _UrutanTanggal { terbaru, terlama }

class RiwayatTab extends ConsumerStatefulWidget {
  const RiwayatTab({super.key});

  @override
  ConsumerState<RiwayatTab> createState() => _RiwayatTabState();
}

class _RiwayatTabState extends ConsumerState<RiwayatTab> {
  _Filter _filter = _Filter.semua;
  _UrutanTanggal _urutan = _UrutanTanggal.terbaru;
  DateTimeRange? _filterDateRange;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<RiwayatItemModel> _buildItems(
    List<Transaksi> transaksis,
    List<Hutang> hutangs,
    List<Piutang> piutangs,
  ) {
    final items = <RiwayatItemModel>[];

    for (final t in transaksis) {
      final isPemasukan = t.jenisTransaksi == 'pemasukan';
      items.add(RiwayatItemModel(
        id: t.id,
        nama: t.kategori,
        nominal: t.total,
        tanggal: t.tgl,
        tipe: isPemasukan ? TipeRiwayat.pemasukan : TipeRiwayat.pengeluaran,
        icon: _iconDariKategori(t.kategori),
        rawTransaksi: t,
      ));
    }

    for (final h in hutangs) {
      items.add(RiwayatItemModel(
        id: h.id,
        nama: h.namaToko,
        nominal: h.nominal,
        tanggal: h.createdAt,
        tipe: TipeRiwayat.hutang,
        icon: Icons.store_outlined,
        keterangan: h.keterangan,
        rawHutang: h,
      ));
    }

    for (final p in piutangs) {
      items.add(RiwayatItemModel(
        id: p.id,
        nama: p.namaOrang,
        nominal: p.nominal,
        tanggal: p.createdAt,
        tipe: TipeRiwayat.piutang,
        icon: Icons.person_outline_rounded,
        keterangan: p.keterangan,
        rawPiutang: p,
      ));
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final riwayatAsync   = ref.watch(riwayatProvider);
    final hutangAsync    = ref.watch(riwayatHutangProvider);
    final piutangAsync   = ref.watch(riwayatPiutangProvider);

    if (riwayatAsync.isLoading || hutangAsync.isLoading || piutangAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (riwayatAsync.hasError) {
      return Center(
        child: Text('Error: ${riwayatAsync.error}',
            style: const TextStyle(color: AppColors.textSecondary)),
      );
    }

    final semuaItem = _buildItems(
      riwayatAsync.value ?? [],
      hutangAsync.value ?? [],
      piutangAsync.value ?? [],
    );

    var filtered = semuaItem.where((item) {
      switch (_filter) {
        case _Filter.pemasukan:   return item.tipe == TipeRiwayat.pemasukan;
        case _Filter.pengeluaran: return item.tipe == TipeRiwayat.pengeluaran;
        case _Filter.hutang:      return item.tipe == TipeRiwayat.hutang;
        case _Filter.piutang:     return item.tipe == TipeRiwayat.piutang;
        case _Filter.semua:       return true;
      }
    }).toList();

    if (_filterDateRange != null) {
      final start = DateTime(
          _filterDateRange!.start.year,
          _filterDateRange!.start.month,
          _filterDateRange!.start.day);
      final end = DateTime(
          _filterDateRange!.end.year,
          _filterDateRange!.end.month,
          _filterDateRange!.end.day,
          23,
          59,
          59);
      filtered = filtered
          .where((item) =>
              item.tanggal.isAfter(start.subtract(const Duration(seconds: 1))) &&
              item.tanggal.isBefore(end.add(const Duration(seconds: 1))))
          .toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((item) {
        final namaMatch = item.nama.toLowerCase().contains(q);
        final ketMatch = item.keterangan?.toLowerCase().contains(q) ?? false;
        final nominalMatch = item.nominal.toInt().toString().contains(q) ||
            formatRupiah(item.nominal).toLowerCase().contains(q);
        return namaMatch || ketMatch || nominalMatch;
      }).toList();
    }

    if (_urutan == _UrutanTanggal.terbaru) {
      filtered.sort((a, b) => b.tanggal.compareTo(a.tanggal));
    } else {
      filtered.sort((a, b) => a.tanggal.compareTo(b.tanggal));
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(riwayatProvider);
        ref.invalidate(riwayatHutangProvider);
        ref.invalidate(riwayatPiutangProvider);
      },
      color: AppColors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Riwayat Transaksi',
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

        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
              style: const TextStyle(fontSize: 13.5, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Cari transaksi, barang, atau nama...',
                hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF9CA3AF)),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF9CA3AF)),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
            ),
          ),
        ),

        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _FilterChip(
                label: 'Semua',
                active: _filter == _Filter.semua,
                onTap: () => setState(() => _filter = _Filter.semua),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Pemasukan',
                active: _filter == _Filter.pemasukan,
                activeColor: _colorMasuk,
                onTap: () => setState(() => _filter = _Filter.pemasukan),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Pengeluaran',
                active: _filter == _Filter.pengeluaran,
                activeColor: _colorKeluar,
                onTap: () => setState(() => _filter = _Filter.pengeluaran),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Hutang',
                active: _filter == _Filter.hutang,
                activeColor: _colorHutang,
                onTap: () => setState(() => _filter = _Filter.hutang),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Piutang',
                active: _filter == _Filter.piutang,
                activeColor: _colorPiutang,
                onTap: () => setState(() => _filter = _Filter.piutang),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                '${filtered.length} Transaksi',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),

              InkWell(
                onTap: () {
                  setState(() {
                    _urutan = _urutan == _UrutanTanggal.terbaru
                        ? _UrutanTanggal.terlama
                        : _UrutanTanggal.terbaru;
                  });
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _urutan == _UrutanTanggal.terbaru
                            ? Icons.arrow_downward_rounded
                            : Icons.arrow_upward_rounded,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _urutan == _UrutanTanggal.terbaru
                            ? 'Terbaru'
                            : 'Terlama',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              InkWell(
                onTap: () async {
                  final now = DateTime.now();
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(now.year + 2),
                    initialDateRange: _filterDateRange,
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
                    setState(() => _filterDateRange = picked);
                  }
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _filterDateRange != null
                        ? AppColors.primary.withValues(alpha: 0.12)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _filterDateRange != null
                          ? AppColors.primary
                          : const Color(0xFFE5E7EB),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.date_range_rounded,
                        size: 14,
                        color: _filterDateRange != null
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _filterDateRange != null ? 'Filtered' : 'Tanggal',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _filterDateRange != null
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        if (_filterDateRange != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.event_rounded,
                          size: 14, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        '${_filterDateRange!.start.day}/${_filterDateRange!.start.month}/${_filterDateRange!.start.year} - ${_filterDateRange!.end.day}/${_filterDateRange!.end.month}/${_filterDateRange!.end.year}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => setState(() => _filterDateRange = null),
                        child: const Icon(Icons.close_rounded,
                            size: 16, color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 10),

        Expanded(
          child: filtered.isEmpty ? _buildEmpty() : _buildList(filtered),
        ),
      ],
    ),
    );
  }

  Widget _buildList(List<RiwayatItemModel> items) {
    final Map<String, List<RiwayatItemModel>> grouped = {};
    for (final item in items) {
      grouped.putIfAbsent(_labelGrup(item.tanggal), () => []).add(item);
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: grouped.length,
      itemBuilder: (context, gi) {
        final entry = grouped.entries.elementAt(gi);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 10),
              child: Text(
                entry.key,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            Container(
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
              child: Column(
                children: [
                  for (int i = 0; i < entry.value.length; i++) ...[
                    _RiwayatItemTile(item: entry.value[i]),
                    if (i < entry.value.length - 1)
                      Divider(
                        height: 1,
                        indent: 64,
                        color: AppColors.inputBorder.withValues(alpha: 0.6),
                      ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 4),
          ],
        );
      },
    );
  }

  Widget _buildEmpty() {
    final label = switch (_filter) {
      _Filter.pemasukan   => 'pemasukan',
      _Filter.pengeluaran => 'pengeluaran',
      _Filter.hutang      => 'hutang',
      _Filter.piutang     => 'piutang',
      _Filter.semua       => null,
    };
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
      children: [
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.history_rounded, size: 40, color: AppColors.primary),
              ),
              const SizedBox(height: 16),
              const Text(
                'Belum ada data',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              Text(
                label == null
                    ? 'Mulai catat transaksi, hutang, atau piutang'
                    : 'Tidak ada data $label',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.active,
    this.activeColor = AppColors.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: active ? activeColor : AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: active
                  ? activeColor.withValues(alpha: 0.25)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: active ? 10 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: active ? FontWeight.bold : FontWeight.w500,
            color: active ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _RiwayatItemTile extends ConsumerWidget {
  final RiwayatItemModel item;

  const _RiwayatItemTile({required this.item});

  Color get _iconBg => switch (item.tipe) {
        TipeRiwayat.pemasukan   => const Color(0xFFDCF7EC),
        TipeRiwayat.pengeluaran => const Color(0xFFFFE5E5),
        TipeRiwayat.hutang      => const Color(0xFFFFE5E5),
        TipeRiwayat.piutang     => const Color(0xFFFFF3DC),
      };

  Color get _iconColor => switch (item.tipe) {
        TipeRiwayat.pemasukan   => _colorMasuk,
        TipeRiwayat.pengeluaran => _colorKeluar,
        TipeRiwayat.hutang      => _colorHutang,
        TipeRiwayat.piutang     => _colorPiutang,
      };

  Color get _nilaiColor => switch (item.tipe) {
        TipeRiwayat.pemasukan   => _colorMasuk,
        TipeRiwayat.pengeluaran => _colorKeluar,
        TipeRiwayat.hutang      => _colorHutang,
        TipeRiwayat.piutang     => _colorPiutang,
      };

  String get _nilaiText => switch (item.tipe) {
        TipeRiwayat.pemasukan   => '+ ${formatRupiah(item.nominal)}',
        TipeRiwayat.pengeluaran => '- ${formatRupiah(item.nominal)}',
        TipeRiwayat.hutang      => formatRupiah(item.nominal),
        TipeRiwayat.piutang     => formatRupiah(item.nominal),
      };

  String get _badgeLabel => switch (item.tipe) {
        TipeRiwayat.hutang  => 'Hutang',
        TipeRiwayat.piutang => 'Piutang',
        _             => '',
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showBadge = item.tipe == TipeRiwayat.hutang || item.tipe == TipeRiwayat.piutang;

    return InkWell(
      onTap: () async {
        final result = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => DetailTransaksiScreen(item: item),
          ),
        );
        if (result == true) {
          ref.invalidate(dashboardSummaryProvider);
          ref.invalidate(riwayatProvider);
          ref.invalidate(riwayatHutangProvider);
          ref.invalidate(riwayatPiutangProvider);
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(item.icon, size: 22, color: _iconColor),
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
                  if (showBadge) ...[
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: _nilaiColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _badgeLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _nilaiColor,
                        ),
                      ),
                    ),
                  ] else if (item.keterangan != null && item.keterangan!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.keterangan!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ],
              ),
            ),
            Text(
              _nilaiText,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: _nilaiColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
