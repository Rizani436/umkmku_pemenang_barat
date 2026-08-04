import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'daftar_usaha_screen.dart';
import 'masuk_screen.dart';



class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 24),
                _buildLogos(),
                const SizedBox(height: 32),
                _buildTitle(),
                const Spacer(flex: 3),
                _buildIllustration(),
                const Spacer(flex: 3),
                _buildTagline(),
                const SizedBox(height: 32),
                _buildButtons(context),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogos() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LogoCircle(assetPath: 'lib/assets/images/logo_unram.png'),
        SizedBox(width: 16),
        _LogoCircle(assetPath: 'lib/assets/images/logo_profesor_berdampak.png'),
        SizedBox(width: 16),
        _LogoCircle(assetPath: 'lib/assets/images/logo_pemenang_barat.png'),
      ],
    );
  }

  Widget _buildTitle() {
    return const Column(
      children: [
        Text(
          'Bisnis-Ku',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 40,
            fontWeight: FontWeight.w800,
            height: 1.1,
          ),
        ),
        Text(
          'Pemenang Barat',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w800,
            height: 1.1,
          ),
        ),
      ],
    );
  }

  Widget _buildIllustration() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 16 / 10,
        child: Image.asset(
          'lib/assets/images/illustration_warung.png',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: Colors.white.withValues(alpha: 0.15),
            alignment: Alignment.center,
            child: const Icon(
              Icons.storefront_rounded,
              size: 48,
              color: Colors.white70,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTagline() {
    return const Text(
      'Mulai Mencatat,\nMulai Berkembang',
      textAlign: TextAlign.center,
      style: TextStyle(color: Colors.white, fontSize: 18, height: 1.4),
    );
  }

  Widget _buildButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DaftarUsahaScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.accentTextDark,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Daftar',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MasukScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Masuk',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}



class _LogoCircle extends StatelessWidget {
  final String assetPath;

  const _LogoCircle({required this.assetPath});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 68,
      height: 68,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      padding: const EdgeInsets.all(4),
      child: ClipOval(
        child: Image.asset(
          assetPath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const Icon(
            Icons.image_not_supported_outlined,
            color: Colors.grey,
            size: 24,
          ),
        ),
      ),
    );
  }
}