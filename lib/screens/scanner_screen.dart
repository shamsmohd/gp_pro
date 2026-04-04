import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({
    super.key,
    this.hideBottomNav = false,
    this.onBackToHome,
  });

  final bool hideBottomNav;
  final VoidCallback? onBackToHome;

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final ImagePicker _picker = ImagePicker();
  final SupabaseClient _supabase = Supabase.instance.client;

  File? _selectedImage;
  bool _isUploading = false;
  String? _uploadedImageUrl;
  String? _statusMessage;

  void _handleBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else if (widget.onBackToHome != null) {
      widget.onBackToHome!();
    }
  }

  Future<void> _pickFromCamera() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() {
        _selectedImage = File(pickedFile.path);
        _uploadedImageUrl = null;
        _statusMessage = 'Image selected from camera.';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Failed to open camera: $e';
      });
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() {
        _selectedImage = File(pickedFile.path);
        _uploadedImageUrl = null;
        _statusMessage = 'Image selected from gallery.';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Failed to open gallery: $e';
      });
    }
  }

  String _getFileExtension(String path) {
    final parts = path.split('.');
    if (parts.length < 2) return 'jpg';
    return parts.last.toLowerCase();
  }

  Future<void> _uploadImageToSupabase() async {
    if (_selectedImage == null) {
      setState(() {
        _statusMessage = 'Please select an image first.';
      });
      return;
    }

    try {
      setState(() {
        _isUploading = true;
        _statusMessage = 'Uploading image...';
      });

      final user = _supabase.auth.currentUser;
      final file = _selectedImage!;
      final extension = _getFileExtension(file.path);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$extension';
      final folder = user?.id ?? 'guest';
      final storagePath = '$folder/$fileName';

      await _supabase.storage.from('food-images').upload(
        storagePath,
        file,
        fileOptions: const FileOptions(upsert: true),
      );

      final imageUrl = _supabase.storage
          .from('food-images')
          .getPublicUrl(storagePath)
          .replaceFirst('.storage.supabase.co', '.supabase.co/storage');

      await _supabase.from('food_scans').insert({
        'user_id': user?.id,
        'image_path': storagePath,
        'image_url': imageUrl,
        'source': 'mobile_app',
        'status': 'uploaded',
        'created_at': DateTime.now().toIso8601String(),
      });

      setState(() {
        _uploadedImageUrl = imageUrl;
        _statusMessage = 'Image uploaded successfully.';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Upload failed: $e';
      });
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _clearImage() {
    setState(() {
      _selectedImage = null;
      _uploadedImageUrl = null;
      _statusMessage = 'Image cleared.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final backgroundGradient = isDark
        ? const [
      Color(0xFF1A1625),
      Color(0xFF171320),
      Color(0xFF120F18),
    ]
        : const [
      Color(0xFFF6F4FA),
      Color(0xFFF1EEFA),
      Color(0xFFEDE7F6),
    ];

    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final subTextColor =
        theme.textTheme.bodySmall?.color ?? const Color(0xFF7B7B7B);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: backgroundGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              22,
              12,
              22,
              widget.hideBottomNav ? 120 : 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (!widget.hideBottomNav)
                      IconButton(
                        onPressed: _handleBack,
                        icon: Icon(
                          Icons.arrow_back,
                          color: textColor,
                          size: 30,
                        ),
                      ),
                    Expanded(
                      child: Center(
                        child: Text(
                          'Food Scanner',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                          ),
                        ),
                      ),
                    ),
                    if (!widget.hideBottomNav)
                      const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  height: 340,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.white.withValues(alpha: 0.82),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.white.withValues(alpha: 0.65),
                    ),
                  ),
                  child: _selectedImage == null
                      ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image_outlined,
                        size: 72,
                        color: const Color(0xFF6C3FC8)
                            .withValues(alpha: 0.8),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No image selected',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Take a food photo or choose one from gallery',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: subTextColor,
                        ),
                      ),
                    ],
                  )
                      : ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Image.file(
                      _selectedImage!,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.camera_alt_outlined,
                        label: 'Camera',
                        onTap: _isUploading ? null : _pickFromCamera,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.photo_library_outlined,
                        label: 'Gallery',
                        onTap: _isUploading ? null : _pickFromGallery,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.cloud_upload_outlined,
                        label: _isUploading ? 'Uploading...' : 'Upload',
                        onTap: _isUploading ? null : _uploadImageToSupabase,
                        filled: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.delete_outline,
                        label: 'Clear',
                        onTap: _isUploading ? null : _clearImage,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.white.withValues(alpha: 0.82),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.white.withValues(alpha: 0.65),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Upload status',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _statusMessage ?? 'No action yet.',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: subTextColor,
                        ),
                      ),
                      if (_uploadedImageUrl != null) ...[
                        const SizedBox(height: 14),
                        Text(
                          'Saved URL:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 6),
                        SelectableText(
                          _uploadedImageUrl!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6C3FC8),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final isDisabled = onTap == null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          color: isDisabled
              ? Colors.grey.withValues(alpha: 0.2)
              : filled
              ? const Color(0xFF6C3FC8)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: filled
                ? const Color(0xFF6C3FC8)
                : const Color(0xFF6C3FC8).withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: filled ? Colors.white : const Color(0xFF6C3FC8),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: filled ? Colors.white : const Color(0xFF6C3FC8),
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}