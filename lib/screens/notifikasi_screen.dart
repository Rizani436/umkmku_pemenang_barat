import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/hutang.dart';
import '../models/piutang.dart';
import '../providers/kasbon_provider.dart';
import '../theme/app_colors.dart';
import 'kirim_tagihan_screen.dart';
import 'detail_kasbon_screen.dart';
import '../utils/format.dart';

enum TipeNotifikasi { menagih, hutang, stok }

class NotifikasiItem {
  final String id;
  final TipeNotifikasi tipe;
  final String judul;
  final String pesan;
  final String waktu;
  final Piutang? rawPiutang;
  final Hutang? rawHutang;

  const NotifikasiItem({
    required this.id,
    required this.tipe,
    required this.judul,
    required this.pesan,
    required this.waktu,
    this.rawPiutang,
    this.rawHutang,
  });
}

class NotifikasiScreen extends ConsumerWidget {
  const NotifikasiScreen({super.key});


  List<NotifikasiItem> _generateNotifikasi(
      List<Hutang> hutangList, List<Piutang> piutangList) {
    final list = <NotifikasiItem>[];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (var p in piutangList) {
      final nominalStr = formatRupiah(p.nominal);
      final createdDt = p.createdAt;
      final diffCreated = today
          .difference(
              DateTime(createdDt.year, createdDt.month, createdDt.day))
          .inDays;
      final timeLabel = diffCreated == 0
          ? 'Hari ini'
          : (diffCreated == 1 ? 'Kemarin' : '$diffCreated hari lalu');

      if (p.tglJatuhTempo != null) {
        final target = DateTime(p.tglJatuhTempo!.year, p.tglJatuhTempo!.month,
            p.tglJatuhTempo!.day);
        final diffTempo = target.difference(today).inDays;

        if (diffTempo < 0) {
          final absDays = diffTempo.abs();
          list.add(NotifikasiItem(
            id: 'p_${p.id}',
            tipe: TipeNotifikasi.menagih,
            judul: 'Waktunya Menagih!',
            pesan:
                'Pembayaran kasbon ${p.namaOrang} sebesar $nominalStr sudah lewat $absDays hari dari tanggal jatuh tempo.',
            waktu: timeLabel,
            rawPiutang: p,
          ));
        } else if (diffTempo == 0) {
          list.add(NotifikasiItem(
            id: 'p_${p.id}',
            tipe: TipeNotifikasi.menagih,
            judul: 'Waktunya Menagih!',
            pesan:
                'Hari ini adalah batas waktu pembayaran kasbon ${p.namaOrang} sebesar $nominalStr.',
            waktu: timeLabel,
            rawPiutang: p,
          ));
        } else {
          final tglStr =
              '${target.day} ${namaBulanIndo[target.month]} ${target.year}';
          list.add(NotifikasiItem(
            id: 'p_${p.id}',
            tipe: TipeNotifikasi.menagih,
            judul: 'Tagihan Kasbon ${p.namaOrang}',
            pesan:
                'Jatuh tempo pembayaran kasbon ${p.namaOrang} sebesar $nominalStr pada $tglStr.',
            waktu: timeLabel,
            rawPiutang: p,
          ));
        }
      } else {
        list.add(NotifikasiItem(
          id: 'p_${p.id}',
          tipe: TipeNotifikasi.menagih,
          judul: 'Tagihan Kasbon ${p.namaOrang}',
          pesan:
              'Ada catatan piutang kasbon ${p.namaOrang} sebesar $nominalStr yang perlu ditagih.',
          waktu: timeLabel,
          rawPiutang: p,
        ));
      }
    }

    for (var h in hutangList) {
      final nominalStr = formatRupiah(h.nominal);
      final createdDt = h.createdAt;
      final diffCreated = today
          .difference(
              DateTime(createdDt.year, createdDt.month, createdDt.day))
          .inDays;
      final timeLabel = diffCreated == 0
          ? 'Hari ini'
          : (diffCreated == 1 ? 'Kemarin' : '$diffCreated hari lalu');

      if (h.tglJatuhTempo != null) {
        final target = DateTime(h.tglJatuhTempo!.year, h.tglJatuhTempo!.month,
            h.tglJatuhTempo!.day);
        final diffTempo = target.difference(today).inDays;

        if (diffTempo < 0) {
          final absDays = diffTempo.abs();
          list.add(NotifikasiItem(
            id: 'h_${h.id}',
            tipe: TipeNotifikasi.hutang,
            judul: 'Persiapkan Uang Tunai',
            pesan:
                'Hutang ke ${h.namaToko} sebesar $nominalStr sudah lewat $absDays hari dari tanggal jatuh tempo!',
            waktu: timeLabel,
            rawHutang: h,
          ));
        } else if (diffTempo <= 1) {
          list.add(NotifikasiItem(
            id: 'h_${h.id}',
            tipe: TipeNotifikasi.hutang,
            judul: 'Persiapkan Uang Tunai',
            pesan:
                'Batas waktu pembayaran hutang ke ${h.namaToko} sebesar $nominalStr adalah ${diffTempo == 0 ? 'hari ini' : 'besok'}.',
            waktu: timeLabel,
            rawHutang: h,
          ));
        } else {
          final tglStr =
              '${target.day} ${namaBulanIndo[target.month]} ${target.year}';
          list.add(NotifikasiItem(
            id: 'h_${h.id}',
            tipe: TipeNotifikasi.hutang,
            judul: 'Jadwal Bayar Hutang',
            pesan:
                'Hutang ke ${h.namaToko} sebesar $nominalStr jatuh tempo pada $tglStr.',
            waktu: timeLabel,
            rawHutang: h,
          ));
        }
      } else {
        list.add(NotifikasiItem(
          id: 'h_${h.id}',
          tipe: TipeNotifikasi.hutang,
          judul: 'Jadwal Bayar Hutang',
          pesan:
              'Ada catatan hutang usaha ke ${h.namaToko} sebesar $nominalStr.',
          waktu: timeLabel,
          rawHutang: h,
        ));
      }
    }

    return list;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hutangAsync = ref.watch(hutangListProvider);
    final piutangAsync = ref.watch(piutangListProvider);

    final hutangList = hutangAsync.value ?? [];
    final piutangList = piutangAsync.value ?? [];
    final notifikasiList = _generateNotifikasi(hutangList, piutangList);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFE),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: AppColors.textPrimary,
                        size: 22,
                      ),
                    ),
                  ),
                  const Text(
                    'Notifikasi',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2B1F7C),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: (hutangAsync.isLoading || piutangAsync.isLoading)
                  ? const Center(child: CircularProgressIndicator())
                  : notifikasiList.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF1F5F9),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.notifications_none_rounded,
                                  size: 36,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Belum Ada Notifikasi',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF334155),
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 40),
                                child: Text(
                                  'Notifikasi penagihan kasbon dan jatuh tempo hutang usaha Anda dari database akan muncul di sini secara otomatis.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: Color(0xFF64748B),
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 8),
                          itemCount: notifikasiList.length,
                          separatorBuilder: (_, index) =>
                              const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final item = notifikasiList[index];
                            return _buildNotifikasiCard(context, item);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotifikasiCard(BuildContext context, NotifikasiItem item) {
    Color bgIcon;
    Color iconColor;
    IconData iconData;

    switch (item.tipe) {
      case TipeNotifikasi.menagih:
        bgIcon = const Color(0xFFFFF3E0);
        iconColor = const Color(0xFFFF9800);
        iconData = Icons.notifications_active_rounded;
        break;
      case TipeNotifikasi.hutang:
        bgIcon = const Color(0xFFFFEBEE);
        iconColor = const Color(0xFFE53935);
        iconData = Icons.calendar_month_rounded;
        break;
      case TipeNotifikasi.stok:
        bgIcon = const Color(0xFFEDE7F6);
        iconColor = const Color(0xFF7E57C2);
        iconData = Icons.inventory_2_rounded;
        break;
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            if (item.rawPiutang != null) {
              if (item.rawPiutang!.nomorHP != null &&
                  item.rawPiutang!.nomorHP!.trim().isNotEmpty) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => KirimTagihanScreen(piutang: item.rawPiutang!),
                  ),
                );
              } else {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => DetailKasbonScreen(piutang: item.rawPiutang!),
                  ),
                );
              }
            } else if (item.rawHutang != null) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => DetailKasbonScreen(hutang: item.rawHutang!),
                ),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: bgIcon,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    iconData,
                    color: iconColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.judul,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.pesan,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF64748B),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        item.waktu,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF94A3B8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
