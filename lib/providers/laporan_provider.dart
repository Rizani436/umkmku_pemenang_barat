import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/transaksi_repository.dart';
import '../repositories/hutang_repository.dart';
import '../repositories/piutang_repository.dart';
import 'usaha_provider.dart';


enum PeriodeLaporan {
  bulanIni,
  bulanLalu,
  pilihBulan,
  rentangTanggal,
  enamBulanTerakhir,
  tahunIni,
  semua,
}


class FilterPeriodeState {
  final PeriodeLaporan jenis;
  final int month;
  final int year;
  final DateTime? customStart;
  final DateTime? customEnd;

  const FilterPeriodeState({
    required this.jenis,
    required this.month,
    required this.year,
    this.customStart,
    this.customEnd,
  });

  factory FilterPeriodeState.defaultState() {
    final now = DateTime.now();
    return FilterPeriodeState(
      jenis: PeriodeLaporan.bulanIni,
      month: now.month,
      year: now.year,
    );
  }

  FilterPeriodeState copyWith({
    PeriodeLaporan? jenis,
    int? month,
    int? year,
    DateTime? customStart,
    DateTime? customEnd,
  }) {
    return FilterPeriodeState(
      jenis: jenis ?? this.jenis,
      month: month ?? this.month,
      year: year ?? this.year,
      customStart: customStart ?? this.customStart,
      customEnd: customEnd ?? this.customEnd,
    );
  }

  (DateTime start, DateTime end) get rentang {
    final now = DateTime.now();
    switch (jenis) {
      case PeriodeLaporan.bulanIni:
        return (
          DateTime(now.year, now.month, 1),
          DateTime(now.year, now.month + 1, 1),
        );
      case PeriodeLaporan.bulanLalu:
        final dt = DateTime(now.year, now.month - 1, 1);
        return (
          dt,
          DateTime(now.year, now.month, 1),
        );
      case PeriodeLaporan.pilihBulan:
        return (
          DateTime(year, month, 1),
          DateTime(year, month + 1, 1),
        );
      case PeriodeLaporan.rentangTanggal:
        final s = customStart ?? DateTime(now.year, now.month, 1);
        final e = customEnd ?? DateTime(now.year, now.month + 1, 1);
        return (
          DateTime(s.year, s.month, s.day),
          DateTime(e.year, e.month, e.day + 1),
        );
      case PeriodeLaporan.enamBulanTerakhir:
        return (
          DateTime(now.year, now.month - 5, 1),
          DateTime(now.year, now.month + 1, 1),
        );
      case PeriodeLaporan.tahunIni:
        return (
          DateTime(now.year, 1, 1),
          DateTime(now.year + 1, 1, 1),
        );
      case PeriodeLaporan.semua:
        return (
          DateTime(2000, 1, 1),
          DateTime(now.year + 1, 1, 1),
        );
    }
  }

