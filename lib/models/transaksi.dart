
class Transaksi {
  final String id;
  final String jenisTransaksi;
  final String kategori;
  final double total;
  final DateTime tgl;
  final DateTime createdAt;
  final String idUsaha;

  const Transaksi({
    required this.id,
    required this.jenisTransaksi,
    required this.kategori,
    required this.total,
    required this.tgl,
    required this.createdAt,
    required this.idUsaha,
  });

  factory Transaksi.fromMap(Map<String, dynamic> map) {
    return Transaksi(
      id: map['id'] as String,
      jenisTransaksi: map['jenis_transaksi'] as String,
      kategori: map['kategori'] as String,
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
      'total': total,
      'tgl': tgl.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'id_usaha': idUsaha,
    };
  }
}
