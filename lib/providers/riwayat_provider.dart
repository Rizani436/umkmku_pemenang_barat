import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaksi.dart';
import '../providers/usaha_provider.dart';
import '../repositories/transaksi_repository.dart';

final riwayatProvider = FutureProvider<List<Transaksi>>((ref) async {
  final idUsaha = await ref.watch(currentUsahaIdProvider.future);
  if (idUsaha == null) return [];
  return ref.read(transaksiRepositoryProvider).getByUsaha(idUsaha);
});
