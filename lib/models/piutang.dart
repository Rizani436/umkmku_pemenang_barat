
class Piutang {
  final String id;
  final String namaOrang;
  final String? nomorHP;
  final double nominal;
  final String? keterangan;
  final DateTime? tglJatuhTempo;
  final DateTime createdAt;
  final String idUsaha;

  const Piutang({
    required this.id,
    required this.namaOrang,
    this.nomorHP,
    required this.nominal,
    this.keterangan,
    this.tglJatuhTempo,
    required this.createdAt,
    required this.idUsaha,
  });

  factory Piutang.fromMap(Map<String, dynamic> map) {
    return Piutang(
      id: map['id'] as String,
      namaOrang: map['nama_orang'] as String,
      nomorHP: map['nomor_hp'] as String?,
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
      'nama_orang': namaOrang,
      'nomor_hp': nomorHP,
      'nominal': nominal,
      'keterangan': keterangan,
      'tgl_jatuh_tempo': tglJatuhTempo?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'id_usaha': idUsaha,
    };
  }
}
