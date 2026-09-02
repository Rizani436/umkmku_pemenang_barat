import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/session_provider.dart';
import '../providers/usaha_provider.dart';
import '../theme/app_colors.dart';
import '../providers/laporan_provider.dart';
import 'welcome_screen.dart';
import 'edit_profil_usaha_screen.dart';
import 'edit_aset_usaha_screen.dart';
import 'samakan_uang_laci_screen.dart';
import 'ubah_pin_screen.dart';
import 'backup_pulihkan_screen.dart';
import '../utils/format.dart';

class DataWilayahIndonesia {
  static const Map<String, Map<String, Map<String, List<String>>>> provData = {
    'Nusa Tenggara Barat (NTB)': {
      'Kab. Lombok Utara': {
        'Pemenang': [
          'Desa Pemenang Barat',
          'Desa Pemenang Timur',
          'Desa Malaka',
          'Desa Gili Indah'
        ],
        'Tanjung': [
          'Desa Tanjung',
          'Desa Sokong',
          'Desa Medana',
          'Desa Jenggala',
          'Desa Teniga'
        ],
        'Gangga': [
          'Desa Gondang',
          'Desa Bentek',
          'Desa Genggelang',
          'Desa Rempek',
          'Desa Sambik Bangkol'
        ],
        'Bayan': [
          'Desa Anyar',
          'Desa Bayan',
          'Desa Karang Bajo',
          'Desa Loloan',
          'Desa Sukadana',
          'Desa Senaru'
        ],
        'Kayangan': [
          'Desa Kayangan',
          'Desa Dangiang',
          'Desa Gumantar',
          'Desa Sesait',
          'Desa Pendua'
        ],
      },
      'Kab. Lombok Barat': {
        'Gerung': ['Gerung Utara', 'Gerung Selatan', 'Dasan Tapen', 'Banyu Urip'],
        'Kediri': ['Kediri', 'Kediri Selatan', 'Rumak', 'Montong Are'],
        'Narmada': ['Narmada', 'Lembuak', 'Nyurbaya', 'Suranadi'],
        'Batu Layar': ['Batu Layar', 'Senggigi', 'Meninting', 'Sandik'],
      },
      'Kota Mataram': {
        'Mataram': ['Mataram Timur', 'Pagejahan', 'Pejanggik', 'Punia'],
        'Ampenan': ['Ampenan Selatan', 'Ampenan Utara', 'Bintaro', 'Daya Peken'],
        'Cakranegara': ['Cakranegara Barat', 'Cakranegara Timur', 'Cakra Selatan', 'Mayura'],
        'Sekarbela': ['Jembangan', 'Karang Pule', 'Kekalik Jaya', 'Tanjung Karang'],
      },
      'Kab. Lombok Tengah': {
        'Praya': ['Praya', 'Semayan', 'Tiuh', 'Renteng'],
        'Pujut': ['Sengkol', 'Kuta', 'Rembitan', 'Tanjung Ringgit'],
      },
      'Kab. Lombok Timur': {
        'Selong': ['Selong', 'Keliwates', 'Pancor', 'Rumbuk'],
        'Labuhan Haji': ['Labuhan Haji', 'Korleko', 'Tanjung'],
      },
      'Kab. Sumbawa': {
        'Sumbawa': ['Brang Biji', 'Brang Bara', 'Bugis', 'Lempeh'],
      },
      'Kab. Sumbawa Barat': {
        'Taliwang': ['Kuang', 'Menala', 'Taliwang', 'Sampir'],
      },
      'Kab. Dompu': {
        'Dompu': ['Bada', 'Bali', 'Karijawa', 'Dorotangga'],
      },
      'Kab. Bima': {
        'Woha': ['Raba', 'Penapali', 'Tente', 'Donggo'],
      },
      'Kota Bima': {
        'Rasanae Barat': ['Dara', 'Pane', 'Paruga', 'Nae'],
      },
    },
    'Bali': {
      'Kota Denpasar': {
        'Denpasar Selatan': ['Sanur', 'Sidakarya', 'Renon', 'Panjer'],
        'Denpasar Barat': ['Pemecutan', 'Dauhn Puri', 'Padangsambian'],
      },
      'Kab. Badung': {
        'Kuta': ['Kuta', 'Legian', 'Seminyak'],
        'Kuta Selatan': ['Jimbaran', 'Nusa Dua', 'Pecatu', 'Benoa'],
        'Mengwi': ['Mengwi', 'Sempidi', 'Kapal'],
      },
    },
    'DKI Jakarta': {
      'Jakarta Selatan': {
        'Kebayoran Baru': ['Senayan', 'Gandaria Utara', 'Melawai', 'Pulo'],
        'Cilandak': ['Cilandak Barat', 'Cipete Selatan', 'Pondok Labu'],
      },
      'Jakarta Pusat': {
        'Gambir': ['Gambir', 'Kebon Kelapa', 'Petojo Selatan'],
        'Menteng': ['Menteng', 'Pegangsaan', 'Cikini'],
      },
    },
    'Jawa Barat': {
      'Kota Bandung': {
        'Coblong': ['Dago', 'Lebak Siliwangi', 'Sadang Serang'],
        'Sumur Bandung': ['Braga', 'Kebon Pisang', 'Merdeka'],
      },
    },
    'Jawa Timur': {
      'Kota Surabaya': {
        'Gubeng': ['Gubeng', 'Airlangga', 'Mojo'],
        'Tegalsari': ['Tegalsari', 'Kedungdoro', 'Dr. Soetomo'],
      },
    },
  };

