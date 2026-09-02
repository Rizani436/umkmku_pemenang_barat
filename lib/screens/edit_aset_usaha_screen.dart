import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/laporan_provider.dart';
import '../providers/usaha_provider.dart';
import '../repositories/usaha_repository.dart';
import '../theme/app_colors.dart';
import '../utils/rupiah_formatter.dart';
import '../utils/format.dart';

class EditAsetUsahaScreen extends ConsumerStatefulWidget {
  final String idUsaha;
  final double currentPersediaan;
  final double currentMesinPeralatan;
  final double currentGedung;

  const EditAsetUsahaScreen({
    super.key,
    required this.idUsaha,
    required this.currentPersediaan,
    required this.currentMesinPeralatan,
    required this.currentGedung,
  });

  @override
  ConsumerState<EditAsetUsahaScreen> createState() => _EditAsetUsahaScreenState();
}

class _EditAsetUsahaScreenState extends ConsumerState<EditAsetUsahaScreen> {
  late TextEditingController _persediaanCtrl;
  late TextEditingController _mesinPeralatanCtrl;
  late TextEditingController _gedungCtrl;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _persediaanCtrl = TextEditingController(text: '0');
    _mesinPeralatanCtrl = TextEditingController(
      text: widget.currentMesinPeralatan > 0 ? formatRibuan(widget.currentMesinPeralatan) : '0',
    );
    _gedungCtrl = TextEditingController(
      text: widget.currentGedung > 0 ? formatRibuan(widget.currentGedung) : '0',
    );
  }

  @override
  void dispose() {
    _persediaanCtrl.dispose();
    _mesinPeralatanCtrl.dispose();
    _gedungCtrl.dispose();
    super.dispose();
  }



  Future<void> _simpanAset() async {
    final rawPersediaan = parseNominalInput(_persediaanCtrl.text);

    final mesinPeralatan = parseNominalInput(_mesinPeralatanCtrl.text);
    final gedung = parseNominalInput(_gedungCtrl.text);

    setState(() => _isSaving = true);

    try {
      final usaha = ref.read(currentUsahaProvider).value;
      final basePersediaan = usaha?.persediaan ?? widget.currentPersediaan;
      final double persediaanFinal = basePersediaan + rawPersediaan;

      if (usaha != null) {
        await ref.read(usahaRepositoryProvider).updateUsaha(
              idUsaha: usaha.id,
              namaUsaha: usaha.namaUsaha,
              jenisUsaha: usaha.jenisUsaha,
              alamat: usaha.alamat,
              persediaan: persediaanFinal,
              mesinPeralatan: mesinPeralatan,
              gedung: gedung,
            );
      }

      ref.invalidate(currentUsahaProvider);
      ref.invalidate(laporanNeracaProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nilai aset usaha berhasil diperbarui!'),
            backgroundColor: Color(0xFF1DB57A),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan data: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    'Kelola Aset Usaha',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  children: [
                    const SizedBox(height: 10),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Atur Nilai Aset Usaha',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Nilai aset ini akan tercatat otomatis pada bagian HARTA (Aktiva) di Laporan Neraca Usaha.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 20),

                          _buildPersediaanField(),
                          const SizedBox(height: 20),

                          _buildAssetField(
                            label: 'Nilai Mesin & Peralatan',
                            hint: 'Masukkan nominal mesin & peralatan',
                            controller: _mesinPeralatanCtrl,
                            icon: Icons.precision_manufacturing_outlined,
                          ),
                          const SizedBox(height: 18),

                          _buildAssetField(
                            label: 'Nilai Gedung / Bangunan',
                            hint: 'Masukkan nominal gedung',
                            controller: _gedungCtrl,
                            icon: Icons.apartment_outlined,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _simpanAset,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5B4FDD),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.check_circle_outline_rounded,
                                size: 20,
                              ),
                        label: Text(
                          _isSaving ? 'Menyimpan...' : 'Simpan Nilai Aset',
                          style: const TextStyle(
                            fontSize: 16,
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
          ],
        ),
      ),
    );
  }

  Widget _buildPersediaanField() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F7FD),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E0FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Tambah Nilai Persediaan / Stok',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                'Saat ini: ${formatRupiah(widget.currentPersediaan)}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          TextField(
            controller: _persediaanCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              CurrencyInputFormatter(),
            ],
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Masukkan nominal tambahan stok',
              prefixIcon: const Icon(Icons.add_shopping_cart_rounded,
                  size: 20, color: Color(0xFF1DB57A)),
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E0FF)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Color(0xFF1DB57A), width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 10),

          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _persediaanCtrl,
            builder: (context, value, _) {
              final rawVal = parseNominalInput(value.text);
              final double totalAkhir = widget.currentPersediaan + rawVal;

              return Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F8F2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFA3E5CE)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Persediaan Baru (+ Tambah Stok):',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      formatRupiah(totalAkhir),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1DB57A),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAssetField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF4B5563),
          ),
        ),
        const SizedBox(height: 6),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    CurrencyInputFormatter(),
                  ],
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF9CA3AF),
                      fontWeight: FontWeight.normal,
                    ),
                    prefixIcon: Icon(icon, size: 20, color: AppColors.primary),
                    filled: true,
                    fillColor: const Color(0xFFF8F7FD),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE5E0FF)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppColors.primary, width: 1.5),
                    ),
                  ),
                ),
                if (value.text.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 4),
                    child: Text(
                      formatRupiah(parseNominalInput(value.text)),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
