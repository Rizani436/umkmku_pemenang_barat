import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/session_provider.dart';

/// Pembatas percobaan PIN.
///
/// PIN hanya 4 angka (10.000 kemungkinan), jadi tanpa pembatas siapa pun yang
/// memegang HP bisa menebaknya dengan sabar. Setelah [maksPercobaan] kali
/// salah, input dikunci selama [durasiKunci], dan hitungannya bertahan
/// walaupun aplikasi ditutup — makanya disimpan di SharedPreferences, bukan
/// di state layar.
class PinLockoutService {
  static const maksPercobaan = 5;
  static const durasiKunci = Duration(minutes: 1);

  static const _prefixGagal = 'pin_gagal_';
  static const _prefixKunci = 'pin_kunci_sampai_';

  final SharedPreferences _prefs;

  PinLockoutService(this._prefs);

  String _keyGagal(String nomorHP) => '$_prefixGagal$nomorHP';
  String _keyKunci(String nomorHP) => '$_prefixKunci$nomorHP';

  /// Sisa waktu kunci, atau [Duration.zero] kalau tidak sedang terkunci.
  Duration sisaKunci(String nomorHP) {
    final sampai = _prefs.getInt(_keyKunci(nomorHP));
    if (sampai == null) return Duration.zero;

    final sisa = DateTime.fromMillisecondsSinceEpoch(sampai)
        .difference(DateTime.now());
    return sisa.isNegative ? Duration.zero : sisa;
  }

  bool sedangTerkunci(String nomorHP) => sisaKunci(nomorHP) > Duration.zero;

  /// Catat satu percobaan gagal. Mengembalikan sisa kesempatan sebelum
  /// terkunci (0 berarti baru saja terkunci).
  Future<int> catatGagal(String nomorHP) async {
    final gagal = (_prefs.getInt(_keyGagal(nomorHP)) ?? 0) + 1;
    await _prefs.setInt(_keyGagal(nomorHP), gagal);

    if (gagal >= maksPercobaan) {
      await _prefs.setInt(
        _keyKunci(nomorHP),
        DateTime.now().add(durasiKunci).millisecondsSinceEpoch,
      );
      await _prefs.remove(_keyGagal(nomorHP));
      return 0;
    }
    return maksPercobaan - gagal;
  }

  /// Dipanggil setelah PIN benar.
  Future<void> reset(String nomorHP) async {
    await _prefs.remove(_keyGagal(nomorHP));
    await _prefs.remove(_keyKunci(nomorHP));
  }
}

final pinLockoutServiceProvider = Provider<PinLockoutService>((ref) {
  return PinLockoutService(ref.read(sharedPreferencesProvider));
});
