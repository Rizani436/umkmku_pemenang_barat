import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import 'dashboard_screen.dart';




class PinMasukScreen extends ConsumerStatefulWidget {
  final String namaUsaha;
  final String nomorHP;

  const PinMasukScreen({
    super.key,
    required this.namaUsaha,
    required this.nomorHP,
  });

  @override
  ConsumerState<PinMasukScreen> createState() => _PinMasukScreenState();
}

class _PinMasukScreenState extends ConsumerState<PinMasukScreen> {
  static const _panjangPin = 4;

  String _input = '';
  String? _errorMessage;
  bool _isLoading = false;



  void _onDigit(String digit) {
    if (_isLoading || _input.length >= _panjangPin) return;
    setState(() {
      _errorMessage = null;
      _input += digit;
    });
    if (_input.length == _panjangPin) _verifikasi();
  }

  void _onBackspace() {
    if (_isLoading || _input.isEmpty) return;
    setState(() => _input = _input.substring(0, _input.length - 1));
  }

  Future<void> _verifikasi() async {
    setState(() => _isLoading = true);

    await ref.read(authControllerProvider.notifier).masuk(
          nomorHP: widget.nomorHP,
          pin: _input,
        );

    if (!mounted) return;

    final authState = ref.read(authControllerProvider);

    if (authState.hasError || authState.value == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'PIN salah atau akun tidak ditemukan';
        _input = '';
      });
      return;
    }


    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
      (route) => false,
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppColors.textPrimary,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),


            _buildLogo(),
            const SizedBox(height: 20),


            Text(
              widget.namaUsaha,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.nomorHP,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),

            const Spacer(flex: 2),


            const Text(
              'Masukkan PIN',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage ?? 'Gunakan PIN 4 angka yang sudah kamu buat.',
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


            if (_isLoading)
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
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(4),
      child: ClipOval(
        child: Image.asset(
          'lib/assets/images/logo_profesor_berdampak.png',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const Icon(
            Icons.storefront_outlined,
            size: 36,
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
        final terisi = index < _input.length;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: terisi ? AppColors.primary : Colors.transparent,
            border: Border.all(
              color: _errorMessage != null
                  ? Colors.redAccent
                  : terisi
                      ? AppColors.primary
                      : AppColors.inputBorder,
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
                    (d) => _KeypadButton(
                      label: d,
                      onTap: () => _onDigit(d),
                    ),
                  )
                  .toList(),
            ),
          ),
          Row(
            children: [
              const Expanded(child: SizedBox()),
              _KeypadButton(label: '0', onTap: () => _onDigit('0')),
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
