import 'package:flutter/material.dart';
import 'transaksi.dart';
import 'hutang.dart';
import 'piutang.dart';

enum TipeRiwayat { pemasukan, pengeluaran, hutang, piutang }

class RiwayatItemModel {
  final String id;
  final String nama;
  final double nominal;
  final DateTime tanggal;
  final TipeRiwayat tipe;
  final IconData icon;
  final String? keterangan;
  final Transaksi? rawTransaksi;
  final Hutang? rawHutang;
  final Piutang? rawPiutang;

  const RiwayatItemModel({
    required this.id,
    required this.nama,
    required this.nominal,
    required this.tanggal,
    required this.tipe,
    required this.icon,
    this.keterangan,
    this.rawTransaksi,
    this.rawHutang,
    this.rawPiutang,
  });
}
