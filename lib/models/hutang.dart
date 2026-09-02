import 'pembayaran_kasbon.dart';

class Hutang {
  final String id;
  final String namaToko;

  /// Sisa yang belum dibayar.
  final double nominal;

  /// Nominal saat kasbon pertama kali dicatat. Tanpa ini, nilai asli hilang
  /// begitu ada cicilan dan laporan lampau tidak bisa direkonstruksi.
  final double nominalAwal;

  /// [StatusKasbon.aktif] atau [StatusKasbon.lunas].
  final String status;
  final String? keterangan;
  final DateTime? tglJatuhTempo;
  final DateTime createdAt;
  final String idUsaha;

  const Hutang({
    required this.id,
    required this.namaToko,
    required this.nominal,
    double? nominalAwal,
    this.status = StatusKasbon.aktif,
    this.keterangan,
    this.tglJatuhTempo,
    required this.createdAt,
    required this.idUsaha,
  }) : nominalAwal = nominalAwal ?? nominal;

  bool get sudahLunas => status == StatusKasbon.lunas;

  double get totalDibayar => nominalAwal - nominal;

  factory Hutang.fromMap(Map<String, dynamic> map) {
    final nominal = (map['nominal'] as num).toDouble();
    return Hutang(
      id: map['id'] as String,
      namaToko: map['nama_toko'] as String,
      nominal: nominal,
      nominalAwal: (map['nominal_awal'] as num?)?.toDouble(),
      status: map['status'] as String? ?? StatusKasbon.aktif,
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
      'nominal_awal': nominalAwal,
      'status': status,
      'keterangan': keterangan,
      'tgl_jatuh_tempo': tglJatuhTempo?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'id_usaha': idUsaha,
    };
  }
}
