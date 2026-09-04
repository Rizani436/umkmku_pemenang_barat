import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/hutang.dart';
import '../models/pengaturan_notifikasi.dart';
import '../models/piutang.dart';
import '../repositories/transaksi_repository.dart';
import '../services/notifikasi_service.dart';
import '../utils/format.dart';
import 'kasbon_provider.dart';
import 'session_provider.dart';
import 'usaha_provider.dart';

final notifikasiServiceProvider = Provider<NotifikasiService>((ref) {
  return NotifikasiService();
});

class PengaturanNotifikasiNotifier extends Notifier<PengaturanNotifikasi> {
  static const _keyHarianAktif = 'notif_harian_aktif';
  static const _keyJamHarian = 'notif_harian_jam';
  static const _keyMenitHarian = 'notif_harian_menit';
  static const _keyTempoAktif = 'notif_tempo_aktif';
  static const _keyHariSebelum = 'notif_tempo_hari_sebelum';
  static const _keyJamTempo = 'notif_tempo_jam';
  static const _keyMenitTempo = 'notif_tempo_menit';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  PengaturanNotifikasi build() {
    const bawaan = PengaturanNotifikasi();
    final p = _prefs;
    return PengaturanNotifikasi(
      pengingatHarianAktif:
          p.getBool(_keyHarianAktif) ?? bawaan.pengingatHarianAktif,
      jamHarian: p.getInt(_keyJamHarian) ?? bawaan.jamHarian,
      menitHarian: p.getInt(_keyMenitHarian) ?? bawaan.menitHarian,
      jatuhTempoAktif: p.getBool(_keyTempoAktif) ?? bawaan.jatuhTempoAktif,
      hariSebelum: p.getInt(_keyHariSebelum) ?? bawaan.hariSebelum,
      jamJatuhTempo: p.getInt(_keyJamTempo) ?? bawaan.jamJatuhTempo,
      menitJatuhTempo: p.getInt(_keyMenitTempo) ?? bawaan.menitJatuhTempo,
    );
  }

  Future<void> _simpan(PengaturanNotifikasi baru) async {
    state = baru;
    final p = _prefs;
    await p.setBool(_keyHarianAktif, baru.pengingatHarianAktif);
    await p.setInt(_keyJamHarian, baru.jamHarian);
    await p.setInt(_keyMenitHarian, baru.menitHarian);
    await p.setBool(_keyTempoAktif, baru.jatuhTempoAktif);
    await p.setInt(_keyHariSebelum, baru.hariSebelum);
    await p.setInt(_keyJamTempo, baru.jamJatuhTempo);
    await p.setInt(_keyMenitTempo, baru.menitJatuhTempo);
  }

  /// Menyalakan/mematikan pengingat harian. Saat dinyalakan, izin notifikasi
  /// diminta lebih dulu; kalau pengguna menolak, setelan tidak jadi berubah
  /// supaya tombol tidak menampilkan "aktif" untuk sesuatu yang tidak akan
  /// pernah muncul. Mengembalikan true kalau perubahan diterapkan.
  Future<bool> setPengingatHarian(bool aktif) async {
    if (aktif && !await _pastikanIzin()) return false;
    await _simpan(state.copyWith(pengingatHarianAktif: aktif));
    return true;
  }

  Future<bool> setJatuhTempo(bool aktif) async {
    if (aktif && !await _pastikanIzin()) return false;
    await _simpan(state.copyWith(jatuhTempoAktif: aktif));
    return true;
  }

  Future<void> setWaktuHarian(TimeOfDay waktu) =>
      _simpan(state.copyWith(jamHarian: waktu.hour, menitHarian: waktu.minute));

  Future<void> setWaktuJatuhTempo(TimeOfDay waktu) => _simpan(
      state.copyWith(jamJatuhTempo: waktu.hour, menitJatuhTempo: waktu.minute));

  Future<void> setHariSebelum(int hari) =>
      _simpan(state.copyWith(hariSebelum: hari));

  Future<bool> _pastikanIzin() async {
    final service = ref.read(notifikasiServiceProvider);
    if (await service.izinAktif()) return true;
    return service.mintaIzin();
  }
}

final pengaturanNotifikasiProvider =
    NotifierProvider<PengaturanNotifikasiNotifier, PengaturanNotifikasi>(
  PengaturanNotifikasiNotifier.new,
);

