import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/pengaturan_notifikasi.dart';
import '../providers/notifikasi_provider.dart';
import '../services/notifikasi_service.dart';
import '../theme/app_colors.dart';

class PengaturanNotifikasiScreen extends ConsumerWidget {
  const PengaturanNotifikasiScreen({super.key});

  static String _formatWaktu(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}.${t.minute.toString().padLeft(2, '0')}';

  static String _labelHariSebelum(int hari) {
    if (hari == 0) return 'Tepat di hari jatuh tempo';
    if (hari == 1) return '1 hari sebelumnya (H-1)';
    return '$hari hari sebelumnya (H-$hari)';
  }

  Future<void> _pilihWaktu(
    BuildContext context, {
    required TimeOfDay awal,
    required Future<void> Function(TimeOfDay) onPilih,
  }) async {
    final hasil = await showTimePicker(context: context, initialTime: awal);
    if (hasil != null) await onPilih(hasil);
  }

  void _pesan(BuildContext context, String teks) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(teks)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setelan = ref.watch(pengaturanNotifikasiProvider);
    final notifier = ref.read(pengaturanNotifikasiProvider.notifier);

    // Menjaga jadwal tetap sinkron selama layar ini terbuka: setiap kali
    // setelan berubah, provider ini dijalankan ulang dan menjadwalkan ulang.
    ref.watch(sinkronisasiNotifikasiProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FF),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
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
                    'Pengingat',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2B1F7C),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                children: [
                  if (!NotifikasiService.didukung)
                    const _KartuInfo(
                      icon: Icons.info_outline_rounded,
                      warna: AppColors.warning,
                      teks: 'Pengingat hanya tersedia di Android dan iOS.',
                    ),
                  _Kartu(
                    judul: 'Catat Transaksi Harian',
                    deskripsi:
                        'Pengingat setiap hari kalau kamu belum mencatat '
                        'transaksi apa pun di hari itu.',
                    children: [
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        activeThumbColor: AppColors.primary,
                        title: const Text(
                          'Aktifkan pengingat harian',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        value: setelan.pengingatHarianAktif,
                        onChanged: NotifikasiService.didukung
                            ? (nilai) async {
                                final ok =
                                    await notifier.setPengingatHarian(nilai);
                                if (!ok && context.mounted) {
                                  _pesan(
                                    context,
                                    'Izin notifikasi ditolak. Aktifkan lewat '
                                    'Pengaturan HP > Aplikasi > Bisnis-Ku.',
                                  );
                                }
                              }
                            : null,
                      ),
                      _BarisPilihan(
                        label: 'Jam pengingat',
                        nilai: _formatWaktu(setelan.waktuHarian),
                        aktif: setelan.pengingatHarianAktif,
                        onTap: () => _pilihWaktu(
                          context,
                          awal: setelan.waktuHarian,
                          onPilih: notifier.setWaktuHarian,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _Kartu(
                    judul: 'Jatuh Tempo Kasbon',
                    deskripsi:
                        'Pengingat menjelang tanggal jatuh tempo hutang ke '
                        'pemasok dan piutang dari pelanggan.',
                    children: [
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        activeThumbColor: AppColors.primary,
                        title: const Text(
                          'Aktifkan pengingat jatuh tempo',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        value: setelan.jatuhTempoAktif,
                        onChanged: NotifikasiService.didukung
                            ? (nilai) async {
                                final ok = await notifier.setJatuhTempo(nilai);
                                if (!ok && context.mounted) {
                                  _pesan(
                                    context,
                                    'Izin notifikasi ditolak. Aktifkan lewat '
                                    'Pengaturan HP > Aplikasi > Bisnis-Ku.',
                                  );
                                }
                              }
                            : null,
                      ),
                      _BarisPilihan(
                        label: 'Diingatkan',
                        nilai: _labelHariSebelum(setelan.hariSebelum),
                        aktif: setelan.jatuhTempoAktif,
                        onTap: () async {
                          final pilihan = await showModalBottomSheet<int>(
                            context: context,
                            backgroundColor: Colors.white,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(20)),
                            ),
                            builder: (_) => SafeArea(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Ingatkan sejak',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  for (final h
                                      in PengaturanNotifikasi.opsiHariSebelum)
                                    ListTile(
                                      title: Text(_labelHariSebelum(h)),
                                      trailing: h == setelan.hariSebelum
                                          ? const Icon(Icons.check_rounded,
                                              color: AppColors.primary)
                                          : null,
                                      onTap: () => Navigator.pop(context, h),
                                    ),
                                  const SizedBox(height: 8),
                                ],
                              ),
                            ),
                          );
                          if (pilihan != null) {
                            await notifier.setHariSebelum(pilihan);
                          }
                        },
                      ),
                      _BarisPilihan(
                        label: 'Jam pengingat',
                        nilai: _formatWaktu(setelan.waktuJatuhTempo),
                        aktif: setelan.jatuhTempoAktif,
                        onTap: () => _pilihWaktu(
                          context,
                          awal: setelan.waktuJatuhTempo,
                          onPilih: notifier.setWaktuJatuhTempo,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const _KartuInfo(
                    icon: Icons.schedule_rounded,
                    warna: AppColors.textSecondary,
                    teks: 'Demi menghemat baterai, Android boleh menggeser '
                        'pengingat beberapa menit dari jam yang kamu pilih.',
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: NotifikasiService.didukung
                          ? () async {
                              final service =
                                  ref.read(notifikasiServiceProvider);
                              if (!await service.izinAktif() &&
                                  !await service.mintaIzin()) {
                                if (context.mounted) {
                                  _pesan(context,
                                      'Izin notifikasi belum diberikan.');
                                }
                                return;
                              }
                              await service.tampilkanUjiCoba();
                              if (context.mounted) {
                                _pesan(context,
                                    'Notifikasi contoh sudah dikirim.');
                              }
                            }
                          : null,
                      icon: const Icon(Icons.notifications_active_outlined,
                          size: 18),
                      label: const Text('Coba Notifikasi Sekarang'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(
                            color: AppColors.primary, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Kartu extends StatelessWidget {
  const _Kartu({
    required this.judul,
    required this.deskripsi,
    required this.children,
  });

  final String judul;
  final String deskripsi;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            judul,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            deskripsi,
            style: const TextStyle(
              fontSize: 12,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

/// Baris "label — nilai" yang bisa diketuk. Dinonaktifkan (redup, tanpa aksi)
/// selama sakelar induknya mati, supaya tidak ada yang mengatur jam untuk
/// pengingat yang tidak menyala.
class _BarisPilihan extends StatelessWidget {
  const _BarisPilihan({
    required this.label,
    required this.nilai,
    required this.aktif,
    required this.onTap,
  });

  final String label;
  final String nilai;
  final bool aktif;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: aktif ? 1 : 0.45,
      child: InkWell(
        onTap: aktif ? onTap : null,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                nilai,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KartuInfo extends StatelessWidget {
  const _KartuInfo({
    required this.icon,
    required this.warna,
    required this.teks,
  });

  final IconData icon;
  final Color warna;
  final String teks;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: warna.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: warna, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              teks,
              style: const TextStyle(
                fontSize: 12,
                height: 1.4,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
