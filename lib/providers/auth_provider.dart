import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/akun.dart';
import '../providers/session_provider.dart';
import '../repositories/auth_repository.dart';


typedef AuthState = Akun?;





class AuthController extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {

    final session = ref.read(sessionServiceProvider);
    final savedId = session.muatIdAkun();

    if (savedId != null) {
      final akun =
          await ref.read(authRepositoryProvider).getById(savedId);
      if (akun != null) return akun;

      await session.hapus();
    }

    return null;
  }

  Future<void> daftar({
    required String namaPemilik,
    required String nomorHP,
    required String pin,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final akun = await ref.read(authRepositoryProvider).daftar(
            namaPemilik: namaPemilik,
            nomorHP: nomorHP,
            pin: pin,
          );

      await ref.read(sessionServiceProvider).simpan(akun.id);
      return akun;
    });
  }

  Future<void> masuk({required String nomorHP, required String pin}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final akun = await ref.read(authRepositoryProvider).masuk(
            nomorHP: nomorHP,
            pin: pin,
          );

      await ref.read(sessionServiceProvider).simpan(akun.id);
      return akun;
    });
  }

  Future<void> keluar() async {

    await ref.read(sessionServiceProvider).hapus();
    state = const AsyncData(null);
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthState>(AuthController.new);
