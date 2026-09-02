import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:umkmku_pemenang_barat/models/usaha.dart';
import 'package:umkmku_pemenang_barat/providers/dashboard_provider.dart';
import 'package:umkmku_pemenang_barat/screens/daftar_usaha_screen.dart';
import 'package:umkmku_pemenang_barat/screens/dashboard/beranda_tab.dart';

/// Flutter melaporkan RenderFlex overflow sebagai error, dan `flutter_test`
/// menjadikannya kegagalan tes. Jadi cukup merender layar di lebar HP yang
/// sempit untuk membuktikan tidak ada lagi tulisan "OVERFLOWED BY ... PIXELS".
class _TanggalTetap extends DashboardDateNotifier {
  _TanggalTetap(this._tanggal);
  final DateTime _tanggal;

  @override
  DateTime build() => _tanggal;
}

void main() {
  final usaha = Usaha(
    id: 'u1',
    namaUsaha: 'Warung Sri',
    jenisUsaha: 'perdagangan',
    kas: 500000,
    idAkun: 'a1',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  Future<void> pumpBeranda(
    WidgetTester tester, {
    required DateTime tanggal,
    required DashboardSummary summary,
    Size ukuran = const Size(360, 800),
  }) async {
    tester.view.physicalSize = ukuran;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardDateProvider.overrideWith(() => _TanggalTetap(tanggal)),
          dashboardSummaryProvider.overrideWith((ref) async => summary),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: BerandaTab(usahaAsync: AsyncData(usaha)),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  const summaryRugi = DashboardSummary(
    uangMasukHariIni: 150000,
    uangKeluarHariIni: 900000,
    keuntunganHariIni: -750000,
    keuntunganKemarin: 100000,
    totalPiutang: 1250000,
    totalHutang: 3400000,
    saldoKas: -250000,
    jatuhTempoTerdekat: [],
  );

  testWidgets('beranda tidak overflow saat tanggal sebelumnya dipilih',
      (tester) async {
    // Kasus terburuk: label memanjang jadi "Defisit / Rugi Tanggal Ini",
    // chip tanggal berisi bulan terpanjang, dan tombol "Kembali ke Hari Ini"
    // ikut muncul. Inilah kombinasi yang dulu overflow 24 piksel.
    await pumpBeranda(
      tester,
      tanggal: DateTime(2025, 9, 30),
      summary: summaryRugi,
    );

    expect(find.text('Defisit / Rugi Tanggal Ini'), findsOneWidget);
    expect(find.text('Kembali ke Hari Ini'), findsOneWidget);
  });

  testWidgets('beranda tidak overflow di layar sangat sempit', (tester) async {
    await pumpBeranda(
      tester,
      tanggal: DateTime(2025, 12, 31),
      summary: summaryRugi,
      ukuran: const Size(320, 700),
    );

    expect(find.byType(BerandaTab), findsOneWidget);
  });

  testWidgets('kolom sektor usaha tidak overflow di layar sempit',
      (tester) async {
    // Hint 'Perdagangan/Jasa/Manufaktur' lebih lebar dari kolomnya; tanpa
    // isExpanded, DropdownButtonFormField meluber ke kanan 30 piksel.
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: DaftarUsahaScreen()));
    await tester.pump();

    expect(find.text('Sektor Usaha'), findsOneWidget);
  });

  testWidgets('beranda hari ini tetap normal', (tester) async {
    final hariIni = DateTime.now();
    await pumpBeranda(
      tester,
      tanggal: DateTime(hariIni.year, hariIni.month, hariIni.day),
      summary: DashboardSummary.kosong,
    );

    expect(find.text('Keuntungan Hari Ini'), findsOneWidget);
    expect(find.text('Kembali ke Hari Ini'), findsNothing);
  });
}
