import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  static const versiSkema = 5;

  static final AppDatabase _instance = AppDatabase._();
  factory AppDatabase() => _instance;

  AppDatabase._()
      : _factory = null,
        _pathOverride = null;

  /// Instance terpisah (bukan singleton) untuk pengujian, supaya skema dan
  /// migrasi bisa diverifikasi tanpa plugin sqflite milik perangkat.
  @visibleForTesting
  AppDatabase.forTesting({
    required DatabaseFactory factory,
    required String path,
  })  : _factory = factory,
        _pathOverride = path;

  final DatabaseFactory? _factory;
  final String? _pathOverride;

  /// Cache Future-nya, bukan Database-nya. Kalau yang di-cache `Database?`,
  /// dua pemanggil bersamaan bisa sama-sama lolos cek null dan membuka
  /// database dua kali.
  Future<Database>? _dbFuture;

  Future<Database> get database {
    return _dbFuture ??= _initDatabase().catchError((Object e) {
      // Jangan simpan future yang gagal, supaya percobaan berikutnya
      // membuka ulang alih-alih mengulang error yang sama selamanya.
      _dbFuture = null;
      throw e;
    });
  }

  Future<Database> _initDatabase() async {
    final factory = _factory ?? databaseFactory;
    final path =
        _pathOverride ?? join(await getDatabasesPath(), 'umkmku_pemenang_barat.db');

    return factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: versiSkema,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
      ),
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE usaha ADD COLUMN persediaan REAL NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE usaha ADD COLUMN perlengkapan REAL NOT NULL DEFAULT 0');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE usaha ADD COLUMN mesin_peralatan REAL NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE usaha ADD COLUMN gedung REAL NOT NULL DEFAULT 0');
    }
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE usaha ADD COLUMN modal_awal REAL NOT NULL DEFAULT 0');
      await db.execute('UPDATE usaha SET modal_awal = kas WHERE modal_awal = 0');
    }
    if (oldVersion < 5) {
      await _createIndexes(db);
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE akun (
        id          TEXT PRIMARY KEY,
        nama_pemilik TEXT NOT NULL,
        nomor_hp    TEXT NOT NULL UNIQUE,
        pin_hash    TEXT NOT NULL,
        created_at  TEXT NOT NULL,
        updated_at  TEXT NOT NULL
      )
    ''');

    // Catatan: setiap kolom yang ditambahkan lewat ALTER TABLE di _onUpgrade
    // WAJIB ikut ditulis di sini, kalau tidak install baru akan kehilangan
    // kolom tersebut (mis. modal_awal sebelum perbaikan ini).
    await db.execute('''
      CREATE TABLE usaha (
        id              TEXT PRIMARY KEY,
        nama_usaha      TEXT NOT NULL,
        alamat          TEXT,
        jenis_usaha     TEXT NOT NULL,
        kas             REAL NOT NULL DEFAULT 0,
        persediaan      REAL NOT NULL DEFAULT 0,
        perlengkapan    REAL NOT NULL DEFAULT 0,
        mesin_peralatan REAL NOT NULL DEFAULT 0,
        gedung          REAL NOT NULL DEFAULT 0,
        modal_awal      REAL NOT NULL DEFAULT 0,
        id_akun         TEXT NOT NULL,
        created_at      TEXT NOT NULL,
        updated_at      TEXT NOT NULL,
        FOREIGN KEY (id_akun) REFERENCES akun(id) ON DELETE CASCADE
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
        id_usaha        TEXT NOT NULL,
        FOREIGN KEY (id_usaha) REFERENCES usaha(id) ON DELETE CASCADE
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
        id_usaha        TEXT NOT NULL,
        FOREIGN KEY (id_usaha) REFERENCES usaha(id) ON DELETE CASCADE
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
        id_usaha        TEXT NOT NULL,
        FOREIGN KEY (id_usaha) REFERENCES usaha(id) ON DELETE CASCADE
      )
    ''');

    await _createIndexes(db);
  }

  /// Semua query dashboard & laporan menyaring per id_usaha lalu per tanggal,
  /// jadi index komposit ini yang dipakai.
  Future<void> _createIndexes(Database db) async {
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_usaha_akun ON usaha(id_akun)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_transaksi_usaha_tgl ON transaksi(id_usaha, tgl)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_hutang_usaha_tempo ON hutang(id_usaha, tgl_jatuh_tempo)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_piutang_usaha_tempo ON piutang(id_usaha, tgl_jatuh_tempo)');
  }

  Future<void> close() async {
    final pending = _dbFuture;
    _dbFuture = null;
    if (pending == null) return;
    final db = await pending;
    await db.close();
  }
}
