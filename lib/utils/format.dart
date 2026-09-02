/// Satu-satunya tempat memformat uang dan tanggal berbahasa Indonesia.
///
/// Sebelumnya daftar nama bulan disalin di 11 berkas dan fungsi rupiah ditulis
/// ulang di 8 berkas dengan hasil yang berbeda-beda (ada yang `Rp1.000`, ada
/// `Rp 1.000`, ada yang rusak untuk nilai minus). Semua call site sekarang
/// memanggil fungsi di berkas ini.
library;

/// Indeks 1–12 supaya bisa langsung dipakai `namaBulanIndo[dt.month]`.
const List<String> namaBulanIndo = [
  '',
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
];

/// Versi singkat, indeks 1–12.
const List<String> namaBulanIndoSingkat = [
  '',
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Ags',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];

/// Angka dengan pemisah ribuan titik, tanpa awalan mata uang: `1.250.000`.
/// Nilai minus tetap benar: `-1.250.000`.
String formatRibuan(Object? value) {
  final double angka;
  if (value == null) {
    angka = 0;
  } else if (value is num) {
    angka = value.toDouble();
  } else {
    angka = double.tryParse(value.toString().replaceAll('.', '')) ?? 0;
  }

  final negatif = angka < 0;
  final s = angka.abs().toStringAsFixed(0);
  final buffer = StringBuffer(negatif ? '-' : '');
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buffer.write('.');
    buffer.write(s[i]);
  }
  return buffer.toString();
}

/// Uang dalam rupiah: `Rp 1.250.000`, `Rp 0`, `-Rp 1.250.000`.
String formatRupiah(num nilai) {
  if (nilai == 0) return 'Rp 0';
  final negatif = nilai < 0;
  return '${negatif ? '-' : ''}Rp ${formatRibuan(nilai.abs())}';
}

/// Kebalikan dari [formatRibuan]: mengubah isi kolom input yang sudah
/// bertitik (`1.250.000`) kembali menjadi angka.
double parseNominalInput(String raw) {
  final bersih = raw.replaceAll(RegExp(r'[^0-9-]'), '');
  return double.tryParse(bersih) ?? 0;
}

/// Tanggal panjang: `2 September 2026`.
/// [padHari] menjadikannya dua digit (`02 September 2026`).
String formatTanggalIndo(DateTime dt, {bool padHari = false}) {
  final hari = padHari ? dt.day.toString().padLeft(2, '0') : '${dt.day}';
  return '$hari ${namaBulanIndo[dt.month]} ${dt.year}';
}

/// Tanggal beserta jam: `2 September 2026, 14:05 WIB`.
String formatTanggalJamIndo(DateTime dt) {
  final jam = dt.hour.toString().padLeft(2, '0');
  final menit = dt.minute.toString().padLeft(2, '0');
  return '${formatTanggalIndo(dt)}, $jam:$menit WIB';
}
