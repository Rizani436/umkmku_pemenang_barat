import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'usaha_provider.dart';

/// Menyegarkan seluruh data yang bergantung pada usaha aktif: ringkasan
/// dashboard, riwayat transaksi, daftar hutang & piutang, serta laporan
/// rugi-laba dan neraca.
///
/// Semua provider itu `ref.watch` ke [currentUsahaProvider] (langsung atau
/// lewat `currentUsahaIdProvider`), jadi cukup satu invalidasi di sini dan
/// Riverpod merambatkannya ke seluruh turunannya.
///
/// Sebelumnya tiap layar menulis sendiri blok 4–6 baris `ref.invalidate(...)`
/// setelah menyimpan data — total 91 pemanggilan. Satu saja yang terlewat,
/// layar lain menampilkan angka basi. Panggil fungsi ini sebagai gantinya.
void refreshDataUsaha(WidgetRef ref) {
  ref.invalidate(currentUsahaProvider);
}
