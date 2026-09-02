import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/hutang.dart';
import '../models/piutang.dart';
import '../providers/dashboard_provider.dart';
import '../providers/kasbon_provider.dart';
import '../providers/riwayat_provider.dart';
import '../repositories/hutang_repository.dart';
import '../repositories/piutang_repository.dart';
import '../theme/app_colors.dart';
import '../utils/rupiah_formatter.dart';
import '../utils/format.dart';

class EditKasbonScreen extends ConsumerStatefulWidget {
  final Hutang? hutang;
  final Piutang? piutang;

  const EditKasbonScreen({
    super.key,
    this.hutang,
    this.piutang,
  }) : assert(hutang != null || piutang != null,
            'Salah satu hutang atau piutang harus diisi');

  @override
  ConsumerState<EditKasbonScreen> createState() => _EditKasbonScreenState();
}

class _EditKasbonScreenState extends ConsumerState<EditKasbonScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _namaCtrl;
  late TextEditingController _nomorHPCtrl;
  late TextEditingController _nominalCtrl;
  late TextEditingController _keteranganCtrl;

  DateTime? _tglJatuhTempo;
  bool _isJatuhTempoChanged = false;
  bool _isLoading = false;

  bool get _isPiutang => widget.piutang != null;
  String get _title => _isPiutang ? 'Edit Piutang' : 'Edit Hutang';

  @override
  void initState() {
    super.initState();
    if (_isPiutang) {
      final p = widget.piutang!;
      _namaCtrl = TextEditingController(text: p.namaOrang);
      _nomorHPCtrl = TextEditingController(text: p.nomorHP ?? '');
      _nominalCtrl =
          TextEditingController(text: formatRibuan(p.nominal));
      _keteranganCtrl = TextEditingController(text: p.keterangan ?? '');
      _tglJatuhTempo = p.tglJatuhTempo;
    } else {
      final h = widget.hutang!;
      _namaCtrl = TextEditingController(text: h.namaToko);
      _nomorHPCtrl = TextEditingController();
      _nominalCtrl =
          TextEditingController(text: formatRibuan(h.nominal));
      _keteranganCtrl = TextEditingController(text: h.keterangan ?? '');
      _tglJatuhTempo = h.tglJatuhTempo;
    }
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _nomorHPCtrl.dispose();
    _nominalCtrl.dispose();
    _keteranganCtrl.dispose();
    super.dispose();
  }


  Future<void> _pilihTanggalJatuhTempo() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tglJatuhTempo ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _tglJatuhTempo = picked;
        _isJatuhTempoChanged = true;
      });
    }
  }

  void _hapusTanggalJatuhTempo() {
    setState(() {
      _tglJatuhTempo = null;
      _isJatuhTempoChanged = true;
    });
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;

    final nama = _namaCtrl.text.trim();
    final nominalStr = _nominalCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
    final nominal = double.tryParse(nominalStr) ?? 0;
    final nomorHP = _nomorHPCtrl.text.trim();
    final keterangan = _keteranganCtrl.text.trim();

    if (nominal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nominal harus lebih dari 0')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isPiutang) {
        await ref.read(piutangRepositoryProvider).update(
              id: widget.piutang!.id,
              namaOrang: nama,
              nominal: nominal,
              nomorHP: nomorHP.isEmpty ? null : nomorHP,
              keterangan: keterangan.isEmpty ? null : keterangan,
              tglJatuhTempo: _tglJatuhTempo,
              updateJatuhTempo: _isJatuhTempoChanged,
            );
      } else {
        await ref.read(hutangRepositoryProvider).update(
              id: widget.hutang!.id,
              namaToko: nama,
              nominal: nominal,
              keterangan: keterangan.isEmpty ? null : keterangan,
              tglJatuhTempo: _tglJatuhTempo,
              updateJatuhTempo: _isJatuhTempoChanged,
            );
      }

      ref.invalidate(hutangListProvider);
      ref.invalidate(piutangListProvider);
      ref.invalidate(dashboardSummaryProvider);
      ref.invalidate(riwayatProvider);

      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$_title berhasil diperbarui! ✨'),
          backgroundColor: const Color(0xFF1DB57A),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memperbarui data: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                    color: AppColors.textPrimary,
                  ),
                  Expanded(
                    child: Text(
                      _title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isPiutang ? 'Nama Pengutang (Pelanggan)' : 'Nama Toko / Supplier',
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _namaCtrl,
                        validator: (val) =>
                            val == null || val.trim().isEmpty ? 'Nama harus diisi' : null,
                        decoration: InputDecoration(
                          hintText: _isPiutang ? 'Contoh: Pak Ahmad' : 'Contoh: Toko Barokah',
                          prefixIcon: Icon(
                            _isPiutang ? Icons.person_rounded : Icons.store_rounded,
                            color: AppColors.primary,
                          ),
                          filled: true,
                          fillColor: AppColors.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (_isPiutang) ...[
                        const Text(
                          'Nomor HP / WhatsApp (Opsional)',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _nomorHPCtrl,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: InputDecoration(
                            hintText: 'Contoh: 081234567890',
                            prefixIcon: const Icon(
                              Icons.phone_rounded,
                              color: AppColors.primary,
                            ),
                            filled: true,
                            fillColor: AppColors.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      const Text(
                        'Nominal Kasbon (Rp)',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _nominalCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          CurrencyInputFormatter(),
                        ],
                        validator: (val) =>
                            val == null || val.trim().isEmpty ? 'Nominal harus diisi' : null,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(
                            Icons.payments_rounded,
                            color: AppColors.primary,
                          ),
                          prefixText: 'Rp ',
                          prefixStyle: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          filled: true,
                          fillColor: AppColors.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        'Tanggal Jatuh Tempo (Opsional)',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: _pilihTanggalJatuhTempo,
                                borderRadius: BorderRadius.circular(14),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 14),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.calendar_month_rounded,
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        _tglJatuhTempo != null
                                            ? formatTanggalIndo(_tglJatuhTempo!, padHari: true)
                                            : 'Pilih Tanggal Jatuh Tempo',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: _tglJatuhTempo != null
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                          color: _tglJatuhTempo != null
                                              ? AppColors.textPrimary
                                              : const Color(0xFF94A3B8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            if (_tglJatuhTempo != null)
                              IconButton(
                                onPressed: _hapusTanggalJatuhTempo,
                                icon: const Icon(
                                  Icons.close_rounded,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        'Catatan / Keterangan (Opsional)',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _keteranganCtrl,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Contoh: Kasbon beras 10kg + telur 1 karpet',
                          filled: true,
                          fillColor: AppColors.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _simpan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Simpan Perubahan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
