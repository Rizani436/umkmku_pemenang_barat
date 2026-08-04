import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/usaha_repository.dart';
import 'dashboard_screen.dart';
import '../theme/app_colors.dart';





class ModalKasScreen extends ConsumerStatefulWidget {

  final String namaUsaha;


  final String idUsaha;


  final void Function(int saldoAwal) onSelesai;

  const ModalKasScreen({
    super.key,
    required this.namaUsaha,
    required this.idUsaha,
    required this.onSelesai,
  });

  @override
  ConsumerState<ModalKasScreen> createState() => _ModalKasScreenState();
}

class _ModalKasScreenState extends ConsumerState<ModalKasScreen> {

  String _angka = '';



  int get _nilaiSaatIni => _angka.isEmpty ? 0 : int.parse(_angka);


  String _formatRupiah(int nilai) {
    if (nilai == 0) return 'Rp 0';
    final s = nilai.toString();
    final buffer = StringBuffer('Rp ');
    final offset = s.length % 3;
    for (int i = 0; i < s.length; i++) {
      if (i != 0 && (i - offset) % 3 == 0) buffer.write('.');
      buffer.write(s[i]);
    }
    return buffer.toString();
  }



  void _onDigit(String digit) {

    if (_angka.length >= 13) return;
    setState(() {
      _angka += digit;
    });
  }

  void _onRibu() {

    if (_angka.isEmpty) return;
    if (_angka.length + 3 > 13) return;
    setState(() {
      _angka += '000';
    });
  }

  void _onBackspace() {
    if (_angka.isEmpty) return;
    setState(() {
      _angka = _angka.substring(0, _angka.length - 1);
    });
  }

  bool _isSaving = false;

  Future<void> _onMulai(BuildContext context) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    
    final nav = Navigator.of(context);


    await ref.read(usahaRepositoryProvider).updateKas(
          idUsaha: widget.idUsaha,
          kas: _nilaiSaatIni.toDouble(),
        );


    widget.onSelesai(_nilaiSaatIni);

    if (!mounted) return;

    nav.pushReplacement(
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 28),


            _buildLogo(),
            const SizedBox(height: 24),


            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Berapa modal kas Anda hari ini?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  height: 1.3,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Masukkan jumlah uang tunai yang ada di\n'
                'laci atau dompet usaha Anda saat ini',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
              ),
            ),
            const SizedBox(height: 28),


            _buildSaldoCard(),
            const SizedBox(height: 20),


            Expanded(child: _buildKeypad()),


            _buildMulaiButton(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 100,
      height: 100,
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
            size: 40,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildSaldoCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            const Text(
              'Saldo Awal',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (child, anim) =>
                  FadeTransition(opacity: anim, child: child),
              child: Text(
                _formatRupiah(_nilaiSaatIni),
                key: ValueKey(_nilaiSaatIni),
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [

          for (final row in [
            ['1', '2', '3'],
            ['4', '5', '6'],
            ['7', '8', '9'],
          ])
            Expanded(
              child: Row(
                children: row
                    .map(
                      (d) => _KeypadBtn(
                        label: d,
                        onTap: () => _onDigit(d),
                      ),
                    )
                    .toList(),
              ),
            ),


          Expanded(
            child: Row(
              children: [
                _KeypadBtn(
                  label: '000',
                  labelStyle: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  onTap: _onRibu,
                ),
                _KeypadBtn(
                  label: '0',
                  onTap: () => _onDigit('0'),
                ),
                _KeypadBtn(
                  icon: Icons.backspace_outlined,
                  onTap: _onBackspace,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMulaiButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        height: 58,
        child: ElevatedButton(
          onPressed: () => _onMulai(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Text(
            'Mulai Gunakan Aplikasi',
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



class _KeypadBtn extends StatelessWidget {
  final String? label;
  final TextStyle? labelStyle;
  final IconData? icon;
  final VoidCallback onTap;

  const _KeypadBtn({
    this.label,
    this.labelStyle,
    this.icon,
    required this.onTap,
  }) : assert(label != null || icon != null);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          splashColor: AppColors.primary.withValues(alpha: 0.08),
          highlightColor: AppColors.primary.withValues(alpha: 0.04),
          child: Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: icon != null
                  ? Icon(icon, size: 24, color: AppColors.textPrimary)
                  : Text(
                      label!,
                      style: labelStyle ??
                          const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
