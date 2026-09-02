import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../repositories/auth_repository.dart';
import '../theme/app_colors.dart';

class UbahPinScreen extends ConsumerStatefulWidget {
  final String idAkun;
  final String namaUsaha;

  const UbahPinScreen({
    super.key,
    required this.idAkun,
    required this.namaUsaha,
  });

  @override
  ConsumerState<UbahPinScreen> createState() => _UbahPinScreenState();
}

/// Tahap 0 sengaja ditaruh di depan: PIN lama harus dibuktikan dulu sebelum
/// boleh diganti.
enum _StepUbahPin { verifikasiLama, pinBaru, konfirmasiBaru }

class _UbahPinScreenState extends ConsumerState<UbahPinScreen> {
  _StepUbahPin _stepUbah = _StepUbahPin.verifikasiLama;
  int _step = 1;
  String _firstPin = '';
  String _currentInput = '';
  bool _isSaving = false;
  bool _isVerifying = false;

  void _onNumberTap(String number) {
    if (_currentInput.length >= 4 || _isSaving || _isVerifying) return;
    setState(() {
      _currentInput += number;
    });

    if (_currentInput.length == 4) {
      if (_stepUbah == _StepUbahPin.verifikasiLama) {
        _verifikasiPinLama();
      } else {
        _processPin();
      }
    }
  }

  void _onBackspace() {
    if (_currentInput.isEmpty || _isSaving || _isVerifying) return;
    setState(() {
      _currentInput = _currentInput.substring(0, _currentInput.length - 1);
    });
  }

  Future<void> _verifikasiPinLama() async {
    setState(() => _isVerifying = true);
    try {
      final cocok = await ref.read(authRepositoryProvider).verifikasiPin(
            idAkun: widget.idAkun,
            pin: _currentInput,
          );
      if (!mounted) return;

      if (!cocok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PIN lama salah. Coba lagi.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        setState(() {
          _currentInput = '';
          _isVerifying = false;
        });
        return;
      }

      setState(() {
        _stepUbah = _StepUbahPin.pinBaru;
        _step = 1;
        _currentInput = '';
        _isVerifying = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memeriksa PIN: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
      setState(() {
        _currentInput = '';
        _isVerifying = false;
      });
    }
  }

  Future<void> _processPin() async {
    if (_step == 1) {
      _firstPin = _currentInput;
      await Future.delayed(const Duration(milliseconds: 200));
      if (!mounted) return;
      setState(() {
        _step = 2;
        _stepUbah = _StepUbahPin.konfirmasiBaru;
        _currentInput = '';
      });
    } else {
      final confirmPin = _currentInput;
      if (confirmPin == _firstPin) {
        setState(() => _isSaving = true);
        try {
          await ref.read(authRepositoryProvider).updatePin(
                idAkun: widget.idAkun,
                pinBaru: confirmPin,
              );
          ref.invalidate(authControllerProvider);

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PIN 4 angka berhasil diperbarui!'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context);
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal memperbarui PIN: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
          setState(() {
            _step = 1;
            _stepUbah = _StepUbahPin.pinBaru;
            _firstPin = '';
            _currentInput = '';
            _isSaving = false;
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PIN konfirmasi tidak cocok. Silakan coba lagi!'),
            backgroundColor: Colors.redAccent,
          ),
        );
        setState(() {
          _step = 1;
          _stepUbah = _StepUbahPin.pinBaru;
          _firstPin = '';
          _currentInput = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String titleText;
    final String subtitleText;
    switch (_stepUbah) {
      case _StepUbahPin.verifikasiLama:
        titleText = 'Masukkan PIN Lama';
        subtitleText = 'Demi keamanan, buktikan dulu PIN Anda saat ini.';
      case _StepUbahPin.pinBaru:
        titleText = 'Ubah PIN 4 Angka';
        subtitleText = 'Gunakan PIN ini untuk masuk ke aplikasi.';
      case _StepUbahPin.konfirmasiBaru:
        titleText = 'Konfirmasi PIN Baru';
        subtitleText = 'Masukkan kembali 4 angka PIN baru Anda.';
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FE),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: AppColors.textPrimary,
                    size: 24,
                  ),
                ),
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),

                    Container(
                      width: 96,
                      height: 96,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'lib/assets/images/logo_aplikasi.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                            Icons.school_rounded,
                            size: 48,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      widget.namaUsaha.isEmpty
                          ? 'Bisnis-Ku Pemenang Barat'
                          : widget.namaUsaha,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3629B7),
                      ),
                    ),

                    const Spacer(),

                    Text(
                      titleText,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF212936),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitleText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF7C8495),
                      ),
                    ),
                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(4, (index) {
                        final isFilled = index < _currentInput.length;
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 7),
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isFilled
                                ? const Color(0xFF3629B7)
                                : const Color(0xFFE2E0F5),
                          ),
                        );
                      }),
                    ),

                    const Spacer(),
                  ],
                ),
              ),
            ),

            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFFAFAFE),
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 20,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(36, 24, 36, 24),
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildNumpadButton('1'),
                      _buildNumpadButton('2'),
                      _buildNumpadButton('3'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildNumpadButton('4'),
                      _buildNumpadButton('5'),
                      _buildNumpadButton('6'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildNumpadButton('7'),
                      _buildNumpadButton('8'),
                      _buildNumpadButton('9'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Expanded(child: SizedBox(height: 56)),
                      _buildNumpadButton('0'),
                      Expanded(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _onBackspace,
                            borderRadius: BorderRadius.circular(28),
                            child: const SizedBox(
                              height: 56,
                              child: Center(
                                child: Icon(
                                  Icons.backspace_outlined,
                                  color: Color(0xFF212936),
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumpadButton(String number) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onNumberTap(number),
          borderRadius: BorderRadius.circular(28),
          child: SizedBox(
            height: 56,
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF212936),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
