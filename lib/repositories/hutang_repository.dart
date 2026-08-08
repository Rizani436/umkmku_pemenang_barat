import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import '../database/database_provider.dart';
import '../models/hutang.dart';


class HutangRepository {
  final AppDatabase _db;
  static const _uuid = Uuid();

  HutangRepository(this._db);




  Future<double> getTotalHutang(String idUsaha) async {
    final db = await _db.database;
    final rows = await db.rawQuery(
      'SELECT COALESCE(SUM(nominal), 0) AS jumlah FROM hutang WHERE id_usaha = ?',
      [idUsaha],
    );
    return (rows.first['jumlah'] as num?)?.toDouble() ?? 0;
  }




  Future<List<Hutang>> getJatuhTempoTerdekat(
    String idUsaha, {
    int limit = 5,
  }) async {
    final db = await _db.database;
    final rows = await db.query(
      'hutang',
      where: 'id_usaha = ? AND tgl_jatuh_tempo IS NOT NULL',
      whereArgs: [idUsaha],
      orderBy: 'tgl_jatuh_tempo ASC',
      limit: limit,
    );
    return rows.map(Hutang.fromMap).toList();
  }



  Future<Hutang> tambah({
    required String idUsaha,
    required String namaToko,
    required double nominal,
    String? keterangan,
    DateTime? tglJatuhTempo,
  }) async {
    final db = await _db.database;
    final now = DateTime.now();
    final hutang = Hutang(
      id: _uuid.v4(),
      namaToko: namaToko,
      nominal: nominal,
      keterangan: keterangan,
      tglJatuhTempo: tglJatuhTempo,
      createdAt: now,
      idUsaha: idUsaha,
    );
    await db.insert('hutang', hutang.toMap());
    return hutang;
  }



  Future<List<Hutang>> getByUsaha(String idUsaha) async {
    final db = await _db.database;
    final rows = await db.query(
      'hutang',
      where: 'id_usaha = ?',
      whereArgs: [idUsaha],
      orderBy: 'created_at DESC',
    );
    return rows.map(Hutang.fromMap).toList();
  }

  Future<void> update({
    required String id,
    required String namaToko,
    required double nominal,
    String? keterangan,
    DateTime? tglJatuhTempo,
    bool updateJatuhTempo = false,
  }) async {
    final db = await _db.database;
    final Map<String, dynamic> data = {
      'nama_toko': namaToko,
      'nominal': nominal,
      'keterangan': keterangan,
    };
    if (updateJatuhTempo) {
      data['tgl_jatuh_tempo'] = tglJatuhTempo?.toIso8601String();
    }
    await db.update(
      'hutang',
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> hapus(String id) async {
    final db = await _db.database;
    await db.delete(
      'hutang',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

final hutangRepositoryProvider = Provider<HutangRepository>((ref) {
  return HutangRepository(ref.read(appDatabaseProvider));
});
