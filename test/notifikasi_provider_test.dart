import 'package:flutter_test/flutter_test.dart';
import 'package:umkmku_pemenang_barat/models/hutang.dart';
import 'package:umkmku_pemenang_barat/models/pembayaran_kasbon.dart';
import 'package:umkmku_pemenang_barat/models/pengaturan_notifikasi.dart';
import 'package:umkmku_pemenang_barat/models/piutang.dart';
import 'package:umkmku_pemenang_barat/providers/notifikasi_provider.dart';

void main() {
  final dibuat = DateTime(2026, 1, 1);

  Piutang piutang({DateTime? tempo, bool lunas = false}) => Piutang(
        id: 'p1',
        namaOrang: 'Bu Sri',
        nominal: 50000,
        status: lunas ? StatusKasbon.lunas : StatusKasbon.aktif,
        tglJatuhTempo: tempo,
        createdAt: dibuat,
        idUsaha: 'u1',
      );

  Hutang hutang({DateTime? tempo, bool lunas = false}) => Hutang(
        id: 'h1',
        namaToko: 'Toko Jaya',
        nominal: 75000,
        status: lunas ? StatusKasbon.lunas : StatusKasbon.aktif,
        tglJatuhTempo: tempo,
        createdAt: dibuat,
        idUsaha: 'u1',
      );

  group('susunJadwalJatuhTempo', () {
    test('kasbon lunas tidak ikut dijadwalkan', () {
      final hasil = susunJadwalJatuhTempo(
        hutang: [hutang(tempo: DateTime(2026, 3, 10), lunas: true)],
        piutang: [piutang(tempo: DateTime(2026, 3, 10), lunas: true)],
        setelan: const PengaturanNotifikasi(),
      );
      expect(hasil, isEmpty);
    });

    test('kasbon tanpa tanggal jatuh tempo tidak ikut dijadwalkan', () {
      final hasil = susunJadwalJatuhTempo(
        hutang: [hutang(tempo: null)],
        piutang: [piutang(tempo: null)],
        setelan: const PengaturanNotifikasi(),
      );
      expect(hasil, isEmpty);
    });

    test('waktu notifikasi mundur sejumlah hariSebelum dari tanggal tempo', () {
      final hasil = susunJadwalJatuhTempo(
        hutang: [],
        piutang: [piutang(tempo: DateTime(2026, 3, 10))],
        setelan: const PengaturanNotifikasi(
          hariSebelum: 2,
          jamJatuhTempo: 8,
          menitJatuhTempo: 30,
        ),
      );
      expect(hasil, hasLength(1));
      expect(hasil.single.waktu, DateTime(2026, 3, 8, 8, 30));
    });

    test('hariSebelum 0 menjadwalkan tepat di tanggal jatuh tempo', () {
      final hasil = susunJadwalJatuhTempo(
        hutang: [hutang(tempo: DateTime(2026, 3, 10))],
        piutang: [],
        setelan: const PengaturanNotifikasi(hariSebelum: 0),
      );
      expect(hasil.single.waktu.day, 10);
      expect(hasil.single.pesan, contains('jatuh tempo hari ini'));
    });

    test('piutang dan hutang aktif keduanya ikut disusun', () {
      final hasil = susunJadwalJatuhTempo(
        hutang: [hutang(tempo: DateTime(2026, 3, 10))],
        piutang: [piutang(tempo: DateTime(2026, 3, 12))],
        setelan: const PengaturanNotifikasi(),
      );
      expect(hasil, hasLength(2));
      expect(hasil.any((j) => j.judul.contains('Bu Sri')), isTrue);
      expect(hasil.any((j) => j.judul.contains('Toko Jaya')), isTrue);
    });
  });
}
