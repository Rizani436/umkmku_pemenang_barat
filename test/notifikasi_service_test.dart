import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:umkmku_pemenang_barat/services/notifikasi_service.dart';

void main() {
  setUpAll(() {
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
  });

  tz.TZDateTime jam(int h, int m, {int hari = 15}) =>
      tz.TZDateTime(tz.local, 2026, 3, hari, h, m);

  group('kemunculanBerikutnya', () {
    test('jam belum lewat hari ini -> dijadwalkan hari ini juga', () {
      final hasil = NotifikasiService.kemunculanBerikutnya(
        jam: 19,
        menit: 0,
        lewatiHariIni: false,
        sekarang: jam(8, 0),
      );
      expect(hasil, jam(19, 0));
    });

    test('jam sudah lewat hari ini -> digeser ke besok', () {
      final hasil = NotifikasiService.kemunculanBerikutnya(
        jam: 19,
        menit: 0,
        lewatiHariIni: false,
        sekarang: jam(20, 0),
      );
      expect(hasil, jam(19, 0, hari: 16));
    });

    test('lewatiHariIni true selalu menjadwalkan besok walau jam belum lewat',
        () {
      final hasil = NotifikasiService.kemunculanBerikutnya(
        jam: 19,
        menit: 0,
        lewatiHariIni: true,
        sekarang: jam(8, 0),
      );
      expect(hasil, jam(19, 0, hari: 16));
    });

    test('tepat pada jamnya dianggap sudah lewat, bukan hari ini', () {
      final hasil = NotifikasiService.kemunculanBerikutnya(
        jam: 19,
        menit: 0,
        lewatiHariIni: false,
        sekarang: jam(19, 0),
      );
      expect(hasil, jam(19, 0, hari: 16));
    });
  });
}
