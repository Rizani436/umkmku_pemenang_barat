import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import '../database/database_provider.dart';
import '../models/pembayaran_kasbon.dart';
import '../providers/usaha_provider.dart';

/// Riwayat cicilan & pelunasan kasbon.
///
/// Sebelumnya tidak ada tabel ini: kasbon yang lunas dihapus dan cicilan
/// sebagian menimpa kolom `nominal`, sehingga tidak ada jejak siapa membayar
/// berapa dan kapan.
class PembayaranKasbonRepository {
  final AppDatabase _db;
  static const _uuid = Uuid();

  PembayaranKasbonRepository(this._db);

  Future<PembayaranKasbon> catat({
    required String idKasbon,
    required String jenis,
    required double nominal,
    required String idUsaha,
    DateTime? tgl,
  }) async {
    final db = await _db.database;
    final now = DateTime.now();
    final pembayaran = PembayaranKasbon(
      id: _uuid.v4(),
      idKasbon: idKasbon,
      jenis: jenis,
      nominal: nominal,
      tgl: tgl ?? now,
      createdAt: now,
      idUsaha: idUsaha,
    );
    await db.insert('pembayaran_kasbon', pembayaran.toMap());
    return pembayaran;
  }

  Future<List<PembayaranKasbon>> getByKasbon(String idKasbon) async {
    final db = await _db.database;
    final rows = await db.query(
      'pembayaran_kasbon',
      where: 'id_kasbon = ?',
      whereArgs: [idKasbon],
      orderBy: 'tgl ASC',
    );
    return rows.map(PembayaranKasbon.fromMap).toList();
  }

  Future<double> totalDibayar(String idKasbon) async {
    final db = await _db.database;
    final rows = await db.rawQuery(
      'SELECT COALESCE(SUM(nominal), 0) AS jumlah '
      'FROM pembayaran_kasbon WHERE id_kasbon = ?',
      [idKasbon],
    );
    return (rows.first['jumlah'] as num?)?.toDouble() ?? 0;
  }

  /// Dipanggil saat kasbon benar-benar dihapus pengguna, supaya tidak
  /// meninggalkan baris pembayaran yatim.
  Future<void> hapusByKasbon(String idKasbon) async {
    final db = await _db.database;
    await db.delete(
      'pembayaran_kasbon',
      where: 'id_kasbon = ?',
      whereArgs: [idKasbon],
    );
  }
}

final pembayaranKasbonRepositoryProvider =
    Provider<PembayaranKasbonRepository>((ref) {
  return PembayaranKasbonRepository(ref.read(appDatabaseProvider));
});

/// Riwayat pembayaran satu kasbon. Ikut `ref.watch(currentUsahaProvider)`
/// supaya `refreshDataUsaha()` menyegarkannya juga setelah cicilan dicatat.
final riwayatPembayaranProvider =
    FutureProvider.family<List<PembayaranKasbon>, String>((ref, idKasbon) async {
  ref.watch(currentUsahaProvider);
  return ref.read(pembayaranKasbonRepositoryProvider).getByKasbon(idKasbon);
});
