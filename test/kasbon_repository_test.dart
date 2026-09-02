import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:umkmku_pemenang_barat/database/app_database.dart';
import 'package:umkmku_pemenang_barat/models/pembayaran_kasbon.dart';
import 'package:umkmku_pemenang_barat/models/tipe_akun.dart';
import 'package:umkmku_pemenang_barat/repositories/hutang_repository.dart';
import 'package:umkmku_pemenang_barat/repositories/pembayaran_kasbon_repository.dart';
import 'package:umkmku_pemenang_barat/repositories/transaksi_repository.dart';

/// Uji perilaku kasbon setelah pelunasan berhenti menghapus baris, dan
/// laporan berhenti menebak jenis akun dari teks kategori.
void main() {
  sqfliteFfiInit();

  late AppDatabase appDb;
  late HutangRepository hutangRepo;
  late PembayaranKasbonRepository pembayaranRepo;
  late TransaksiRepository transaksiRepo;

  const idUsaha = 'usaha-1';

  setUp(() async {
    appDb = AppDatabase.forTesting(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    hutangRepo = HutangRepository(appDb);
    pembayaranRepo = PembayaranKasbonRepository(appDb);
    transaksiRepo = TransaksiRepository(appDb);

    // Kunci asing aktif, jadi usaha induknya harus ada dulu.
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

  group('cicilan', () {
    test('mengurangi sisa dan menyimpan nominal awal', () async {
      final hutang = await hutangRepo.tambah(
        idUsaha: idUsaha,
        namaToko: 'Toko Jaya',
        nominal: 100000,
      );

      await pembayaranRepo.catat(
        idKasbon: hutang.id,
        jenis: JenisKasbon.hutang,
        nominal: 30000,
        idUsaha: idUsaha,
      );
      await hutangRepo.bayar(id: hutang.id, sisaBaru: 70000);

      final hasil = await hutangRepo.getById(hutang.id);
      expect(hasil!.nominal, 70000);
      expect(hasil.nominalAwal, 100000, reason: 'nominal asli tidak boleh hilang');
      expect(hasil.totalDibayar, 30000);
      expect(hasil.sudahLunas, isFalse);
    });

    test('riwayat pembayaran tersimpan lengkap', () async {
      final hutang = await hutangRepo.tambah(
        idUsaha: idUsaha,
        namaToko: 'Toko Jaya',
        nominal: 100000,
      );

      for (final nominal in [30000.0, 20000.0, 50000.0]) {
        await pembayaranRepo.catat(
          idKasbon: hutang.id,
          jenis: JenisKasbon.hutang,
          nominal: nominal,
          idUsaha: idUsaha,
        );
      }

      final riwayat = await pembayaranRepo.getByKasbon(hutang.id);
      expect(riwayat, hasLength(3));
      expect(await pembayaranRepo.totalDibayar(hutang.id), 100000);
    });
  });

  group('pelunasan', () {
    test('kasbon lunas ditandai, bukan dihapus', () async {
      final hutang = await hutangRepo.tambah(
        idUsaha: idUsaha,
        namaToko: 'Toko Jaya',
        nominal: 100000,
      );

      await pembayaranRepo.catat(
        idKasbon: hutang.id,
        jenis: JenisKasbon.hutang,
        nominal: 100000,
        idUsaha: idUsaha,
      );
      await hutangRepo.bayar(id: hutang.id, sisaBaru: 0);

      final hasil = await hutangRepo.getById(hutang.id);
      expect(hasil, isNotNull, reason: 'baris harus tetap ada setelah lunas');
      expect(hasil!.sudahLunas, isTrue);
      expect(hasil.nominalAwal, 100000);
    });

    test('yang lunas keluar dari daftar aktif, total, dan jatuh tempo',
        () async {
      final lunas = await hutangRepo.tambah(
        idUsaha: idUsaha,
        namaToko: 'Toko Lunas',
        nominal: 100000,
        tglJatuhTempo: DateTime.now().add(const Duration(days: 3)),
      );
      await hutangRepo.tambah(
        idUsaha: idUsaha,
        namaToko: 'Toko Aktif',
        nominal: 50000,
        tglJatuhTempo: DateTime.now().add(const Duration(days: 5)),
      );

      await hutangRepo.bayar(id: lunas.id, sisaBaru: 0);

      expect(await hutangRepo.getTotalHutang(idUsaha), 50000);
      expect(await hutangRepo.getByUsaha(idUsaha), hasLength(1));
      expect(await hutangRepo.getSemuaByUsaha(idUsaha), hasLength(2));

      final tempo = await hutangRepo.getJatuhTempoTerdekat(idUsaha);
      expect(tempo.map((h) => h.namaToko), ['Toko Aktif']);
    });
  });

  group('tipe akun transaksi', () {
    test('diisi otomatis dari kategori saat transaksi dibuat', () async {
      final stok = await transaksiRepo.tambah(
        idUsaha: idUsaha,
        jenisTransaksi: 'pengeluaran',
        kategori: 'Kulakan/Stok',
        total: 200000,
      );
      expect(stok.tipeAkun, TipeAkun.hpp);

      final jual = await transaksiRepo.tambah(
        idUsaha: idUsaha,
        jenisTransaksi: 'pemasukan',
        kategori: 'Minuman',
        total: 50000,
      );
      expect(jual.tipeAkun, TipeAkun.penjualan);
    });

    test('total stok tidak lagi ikut menghitung nama toko yang mirip',
        () async {
      await transaksiRepo.tambah(
        idUsaha: idUsaha,
        jenisTransaksi: 'pengeluaran',
        kategori: 'Kulakan/Stok',
        total: 200000,
      );
      // Aturan lama (LIKE '%bahan%') akan menambahkan yang ini ke total stok.
      await transaksiRepo.tambah(
        idUsaha: idUsaha,
        jenisTransaksi: 'pengeluaran',
        kategori: 'Pelunasan Hutang (Toko Bahan Jaya)',
        total: 75000,
      );

      expect(await transaksiRepo.getTotalPengeluaranStokAll(idUsaha), 200000);
      // Uangnya tetap terhitung sebagai pengeluaran kas.
      expect(await transaksiRepo.getTotalPengeluaranAll(idUsaha), 275000);
    });

    test('pendapatan lain tidak masuk hitungan penjualan', () async {
      await transaksiRepo.tambah(
        idUsaha: idUsaha,
        jenisTransaksi: 'pemasukan',
        kategori: 'Sembako',
        total: 90000,
      );
      await transaksiRepo.tambah(
        idUsaha: idUsaha,
        jenisTransaksi: 'pemasukan',
        kategori: 'Pendapatan Lain',
        total: 10000,
      );

      expect(await transaksiRepo.getTotalPemasukanPenjualanAll(idUsaha), 90000);
      expect(await transaksiRepo.getTotalPemasukanAll(idUsaha), 100000);
    });

    test('mengubah kategori ikut memperbarui tipe akun', () async {
      final trx = await transaksiRepo.tambah(
        idUsaha: idUsaha,
        jenisTransaksi: 'pengeluaran',
        kategori: 'Operasional',
        total: 40000,
      );
      expect(await transaksiRepo.getTotalPengeluaranStokAll(idUsaha), 0);

      await transaksiRepo.update(
        id: trx.id,
        jenisTransaksi: 'pengeluaran',
        kategori: 'Bahan Baku',
        total: 40000,
      );

      expect(await transaksiRepo.getTotalPengeluaranStokAll(idUsaha), 40000);
    });
  });
}
