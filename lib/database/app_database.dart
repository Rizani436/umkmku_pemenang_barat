import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';









class AppDatabase {

  static final AppDatabase _instance = AppDatabase._();
  factory AppDatabase() => _instance;
  AppDatabase._();

  static Database? _db;

  Future<Database> get database async {
    _db ??= await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'umkmku_pemenang_barat.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onConfigure: (db) async {

        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
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


    await db.execute('''
      CREATE TABLE usaha (
        id          TEXT PRIMARY KEY,
        nama_usaha  TEXT NOT NULL,
        alamat      TEXT,
        jenis_usaha TEXT NOT NULL,
        kas         REAL NOT NULL DEFAULT 0,
        id_akun     TEXT NOT NULL,
        created_at  TEXT NOT NULL,
        updated_at  TEXT NOT NULL,
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
  }


  Future<void> close() async => _db?.close();
}