  static const List<String> bidangUsahaList = [
    'Perdagangan / Toko Kelontong',
    'Kuliner / Makanan & Minuman',
    'Jasa & Layanan',
    'Pertanian & Perkebunan',
    'Peternakan & Perikanan',
    'Industri Kreatif & Kerajinan',
    'Fashion & Pakaian',
    'Lainnya',
  ];
}

class ProfilUsahaScreen extends ConsumerStatefulWidget {
  const ProfilUsahaScreen({super.key});

  @override
  ConsumerState<ProfilUsahaScreen> createState() => _ProfilUsahaScreenState();
}

class _ProfilUsahaScreenState extends ConsumerState<ProfilUsahaScreen> {











  Future<void> _handleRefresh() async {
    ref.invalidate(currentUsahaProvider);
    ref.invalidate(authControllerProvider);
    ref.invalidate(laporanNeracaProvider);
    try {
      await Future.wait([
        ref.read(currentUsahaProvider.future),
        ref.read(authControllerProvider.future),
        ref.read(laporanNeracaProvider.future),
      ]);
    } catch (_) {}
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Keluar dari Aplikasi?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFFFF5A5A),
          ),
        ),
        content: const Text(
          'Anda perlu memasukkan PIN kembali saat membuka aplikasi berikutnya.',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref.read(sessionServiceProvider).hapus();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5A5A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final usahaAsync = ref.watch(currentUsahaProvider);
    final akunAsync = ref.watch(authControllerProvider);
    final neracaAsync = ref.watch(laporanNeracaProvider);

    final usaha = usahaAsync.value;
    final akun = akunAsync.value;

    final namaUsaha = (usaha?.namaUsaha.isNotEmpty ?? false) ? usaha!.namaUsaha : '-';
    final jenisUsaha = (usaha?.jenisUsaha.isNotEmpty ?? false) ? usaha!.jenisUsaha : '-';
    final namaPemilik = (akun?.namaPemilik.isNotEmpty ?? false) ? akun!.namaPemilik : '-';
    final alamat = (usaha?.alamat?.isNotEmpty ?? false) ? usaha!.alamat! : '-';
    final nomorHP = (akun?.nomorHP.isNotEmpty ?? false) ? akun!.nomorHP : '-';
    final persediaan = neracaAsync.value?.persediaan ?? usaha?.persediaan ?? 0;
    final mesinPeralatan = usaha?.mesinPeralatan ?? 0;
    final gedung = usaha?.gedung ?? 0;
    final kas = usaha?.kas ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9FE),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: AppColors.textPrimary,
                        size: 22,
                      ),
                    ),
                  ),
                  const Text(
                    'Profil Usaha',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      onPressed: _handleRefresh,
                      tooltip: 'Refresh Data',
                      icon: const Icon(
                        Icons.refresh_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: RefreshIndicator(
                onRefresh: _handleRefresh,
                color: AppColors.primary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Column(
                  children: [
                    const SizedBox(height: 10),

                    Text(
                      namaUsaha,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F0FF),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: const Color(0xFFD0C9FF), width: 1),
                      ),
                      child: Text(
                        jenisUsaha,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _infoTile(
                            icon: Icons.person_rounded,
                            label: 'Nama Pemilik',
                            value: namaPemilik,
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Divider(height: 1, color: Color(0xFFEEEDF5)),
                          ),
                          _infoTile(
                            icon: Icons.location_on_rounded,
                            label: 'Alamat',
                            value: alamat,
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Divider(height: 1, color: Color(0xFFEEEDF5)),
                          ),
                          _infoTile(
                            icon: Icons.smartphone_rounded,
                            label: 'Nomor HP',
                            value: nomorHP,
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Divider(height: 1, color: Color(0xFFEEEDF5)),
                          ),
                          _infoTile(
                            icon: Icons.inventory_2_outlined,
                            label: 'Persediaan',
                            value: formatRupiah(persediaan),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Divider(height: 1, color: Color(0xFFEEEDF5)),
                          ),
                          _infoTile(
                            icon: Icons.precision_manufacturing_outlined,
                            label: 'Mesin & Peralatan',
                            value: formatRupiah(mesinPeralatan),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Divider(height: 1, color: Color(0xFFEEEDF5)),
                          ),
                          _infoTile(
                            icon: Icons.apartment_outlined,
                            label: 'Gedung / Bangunan',
                            value: formatRupiah(gedung),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _menuTile(
                            icon: Icons.account_balance_wallet_outlined,
                            title: 'Samakan Uang Laci',
                            onTap: () {
                              if (usaha != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => SamakanUangLaciScreen(
                                      idUsaha: usaha.id,
                                      currentKas: kas,
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Divider(height: 1, color: Color(0xFFEEEDF5)),
                          ),
                          _menuTile(
                            icon: Icons.account_balance_outlined,
                            title: 'Kelola Aset Usaha',
                            onTap: () {
                              if (usaha != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => EditAsetUsahaScreen(
                                      idUsaha: usaha.id,
                                      currentPersediaan: persediaan,
                                      currentMesinPeralatan: mesinPeralatan,
                                      currentGedung: gedung,
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Divider(height: 1, color: Color(0xFFEEEDF5)),
                          ),
                          _menuTile(
                            icon: Icons.cloud_sync_outlined,
                            title: 'Backup & Pulihkan Data',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const BackupPulihkanScreen(),
                                ),
                              );
                            },
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Divider(height: 1, color: Color(0xFFEEEDF5)),
                          ),
                          _menuTile(
                            icon: Icons.lock_outline_rounded,
                            title: 'Ubah PIN',
                            onTap: () {
                              if (akun != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => UbahPinScreen(
                                      idAkun: akun.id,
                                      namaUsaha: namaUsaha,
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          if (usaha != null && akun != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EditProfilUsahaScreen(
                                  idUsaha: usaha.id,
                                  idAkun: akun.id,
                                  currentNamaUsaha: namaUsaha,
                                  currentJenisUsaha: jenisUsaha,
                                  currentNamaPemilik: namaPemilik,
                                  currentAlamat: alamat,
                                  currentNomorHP: nomorHP,
                                ),
                              ),
                            );
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(
                              color: AppColors.primary, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text(
                          'Edit Profile',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: () => _confirmLogout(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFFF5A5A),
                          backgroundColor: const Color(0xFFFFF5F5),
                          side: const BorderSide(
                              color: Color(0xFFFFC1C1), width: 1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.exit_to_app_rounded, size: 18),
                        label: const Text(
                          'Keluar / Logout',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
  }

  Widget _infoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F0FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _menuTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F0FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
