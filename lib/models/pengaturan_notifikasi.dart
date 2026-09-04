import 'package:flutter/material.dart';

/// Preferensi pengingat milik pengguna. Disimpan di SharedPreferences, bukan
/// SQLite: ini setelan perangkat (tergantung izin notifikasi HP yang
/// bersangkutan), bukan data usaha yang ikut di-backup/dipulihkan.
@immutable
class PengaturanNotifikasi {
  /// Pengingat "sudah catat transaksi hari ini?" tiap hari.
  final bool pengingatHarianAktif;
  final int jamHarian;
  final int menitHarian;

  /// Pengingat hutang & piutang yang mendekati jatuh tempo.
  final bool jatuhTempoAktif;

  /// Berapa hari sebelum tanggal jatuh tempo notifikasi dikirim (H-[hariSebelum]).
  final int hariSebelum;
  final int jamJatuhTempo;
  final int menitJatuhTempo;

  const PengaturanNotifikasi({
    this.pengingatHarianAktif = false,
    this.jamHarian = 19,
    this.menitHarian = 0,
    this.jatuhTempoAktif = false,
    this.hariSebelum = 1,
    this.jamJatuhTempo = 8,
    this.menitJatuhTempo = 0,
  });

  /// Pilihan H-berapa yang ditawarkan di layar pengaturan.
  static const opsiHariSebelum = [0, 1, 2, 3, 7];

  TimeOfDay get waktuHarian => TimeOfDay(hour: jamHarian, minute: menitHarian);

  TimeOfDay get waktuJatuhTempo =>
      TimeOfDay(hour: jamJatuhTempo, minute: menitJatuhTempo);

  bool get adaYangAktif => pengingatHarianAktif || jatuhTempoAktif;

  PengaturanNotifikasi copyWith({
    bool? pengingatHarianAktif,
    int? jamHarian,
    int? menitHarian,
    bool? jatuhTempoAktif,
    int? hariSebelum,
    int? jamJatuhTempo,
    int? menitJatuhTempo,
  }) {
    return PengaturanNotifikasi(
      pengingatHarianAktif: pengingatHarianAktif ?? this.pengingatHarianAktif,
      jamHarian: jamHarian ?? this.jamHarian,
      menitHarian: menitHarian ?? this.menitHarian,
      jatuhTempoAktif: jatuhTempoAktif ?? this.jatuhTempoAktif,
      hariSebelum: hariSebelum ?? this.hariSebelum,
      jamJatuhTempo: jamJatuhTempo ?? this.jamJatuhTempo,
      menitJatuhTempo: menitJatuhTempo ?? this.menitJatuhTempo,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PengaturanNotifikasi &&
          other.pengingatHarianAktif == pengingatHarianAktif &&
          other.jamHarian == jamHarian &&
          other.menitHarian == menitHarian &&
          other.jatuhTempoAktif == jatuhTempoAktif &&
          other.hariSebelum == hariSebelum &&
          other.jamJatuhTempo == jamJatuhTempo &&
          other.menitJatuhTempo == menitJatuhTempo;

  @override
  int get hashCode => Object.hash(
        pengingatHarianAktif,
        jamHarian,
        menitHarian,
        jatuhTempoAktif,
        hariSebelum,
        jamJatuhTempo,
        menitJatuhTempo,
      );
}
