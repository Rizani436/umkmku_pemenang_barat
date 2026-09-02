import 'tipe_akun.dart';

class Transaksi {
  final String id;
  final String jenisTransaksi;
  final String kategori;

  /// Jenis akun untuk laporan. Disimpan saat transaksi dibuat, bukan ditebak
  /// dari teks kategori waktu laporan dihitung — lihat [TipeAkun].
  final String tipeAkun;
  final double total;
  final DateTime tgl;
  final DateTime createdAt;
  final String idUsaha;

  const Transaksi({
    required this.id,
    required this.jenisTransaksi,
    required this.kategori,
    required this.tipeAkun,
    required this.total,
    required this.tgl,
    required this.createdAt,
    required this.idUsaha,
  });

  factory Transaksi.fromMap(Map<String, dynamic> map) {
    final jenis = map['jenis_transaksi'] as String;
    final kategori = map['kategori'] as String;
    return Transaksi(
      id: map['id'] as String,
      jenisTransaksi: jenis,
      kategori: kategori,
      tipeAkun: map['tipe_akun'] as String? ??
          TipeAkun.dariKategori(jenisTransaksi: jenis, kategori: kategori),
      total: (map['total'] as num).toDouble(),
      tgl: DateTime.parse(map['tgl'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      idUsaha: map['id_usaha'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'jenis_transaksi': jenisTransaksi,
      'kategori': kategori,
      'tipe_akun': tipeAkun,
      'total': total,
      'tgl': tgl.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'id_usaha': idUsaha,
    };
  }
}
