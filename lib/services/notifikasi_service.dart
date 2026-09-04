import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Satu item pengingat jatuh tempo yang siap dijadwalkan.
class JadwalJatuhTempo {
  final String judul;
  final String pesan;

  /// Kapan notifikasi muncul, dalam waktu lokal perangkat.
  final DateTime waktu;

  const JadwalJatuhTempo({
    required this.judul,
    required this.pesan,
    required this.waktu,
  });
}

/// Pembungkus `flutter_local_notifications`. Semua penjadwalan notifikasi
/// aplikasi lewat kelas ini, jangan panggil plugin-nya langsung dari layar.
///
/// Catatan soal mode alarm: kita sengaja memakai
/// [AndroidScheduleMode.inexactAllowWhileIdle], bukan mode exact. Pengingat
/// pembukuan tidak butuh presisi detik, sementara mode exact menuntut izin
/// `SCHEDULE_EXACT_ALARM`/`USE_EXACT_ALARM` yang di Play Store hanya
/// diperbolehkan untuk aplikasi alarm/kalender. Konsekuensinya notifikasi bisa
/// meleset beberapa menit — itu diterima.
class NotifikasiService {
  NotifikasiService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  /// ID pengingat catat harian. Tetap, supaya penjadwalan ulang menimpa yang
  /// lama alih-alih menumpuk.
  static const idPengingatHarian = 1001;

  /// ID notifikasi uji coba dari layar pengaturan.
  static const idUjiCoba = 1002;

  /// Notifikasi jatuh tempo memakai ID berurutan mulai dari sini. Rentangnya
  /// dipakai juga saat membatalkan jadwal lama — lihat [_batalkanJatuhTempo].
  static const idAwalJatuhTempo = 2000;

  /// Batas jumlah pengingat jatuh tempo yang aktif bersamaan. Android membatasi
  /// alarm tertunda per aplikasi, dan kasbon yang jatuh temponya paling dekat
  /// memang yang paling perlu diingatkan.
  static const maksJadwalJatuhTempo = 40;

  static const _channelHarian = AndroidNotificationChannel(
    'pengingat_harian',
    'Pengingat Catat Harian',
    description: 'Mengingatkan mencatat pemasukan & pengeluaran setiap hari.',
    importance: Importance.high,
  );

  static const _channelJatuhTempo = AndroidNotificationChannel(
    'pengingat_jatuh_tempo',
    'Pengingat Jatuh Tempo Kasbon',
    description: 'Mengingatkan hutang & piutang yang mendekati jatuh tempo.',
    importance: Importance.high,
  );

  bool _siap = false;

  /// True kalau platformnya mendukung notifikasi lokal terjadwal. Di desktop
  /// (termasuk saat pengujian dengan sqflite_common_ffi) semua metode di kelas
  /// ini jadi no-op supaya tidak melempar MissingPluginException.
  static bool get didukung => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// Menyiapkan zona waktu dan channel notifikasi. Aman dipanggil berulang.
  Future<void> init() async {
    if (_siap || !didukung) return;

    tz_data.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      // Kalau identifier dari perangkat tidak dikenali database tz, jatuh ke
      // WIB. Lebih baik zona waktunya meleset daripada fitur mati total.
      tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
    }

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(_channelHarian);
    await android?.createNotificationChannel(_channelJatuhTempo);

