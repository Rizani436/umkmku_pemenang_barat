import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:umkmku_pemenang_barat/database/app_database.dart';

/// Skema database adalah bagian yang paling mahal kalau salah: kolom yang
/// lupa ditulis di _onCreate baru ketahuan setelah aplikasi dipasang di HP
/// pengguna baru. Tes ini menjaga _onCreate dan _onUpgrade tetap menghasilkan
/// bentuk tabel yang sama.
void main() {
  sqfliteFfiInit();

  Future<AppDatabase> bukaDbBaru() async {
    final db = AppDatabase.forTesting(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    await db.database;
    return db;
  }

  Future<Set<String>> kolomTabel(Database db, String tabel) async {
    final rows = await db.rawQuery('PRAGMA table_info($tabel)');
    return rows.map((r) => r['name'] as String).toSet();
  }

  group('_onCreate', () {
    test('membuat semua tabel yang dipakai aplikasi', () async {
      final appDb = await bukaDbBaru();
      final db = await appDb.database;

      final rows = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type = 'table'");
      final tabel = rows.map((r) => r['name'] as String).toSet();

      expect(tabel, containsAll(['akun', 'usaha', 'transaksi', 'hutang', 'piutang']));
      await appDb.close();
    });

    test('tabel usaha memuat semua kolom hasil migrasi, termasuk modal_awal',
        () async {
      final appDb = await bukaDbBaru();
      final db = await appDb.database;

      // modal_awal dulu hanya ditambahkan lewat _onUpgrade, sehingga install
      // baru kehilangan kolomnya.
      expect(
        await kolomTabel(db, 'usaha'),
        containsAll([
          'persediaan',
          'perlengkapan',
          'mesin_peralatan',
          'gedung',
          'modal_awal',
        ]),
      );
      await appDb.close();
    });

    test('membuat index untuk query dashboard dan laporan', () async {
      final appDb = await bukaDbBaru();
      final db = await appDb.database;

      final rows = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type = 'index'");
      final index = rows.map((r) => r['name'] as String).toSet();

      expect(index, contains('idx_transaksi_usaha_tgl'));
      expect(index, contains('idx_hutang_usaha_tempo'));
      expect(index, contains('idx_piutang_usaha_tempo'));
      await appDb.close();
    });
  });

  test('install baru dan hasil upgrade punya kolom usaha yang identik',
      () async {
    // Database lama (versi 1) yang lalu dimigrasi harus mendarat di bentuk
    // yang sama dengan install baru — inilah yang dulu tidak terpenuhi.
    final path = '${Directory.systemTemp.path}/umkmku_migrasi_test.db';
    await databaseFactoryFfi.deleteDatabase(path);

    final lama = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, _) async {
          // Bentuk skema versi 1 yang asli.
          await db.execute('''
            CREATE TABLE akun (
              id           TEXT PRIMARY KEY,
              nama_pemilik TEXT NOT NULL,
              nomor_hp     TEXT NOT NULL UNIQUE,
              pin_hash     TEXT NOT NULL,
              created_at   TEXT NOT NULL,
              updated_at   TEXT NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE usaha (
              id              TEXT PRIMARY KEY,
              nama_usaha      TEXT NOT NULL,
              alamat          TEXT,
              jenis_usaha     TEXT NOT NULL,
              kas             REAL NOT NULL DEFAULT 0,
              id_akun         TEXT NOT NULL,
              created_at      TEXT NOT NULL,
              updated_at      TEXT NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE transaksi (
              id              TEXT PRIMARY KEY,
              jenis_transaksi TEXT NOT NULL,
              kategori        TEXT NOT NULL,
              total           REAL NOT NULL,
              tgl             TEXT NOT NULL,
              created_at      TEXT NOT NULL,
              id_usaha        TEXT NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE hutang (
              id              TEXT PRIMARY KEY,
              nama_toko       TEXT NOT NULL,
              nominal         REAL NOT NULL,
              keterangan      TEXT,
              tgl_jatuh_tempo TEXT,
              created_at      TEXT NOT NULL,
              id_usaha        TEXT NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE piutang (
              id              TEXT PRIMARY KEY,
              nama_orang      TEXT NOT NULL,
              nomor_hp        TEXT,
              nominal         REAL NOT NULL,
              keterangan      TEXT,
              tgl_jatuh_tempo TEXT,
              created_at      TEXT NOT NULL,
              id_usaha        TEXT NOT NULL
            )
          ''');
        },
      ),
    );
    await lama.close();

    final appDb = AppDatabase.forTesting(
      factory: databaseFactoryFfi,
      path: path,
    );
    final dimigrasi = await appDb.database;
    final kolomHasilUpgrade = await kolomTabel(dimigrasi, 'usaha');
    await appDb.close();

    final baru = await bukaDbBaru();
    final kolomInstallBaru = await kolomTabel(await baru.database, 'usaha');
    await baru.close();

    expect(kolomHasilUpgrade, equals(kolomInstallBaru));
    await databaseFactoryFfi.deleteDatabase(path);
  });
}
