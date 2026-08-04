import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/hutang_repository.dart';
import '../repositories/piutang_repository.dart';
import '../repositories/transaksi_repository.dart';
import 'usaha_provider.dart';



enum TrendKeuntungan { naik, turun, netral }



enum JatuhTempoJenis { hutang, piutang }


class JatuhTempoItem {
  final String id;
  final String nama;
  final double nominal;
  final DateTime? tglJatuhTempo;
  final JatuhTempoJenis jenis;

  const JatuhTempoItem({
    required this.id,
    required this.nama,
    required this.nominal,
    this.tglJatuhTempo,
    required this.jenis,
  });


  int get selisihHari {
    if (tglJatuhTempo == null) return 9999;
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final tglDate = DateTime(
      tglJatuhTempo!.year,
      tglJatuhTempo!.month,
      tglJatuhTempo!.day,
    );
    return tglDate.difference(todayDate).inDays;
  }


  String get labelJatuhTempo {
    if (tglJatuhTempo == null) return '-';
    final diff = selisihHari;
    if (diff < 0) return 'Terlambat ${-diff}h';
    if (diff == 0) return 'Hari Ini';
    if (diff == 1) return 'Besok';
    if (diff == 2) return 'Lusa';
    return '$diff hari';
  }
}


class DashboardSummary {
  final double uangMasukHariIni;
  final double uangKeluarHariIni;
  final double keuntunganHariIni;
  final double keuntunganKemarin;
  final double totalPiutang;
  final double totalHutang;
  final List<JatuhTempoItem> jatuhTempoTerdekat;

  const DashboardSummary({
    required this.uangMasukHariIni,
    required this.uangKeluarHariIni,
    required this.keuntunganHariIni,
    required this.keuntunganKemarin,
    required this.totalPiutang,
    required this.totalHutang,
    required this.jatuhTempoTerdekat,
  });


  TrendKeuntungan get trend {
    if (keuntunganHariIni > keuntunganKemarin) return TrendKeuntungan.naik;
    if (keuntunganHariIni < keuntunganKemarin) return TrendKeuntungan.turun;
    return TrendKeuntungan.netral;
  }

  static const kosong = DashboardSummary(
    uangMasukHariIni: 0,
    uangKeluarHariIni: 0,
    keuntunganHariIni: 0,
    keuntunganKemarin: 0,
    totalPiutang: 0,
    totalHutang: 0,
    jatuhTempoTerdekat: [],
  );
}





final dashboardSummaryProvider = FutureProvider<DashboardSummary>((ref) async {
  final usahaAsync = ref.watch(currentUsahaProvider);
  final usaha = usahaAsync.value;
  if (usaha == null) return DashboardSummary.kosong;

  final idUsaha = usaha.id;
  final transaksiRepo = ref.read(transaksiRepositoryProvider);
  final hutangRepo = ref.read(hutangRepositoryProvider);
  final piutangRepo = ref.read(piutangRepositoryProvider);


  final results = await Future.wait([
    transaksiRepo.getMasukHariIni(idUsaha),
    transaksiRepo.getKeluarHariIni(idUsaha),
    transaksiRepo.getMasukKemarin(idUsaha),
    transaksiRepo.getKeluarKemarin(idUsaha),
    piutangRepo.getTotalPiutang(idUsaha),
    hutangRepo.getTotalHutang(idUsaha),
  ]);

  final masukHariIni = results[0];
  final keluarHariIni = results[1];
  final masukKemarin = results[2];
  final keluarKemarin = results[3];
  final totalPiutang = results[4];
  final totalHutang = results[5];


  final hutangList = await hutangRepo.getJatuhTempoTerdekat(idUsaha, limit: 5);
  final piutangList =
      await piutangRepo.getJatuhTempoTerdekat(idUsaha, limit: 5);

  final jatuhTempo = [
    ...hutangList.map(
      (h) => JatuhTempoItem(
        id: h.id,
        nama: h.namaToko,
        nominal: h.nominal,
        tglJatuhTempo: h.tglJatuhTempo,
        jenis: JatuhTempoJenis.hutang,
      ),
    ),
    ...piutangList.map(
      (p) => JatuhTempoItem(
        id: p.id,
        nama: p.namaOrang,
        nominal: p.nominal,
        tglJatuhTempo: p.tglJatuhTempo,
        jenis: JatuhTempoJenis.piutang,
      ),
    ),
  ]..sort((a, b) => a.selisihHari.compareTo(b.selisihHari));

  return DashboardSummary(
    uangMasukHariIni: masukHariIni,
    uangKeluarHariIni: keluarHariIni,
    keuntunganHariIni: masukHariIni - keluarHariIni,
    keuntunganKemarin: masukKemarin - keluarKemarin,
    totalPiutang: totalPiutang,
    totalHutang: totalHutang,
    jatuhTempoTerdekat: jatuhTempo.take(5).toList(),
  );
});
