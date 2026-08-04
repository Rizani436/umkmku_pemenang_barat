


class AkunCredential {
  final String idAkun;
  final String pinHash;

  const AkunCredential({required this.idAkun, required this.pinHash});

  factory AkunCredential.fromJson(Map<String, dynamic> json) {
    return AkunCredential(
      idAkun: json['idAkun'] as String,
      pinHash: json['pinHash'] as String,
    );
  }

  Map<String, dynamic> toJson() => {'idAkun': idAkun, 'pinHash': pinHash};
}
