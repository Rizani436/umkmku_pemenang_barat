/// Status sebuah hutang/piutang.
///
/// Dulu kasbon yang lunas langsung `DELETE` dari tabel, sehingga nominal asli
/// dan tanggal pelunasannya hilang dan laporan periode lampau tidak bisa
/// direkonstruksi. Sekarang barisnya tetap ada, hanya berganti status.
class StatusKasbon {
  StatusKasbon._();

  static const aktif = 'aktif';
  static const lunas = 'lunas';
}

class JenisKasbon {
  JenisKasbon._();

  static const hutang = 'hutang';
  static const piutang = 'piutang';
}

/// Satu kali pembayaran (cicilan atau pelunasan) atas sebuah kasbon.
class PembayaranKasbon {
  final String id;
  final String idKasbon;

  /// [JenisKasbon.hutang] atau [JenisKasbon.piutang].
  final String jenis;
  final double nominal;
  final DateTime tgl;
  final DateTime createdAt;
  final String idUsaha;

  const PembayaranKasbon({
    required this.id,
    required this.idKasbon,
    required this.jenis,
    required this.nominal,
    required this.tgl,
    required this.createdAt,
    required this.idUsaha,
  });

  factory PembayaranKasbon.fromMap(Map<String, dynamic> map) {
    return PembayaranKasbon(
      id: map['id'] as String,
      idKasbon: map['id_kasbon'] as String,
      jenis: map['jenis'] as String,
      nominal: (map['nominal'] as num).toDouble(),
      tgl: DateTime.parse(map['tgl'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      idUsaha: map['id_usaha'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'id_kasbon': idKasbon,
      'jenis': jenis,
      'nominal': nominal,
      'tgl': tgl.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'id_usaha': idUsaha,
    };
  }
}
