import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../repositories/auth_repository.dart';
import '../repositories/usaha_repository.dart';
import '../services/wilayah_service.dart';
import '../theme/app_colors.dart';
import '../providers/refresh.dart';

class EditProfilUsahaScreen extends ConsumerStatefulWidget {
  final String idUsaha;
  final String idAkun;
  final String currentNamaUsaha;
  final String currentJenisUsaha;
  final String currentNamaPemilik;
  final String currentAlamat;
  final String currentNomorHP;

  const EditProfilUsahaScreen({
    super.key,
    required this.idUsaha,
    required this.idAkun,
    required this.currentNamaUsaha,
    required this.currentJenisUsaha,
    required this.currentNamaPemilik,
    required this.currentAlamat,
    required this.currentNomorHP,
  });

  @override
  ConsumerState<EditProfilUsahaScreen> createState() =>
      _EditProfilUsahaScreenState();
}

class _EditProfilUsahaScreenState extends ConsumerState<EditProfilUsahaScreen> {
  late TextEditingController _namaPemilikCtrl;
  late TextEditingController _namaUsahaCtrl;
  late TextEditingController _nomorHPCtrl;
  late TextEditingController _alamatCtrl;

  late String _selectedSektor;
  bool _isSaving = false;

  final List<String> _sektorOptions = [
    'Perdagangan',
    'Jasa',
    'Manufaktur',
  ];

  @override
  void initState() {
    super.initState();
    _namaPemilikCtrl = TextEditingController(
        text: widget.currentNamaPemilik == '-' ? '' : widget.currentNamaPemilik);
    _namaUsahaCtrl = TextEditingController(
        text: widget.currentNamaUsaha == '-' ? '' : widget.currentNamaUsaha);
    _nomorHPCtrl = TextEditingController(
        text: widget.currentNomorHP == '-' ? '' : widget.currentNomorHP);
    _alamatCtrl = TextEditingController(
        text: widget.currentAlamat == '-' ? '' : widget.currentAlamat);

    _selectedSektor = _sektorOptions.contains(widget.currentJenisUsaha)
        ? widget.currentJenisUsaha
        : 'Perdagangan';
  }

  @override
  void dispose() {
    _namaPemilikCtrl.dispose();
    _namaUsahaCtrl.dispose();
    _nomorHPCtrl.dispose();
    _alamatCtrl.dispose();
    super.dispose();
  }

