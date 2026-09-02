import 'package:flutter_test/flutter_test.dart';
import 'package:umkmku_pemenang_barat/models/tipe_akun.dart';

void main() {
  String tipe(String jenis, String kategori) =>
      TipeAkun.dariKategori(jenisTransaksi: jenis, kategori: kategori);

  group('pemasukan', () {
    test('kategori penjualan biasa', () {
      expect(tipe('pemasukan', 'Makanan/Jajanan'), TipeAkun.penjualan);
      expect(tipe('pemasukan', 'Ongkos Jasa'), TipeAkun.penjualan);
      expect(tipe('pemasukan', 'Terima Pesanan'), TipeAkun.penjualan);
    });

    test('pendapatan lain dipisahkan', () {
      expect(tipe('pemasukan', 'Pendapatan Lain'), TipeAkun.pendapatanLain);
      expect(tipe('pemasukan', '  pendapatan lain  '), TipeAkun.pendapatanLain);
    });
  });

  group('pengeluaran', () {
    test('kategori harga pokok dari ketiga sektor', () {
      expect(tipe('pengeluaran', 'Kulakan/Stok'), TipeAkun.hpp);
      expect(tipe('pengeluaran', 'Bahan Baku'), TipeAkun.hpp);
      expect(tipe('pengeluaran', 'Kemasan'), TipeAkun.hpp);
      expect(tipe('pengeluaran', 'Bahan Pakai'), TipeAkun.hpp);
    });

    test('keperluan pribadi terpisah dari beban usaha', () {
      expect(tipe('pengeluaran', 'Kep. Pribadi'), TipeAkun.pribadi);
    });

    test('sisanya operasional', () {
      expect(tipe('pengeluaran', 'Operasional'), TipeAkun.operasional);
      expect(tipe('pengeluaran', 'Upah Karyawan'), TipeAkun.operasional);
      expect(tipe('pengeluaran', 'Lainnya'), TipeAkun.operasional);
    });
  });

  group('kategori bebas dari pembayaran kasbon', () {
    test('nama toko yang mengandung kata kunci tidak lagi dikira stok', () {
      // Inilah bug aturan lama: LOWER(kategori) LIKE '%bahan%' membuat
      // pelunasan hutang ke "Toko Bahan Jaya" terhitung sebagai pembelian
      // stok dan merusak nilai persediaan di neraca.
      expect(
        tipe('pengeluaran', 'Pelunasan Hutang (Toko Bahan Jaya)'),
        TipeAkun.operasional,
      );
      expect(
        tipe('pengeluaran', 'Cicilan Hutang (Warung Sembako Stok Murah)'),
        TipeAkun.operasional,
      );
    });

    test('penerimaan piutang tetap dihitung sebagai penjualan', () {
      // Pembukuan aplikasi ini berbasis kas: pendapatan diakui saat uangnya
      // diterima, jadi perilaku ini sengaja dipertahankan.
      expect(
        tipe('pemasukan', 'Pelunasan Piutang (Bu Sri)'),
        TipeAkun.penjualan,
      );
    });
  });
}
