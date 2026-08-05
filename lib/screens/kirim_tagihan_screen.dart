import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/piutang.dart';
import '../providers/usaha_provider.dart';
import '../theme/app_colors.dart';
import '../repositories/piutang_repository.dart';
import '../providers/kasbon_provider.dart';
import '../providers/riwayat_provider.dart';

class KirimTagihanScreen extends ConsumerStatefulWidget {
  final Piutang piutang;

  const KirimTagihanScreen({super.key, required this.piutang});

  @override
  ConsumerState<KirimTagihanScreen> createState() => _KirimTagihanScreenState();
}

class _KirimTagihanScreenState extends ConsumerState<KirimTagihanScreen> {
  late final String _waktuFormatted;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final jam = now.hour.toString().padLeft(2, '0');
    final menit = now.minute.toString().padLeft(2, '0');
    _waktuFormatted = '$jam:$menit';
  }

  String _formatRupiah(double nilai) {
    if (nilai == 0) return 'Rp 0';
    final s = nilai.toInt().toString();
    final buf = StringBuffer('Rp ');
    final off = s.length % 3;
    for (int i = 0; i < s.length; i++) {
      if (i != 0 && (i - off) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  String _buildPesan(String namaUsaha) {
    final nominalStr = _formatRupiah(widget.piutang.nominal);
    final keteranganText = (widget.piutang.keterangan != null &&
            widget.piutang.keterangan!.trim().isNotEmpty)
        ? ' (${widget.piutang.keterangan})'
        : '';

    return 'Halo ${widget.piutang.namaOrang}, ini dari $namaUsaha. Mengingatkan ada nota kasbon$keteranganText yang belum diselesaikan sebesar $nominalStr. Terima kasih.';
  }

  Future<String?> _showInputPhoneDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Masukkan Nomor WhatsApp'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nomor WhatsApp untuk ${widget.piutang.namaOrang} belum disimpan.'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Nomor HP / WhatsApp',
                hintText: 'Contoh: 08123456789',
                prefixIcon: Icon(Icons.phone_android_rounded),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final val = controller.text.trim();
              if (val.isNotEmpty) {
                await ref.read(piutangRepositoryProvider).update(
                      id: widget.piutang.id,
                      namaOrang: widget.piutang.namaOrang,
                      nominal: widget.piutang.nominal,
                      nomorHP: val,
                      keterangan: widget.piutang.keterangan,
                    );
                ref.invalidate(piutangListProvider);
                ref.invalidate(riwayatProvider);
              }
              if (!ctx.mounted) return;
              Navigator.pop(ctx, val);
            },
            child: const Text('Simpan & Lanjut'),
          ),
        ],
      ),
    );
  }

  Future<void> _kirimViaWhatsApp(String pesanText) async {
    var rawPhone = widget.piutang.nomorHP ?? '';
    if (rawPhone.trim().isEmpty) {
      final inputPhone = await _showInputPhoneDialog();
      if (inputPhone == null || inputPhone.trim().isEmpty) return;
      rawPhone = inputPhone;
    }

    var phone = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');

    if (phone.startsWith('0')) {
      phone = '62${phone.substring(1)}';
    }

    final encodedMessage = Uri.encodeComponent(pesanText);
    final url = Uri.parse('https://wa.me/$phone?text=$encodedMessage');

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(url);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membuka WhatsApp: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final usaha = ref.watch(currentUsahaProvider).value;
    final namaUsaha = (usaha != null && usaha.namaUsaha.isNotEmpty)
        ? usaha.namaUsaha
        : 'Warung Pak Musleh';

    final pesanText = _buildPesan(namaUsaha);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pratinjau Pesan Tagihan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Pastikan pesan sudah sesuai sebelum dikirim.',
                      style: TextStyle(
                        fontSize: 13.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildPreviewCard(pesanText),
                    const SizedBox(height: 18),
                    _buildInfoAlertBox(),
                  ],
                ),
              ),
            ),
            _buildKirimButton(pesanText),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            color: AppColors.textPrimary,
          ),
          const Expanded(
            child: Text(
              'Kirim Tagihan',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildPreviewCard(String pesanText) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
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
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: Color(0xFFDCF7EC),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chat_rounded,
                  size: 16,
                  color: Color(0xFF25D366),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Pesan WhatsApp',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          Divider(
            height: 24,
            color: AppColors.inputBorder.withValues(alpha: 0.5),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            decoration: BoxDecoration(
              color: const Color(0xFFE2F8D8),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pesanText,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF111B21),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Text(
                    _waktuFormatted,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.black.withValues(alpha: 0.45),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoAlertBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F1FB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.inputBorder.withValues(alpha: 0.6),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Pesan ini akan dikirim melalui aplikasi WhatsApp Anda. Anda dapat mengubah isi pesan sebelum mengirimnya.',
              style: TextStyle(
                fontSize: 12.5,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKirimButton(String pesanText) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton.icon(
          onPressed: () => _kirimViaWhatsApp(pesanText),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF25D366),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          icon: const Icon(Icons.send_rounded, size: 18),
          label: const Text(
            'Kirim via WhatsApp',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }
}
