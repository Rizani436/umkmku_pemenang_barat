import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/dashboard_provider.dart';
import '../providers/laporan_provider.dart';
import '../providers/usaha_provider.dart';
import '../repositories/transaksi_repository.dart';
import '../repositories/usaha_repository.dart';
import '../theme/app_colors.dart';

class SamakanUangLaciScreen extends ConsumerStatefulWidget {
  final String idUsaha;
  final double currentKas;

  const SamakanUangLaciScreen({
    super.key,
    required this.idUsaha,
    required this.currentKas,
  });

  @override
  ConsumerState<SamakanUangLaciScreen> createState() =>
      _SamakanUangLaciScreenState();
}

class _SamakanUangLaciScreenState
    extends ConsumerState<SamakanUangLaciScreen> {
  String _inputNominal = '0';
  bool _isFirstInput = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.currentKas.toInt().abs().toString();
    _inputNominal = initial;
  }

  void _onKeyPress(String val) {
    setState(() {
      if (_isFirstInput) {
        _isFirstInput = false;
        if (val == 'backspace') {
          if (_inputNominal.length > 1) {
            _inputNominal = _inputNominal.substring(0, _inputNominal.length - 1);
          } else {
            _inputNominal = '0';
          }
          return;
        } else if (val == '000') {
          _inputNominal = '0';
          return;
        } else {
          _inputNominal = val;
          return;
        }
      }

      if (val == 'backspace') {
        if (_inputNominal.length > 1) {
          _inputNominal = _inputNominal.substring(0, _inputNominal.length - 1);
        } else {
          _inputNominal = '0';
        }
      } else if (val == '000') {
        if (_inputNominal != '0') {
          if (_inputNominal.length <= 11) {
            _inputNominal += '000';
          }
        }
      } else {
        if (_inputNominal == '0') {
          _inputNominal = val;
        } else {
          if (_inputNominal.length <= 13) {
            _inputNominal += val;
          }
        }
      }
    });
  }

  String _formatDisplay(String raw) {
    final nilai = double.tryParse(raw) ?? 0;
    if (nilai == 0) return '0';
    final s = nilai.toInt().abs().toString();
    final buf = StringBuffer();
    final off = s.length % 3;
    for (int i = 0; i < s.length; i++) {
      if (i != 0 && (i - off) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  Future<void> _sesuaikanSaldo() async {
    final inputKas = double.tryParse(_inputNominal) ?? 0;
    setState(() => _isSaving = true);

    try {
      final transaksiRepo = ref.read(transaksiRepositoryProvider);
      final results = await Future.wait([
        transaksiRepo.getTotalPemasukanAll(widget.idUsaha),
        transaksiRepo.getTotalPengeluaranAll(widget.idUsaha),
      ]);
      final totalPemasukanAll = results[0];
      final totalPengeluaranAll = results[1];

      final adjustedBaseKas = inputKas - totalPemasukanAll + totalPengeluaranAll;

      await ref.read(usahaRepositoryProvider).updateKas(
            idUsaha: widget.idUsaha,
            kas: adjustedBaseKas,
          );

      ref.invalidate(currentUsahaProvider);
      ref.invalidate(dashboardSummaryProvider);
      ref.invalidate(laporanNeracaProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Saldo uang laci berhasil diselaraskan menjadi Rp ${_formatDisplay(_inputNominal)}'),
            backgroundColor: const Color(0xFF1DB57A),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyesuaikan saldo: $e'),
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
    final displayFormatted = _formatDisplay(_inputNominal);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FF),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
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
                    'Samakan Uang Laci',
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
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 12),

                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEBE7FF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: Color(0xFF5B4FDD),
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'Berapa uang di laci saat ini?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2B1F7C),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Jika catatan aplikasi berbeda dengan uang fisik Anda, masukkan jumlah uang yang sebenarnya di sini agar sistem merapikannya otomatis.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF7C8495),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 18,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'SALDO TUNAI FISIK',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF9CA3AF),
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 10),
                          RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              children: [
                                const TextSpan(
                                  text: 'Rp ',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF7B6FF0),
                                  ),
                                ),
                                TextSpan(
                                  text: displayFormatted,
                                  style: const TextStyle(
                                    fontSize: 34,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF5B4FDD),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    Column(
                      children: [
                        Row(
                          children: [
                            _buildKeyButton('1'),
                            const SizedBox(width: 12),
                            _buildKeyButton('2'),
                            const SizedBox(width: 12),
                            _buildKeyButton('3'),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _buildKeyButton('4'),
                            const SizedBox(width: 12),
                            _buildKeyButton('5'),
                            const SizedBox(width: 12),
                            _buildKeyButton('6'),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _buildKeyButton('7'),
                            const SizedBox(width: 12),
                            _buildKeyButton('8'),
                            const SizedBox(width: 12),
                            _buildKeyButton('9'),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _buildKeyButton('000', isSpecial: true),
                            const SizedBox(width: 12),
                            _buildKeyButton('0'),
                            const SizedBox(width: 12),
                            _buildKeyButton('backspace', isSpecial: true),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _sesuaikanSaldo,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5B4FDD),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Sesuaikan Saldo',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyButton(String val, {bool isSpecial = false}) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onKeyPress(val),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: 54,
            decoration: BoxDecoration(
              color: isSpecial ? const Color(0xFFF3F0FF) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: val == 'backspace'
                  ? const Icon(
                      Icons.backspace_outlined,
                      color: Color(0xFF2B1F7C),
                      size: 22,
                    )
                  : Text(
                      val,
                      style: TextStyle(
                        fontSize: val == '000' ? 17 : 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2B1F7C),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
