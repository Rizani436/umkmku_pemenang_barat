import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:umkmku_pemenang_barat/database/app_database.dart';
import 'package:umkmku_pemenang_barat/repositories/transaksi_repository.dart';

/// Uji [TransaksiRepository.adaTransaksiPadaTanggal], dipakai provider
/// pengingat harian untuk memutuskan apakah pengingat "belum catat hari ini"
/// perlu digeser ke besok.
void main() {
  sqfliteFfiInit();

  late AppDatabase appDb;
  late TransaksiRepository transaksiRepo;

  const idUsaha = 'usaha-1';

  setUp(() async {
    appDb = AppDatabase.forTesting(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    transaksiRepo = TransaksiRepository(appDb);

    final db = await appDb.database;
    final now = DateTime.now().toIso8601String();
    await db.insert('akun', {
      'id': 'akun-1',
      'nama_pemilik': 'Sri',
      'nomor_hp': '0812',
      'pin_hash': 'x',
      'created_at': now,
      'updated_at': now,
    });
    await db.insert('usaha', {
      'id': idUsaha,
      'nama_usaha': 'Warung Sri',
      'jenis_usaha': 'perdagangan',
      'id_akun': 'akun-1',
      'created_at': now,
      'updated_at': now,
    });
  });

  tearDown(() => appDb.close());

  group('adaTransaksiPadaTanggal', () {
    test('false kalau belum ada transaksi sama sekali', () async {
      expect(
        await transaksiRepo.adaTransaksiPadaTanggal(idUsaha, DateTime.now()),
        isFalse,
      );
    });

    test('true kalau ada transaksi pada tanggal itu, walau nominalnya 0',
        () async {
      final hariIni = DateTime.now();
      await transaksiRepo.tambah(
        idUsaha: idUsaha,
        jenisTransaksi: 'pemasukan',
        kategori: 'Minuman',
        total: 0,
        tgl: hariIni,
      );

      expect(
        await transaksiRepo.adaTransaksiPadaTanggal(idUsaha, hariIni),
        isTrue,
      );
    });

    test('transaksi di hari lain tidak ikut terhitung', () async {
      final kemarin = DateTime.now().subtract(const Duration(days: 1));
      await transaksiRepo.tambah(
        idUsaha: idUsaha,
        jenisTransaksi: 'pemasukan',
        kategori: 'Minuman',
        total: 15000,
        tgl: kemarin,
      );

      expect(
        await transaksiRepo.adaTransaksiPadaTanggal(idUsaha, DateTime.now()),
        isFalse,
      );
      expect(
        await transaksiRepo.adaTransaksiPadaTanggal(idUsaha, kemarin),
        isTrue,
      );
    });

    test('transaksi milik usaha lain tidak ikut terhitung', () async {
      final db = await appDb.database;
      final now = DateTime.now().toIso8601String();
      await db.insert('usaha', {
        'id': 'usaha-2',
        'nama_usaha': 'Warung Lain',
        'jenis_usaha': 'perdagangan',
        'id_akun': 'akun-1',
        'created_at': now,
        'updated_at': now,
      });
      await transaksiRepo.tambah(
        idUsaha: 'usaha-2',
        jenisTransaksi: 'pemasukan',
        kategori: 'Minuman',
        total: 15000,
      );

      expect(
        await transaksiRepo.adaTransaksiPadaTanggal(idUsaha, DateTime.now()),
        isFalse,
      );
    });
  });
}
