import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import '../database/database_provider.dart';
import '../models/piutang.dart';


class PiutangRepository {
  final AppDatabase _db;
  static const _uuid = Uuid();

  PiutangRepository(this._db);




  Future<double> getTotalPiutang(String idUsaha) async {
    final db = await _db.database;
    final rows = await db.rawQuery(
      'SELECT COALESCE(SUM(nominal), 0) AS jumlah FROM piutang WHERE id_usaha = ?',
      [idUsaha],
    );
    return (rows.first['jumlah'] as num?)?.toDouble() ?? 0;
  }




  /// Lihat catatan di [HutangRepository.getJatuhTempoTerdekat] — aturan
  /// penyaringannya sengaja dibuat sama.
  Future<List<Piutang>> getJatuhTempoTerdekat(
    String idUsaha, {
    int limit = 5,
    int toleransiTerlambatHari = 30,
  }) async {
    final db = await _db.database;
    final today = DateTime.now();
    final batasBawah = DateTime(today.year, today.month, today.day)
        .subtract(Duration(days: toleransiTerlambatHari))
        .toIso8601String();

    final rows = await db.query(
      'piutang',
      where: 'id_usaha = ? AND tgl_jatuh_tempo IS NOT NULL '
          'AND tgl_jatuh_tempo >= ?',
      whereArgs: [idUsaha, batasBawah],
      orderBy: 'tgl_jatuh_tempo ASC',
      limit: limit,
    );
    return rows.map(Piutang.fromMap).toList();
  }



  Future<Piutang> tambah({
    required String idUsaha,
    required String namaOrang,
    required double nominal,
    String? nomorHP,
    String? keterangan,
    DateTime? tglJatuhTempo,
  }) async {
    final db = await _db.database;
    final now = DateTime.now();
    final piutang = Piutang(
      id: _uuid.v4(),
      namaOrang: namaOrang,
      nomorHP: nomorHP,
      nominal: nominal,
      keterangan: keterangan,
      tglJatuhTempo: tglJatuhTempo,
      createdAt: now,
      idUsaha: idUsaha,
    );
    await db.insert('piutang', piutang.toMap());
    return piutang;
  }



  Future<List<Piutang>> getByUsaha(String idUsaha) async {
    final db = await _db.database;
    final rows = await db.query(
      'piutang',
      where: 'id_usaha = ?',
      whereArgs: [idUsaha],
      orderBy: 'created_at DESC',
    );
    return rows.map(Piutang.fromMap).toList();
  }

  Future<void> update({
    required String id,
    required String namaOrang,
    required double nominal,
    String? nomorHP,
    String? keterangan,
    DateTime? tglJatuhTempo,
    bool updateJatuhTempo = false,
  }) async {
    final db = await _db.database;
    final Map<String, dynamic> data = {
      'nama_orang': namaOrang,
      'nominal': nominal,
      'nomor_hp': nomorHP,
      'keterangan': keterangan,
    };
    if (updateJatuhTempo) {
      data['tgl_jatuh_tempo'] = tglJatuhTempo?.toIso8601String();
    }
    await db.update(
      'piutang',
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> hapus(String id) async {
    final db = await _db.database;
    await db.delete(
      'piutang',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

final piutangRepositoryProvider = Provider<PiutangRepository>((ref) {
  return PiutangRepository(ref.read(appDatabaseProvider));
});
