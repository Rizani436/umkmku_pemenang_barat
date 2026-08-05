import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/hutang.dart';
import '../models/piutang.dart';
import '../providers/auth_provider.dart';
import '../repositories/hutang_repository.dart';
import '../repositories/piutang_repository.dart';
import '../repositories/usaha_repository.dart';

final hutangListProvider = FutureProvider<List<Hutang>>((ref) async {
  final akun = ref.watch(authControllerProvider).value;
  if (akun == null) return [];
  final usaha = await ref.read(usahaRepositoryProvider).getUsahaByAkun(akun.id);
  if (usaha == null) return [];
  return ref.read(hutangRepositoryProvider).getByUsaha(usaha.id);
});

final piutangListProvider = FutureProvider<List<Piutang>>((ref) async {
  final akun = ref.watch(authControllerProvider).value;
  if (akun == null) return [];
  final usaha = await ref.read(usahaRepositoryProvider).getUsahaByAkun(akun.id);
  if (usaha == null) return [];
  return ref.read(piutangRepositoryProvider).getByUsaha(usaha.id);
});