/// Apakah usaha aktif sudah punya transaksi hari ini. Dipakai untuk menunda
/// pengingat harian ke besok kalau pemiliknya sudah mencatat.
final adaTransaksiHariIniProvider = FutureProvider<bool>((ref) async {
  final idUsaha = await ref.watch(currentUsahaIdProvider.future);
  if (idUsaha == null) return false;
  return ref
      .read(transaksiRepositoryProvider)
      .adaTransaksiPadaTanggal(idUsaha, DateTime.now());
});

/// Menyusun ulang seluruh jadwal notifikasi dari data terbaru.
///
/// Provider ini di-`watch` dari kerangka dashboard supaya berjalan ulang
/// otomatis setiap kali setelan berubah atau data usaha di-invalidasi lewat
/// `refreshDataUsaha()` — jadi jadwal ikut menyesuaikan begitu ada kasbon baru,
/// kasbon lunas, atau transaksi hari ini dicatat, tanpa perlu dipanggil manual
/// dari tiap layar.
final sinkronisasiNotifikasiProvider = FutureProvider<void>((ref) async {
  if (!NotifikasiService.didukung) return;

  final service = ref.watch(notifikasiServiceProvider);
  final setelan = ref.watch(pengaturanNotifikasiProvider);

  if (!setelan.adaYangAktif) {
    await service.batalkanSemua();
    return;
  }

  if (setelan.pengingatHarianAktif) {
    final sudahCatat = await ref.watch(adaTransaksiHariIniProvider.future);
    await service.jadwalkanPengingatHarian(
      jam: setelan.jamHarian,
      menit: setelan.menitHarian,
      sudahCatatHariIni: sudahCatat,
    );
  } else {
    await service.batalkanPengingatHarian();
  }

  if (setelan.jatuhTempoAktif) {
    final hutang = await ref.watch(hutangListProvider.future);
    final piutang = await ref.watch(piutangListProvider.future);
    await service.jadwalkanJatuhTempo(
      susunJadwalJatuhTempo(
        hutang: hutang,
        piutang: piutang,
        setelan: setelan,
      ),
    );
  } else {
    await service.jadwalkanJatuhTempo(const []);
  }
});

/// Mengubah daftar kasbon menjadi jadwal notifikasi.
///
/// Dipisah dari [sinkronisasiNotifikasiProvider] supaya bisa diuji tanpa
/// plugin notifikasi. Kasbon yang sudah lunas atau tanpa tanggal jatuh tempo
/// dilewati; yang waktunya sudah lewat disaring di
/// [NotifikasiService.jadwalkanJatuhTempo].
List<JadwalJatuhTempo> susunJadwalJatuhTempo({
  required List<Hutang> hutang,
  required List<Piutang> piutang,
  required PengaturanNotifikasi setelan,
}) {
  final hasil = <JadwalJatuhTempo>[];

  DateTime waktuNotif(DateTime tempo) => DateTime(
        tempo.year,
        tempo.month,
        tempo.day - setelan.hariSebelum,
        setelan.jamJatuhTempo,
        setelan.menitJatuhTempo,
      );

  String kapan(DateTime tempo) {
    if (setelan.hariSebelum == 0) return 'jatuh tempo hari ini';
    if (setelan.hariSebelum == 1) return 'jatuh tempo besok';
    return 'jatuh tempo ${setelan.hariSebelum} hari lagi '
        '(${tempo.day} ${namaBulanIndo[tempo.month]})';
  }

  for (final p in piutang) {
    final tempo = p.tglJatuhTempo;
    if (p.sudahLunas || tempo == null) continue;
    hasil.add(JadwalJatuhTempo(
      judul: 'Waktunya menagih ${p.namaOrang}',
      pesan: 'Kasbon ${p.namaOrang} sebesar ${formatRupiah(p.nominal)} '
          '${kapan(tempo)}.',
      waktu: waktuNotif(tempo),
    ));
  }

  for (final h in hutang) {
    final tempo = h.tglJatuhTempo;
    if (h.sudahLunas || tempo == null) continue;
    hasil.add(JadwalJatuhTempo(
      judul: 'Hutang ke ${h.namaToko}',
      pesan: 'Hutang ${h.namaToko} sebesar ${formatRupiah(h.nominal)} '
          '${kapan(tempo)}.',
      waktu: waktuNotif(tempo),
    ));
  }

  return hasil;
}