  void _showAddressPicker() {
    final allProvinces = WilayahOfflineService.getProvinces();
    String selectedProv = 'Nusa Tenggara Barat (NTB)';
    if (!allProvinces.contains(selectedProv)) {
      selectedProv = allProvinces.first;
    }

    List<String> availableKabs = WilayahOfflineService.getRegencies(selectedProv);
    String selectedKab = availableKabs.isNotEmpty ? availableKabs.first : '';

    List<String> availableKecs = WilayahOfflineService.getDistricts(selectedProv, selectedKab);
    String selectedKec = availableKecs.isNotEmpty ? availableKecs.first : '';

    List<String> availableDesas = WilayahOfflineService.getVillages(selectedProv, selectedKab, selectedKec);
    String selectedDesa = availableDesas.isNotEmpty ? availableDesas.first : '';

    final detailJalanCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (bottomContext, setModalState) {
            availableKabs = WilayahOfflineService.getRegencies(selectedProv);
            if (!availableKabs.contains(selectedKab)) {
              selectedKab = availableKabs.isNotEmpty ? availableKabs.first : '';
            }

            availableKecs = WilayahOfflineService.getDistricts(selectedProv, selectedKab);
            if (!availableKecs.contains(selectedKec)) {
              selectedKec = availableKecs.isNotEmpty ? availableKecs.first : '';
            }

            availableDesas = WilayahOfflineService.getVillages(selectedProv, selectedKab, selectedKec);
            if (!availableDesas.contains(selectedDesa)) {
              selectedDesa = availableDesas.isNotEmpty ? availableDesas.first : '';
            }

            final parts = <String>[];
            if (detailJalanCtrl.text.trim().isNotEmpty) {
              parts.add(detailJalanCtrl.text.trim());
            }
            if (selectedDesa.isNotEmpty) parts.add(selectedDesa);
            if (selectedKec.isNotEmpty) parts.add('Kec. $selectedKec');
            if (selectedKab.isNotEmpty) parts.add(selectedKab);
            if (selectedProv.isNotEmpty) parts.add('Prov. $selectedProv');
            final previewText = parts.join(', ');

            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(bottomContext).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Pilih Alamat Wilayah Usaha',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(bottomContext),
                          icon: const Icon(Icons.close_rounded,
                              color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 10),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('1. Provinsi',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textSecondary)),               
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: allProvinces.contains(selectedProv)
                              ? selectedProv
                              : null,
                          items: allProvinces.map((prov) {
                            return DropdownMenuItem(
                                value: prov,
                                child: Text(prov,
                                    style: const TextStyle(fontSize: 13)));
                          }).toList(),
                          onChanged: (val) {
                            if (val == null) return;
                            setModalState(() {
                              selectedProv = val;
                              final kabs = WilayahOfflineService.getRegencies(selectedProv);
                              selectedKab = kabs.isNotEmpty ? kabs.first : '';
                              final kecs = WilayahOfflineService.getDistricts(selectedProv, selectedKab);
                              selectedKec = kecs.isNotEmpty ? kecs.first : '';
                              final desas = WilayahOfflineService.getVillages(selectedProv, selectedKab, selectedKec);
                              selectedDesa = desas.isNotEmpty ? desas.first : '';
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    const Text('2. Kabupaten / Kota',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: availableKabs.contains(selectedKab)
                              ? selectedKab
                              : null,
                          items: availableKabs.map((kab) {
                            return DropdownMenuItem(
                                value: kab,
                                child: Text(kab,
                                    style: const TextStyle(fontSize: 13)));
                          }).toList(),
                          onChanged: (val) {
                            if (val == null) return;
                            setModalState(() {
                              selectedKab = val;
                              final kecs = WilayahOfflineService.getDistricts(selectedProv, selectedKab);
                              selectedKec = kecs.isNotEmpty ? kecs.first : '';
                              final desas = WilayahOfflineService.getVillages(selectedProv, selectedKab, selectedKec);
                              selectedDesa = desas.isNotEmpty ? desas.first : '';
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    const Text('3. Kecamatan',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: availableKecs.contains(selectedKec)
                              ? selectedKec
                              : null,
                          items: availableKecs.map((kec) {
                            return DropdownMenuItem(
                                value: kec,
                                child: Text(kec,
                                    style: const TextStyle(fontSize: 13)));
                          }).toList(),
                          onChanged: (val) {
                            if (val == null) return;
                            setModalState(() {
                              selectedKec = val;
                              final desas = WilayahOfflineService.getVillages(selectedProv, selectedKab, selectedKec);
                              selectedDesa = desas.isNotEmpty ? desas.first : '';
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    const Text('4. Desa / Kelurahan',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: availableDesas.contains(selectedDesa)
                              ? selectedDesa
                              : null,
                          items: availableDesas.map((desa) {
                            return DropdownMenuItem(
                                value: desa,
                                child: Text(desa,
                                    style: const TextStyle(fontSize: 13)));
                          }).toList(),
                          onChanged: (val) {
                            if (val == null) return;
                            setModalState(() {
                              selectedDesa = val;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    const Text('5. Detail Jalan / Dusun / RT RW (Opsional)',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: detailJalanCtrl,
                      onChanged: (_) => setModalState(() {}),
                      decoration: const InputDecoration(
                        hintText: 'Contoh: Jl. Bangsal Utama No. 45',
                        prefixIcon:
                            Icon(Icons.edit_location_alt_rounded, size: 18),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F0FF),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFD0C9FF)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Pratinjau Alamat Lengkap:',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary)),
                          const SizedBox(height: 4),
                          Text(
                            previewText,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _alamatCtrl.text = previewText;
                          });
                          Navigator.pop(bottomContext);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Gunakan Alamat Ini',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _simpanPerubahan() async {
    final newNamaPemilik = _namaPemilikCtrl.text.trim();
    final newNamaUsaha = _namaUsahaCtrl.text.trim();
    final newNomorHP = _nomorHPCtrl.text.trim();
    final newAlamat = _alamatCtrl.text.trim();

    if (newNamaPemilik.isEmpty || newNamaUsaha.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nama Pemilik & Nama Usaha wajib diisi!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await ref.read(usahaRepositoryProvider).updateUsaha(
            idUsaha: widget.idUsaha,
            namaUsaha: newNamaUsaha,
            jenisUsaha: _selectedSektor,
            alamat: newAlamat,
          );

      await ref.read(authRepositoryProvider).updateAkun(
            idAkun: widget.idAkun,
            namaPemilik: newNamaPemilik,
            nomorHP: newNomorHP,
          );

      refreshDataUsaha(ref);
      ref.invalidate(authControllerProvider);
      refreshDataUsaha(ref);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil usaha berhasil diperbarui!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan perubahan: $e'),
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
                    'Edit Profil Usaha',
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
                          _buildFieldLabel('Nama Pemilik'),
                          const SizedBox(height: 6),
                          _buildInputField(
                            controller: _namaPemilikCtrl,
                            hint: 'Masukkan nama pemilik',
                          ),
                          const SizedBox(height: 16),

                          _buildFieldLabel('Nama Usaha'),
                          const SizedBox(height: 6),
                          _buildInputField(
                            controller: _namaUsahaCtrl,
                            hint: 'Masukkan nama usaha',
                          ),
                          const SizedBox(height: 16),

                          _buildFieldLabel('Sektor Usaha'),
                          const SizedBox(height: 6),
                          Container(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F7FD),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE5E0FF)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                icon: const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: AppColors.textSecondary,
                                ),
                                value: _sektorOptions.contains(_selectedSektor)
                                    ? _selectedSektor
                                    : _sektorOptions.first,
                                items: _sektorOptions.map((opt) {
                                  return DropdownMenuItem(
                                    value: opt,
                                    child: Text(
                                      opt,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _selectedSektor = val);
                                  }
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),



                          _buildFieldLabel('Nomor HP'),
                          const SizedBox(height: 6),
                          _buildInputField(
                            controller: _nomorHPCtrl,
                            hint: 'Masukkan nomor HP',
                            keyboardType: TextInputType.phone,
                            prefixIcon: const Icon(
                              Icons.phone_outlined,
                              size: 18,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 16),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildFieldLabel('Alamat Usaha'),
                              GestureDetector(
                                onTap: _showAddressPicker,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color:
                                        AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.map_rounded,
                                          size: 14, color: AppColors.primary),
                                      SizedBox(width: 4),
                                      Text(
                                        'Pilih Wilayah',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          _buildInputField(
                            controller: _alamatCtrl,
                            hint: 'Klik Pilih Wilayah atau ketik alamat...',
                            maxLines: 2,
                            prefixIcon: const Icon(
                              Icons.location_on_outlined,
                              size: 18,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _simpanPerubahan,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
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
                          _isSaving ? 'Menyimpan...' : 'Simpan Perubahan',
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

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: Color(0xFF6B7280),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    Widget? prefixIcon,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1F2937),
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          fontSize: 13,
          color: Color(0xFF9CA3AF),
          fontWeight: FontWeight.normal,
        ),
        prefixIcon: prefixIcon,
        filled: true,
        fillColor: const Color(0xFFF8F7FD),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E0FF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}
