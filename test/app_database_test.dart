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
      options: OpenDatabaseOptions(version: 1, onCreate: _skemaV1),
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

  test('upgrade v1 mengisi tipe_akun dan kolom kasbon baru', () async {
    final path = '${Directory.systemTemp.path}/umkmku_migrasi_v6_test.db';
    await databaseFactoryFfi.deleteDatabase(path);

    final lama = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(version: 1, onCreate: _skemaV1),
    );
    final now = DateTime.now().toIso8601String();
    await lama.insert('transaksi', {
      'id': 't1',
      'jenis_transaksi': 'pengeluaran',
      'kategori': 'Kulakan/Stok',
      'total': 200000,
      'tgl': now,
      'created_at': now,
      'id_usaha': 'u1',
    });
    await lama.insert('transaksi', {
      'id': 't2',
      'jenis_transaksi': 'pengeluaran',
      // Aturan lama akan mengira ini pembelian stok karena mengandung "bahan".
      'kategori': 'Pelunasan Hutang (Toko Bahan Jaya)',
      'total': 75000,
      'tgl': now,
      'created_at': now,
      'id_usaha': 'u1',
    });
    await lama.insert('transaksi', {
      'id': 't3',
      'jenis_transaksi': 'pemasukan',
      'kategori': 'Pendapatan Lain',
      'total': 10000,
      'tgl': now,
      'created_at': now,
      'id_usaha': 'u1',
    });
    await lama.insert('hutang', {
      'id': 'h1',
      'nama_toko': 'Toko Jaya',
      'nominal': 50000,
      'created_at': now,
      'id_usaha': 'u1',
    });
    await lama.close();

    final appDb =
        AppDatabase.forTesting(factory: databaseFactoryFfi, path: path);
    final db = await appDb.database;

    Future<String> tipe(String id) async {
      final rows = await db.query('transaksi',
          columns: ['tipe_akun'], where: 'id = ?', whereArgs: [id]);
      return rows.first['tipe_akun'] as String;
    }

    expect(await tipe('t1'), 'hpp');
    expect(await tipe('t2'), 'operasional',
        reason: 'nama toko tidak boleh membuatnya terhitung sebagai stok');
    expect(await tipe('t3'), 'pendapatan_lain');

    final hutang = (await db.query('hutang', where: 'id = ?', whereArgs: ['h1']))
        .first;
    expect(hutang['status'], 'aktif');
    expect(hutang['nominal_awal'], 50000,
        reason: 'kasbon lama memakai sisa saat ini sebagai nominal awal');

    // Tabel dan index riwayat pembayaran ikut terbentuk lewat jalur upgrade.
    final objek = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE name IN "
        "('pembayaran_kasbon', 'idx_pembayaran_kasbon')");
    expect(objek, hasLength(2));

    await appDb.close();
    await databaseFactoryFfi.deleteDatabase(path);
  });
}

/// Bentuk skema versi 1 yang asli, dipakai sebagai titik awal uji migrasi.
Future<void> _skemaV1(Database db, int version) async {
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
}
