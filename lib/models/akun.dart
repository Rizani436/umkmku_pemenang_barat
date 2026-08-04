
class Akun {
  final String id;
  final String namaPemilik;
  final String nomorHP;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Akun({
    required this.id,
    required this.namaPemilik,
    required this.nomorHP,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Akun.fromMap(Map<String, dynamic> map) {
    return Akun(
      id: map['id'] as String,
      namaPemilik: map['nama_pemilik'] as String,
      nomorHP: map['nomor_hp'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap({String? pinHash}) {
    return {
      'id': id,
      'nama_pemilik': namaPemilik,
      'nomor_hp': nomorHP,

      if (pinHash != null) 'pin_hash': pinHash,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
