import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:umkmku_pemenang_barat/services/pin_lockout_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PinLockoutService lockout;
  const nomorHP = '081234567890';

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    lockout = PinLockoutService(await SharedPreferences.getInstance());
  });

  test('awalnya tidak terkunci', () {
    expect(lockout.sedangTerkunci(nomorHP), isFalse);
    expect(lockout.sisaKunci(nomorHP), Duration.zero);
  });

  test('sisa kesempatan berkurang tiap kali gagal', () async {
    expect(await lockout.catatGagal(nomorHP), PinLockoutService.maksPercobaan - 1);
    expect(await lockout.catatGagal(nomorHP), PinLockoutService.maksPercobaan - 2);
    expect(lockout.sedangTerkunci(nomorHP), isFalse);
  });

  test('terkunci setelah mencapai batas percobaan', () async {
    int sisa = -1;
    for (var i = 0; i < PinLockoutService.maksPercobaan; i++) {
      sisa = await lockout.catatGagal(nomorHP);
    }

    expect(sisa, 0);
    expect(lockout.sedangTerkunci(nomorHP), isTrue);
    expect(lockout.sisaKunci(nomorHP), greaterThan(Duration.zero));
    expect(lockout.sisaKunci(nomorHP),
        lessThanOrEqualTo(PinLockoutService.durasiKunci));
  });

  test('kunci dihitung per nomor HP, bukan global', () async {
    for (var i = 0; i < PinLockoutService.maksPercobaan; i++) {
      await lockout.catatGagal(nomorHP);
    }

    expect(lockout.sedangTerkunci(nomorHP), isTrue);
    expect(lockout.sedangTerkunci('089999999999'), isFalse);
  });

  test('reset membersihkan hitungan dan kunci setelah PIN benar', () async {
    for (var i = 0; i < PinLockoutService.maksPercobaan; i++) {
      await lockout.catatGagal(nomorHP);
    }
    await lockout.reset(nomorHP);

    expect(lockout.sedangTerkunci(nomorHP), isFalse);
    // Hitungan gagal ikut nol, jadi kesempatan penuh lagi.
    expect(await lockout.catatGagal(nomorHP),
        PinLockoutService.maksPercobaan - 1);
  });
}
