import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../repositories/usaha_repository.dart';
import '../theme/app_colors.dart';
import 'modal_kas_screen.dart';

enum _PinStep { buat, konfirmasi }




class PinSetupScreen extends ConsumerStatefulWidget {
  final String namaPemilik;
  final String namaUsaha;
  final String sektorUsaha;
  final String nomorHP;

  const PinSetupScreen({
    super.key,
    required this.namaPemilik,
    required this.namaUsaha,
    required this.sektorUsaha,
    required this.nomorHP,
  });

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen> {
  static const _panjangPin = 4;

  _PinStep _step = _PinStep.buat;
  String _pinAwal = '';
  String _inputSaatIni = '';
  String? _errorMessage;
  bool _isSubmitting = false;

  void _onDigitTap(String digit) {
    if (_isSubmitting || _inputSaatIni.length >= _panjangPin) return;

    setState(() {
      _errorMessage = null;
      _inputSaatIni += digit;
    });

    if (_inputSaatIni.length == _panjangPin) {
      _handlePinLengkap();
    }
  }

  void _onBackspace() {
    if (_isSubmitting || _inputSaatIni.isEmpty) return;
    setState(() {
      _inputSaatIni = _inputSaatIni.substring(0, _inputSaatIni.length - 1);
    });
  }

  Future<void> _handlePinLengkap() async {
    if (_step == _PinStep.buat) {
      final pinPertama = _inputSaatIni;
      await Future.delayed(const Duration(milliseconds: 200));
      if (!mounted) return;
      setState(() {
        _pinAwal = pinPertama;
        _inputSaatIni = '';
        _step = _PinStep.konfirmasi;
      });
      return;
    }


    if (_inputSaatIni != _pinAwal) {
      setState(() => _errorMessage = 'PIN tidak cocok, coba lagi');
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      setState(() => _inputSaatIni = '');
      return;
    }

    await _submit();
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);

    await ref
        .read(authControllerProvider.notifier)
        .daftar(
          namaPemilik: widget.namaPemilik,
          nomorHP: widget.nomorHP,
          pin: _pinAwal,
        );

    final authState = ref.read(authControllerProvider);

    if (authState.hasError || authState.value == null) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = 'Gagal membuat akun, coba lagi';
        _step = _PinStep.buat;
        _pinAwal = '';
        _inputSaatIni = '';
      });
      return;
    }

    final akun = authState.value!;

    final usaha = await ref
        .read(usahaRepositoryProvider)
        .buatUsaha(
          namaUsaha: widget.namaUsaha,
          jenisUsaha: widget.sektorUsaha,
          idAkun: akun.id,
        );

    if (!mounted) return;


    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => ModalKasScreen(
          namaUsaha: widget.namaUsaha,
          idUsaha: usaha.id,
          onSelesai: (_) {

          },
        ),
      ),
      (route) => route.isFirst,
    );
  }


  @override
  Widget build(BuildContext context) {
    final isKonfirmasi = _step == _PinStep.konfirmasi;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 32),
            _buildLogo(),
            const SizedBox(height: 20),
            const Text(
              'Bisnis-Ku',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(flex: 2),
            Text(
              isKonfirmasi ? 'Konfirmasi PIN' : 'Buat PIN 4 Angka',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage ??
                    (isKonfirmasi
                        ? 'Masukkan ulang PIN yang sama untuk konfirmasi.'
                        : 'Gunakan PIN ini untuk masuk ke aplikasi.'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: _errorMessage != null
                      ? Colors.redAccent
                      : AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildDots(),
            const Spacer(flex: 3),
            if (_isSubmitting)
              const Padding(
                padding: EdgeInsets.only(bottom: 40),
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            else
              _buildKeypad(),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(6),
      child: ClipOval(
        child: Image.asset(
          'lib/assets/images/logo_profesor_berdampak.png',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const Icon(
            Icons.school_outlined,
            size: 48,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_panjangPin, (index) {
        final terisi = index < _inputSaatIni.length;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: terisi ? AppColors.primary : Colors.transparent,
            border: Border.all(
              color: terisi ? AppColors.primary : AppColors.inputBorder,
              width: 1.5,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildKeypad() {
    const rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...rows.map(
            (row) => Row(
              children: row
                  .map(
                    (digit) => _KeypadButton(
                      label: digit,
                      onTap: () => _onDigitTap(digit),
                    ),
                  )
                  .toList(),
            ),
          ),
          Row(
            children: [
              const Expanded(child: SizedBox()),
              _KeypadButton(label: '0', onTap: () => _onDigitTap('0')),
              Expanded(
                child: InkWell(
                  onTap: _onBackspace,
                  child: const SizedBox(
                    height: 72,
                    child: Center(
                      child: Icon(
                        Icons.backspace_outlined,
                        size: 26,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _KeypadButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _KeypadButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 72,
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}