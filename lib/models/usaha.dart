
class Usaha {
  final String id;
  final String namaUsaha;
  final String? alamat;
  final String jenisUsaha;
  final double kas;
  final String idAkun;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Usaha({
    required this.id,
    required this.namaUsaha,
    this.alamat,
    required this.jenisUsaha,
    required this.kas,
    required this.idAkun,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Usaha.fromMap(Map<String, dynamic> map) {
    return Usaha(
      id: map['id'] as String,
      namaUsaha: map['nama_usaha'] as String,
      alamat: map['alamat'] as String?,
      jenisUsaha: map['jenis_usaha'] as String,
      kas: (map['kas'] as num).toDouble(),
      idAkun: map['id_akun'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama_usaha': namaUsaha,
      'alamat': alamat,
      'jenis_usaha': jenisUsaha,
      'kas': kas,
      'id_akun': idAkun,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Usaha copyWith({double? kas, String? alamat, DateTime? updatedAt}) {
    return Usaha(
      id: id,
      namaUsaha: namaUsaha,
      alamat: alamat ?? this.alamat,
      jenisUsaha: jenisUsaha,
      kas: kas ?? this.kas,
      idAkun: idAkun,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
