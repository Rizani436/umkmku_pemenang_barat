
class Hutang {
  final String id;
  final String namaToko;
  final double nominal;
  final String? keterangan;
  final DateTime? tglJatuhTempo;
  final DateTime createdAt;
  final String idUsaha;

  const Hutang({
    required this.id,
    required this.namaToko,
    required this.nominal,
    this.keterangan,
    this.tglJatuhTempo,
    required this.createdAt,
    required this.idUsaha,
  });

  factory Hutang.fromMap(Map<String, dynamic> map) {
    return Hutang(
      id: map['id'] as String,
      namaToko: map['nama_toko'] as String,
      nominal: (map['nominal'] as num).toDouble(),
      keterangan: map['keterangan'] as String?,
      tglJatuhTempo: map['tgl_jatuh_tempo'] != null
          ? DateTime.parse(map['tgl_jatuh_tempo'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      idUsaha: map['id_usaha'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama_toko': namaToko,
      'nominal': nominal,
      'keterangan': keterangan,
      'tgl_jatuh_tempo': tglJatuhTempo?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'id_usaha': idUsaha,
    };
  }
}
