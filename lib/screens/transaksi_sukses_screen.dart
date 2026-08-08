import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'tambah_transaksi_screen.dart';

class TransaksiSuksesScreen extends StatefulWidget {
  final String jenisTransaksi;
  final String kategori;
  final double total;

  const TransaksiSuksesScreen({
    super.key,
    required this.jenisTransaksi,
    required this.kategori,
    required this.total,
  });

  @override
  State<TransaksiSuksesScreen> createState() => _TransaksiSuksesScreenState();
}

class _TransaksiSuksesScreenState extends State<TransaksiSuksesScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fade = CurvedAnimation(parent: _ctrl, curve: const Interval(0.4, 1.0));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  bool get _isPemasukan => widget.jenisTransaksi == 'pemasukan';

  Color get _activeColor => _isPemasukan
      ? const Color(0xFF1DB57A)
      : const Color(0xFFFF5A5A);

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),

              FadeTransition(
                opacity: _fade,
                child: const Text(
                  'Berhasil Disimpan!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 40),

              ScaleTransition(
                scale: _scale,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(
                      color: _activeColor,
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _activeColor.withValues(alpha: 0.18),
                        blurRadius: 32,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    size: 72,
                    color: _activeColor,
                  ),
                ),
              ),
              const SizedBox(height: 40),

              FadeTransition(
                opacity: _fade,
                child: Column(
                  children: [
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: _activeColor,
                        ),
                        children: [
                          TextSpan(
                            text: _isPemasukan ? 'Pendapatan ' : 'Pengeluaran ',
                          ),
                          TextSpan(text: _formatRupiah(widget.total)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.kategori,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 3),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => const TambahTransaksiScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Tambah Transaksi',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Kembali ke Beranda',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