  String get label {
    const namaBulanLengkap = [
      '',
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    const namaBulanSingkat = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Ags',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];

    switch (jenis) {
      case PeriodeLaporan.bulanIni:
        return 'Bulan Ini';
      case PeriodeLaporan.bulanLalu:
        return 'Bulan Lalu';
      case PeriodeLaporan.pilihBulan:
        return '${namaBulanLengkap[month]} $year';
      case PeriodeLaporan.rentangTanggal:
        if (customStart != null && customEnd != null) {
          return '${customStart!.day} ${namaBulanSingkat[customStart!.month]} - ${customEnd!.day} ${namaBulanSingkat[customEnd!.month]} ${customEnd!.year}';
        }
        return 'Rentang Tanggal';
      case PeriodeLaporan.enamBulanTerakhir:
        return '6 Bulan Terakhir';
      case PeriodeLaporan.tahunIni:
        return 'Tahun Ini';
      case PeriodeLaporan.semua:
        return 'Semua';
    }
  }

  String get detailLabel {
    const namaBulanLengkap = [
      '',
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    final now = DateTime.now();

    switch (jenis) {
      case PeriodeLaporan.bulanIni:
        return '${namaBulanLengkap[now.month]} ${now.year}';
      case PeriodeLaporan.bulanLalu:
        final dt = DateTime(now.year, now.month - 1, 1);
        return '${namaBulanLengkap[dt.month]} ${dt.year}';
      case PeriodeLaporan.pilihBulan:
        return '${namaBulanLengkap[month]} $year';
      case PeriodeLaporan.rentangTanggal:
        if (customStart != null && customEnd != null) {
          return '${customStart!.day} ${namaBulanLengkap[customStart!.month]} ${customStart!.year} - ${customEnd!.day} ${namaBulanLengkap[customEnd!.month]} ${customEnd!.year}';
        }
        return 'Rentang Tanggal';
      case PeriodeLaporan.enamBulanTerakhir:
        final dtStart = DateTime(now.year, now.month - 5, 1);
        return '${namaBulanLengkap[dtStart.month]} ${dtStart.year} - ${namaBulanLengkap[now.month]} ${now.year}';
      case PeriodeLaporan.tahunIni:
        return 'Tahun ${now.year}';
      case PeriodeLaporan.semua:
        return 'Semua Periode';
    }
  }
}


class PeriodeLaporanNotifier extends Notifier<FilterPeriodeState> {
  @override
  FilterPeriodeState build() => FilterPeriodeState.defaultState();

  void ubahJenis(PeriodeLaporan jenis) {
    state = state.copyWith(jenis: jenis);
  }

  void setBulanSpesifik(int month, int year) {
    state = FilterPeriodeState(
      jenis: PeriodeLaporan.pilihBulan,
      month: month,
      year: year,
    );
  }

  void setRentangTanggal(DateTime start, DateTime end) {
    state = FilterPeriodeState(
      jenis: PeriodeLaporan.rentangTanggal,
      month: start.month,
      year: start.year,
      customStart: start,
      customEnd: end,
    );
  }
}

final periodeLaporanProvider =
    NotifierProvider<PeriodeLaporanNotifier, FilterPeriodeState>(
  PeriodeLaporanNotifier.new,
);


class LaporanRugiLaba {
  final double totalPendapatan;
  final double totalPengeluaran;

  const LaporanRugiLaba({
    required this.totalPendapatan,
    required this.totalPengeluaran,
  });

  double get penghasilanKotor => totalPendapatan - totalPengeluaran;

  static const kosong = LaporanRugiLaba(
    totalPendapatan: 0,
    totalPengeluaran: 0,
  );
}


class LaporanNeraca {
  final double kas;
  final double piutang;
  final double persediaan;
  final double mesinPeralatan;
  final double gedung;

  final double hutang;
  final double penghasilanKotor;

  const LaporanNeraca({
    required this.kas,
    required this.piutang,
    this.persediaan = 0,
    this.mesinPeralatan = 0,
    this.gedung = 0,
    required this.hutang,
    required this.penghasilanKotor,
  });

  double get totalHarta => kas + piutang + persediaan + mesinPeralatan + gedung;

  double get modal => totalHarta - hutang - penghasilanKotor;

  double get totalDana => hutang + modal + penghasilanKotor;

  bool get seimbang => (totalHarta - totalDana).abs() < 1;

  static const kosong = LaporanNeraca(
    kas: 0,
    piutang: 0,
    persediaan: 0,
    mesinPeralatan: 0,
    gedung: 0,
    hutang: 0,
    penghasilanKotor: 0,
  );
}


final laporanRugiLabaProvider = FutureProvider<LaporanRugiLaba>((ref) async {
  final usahaAsync = ref.watch(currentUsahaProvider);
  final usaha = usahaAsync.value;
  if (usaha == null) return LaporanRugiLaba.kosong;

  final filter = ref.watch(periodeLaporanProvider);
  final (start, end) = filter.rentang;
  final idUsaha = usaha.id;

  final transaksiRepo = ref.read(transaksiRepositoryProvider);

  final results = await Future.wait([
    transaksiRepo.getSumByPeriode(idUsaha, 'pemasukan', start, end),
    transaksiRepo.getSumByPeriode(idUsaha, 'pengeluaran', start, end),
  ]);

  return LaporanRugiLaba(
    totalPendapatan: results[0],
    totalPengeluaran: results[1],
  );
});


final laporanNeracaProvider = FutureProvider<LaporanNeraca>((ref) async {
  final usahaAsync = ref.watch(currentUsahaProvider);
  final usaha = usahaAsync.value;
  if (usaha == null) return LaporanNeraca.kosong;

  final idUsaha = usaha.id;
  final filter = ref.watch(periodeLaporanProvider);
  final (start, end) = filter.rentang;

  final transaksiRepo = ref.read(transaksiRepositoryProvider);
  final hutangRepo = ref.read(hutangRepositoryProvider);
  final piutangRepo = ref.read(piutangRepositoryProvider);

  final results = await Future.wait([
    transaksiRepo.getSumAllTime(idUsaha, 'pemasukan'),
    transaksiRepo.getSumAllTime(idUsaha, 'pengeluaran'),
    piutangRepo.getTotalPiutang(idUsaha),
    hutangRepo.getTotalHutang(idUsaha),
    transaksiRepo.getSumByPeriode(idUsaha, 'pemasukan', start, end),
    transaksiRepo.getSumByPeriode(idUsaha, 'pengeluaran', start, end),
    transaksiRepo.getTotalPengeluaranStokAll(idUsaha),
    transaksiRepo.getTotalPemasukanPenjualanAll(idUsaha),
  ]);

  final totalPemasukanAll = results[0];
  final totalPengeluaranAll = results[1];
  final piutangTotal = results[2];
  final hutangTotal = results[3];
  final totalPengeluaranStok = results[6];
  final totalPemasukanPenjualan = results[7];

  final kasCalc = usaha.kas + totalPemasukanAll - totalPengeluaranAll;
  final kasTotal = kasCalc < 0 ? 0.0 : kasCalc;

  final sisaPersediaan = usaha.persediaan + totalPengeluaranStok - totalPemasukanPenjualan;
  final persediaanReal = sisaPersediaan < 0 ? 0.0 : sisaPersediaan;

  return LaporanNeraca(
    kas: kasTotal,
    piutang: piutangTotal,
    persediaan: persediaanReal,
    mesinPeralatan: usaha.mesinPeralatan,
    gedung: usaha.gedung,
    hutang: hutangTotal,
    penghasilanKotor: results[4] - results[5],
  );
});
