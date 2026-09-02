import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/usaha.dart';
import '../providers/auth_provider.dart';
import '../repositories/usaha_repository.dart';

/// Sumber tunggal data usaha milik akun yang sedang masuk.
/// Provider lain WAJIB turun dari sini, jangan memanggil getUsahaByAkun()
/// sendiri-sendiri (sebelumnya query yang sama diulang di 3 provider).
final currentUsahaProvider = FutureProvider<Usaha?>((ref) async {
  final akun = ref.watch(authControllerProvider).value;
  if (akun == null) return null;
  return ref.read(usahaRepositoryProvider).getUsahaByAkun(akun.id);
});

/// Versi ringkas untuk provider yang hanya butuh id-nya.
final currentUsahaIdProvider = FutureProvider<String?>((ref) async {
  final usaha = await ref.watch(currentUsahaProvider.future);
  return usaha?.id;
});
