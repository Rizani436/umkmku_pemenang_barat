import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaksi.dart';
import '../providers/auth_provider.dart';
import '../repositories/transaksi_repository.dart';
import '../repositories/usaha_repository.dart';

final riwayatProvider = FutureProvider<List<Transaksi>>((ref) async {
  final authAsync = ref.watch(authControllerProvider);
  final akun = authAsync.value;
  if (akun == null) return [];

  final usaha =
      await ref.read(usahaRepositoryProvider).getUsahaByAkun(akun.id);
  if (usaha == null) return [];

  return ref.read(transaksiRepositoryProvider).getByUsaha(usaha.id);
});
