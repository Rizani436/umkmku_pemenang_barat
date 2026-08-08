import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'pin_setup_screen.dart';





class DaftarUsahaScreen extends StatefulWidget {
  const DaftarUsahaScreen({super.key});

  @override
  State<DaftarUsahaScreen> createState() => _DaftarUsahaScreenState();
}

class _DaftarUsahaScreenState extends State<DaftarUsahaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaPemilikController = TextEditingController();
  final _namaUsahaController = TextEditingController();
  final _nomorHPController = TextEditingController();

  static const _sektorOptions = ['Perdagangan', 'Jasa', 'Manufaktur'];
  String? _sektorTerpilih;

  @override
  void dispose() {
    _namaPemilikController.dispose();
    _namaUsahaController.dispose();
    _nomorHPController.dispose();
    super.dispose();
  }

  void _lanjutBuatPin() {
    final formValid = _formKey.currentState?.validate() ?? false;
    if (!formValid) return;

    if (_sektorTerpilih == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih sektor usaha terlebih dahulu')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PinSetupScreen(
          namaPemilik: _namaPemilikController.text.trim(),
          namaUsaha: _namaUsahaController.text.trim(),
          sektorUsaha: _sektorTerpilih!,
          nomorHP: _nomorHPController.text.trim(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'Daftar Usaha Baru',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const Text(
                          'Bisnis-Ku',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildLabel('Nama Pemilik'),
                        _buildTextField(
                          controller: _namaPemilikController,
                          hint: 'Masukkan nama lengkap',
                          validatorMessage: 'Nama pemilik wajib diisi',
                        ),
                        const SizedBox(height: 20),
                        _buildLabel('Nama Usaha'),
                        _buildTextField(
                          controller: _namaUsahaController,
                          hint: 'Contoh: Warung Berkah',
                          validatorMessage: 'Nama usaha wajib diisi',
                        ),
                        const SizedBox(height: 20),
                        _buildLabel('Sektor Usaha'),
                        _buildDropdown(),
                        const SizedBox(height: 20),
                        _buildLabel('Nomor HP'),
                        _buildTextField(
                          controller: _nomorHPController,
                          hint: '08xx xxxx xxxx',
                          keyboardType: TextInputType.phone,
                          validatorMessage: 'Nomor HP wajib diisi',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _lanjutBuatPin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Lanjut Buat PIN',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required String validatorMessage,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
      decoration: _inputDecoration(hint),
      validator: (value) =>
          (value == null || value.trim().isEmpty) ? validatorMessage : null,
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _sektorTerpilih,
      decoration: _inputDecoration('Perdagangan/Jasa/Manufaktur'),
      icon: const Icon(Icons.keyboard_arrow_down),
      items: _sektorOptions
          .map(
            (sektor) => DropdownMenuItem(value: sektor, child: Text(sektor)),
          )
          .toList(),
      onChanged: (value) => setState(() => _sektorTerpilih = value),
      validator: (value) => value == null ? 'Pilih sektor usaha' : null,
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textSecondary),
      filled: true,
      fillColor: AppColors.inputFill,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.inputBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.inputBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }
}

