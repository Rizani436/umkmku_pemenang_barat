import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import '../database/database_provider.dart';
import '../models/tipe_akun.dart';
import '../models/transaksi.dart';


class TransaksiRepository {
  final AppDatabase _db;
  static const _uuid = Uuid();

  TransaksiRepository(this._db);




  Future<double> getMasukHariIni(String idUsaha) =>
      _sumTanggal(idUsaha, 'pemasukan', DateTime.now());

  Future<double> getKeluarHariIni(String idUsaha) =>
      _sumTanggal(idUsaha, 'pengeluaran', DateTime.now());

  Future<double> getMasukKemarin(String idUsaha) =>
      _sumTanggal(idUsaha, 'pemasukan',
          DateTime.now().subtract(const Duration(days: 1)));

  Future<double> getKeluarKemarin(String idUsaha) =>
      _sumTanggal(idUsaha, 'pengeluaran',
          DateTime.now().subtract(const Duration(days: 1)));

  Future<double> getMasukTanggal(String idUsaha, DateTime date) =>
      _sumTanggal(idUsaha, 'pemasukan', date);

  Future<double> getKeluarTanggal(String idUsaha, DateTime date) =>
      _sumTanggal(idUsaha, 'pengeluaran', date);


  Future<double> _sumTanggal(
      String idUsaha, String jenis, DateTime tanggal) async {
    final db = await _db.database;
    final start =
        DateTime(tanggal.year, tanggal.month, tanggal.day).toIso8601String();
    final end = DateTime(tanggal.year, tanggal.month, tanggal.day + 1)
        .toIso8601String();

    const query = '''
      SELECT COALESCE(SUM(total), 0) AS jumlah
      FROM transaksi
      WHERE id_usaha = ? AND jenis_transaksi = ?
        AND tgl >= ? AND tgl < ?
      ''';

    final rows = await db.rawQuery(
      query,
      [idUsaha, jenis, start, end],
    );
    return (rows.first['jumlah'] as num?)?.toDouble() ?? 0;
  }

  /// Apakah ada transaksi tercatat pada [tanggal].
  ///
  /// Sengaja menghitung baris, bukan menjumlahkan `total` seperti
  /// [_sumTanggal]: pengingat harian perlu tahu "sudah mencatat atau belum",
  /// dan transaksi bernilai 0 tetap dihitung sebagai sudah mencatat.
  Future<bool> adaTransaksiPadaTanggal(String idUsaha, DateTime tanggal) async {
    final db = await _db.database;
    final start =
        DateTime(tanggal.year, tanggal.month, tanggal.day).toIso8601String();
    final end = DateTime(tanggal.year, tanggal.month, tanggal.day + 1)
        .toIso8601String();

    final rows = await db.rawQuery(
      '''
      SELECT 1 FROM transaksi
      WHERE id_usaha = ? AND tgl >= ? AND tgl < ?
      LIMIT 1
      ''',
      [idUsaha, start, end],
    );
    return rows.isNotEmpty;
  }

