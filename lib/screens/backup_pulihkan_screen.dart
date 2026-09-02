import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import '../database/database_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/session_provider.dart';
import '../theme/app_colors.dart';
import '../utils/format.dart';
import '../providers/refresh.dart';

class BackupPulihkanScreen extends ConsumerStatefulWidget {
  const BackupPulihkanScreen({super.key});

  @override
  ConsumerState<BackupPulihkanScreen> createState() =>
      _BackupPulihkanScreenState();
}

class _BackupPulihkanScreenState extends ConsumerState<BackupPulihkanScreen> {
  String _lastBackupDate = 'Belum pernah';
  bool _isBackingUp = false;
  bool _isRestoring = false;

  @override
  void initState() {
    super.initState();
    _loadLastBackupDate();
  }

  void _loadLastBackupDate() {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final saved = prefs.getString('last_backup_date');
      if (saved != null && saved.isNotEmpty) {
        setState(() {
          _lastBackupDate = saved;
        });
      }
    } catch (e, st) {
      debugPrint('Gagal membaca tanggal salinan terakhir: $e\n$st');
    }
  }


  Future<void> _buatSalinanSekarang() async {
    if (_isBackingUp || _isRestoring) return;
    setState(() => _isBackingUp = true);

    try {
      final appDb = ref.read(appDatabaseProvider);
      final db = await appDb.database;

      // Tabel `akun` SENGAJA tidak ikut dicadangkan. Isinya nomor HP dan
      // pin_hash; file ini berakhir di folder Download yang bisa dibaca
      // aplikasi lain dan sering ikut terkirim saat di-share. PIN hanya 4
      // angka, jadi hash yang bocor praktis sama dengan PIN yang bocor.
      // Proses pemulihan juga tidak membutuhkannya — usaha yang dipulihkan
      // selalu dipasang ke akun yang sedang masuk.
      final usahaList = await db.query('usaha');
      final transaksiList = await db.query('transaksi');
      final hutangList = await db.query('hutang');
      final piutangList = await db.query('piutang');

      final backupMap = {
        'app': 'UMKM-Ku Pemenang Barat',
        'version': 2,
        'created_at': DateTime.now().toIso8601String(),
        'usaha': usahaList,
        'transaksi': transaksiList,
        'hutang': hutangList,
        'piutang': piutangList,
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(backupMap);
      final jsonBytes = Uint8List.fromList(utf8.encode(jsonString));

      final dt = DateTime.now();
      final dateTag =
          '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      final fileName = 'UMKMKu_Backup_$dateTag.json';

      bool savedDirectlyToDownload = false;

      try {
        final downloadDirs = [
          Directory('/storage/emulated/0/Download'),
          Directory('/sdcard/Download'),
        ];

        for (final dir in downloadDirs) {
          if (await dir.exists()) {
            final targetFile = File('${dir.path}/$fileName');
            await targetFile.writeAsBytes(jsonBytes);
            savedDirectlyToDownload = true;
            break;
          }
        }
      } catch (e, st) {
        // Bukan kegagalan fatal: di bawah masih ada jalur berbagi file.
        // Tetap dicatat supaya tidak hilang diam-diam saat debugging.
        debugPrint('Gagal menulis ke folder Download: $e\n$st');
      }

      if (!savedDirectlyToDownload) {
        await Printing.sharePdf(
          bytes: jsonBytes,
          filename: fileName,
        );
      }

      final nowStr = formatTanggalIndo(dt);
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setString('last_backup_date', nowStr);

      setState(() {
        _lastBackupDate = nowStr;
      });

      if (!mounted) return;
      final msg = savedDirectlyToDownload
          ? 'File salinan ($fileName) otomatis tersimpan di folder Download HP Anda!'
          : 'File salinan ($fileName) berhasil dibuat!';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membuat file salinan: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isBackingUp = false);
      }
    }
  }

  Future<void> _pilihFileSalinan() async {
    if (_isBackingUp || _isRestoring) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      String rawJson = '';

      if (file.bytes != null && file.bytes!.isNotEmpty) {
        rawJson = utf8.decode(file.bytes!);
      } else if (file.path != null && file.path!.isNotEmpty) {
        final f = File(file.path!);
        if (await f.exists()) {
          rawJson = await f.readAsString();
        }
      }

      if (rawJson.trim().isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File salinan kosong atau tidak dapat dibaca.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      await _restoreFromRawJson(rawJson, fileName: file.name);
    } catch (e) {
      if (!mounted) return;
      _showManualPasteDialog(errorMsg: '$e');
    }
  }

  Future<void> _restoreFromRawJson(String rawJson, {String? fileName}) async {
    try {
      final Map<String, dynamic> backupMap = jsonDecode(rawJson);
      if (!backupMap.containsKey('transaksi') ||
          !backupMap.containsKey('usaha')) {
        throw Exception('Format file salinan JSON tidak valid.');
      }

      final usahaList =
          List<Map<String, dynamic>>.from(backupMap['usaha'] ?? []);

      if (usahaList.isEmpty) {
        throw Exception(
            'Tidak ditemukan data profil usaha di dalam file salinan.');
      }

      Map<String, dynamic> selectedUsaha;

      if (usahaList.length == 1) {
        selectedUsaha = usahaList.first;
      } else {
        final chosen = await _showSelectUsahaDialog(usahaList);
        if (chosen == null) return;
        selectedUsaha = chosen;
      }

      final currentAkun = ref.read(authControllerProvider).value;
      final currentAkunId =
          currentAkun?.id ?? ref.read(sessionServiceProvider).muatIdAkun();

      if (currentAkunId == null || currentAkunId.isEmpty) {
        throw Exception(
            'Tidak ada akun yang sedang masuk. Masuk dulu sebelum memulihkan data.');
      }

      // Memulihkan berarti MENIMPA data usaha yang sekarang. Wajib
      // dikonfirmasi dulu — sebelumnya langsung jalan tanpa peringatan.
      final lanjut = await _konfirmasiTimpaData(
        namaUsaha: '${selectedUsaha['nama_usaha'] ?? 'Usaha'}',
      );
      if (lanjut != true) return;

      if (!mounted) return;
      setState(() => _isRestoring = true);

      final selectedUsahaId = selectedUsaha['id'];

      final filteredTransaksi = (backupMap['transaksi'] as List?)
              ?.where((t) => t['id_usaha'] == selectedUsahaId)
              .toList() ??
          [];

      final filteredHutang = (backupMap['hutang'] as List?)
              ?.where((h) => h['id_usaha'] == selectedUsahaId)
              .toList() ??
          [];

      final filteredPiutang = (backupMap['piutang'] as List?)
              ?.where((p) => p['id_usaha'] == selectedUsahaId)
              .toList() ??
          [];

      final appDb = ref.read(appDatabaseProvider);
      final db = await appDb.database;

      await db.transaction((txn) async {
        // Hanya menghapus milik akun yang sedang masuk. Sebelumnya
        // `txn.delete('usaha')` tanpa WHERE ikut menghabiskan data akun lain
        // di HP yang sama.
        final usahaMilikAkun = await txn.query(
          'usaha',
          columns: ['id'],
          where: 'id_akun = ?',
          whereArgs: [currentAkunId],
        );
        final idUsahaMilikAkun =
            usahaMilikAkun.map((r) => r['id'] as String).toList();

        if (idUsahaMilikAkun.isNotEmpty) {
          final placeholder =
              List.filled(idUsahaMilikAkun.length, '?').join(',');
          for (final tabel in ['transaksi', 'hutang', 'piutang']) {
            await txn.delete(
              tabel,
              where: 'id_usaha IN ($placeholder)',
              whereArgs: idUsahaMilikAkun,
            );
          }
          await txn.delete(
            'usaha',
            where: 'id_akun = ?',
            whereArgs: [currentAkunId],
          );
        }

        final mapUsaha = Map<String, dynamic>.from(selectedUsaha);
        mapUsaha['id_akun'] = currentAkunId;
        await txn.insert('usaha', mapUsaha);

        for (final item in filteredTransaksi) {
          await txn.insert('transaksi', Map<String, dynamic>.from(item));
        }
        for (final item in filteredHutang) {
          await txn.insert('hutang', Map<String, dynamic>.from(item));
        }
        for (final item in filteredPiutang) {
          await txn.insert('piutang', Map<String, dynamic>.from(item));
        }
      });

      refreshDataUsaha(ref);

      if (!mounted) return;
      final nama = selectedUsaha['nama_usaha'] ?? 'Usaha';
      final fileLabel = fileName != null ? ' ($fileName)' : '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Berhasil memulihkan data "$nama"$fileLabel ke akun Anda!'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memulihkan data: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isRestoring = false);
      }
    }
  }

  /// Pemulihan bersifat menimpa dan tidak bisa dibatalkan, jadi minta
  /// persetujuan eksplisit dulu.
  Future<bool?> _konfirmasiTimpaData({required String namaUsaha}) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Timpa data saat ini?'),
        content: Text(
          'Seluruh transaksi, hutang, dan piutang usaha Anda yang tersimpan '
          'sekarang akan DIHAPUS dan diganti dengan data "$namaUsaha" dari '
          'file salinan.\n\nTindakan ini tidak dapat dibatalkan. Sebaiknya '
          'buat salinan terbaru dulu sebelum melanjutkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Ya, timpa'),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>?> _showSelectUsahaDialog(
      List<Map<String, dynamic>> usahaList) async {
    Map<String, dynamic> selected = usahaList.first;

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: const Text(
              'Pilih Usaha untuk Dipulihkan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2B1F7C),
              ),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ditemukan ${usahaList.length} data usaha di file salinan. Silakan pilih usaha yang ingin Anda gunakan:',
                    style: const TextStyle(
                        fontSize: 12.5, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        children: usahaList.map((u) {
                          final isSelected = u['id'] == selected['id'];
                          final nama = u['nama_usaha'] ?? 'Tanpa Nama';
                          final jenis = u['jenis_usaha'] ?? 'Umum';
                          final alamat = u['alamat'] ?? '-';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFF3F0FF)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : const Color(0xFFE5E7EB),
                                width: isSelected ? 1.5 : 1.0,
                              ),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                setDialogState(() {
                                  selected = u;
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    Icon(
                                      isSelected
                                          ? Icons.radio_button_checked_rounded
                                          : Icons.radio_button_off_rounded,
                                      color: isSelected
                                          ? AppColors.primary
                                          : const Color(0xFF9CA3AF),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            nama,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF212936),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Kategori: $jenis | Alamat: $alamat',
                                            style: const TextStyle(
                                              fontSize: 11.5,
                                              color: Color(0xFF7C8495),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, null),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, selected),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Pulihkan Usaha Ini'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showManualPasteDialog({String? errorMsg}) {
    final jsonCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Pulihkan Data Salinan JSON',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2B1F7C),
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (errorMsg != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Pilihan file gagal ($errorMsg). Anda dapat menempel isinya di bawah ini:',
                    style: const TextStyle(fontSize: 11.5, color: Colors.redAccent),
                  ),
                ),
              const Text(
                'Salin (copy) seluruh isi file .json dari File Explorer HP Anda, lalu tempel di sini:',
                style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: jsonCtrl,
                maxLines: 6,
                style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                decoration: InputDecoration(
                  hintText: 'Tempel teks isi file JSON salinan di sini...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final rawJson = jsonCtrl.text.trim();
              if (rawJson.isEmpty) return;
              Navigator.pop(ctx);
              _restoreFromRawJson(rawJson);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Pulihkan Data'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                    'Backup & Pulihkan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2B1F7C),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEBE7FF),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.cloud_download_rounded,
                                  color: AppColors.primary,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 14),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Simpan Data ke HP',
                                      style: TextStyle(
                                        fontSize: 15.5,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF212936),
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Buat salinan data transaksi Anda agar aman dan tidak hilang.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF7C8495),
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 11),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F0FF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.history_rounded,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Salinan terakhir: $_lastBackupDate',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: Color(0xFF4B5563),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: (_isBackingUp || _isRestoring)
                                  ? null
                                  : _buatSalinanSekarang,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              icon: _isBackingUp
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.save_outlined,
                                      size: 18,
                                    ),
                              label: const Text(
                                'Buat Salinan Sekarang',
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEBE7FF),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.folder_rounded,
                                  color: AppColors.primary,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 14),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Pulihkan Data Lama',
                                      style: TextStyle(
                                        fontSize: 15.5,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF212936),
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Kembalikan data dari file salinan yang pernah Anda buat sebelumnya.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF7C8495),
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),

                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: OutlinedButton.icon(
                              onPressed: (_isBackingUp || _isRestoring)
                                  ? null
                                  : _pilihFileSalinan,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: const BorderSide(
                                  color: AppColors.primary,
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              icon: _isRestoring
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.primary,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.file_upload_outlined,
                                      size: 18,
                                    ),
                              label: const Text(
                                'Pilih File Salinan',
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 36),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.lock_outline_rounded,
                          size: 14,
                          color: Color(0xFF9CA3AF),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Data Anda disimpan dengan aman di dalam memori HP ini, tidak memerlukan internet.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
