import 'kategori_transaksi.dart';

/// Jenis akun sebuah transaksi untuk keperluan laporan.
///
/// Sebelumnya laporan menebak jenis akun dengan mencocokkan teks kategori
/// (`LOWER(kategori) LIKE '%stok%' OR '%bahan%' ...`). Cara itu rapuh: kasbon
/// atas nama "Toko Bahan Jaya" ikut terhitung sebagai pembelian stok, dan
/// kategori baru yang tidak mengandung kata kunci itu hilang dari laporan.
/// Sekarang jenisnya disimpan eksplisit di kolom `transaksi.tipe_akun`.
class TipeAkun {
  TipeAkun._();

  /// Pemasukan dari penjualan barang/jasa.
  static const penjualan = 'penjualan';

  /// Pemasukan di luar usaha inti.
  static const pendapatanLain = 'pendapatan_lain';

  /// Harga pokok: pembelian stok, bahan baku, kemasan.
  static const hpp = 'hpp';

  /// Beban menjalankan usaha (operasional, upah, perawatan, dll).
  static const operasional = 'operasional';

  /// Uang yang diambil pemilik untuk keperluan pribadi (prive).
  static const pribadi = 'pribadi';

  static const semua = [
    penjualan,
    pendapatanLain,
    hpp,
    operasional,
    pribadi,
  ];

  /// Kategori pengeluaran yang tergolong harga pokok, diambil dari daftar
  /// kategori tetap di [KategoriTransaksi].
  static const _kategoriHpp = {
    'kulakan/stok',
    'bahan baku',
    'kemasan',
    'bahan pakai',
  };

  static const _kategoriPribadi = {'kep. pribadi'};

  static const _kategoriPendapatanLain = {'pendapatan lain'};

  /// Menentukan tipe akun dari pasangan jenis transaksi + label kategori.
  ///
  /// Kategori bebas (mis. "Pelunasan Hutang (Toko Bahan Jaya)" yang dibuat
  /// saat mencatat pembayaran kasbon) jatuh ke [operasional] untuk pengeluaran
  /// dan [penjualan] untuk pemasukan — pembukuan aplikasi ini berbasis kas,
  /// jadi uang kasbon yang keluar/masuk memang tercatat saat dibayar.
  static String dariKategori({
    required String jenisTransaksi,
    required String kategori,
  }) {
    final k = kategori.toLowerCase().trim();

    if (jenisTransaksi == 'pemasukan') {
      return _kategoriPendapatanLain.contains(k) ? pendapatanLain : penjualan;
    }

    if (_kategoriHpp.contains(k)) return hpp;
    if (_kategoriPribadi.contains(k)) return pribadi;
    return operasional;
  }
}
