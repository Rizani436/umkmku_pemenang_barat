
class Usaha {
  final String id;
  final String namaUsaha;
  final String? alamat;
  final String jenisUsaha;
  final double kas;
  final double persediaan;
  final double mesinPeralatan;
  final double gedung;
  final String idAkun;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Usaha({
    required this.id,
    required this.namaUsaha,
    this.alamat,
    required this.jenisUsaha,
    required this.kas,
    this.persediaan = 0,
    this.mesinPeralatan = 0,
    this.gedung = 0,
    required this.idAkun,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Usaha.fromMap(Map<String, dynamic> map) {
    final kasVal = (map['kas'] as num).toDouble();
    return Usaha(
      id: map['id'] as String,
      namaUsaha: map['nama_usaha'] as String,
      alamat: map['alamat'] as String?,
      jenisUsaha: map['jenis_usaha'] as String,
      kas: kasVal,
      persediaan: (map['persediaan'] as num?)?.toDouble() ?? 0.0,
      mesinPeralatan: (map['mesin_peralatan'] as num?)?.toDouble() ?? 0.0,
      gedung: (map['gedung'] as num?)?.toDouble() ?? 0.0,
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
      'persediaan': persediaan,
      'mesin_peralatan': mesinPeralatan,
      'gedung': gedung,
      'id_akun': idAkun,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Usaha copyWith({
    double? kas,
    double? persediaan,
    double? mesinPeralatan,
    double? gedung,
    String? alamat,
    DateTime? updatedAt,
  }) {
    return Usaha(
      id: id,
      namaUsaha: namaUsaha,
      alamat: alamat ?? this.alamat,
      jenisUsaha: jenisUsaha,
      kas: kas ?? this.kas,
      persediaan: persediaan ?? this.persediaan,
      mesinPeralatan: mesinPeralatan ?? this.mesinPeralatan,
      gedung: gedung ?? this.gedung,
      idAkun: idAkun,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
