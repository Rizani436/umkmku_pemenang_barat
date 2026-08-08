import 'package:bcrypt/bcrypt.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import '../database/database_provider.dart';
import '../models/akun.dart';



class AuthRepository {
  final AppDatabase _db;
  static const _uuid = Uuid();

  AuthRepository(this._db);



  String _hashPin(String pin) =>
      BCrypt.hashpw(pin, BCrypt.gensalt(logRounds: 10));

  bool _verifyPin(String pin, String hash) => BCrypt.checkpw(pin, hash);



  Future<Akun> daftar({
    required String namaPemilik,
    required String nomorHP,
    required String pin,
  }) async {
    final db = await _db.database;


    final existing = await db.query(
      'akun',
      where: 'nomor_hp = ?',
      whereArgs: [nomorHP],
    );
    if (existing.isNotEmpty) {
      throw Exception('Nomor HP $nomorHP sudah terdaftar');
    }

    final now = DateTime.now();
    final akun = Akun(
      id: _uuid.v4(),
      namaPemilik: namaPemilik,
      nomorHP: nomorHP,
      createdAt: now,
      updatedAt: now,
    );

    await db.insert('akun', akun.toMap(pinHash: _hashPin(pin)));

    return akun;
  }



  Future<Akun> masuk({
    required String nomorHP,
    required String pin,
  }) async {
    final db = await _db.database;

    final rows = await db.query(
      'akun',
      where: 'nomor_hp = ?',
      whereArgs: [nomorHP],
    );

    if (rows.isEmpty) {
      throw Exception('Nomor HP $nomorHP belum terdaftar');
    }

    final row = rows.first;
    final pinHash = row['pin_hash'] as String;

    if (!_verifyPin(pin, pinHash)) {
      throw Exception('PIN salah');
    }

    return Akun.fromMap(row);
  }



  Future<Akun?> getById(String id) async {
    final db = await _db.database;
    final rows = await db.query(
      'akun',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (rows.isEmpty) return null;
    return Akun.fromMap(rows.first);
  }

  Future<void> updateAkun({
    required String idAkun,
    required String namaPemilik,
    required String nomorHP,
  }) async {
    final db = await _db.database;
    await db.update(
      'akun',
      {
        'nama_pemilik': namaPemilik,
        'nomor_hp': nomorHP,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [idAkun],
    );
  }

  Future<void> updatePin({
    required String idAkun,
    required String pinBaru,
  }) async {
    final db = await _db.database;
    await db.update(
      'akun',
      {
        'pin_hash': _hashPin(pinBaru),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [idAkun],
    );
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.read(appDatabaseProvider));
});
