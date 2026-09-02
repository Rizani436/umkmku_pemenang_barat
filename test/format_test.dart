import 'package:flutter_test/flutter_test.dart';
import 'package:umkmku_pemenang_barat/utils/format.dart';

void main() {
  group('formatRibuan', () {
    test('menyisipkan titik tiap tiga digit', () {
      expect(formatRibuan(0), '0');
      expect(formatRibuan(999), '999');
      expect(formatRibuan(1000), '1.000');
      expect(formatRibuan(1250000), '1.250.000');
      expect(formatRibuan(12345678), '12.345.678');
    });

    test('menangani nilai minus', () {
      // Versi lama memakai toInt().toString() sehingga tanda minus ikut
      // terhitung sebagai digit dan hasilnya jadi '-1.00.0'.
      expect(formatRibuan(-1000), '-1.000');
      expect(formatRibuan(-1250000), '-1.250.000');
    });

    test('menerima null dan teks bertitik', () {
      expect(formatRibuan(null), '0');
      expect(formatRibuan('1.500'), '1.500');
    });
  });

  group('formatRupiah', () {
    test('memakai spasi setelah Rp secara konsisten', () {
      expect(formatRupiah(0), 'Rp 0');
      expect(formatRupiah(1000), 'Rp 1.000');
      expect(formatRupiah(1250000), 'Rp 1.250.000');
    });

    test('nilai minus diberi tanda di depan', () {
      expect(formatRupiah(-1250000), '-Rp 1.250.000');
    });

    test('pecahan dibulatkan ke rupiah penuh', () {
      expect(formatRupiah(1500.6), 'Rp 1.501');
    });
  });

  group('tanggal', () {
    final dt = DateTime(2026, 9, 2, 14, 5);

    test('formatTanggalIndo', () {
      expect(formatTanggalIndo(dt), '2 September 2026');
      expect(formatTanggalIndo(dt, padHari: true), '02 September 2026');
    });

    test('formatTanggalJamIndo', () {
      expect(formatTanggalJamIndo(dt), '2 September 2026, 14:05 WIB');
    });

    test('nama bulan terindeks 1-12', () {
      expect(namaBulanIndo[1], 'Januari');
      expect(namaBulanIndo[12], 'Desember');
      expect(namaBulanIndoSingkat[8], 'Ags');
    });
  });
}
