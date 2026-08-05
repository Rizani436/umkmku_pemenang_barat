import 'package:flutter/material.dart';

enum SektorUsaha { perdagangan, manufaktur, jasa }

extension SektorUsahaExt on SektorUsaha {
  String get label {
    switch (this) {
      case SektorUsaha.perdagangan:
        return 'Perdagangan';
      case SektorUsaha.manufaktur:
        return 'Manufaktur';
      case SektorUsaha.jasa:
        return 'Jasa';
    }
  }
}

SektorUsaha sektorFromString(String nilai) {
  switch (nilai.toLowerCase().trim()) {
    case 'manufaktur':
      return SektorUsaha.manufaktur;
    case 'jasa':
      return SektorUsaha.jasa;
    case 'perdagangan':
    default:
      return SektorUsaha.perdagangan;
  }
}

class KategoriItem {
  final String label;
  final IconData icon;

  const KategoriItem({required this.label, required this.icon});
}

class KategoriTransaksi {
  KategoriTransaksi._();

  static const List<KategoriItem> _masukPerdagangan = [
    KategoriItem(label: 'Makanan/Jajanan', icon: Icons.restaurant_menu_rounded),
    KategoriItem(label: 'Minuman', icon: Icons.water_drop_outlined),
    KategoriItem(label: 'Sembako', icon: Icons.shopping_bag_outlined),
    KategoriItem(label: 'Barang Lain', icon: Icons.inventory_2_outlined),
    KategoriItem(label: 'Pendapatan Lain', icon: Icons.add_circle_outline_rounded),
  ];

  static const List<KategoriItem> _masukManufaktur = [
    KategoriItem(label: 'Jual Eceran', icon: Icons.storefront_outlined),
    KategoriItem(label: 'Terima Pesanan', icon: Icons.receipt_long_outlined),
    KategoriItem(label: 'Pendapatan Lain', icon: Icons.add_circle_outline_rounded),
  ];

  static const List<KategoriItem> _masukJasa = [
    KategoriItem(label: 'Ongkos Jasa', icon: Icons.construction_rounded),
    KategoriItem(label: 'Jual Sampingan', icon: Icons.sell_outlined),
    KategoriItem(label: 'Pendapatan Lain', icon: Icons.add_circle_outline_rounded),
  ];

  static const List<KategoriItem> _keluarPerdagangan = [
    KategoriItem(label: 'Kulakan/Stok', icon: Icons.local_shipping_outlined),
    KategoriItem(label: 'Operasional', icon: Icons.settings_outlined),
    KategoriItem(label: 'Upah Karyawan', icon: Icons.people_outline_rounded),
    KategoriItem(label: 'Kep. Pribadi', icon: Icons.person_outline_rounded),
    KategoriItem(label: 'Lainnya', icon: Icons.more_horiz_rounded),
  ];

  static const List<KategoriItem> _keluarManufaktur = [
    KategoriItem(label: 'Bahan Baku', icon: Icons.category_outlined),
    KategoriItem(label: 'Kemasan', icon: Icons.inventory_outlined),
    KategoriItem(label: 'Op. Produksi', icon: Icons.precision_manufacturing_outlined),
    KategoriItem(label: 'Upah Karyawan', icon: Icons.people_outline_rounded),
    KategoriItem(label: 'Kep. Pribadi', icon: Icons.person_outline_rounded),
    KategoriItem(label: 'Lainnya', icon: Icons.more_horiz_rounded),
  ];

  static const List<KategoriItem> _keluarJasa = [
    KategoriItem(label: 'Bahan Pakai', icon: Icons.science_outlined),
    KategoriItem(label: 'Perawatan', icon: Icons.build_outlined),
    KategoriItem(label: 'Operasional', icon: Icons.settings_outlined),
    KategoriItem(label: 'Bagi Hasil', icon: Icons.handshake_outlined),
    KategoriItem(label: 'Kep. Pribadi', icon: Icons.person_outline_rounded),
    KategoriItem(label: 'Lainnya', icon: Icons.more_horiz_rounded),
  ];

  static List<KategoriItem> masuk(SektorUsaha sektor) {
    switch (sektor) {
      case SektorUsaha.manufaktur:
        return _masukManufaktur;
      case SektorUsaha.jasa:
        return _masukJasa;
      case SektorUsaha.perdagangan:
        return _masukPerdagangan;
    }
  }

  static List<KategoriItem> keluar(SektorUsaha sektor) {
    switch (sektor) {
      case SektorUsaha.manufaktur:
        return _keluarManufaktur;
      case SektorUsaha.jasa:
        return _keluarJasa;
      case SektorUsaha.perdagangan:
        return _keluarPerdagangan;
    }
  }
}
