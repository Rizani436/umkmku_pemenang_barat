import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import '../database/database_provider.dart';
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


  Future<double> _sumTanggal(
      String idUsaha, String jenis, DateTime tanggal) async {
    final db = await _db.database;
    final start =
        DateTime(tanggal.year, tanggal.month, tanggal.day).toIso8601String();
    final end = DateTime(tanggal.year, tanggal.month, tanggal.day + 1)
        .toIso8601String();

    final rows = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(total), 0) AS jumlah
      FROM transaksi
      WHERE id_usaha = ? AND jenis_transaksi = ?
        AND tgl >= ? AND tgl < ?
      ''',
      [idUsaha, jenis, start, end],
    );
    return (rows.first['jumlah'] as num?)?.toDouble() ?? 0;
  }



  Future<Transaksi> tambah({
    required String idUsaha,
    required String jenisTransaksi,
    required String kategori,
    required double total,
    DateTime? tgl,
  }) async {
    final db = await _db.database;
    final now = DateTime.now();
    final transaksi = Transaksi(
      id: _uuid.v4(),
      jenisTransaksi: jenisTransaksi,
      kategori: kategori,
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
}

final transaksiRepositoryProvider = Provider<TransaksiRepository>((ref) {
  return TransaksiRepository(ref.read(appDatabaseProvider));
});