    _siap = true;
  }

  /// Meminta izin notifikasi (Android 13+ dan iOS). Panggil saat pengguna
  /// menyalakan pengingat, bukan saat aplikasi pertama dibuka.
  Future<bool> mintaIzin() async {
    if (!didukung) return false;
    await init();

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    return await ios?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        ) ??
        false;
  }

  Future<bool> izinAktif() async {
    if (!didukung) return false;
    await init();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.areNotificationsEnabled() ?? false;
    }
    return true;
  }

  NotificationDetails get _detailHarian => NotificationDetails(
        android: AndroidNotificationDetails(
          _channelHarian.id,
          _channelHarian.name,
          channelDescription: _channelHarian.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      );

  NotificationDetails get _detailJatuhTempo => NotificationDetails(
        android: AndroidNotificationDetails(
          _channelJatuhTempo.id,
          _channelJatuhTempo.name,
          channelDescription: _channelJatuhTempo.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      );

  /// Menjadwalkan pengingat "belum mencatat hari ini" yang berulang setiap hari
  /// pada [jam]:[menit].
  ///
  /// [sudahCatatHariIni] menggeser kemunculan pertama ke besok — kalau pemilik
  /// usaha sudah mencatat, mengingatkannya malam ini hanya mengganggu.
  Future<void> jadwalkanPengingatHarian({
    required int jam,
    required int menit,
    required bool sudahCatatHariIni,
  }) async {
    if (!didukung) return;
    await init();
    await batalkanPengingatHarian();

    final waktu = kemunculanBerikutnya(
      jam: jam,
      menit: menit,
      lewatiHariIni: sudahCatatHariIni,
    );

    await _plugin.zonedSchedule(
      id: idPengingatHarian,
      scheduledDate: waktu,
      title: 'Sudah catat transaksi hari ini?',
      body: 'Luangkan semenit untuk mencatat pemasukan & pengeluaran hari ini '
          'supaya laporanmu tetap rapi.',
      notificationDetails: _detailHarian,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'pengingat_harian',
    );
  }

  /// Kemunculan berikutnya untuk jam harian tertentu.
  static tz.TZDateTime kemunculanBerikutnya({
    required int jam,
    required int menit,
    required bool lewatiHariIni,
    tz.TZDateTime? sekarang,
  }) {
    final now = sekarang ?? tz.TZDateTime.now(tz.local);
    var waktu =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, jam, menit);
    if (lewatiHariIni || !waktu.isAfter(now)) {
      waktu = waktu.add(const Duration(days: 1));
    }
    return waktu;
  }

  Future<void> batalkanPengingatHarian() async {
    if (!didukung) return;
    await _plugin.cancel(id: idPengingatHarian);
  }

  /// Mengganti seluruh jadwal jatuh tempo dengan [daftar].
  ///
  /// Selalu batalkan-lalu-jadwalkan-ulang, jangan menambah: kasbon bisa lunas,
  /// dihapus, atau tanggal temponya diubah, dan tidak ada cara mengetahui itu
  /// dari sisi notifikasi selain menyusun ulang dari data terbaru.
  Future<void> jadwalkanJatuhTempo(List<JadwalJatuhTempo> daftar) async {
    if (!didukung) return;
    await init();
    await _batalkanJatuhTempo();

    final now = tz.TZDateTime.now(tz.local);
    final terjadwal = daftar
        .map((j) => (jadwal: j, waktu: tz.TZDateTime.from(j.waktu, tz.local)))
        .where((e) => e.waktu.isAfter(now))
        .toList()
      ..sort((a, b) => a.waktu.compareTo(b.waktu));

    final dipakai = terjadwal.take(maksJadwalJatuhTempo).toList();
    for (var i = 0; i < dipakai.length; i++) {
      await _plugin.zonedSchedule(
        id: idAwalJatuhTempo + i,
        scheduledDate: dipakai[i].waktu,
        title: dipakai[i].jadwal.judul,
        body: dipakai[i].jadwal.pesan,
        notificationDetails: _detailJatuhTempo,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: 'jatuh_tempo',
      );
    }
  }

  Future<void> _batalkanJatuhTempo() async {
    final tertunda = await _plugin.pendingNotificationRequests();
    for (final n in tertunda) {
      if (n.id >= idAwalJatuhTempo &&
          n.id < idAwalJatuhTempo + maksJadwalJatuhTempo) {
        await _plugin.cancel(id: n.id);
      }
    }
  }

  Future<void> batalkanSemua() async {
    if (!didukung) return;
    await init();
    await _plugin.cancelAll();
  }

  /// Notifikasi contoh supaya pengguna bisa memastikan izinnya sudah benar
  /// tanpa menunggu sampai jam pengingat tiba.
  Future<void> tampilkanUjiCoba() async {
    if (!didukung) return;
    await init();
    await _plugin.show(
      id: idUjiCoba,
      title: 'Contoh pengingat Bisnis-Ku',
      body: 'Kalau notifikasi ini muncul, pengingat kamu sudah aktif.',
      notificationDetails: _detailHarian,
    );
  }

  Future<List<PendingNotificationRequest>> jadwalTertunda() async {
    if (!didukung) return const [];
    await init();
    return _plugin.pendingNotificationRequests();
  }
}