  Future<double> getTotalPemasukanAll(String idUsaha) async {
    final db = await _db.database;
    final rows = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(total), 0) AS jumlah
      FROM transaksi
      WHERE id_usaha = ? AND jenis_transaksi = 'pemasukan'
      ''',
      [idUsaha],
    );
    return (rows.first['jumlah'] as num?)?.toDouble() ?? 0;
  }

  Future<double> getTotalPengeluaranAll(String idUsaha) async {
    final db = await _db.database;
    final rows = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(total), 0) AS jumlah
      FROM transaksi
      WHERE id_usaha = ? AND jenis_transaksi = 'pengeluaran'
      ''',
      [idUsaha],
    );
    return (rows.first['jumlah'] as num?)?.toDouble() ?? 0;
  }



  Future<Transaksi> tambah({
    required String idUsaha,
    required String jenisTransaksi,
    required String kategori,
    required double total,
    DateTime? tgl,
    String? tipeAkun,
  }) async {
    final db = await _db.database;
    final now = DateTime.now();
    final transaksi = Transaksi(
      id: _uuid.v4(),
      jenisTransaksi: jenisTransaksi,
      kategori: kategori,
      tipeAkun: tipeAkun ??
          TipeAkun.dariKategori(
            jenisTransaksi: jenisTransaksi,
            kategori: kategori,
          ),
      total: total,
      tgl: tgl ?? now,
      createdAt: now,
      idUsaha: idUsaha,
    );
    await db.insert('transaksi', transaksi.toMap());
    return transaksi;
  }



  Future<List<Transaksi>> getByUsaha(String idUsaha) async {
    final db = await _db.database;
    final rows = await db.query(
      'transaksi',
      where: 'id_usaha = ?',
      whereArgs: [idUsaha],
      orderBy: 'tgl DESC',
    );
    return rows.map(Transaksi.fromMap).toList();
  }

  Future<void> update({
    required String id,
    required String jenisTransaksi,
    required String kategori,
    required double total,
  }) async {
    final db = await _db.database;
    await db.update(
      'transaksi',
      {
        'jenis_transaksi': jenisTransaksi,
        'kategori': kategori,
        // Kategori berubah berarti jenis akunnya bisa ikut berubah.
        'tipe_akun': TipeAkun.dariKategori(
          jenisTransaksi: jenisTransaksi,
          kategori: kategori,
        ),
        'total': total,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> hapus(String id) async {
    final db = await _db.database;
    await db.delete(
      'transaksi',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<double> getSumByPeriode(
    String idUsaha,
    String jenis,
    DateTime start,
    DateTime end,
  ) async {
    final db = await _db.database;
    const query = '''
      SELECT COALESCE(SUM(total), 0) AS jumlah
      FROM transaksi
      WHERE id_usaha = ? AND jenis_transaksi = ?
        AND tgl >= ? AND tgl < ?
      ''';

    final rows = await db.rawQuery(
      query,
      [idUsaha, jenis, start.toIso8601String(), end.toIso8601String()],
    );
    return (rows.first['jumlah'] as num?)?.toDouble() ?? 0;
  }

  Future<double> getSumAllTime(String idUsaha, String jenis) async {
    final db = await _db.database;
    final rows = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(total), 0) AS jumlah
      FROM transaksi
      WHERE id_usaha = ? AND jenis_transaksi = ?
      ''',
      [idUsaha, jenis],
    );
    return (rows.first['jumlah'] as num?)?.toDouble() ?? 0;
  }

  /// Total per jenis akun sepanjang waktu. Menggantikan pencocokan teks
  /// kategori (`LIKE '%stok%'`) yang dulu ikut menangkap nama toko/pelanggan
  /// yang kebetulan mengandung kata itu.
  Future<double> getSumTipeAkunAllTime(String idUsaha, String tipeAkun) async {
    final db = await _db.database;
    final rows = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(total), 0) AS jumlah
      FROM transaksi
      WHERE id_usaha = ? AND tipe_akun = ?
      ''',
      [idUsaha, tipeAkun],
    );
    return (rows.first['jumlah'] as num?)?.toDouble() ?? 0;
  }

  Future<double> getSumTipeAkunPeriode(
    String idUsaha,
    String tipeAkun,
    DateTime start,
    DateTime end,
  ) async {
    final db = await _db.database;
    final rows = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(total), 0) AS jumlah
      FROM transaksi
      WHERE id_usaha = ? AND tipe_akun = ?
        AND tgl >= ? AND tgl < ?
      ''',
      [idUsaha, tipeAkun, start.toIso8601String(), end.toIso8601String()],
    );
    return (rows.first['jumlah'] as num?)?.toDouble() ?? 0;
  }

  Future<double> getTotalPengeluaranStokAll(String idUsaha) =>
      getSumTipeAkunAllTime(idUsaha, TipeAkun.hpp);

  Future<double> getTotalPemasukanPenjualanAll(String idUsaha) =>
      getSumTipeAkunAllTime(idUsaha, TipeAkun.penjualan);
}

final transaksiRepositoryProvider = Provider<TransaksiRepository>((ref) {
  return TransaksiRepository(ref.read(appDatabaseProvider));
});
