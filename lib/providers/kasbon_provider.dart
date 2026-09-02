import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/hutang.dart';
import '../models/piutang.dart';
import '../providers/usaha_provider.dart';
import '../repositories/hutang_repository.dart';
import '../repositories/piutang_repository.dart';

final hutangListProvider = FutureProvider<List<Hutang>>((ref) async {
  final idUsaha = await ref.watch(currentUsahaIdProvider.future);
  if (idUsaha == null) return [];
  return ref.read(hutangRepositoryProvider).getByUsaha(idUsaha);
});

final piutangListProvider = FutureProvider<List<Piutang>>((ref) async {
  final idUsaha = await ref.watch(currentUsahaIdProvider.future);
  if (idUsaha == null) return [];
  return ref.read(piutangRepositoryProvider).getByUsaha(idUsaha);
});
