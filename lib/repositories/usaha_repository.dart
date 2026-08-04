import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import '../database/database_provider.dart';
import '../models/usaha.dart';


class UsahaRepository {
  final AppDatabase _db;
  static const _uuid = Uuid();

  UsahaRepository(this._db);



  Future<Usaha> buatUsaha({
    required String namaUsaha,
    required String jenisUsaha,
    required String idAkun,
    double kas = 0,
    String? alamat,
  }) async {
    final db = await _db.database;
    final now = DateTime.now();

    final usaha = Usaha(
      id: _uuid.v4(),
      namaUsaha: namaUsaha,
      alamat: alamat,
      jenisUsaha: jenisUsaha,
      kas: kas,
      idAkun: idAkun,
      createdAt: now,
      updatedAt: now,
    );

    await db.insert('usaha', usaha.toMap());

    return usaha;
  }



  Future<void> updateKas({
    required String idUsaha,
    required double kas,
  }) async {
    final db = await _db.database;
    await db.update(
      'usaha',
      {'kas': kas, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [idUsaha],
    );
  }



  Future<Usaha?> getUsahaByAkun(String idAkun) async {
    final db = await _db.database;
    final rows = await db.query(
      'usaha',
      where: 'id_akun = ?',
      whereArgs: [idAkun],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Usaha.fromMap(rows.first);
  }
}

final usahaRepositoryProvider = Provider<UsahaRepository>((ref) {
  return UsahaRepository(ref.read(appDatabaseProvider));
});
