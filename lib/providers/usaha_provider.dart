import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/usaha.dart';
import '../providers/auth_provider.dart';
import '../repositories/usaha_repository.dart';



final currentUsahaProvider = FutureProvider<Usaha?>((ref) async {

  final authAsync = ref.watch(authControllerProvider);
  final akun = authAsync.value;
  if (akun == null) return null;
  return ref.read(usahaRepositoryProvider).getUsahaByAkun(akun.id);
});
