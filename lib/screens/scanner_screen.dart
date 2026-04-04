import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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

class _ScannerScreenState extends State<ScannerScreen>
    with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  final SupabaseClient _supabase = Supabase.instance.client;

  File? _selectedImage;
  bool _isUploading = false;
  _UploadState _uploadState = _UploadState.idle;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

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
        _uploadState = _UploadState.idle;
      });
    } catch (e) {
      _showSnack('Failed to open camera');
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
        _uploadState = _UploadState.idle;
      });
    } catch (e) {
      _showSnack('Failed to open gallery');
    }
  }

  String _getFileExtension(String path) {
    final parts = path.split('.');
    if (parts.length < 2) return 'jpg';
    return parts.last.toLowerCase();
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isUploading = true;
      _uploadState = _UploadState.uploading;
    });
    _pulseController.repeat(reverse: true);

    try {
      final user = _supabase.auth.currentUser;
      final session = _supabase.auth.currentSession;
      final file = _selectedImage!;
      final extension = _getFileExtension(file.path);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$extension';
      final folder = user?.id ?? 'guest';
      final storagePath = '$folder/$fileName';

      final bytes = await file.readAsBytes();
      final mimeType = switch (extension) {
        'png' => 'image/png',
        'gif' => 'image/gif',
        'webp' => 'image/webp',
        _ => 'image/jpeg',
      };

      const supabaseUrl = 'https://gmdosbaezuykmyuiidhk.supabase.co';
      final uploadUrl = Uri.parse(
        '$supabaseUrl/storage/v1/object/food-images/$storagePath',
      );

      final response = await http.post(
        uploadUrl,
        headers: {
          'Authorization': 'Bearer ${session?.accessToken ?? ''}',
          'Content-Type': mimeType,
          'x-upsert': 'true',
        },
        body: bytes,
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Upload failed (${response.statusCode})');
      }

      final imageUrl =
          '$supabaseUrl/storage/v1/object/public/food-images/$storagePath';

      await _supabase.from('food_scans').insert({
        'user_id': user?.id,
        'image_path': storagePath,
        'image_url': imageUrl,
        'source': 'mobile_app',
        'status': 'uploaded',
        'created_at': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;
      setState(() {
        _uploadState = _UploadState.success;
      });
    } catch (e) {
      debugPrint('Scanner upload error: $e');
      if (!mounted) return;
      setState(() {
        _uploadState = _UploadState.error;
      });
      _showSnack('Upload failed. Please try again.');
    } finally {
      _pulseController.stop();
      _pulseController.reset();
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  void _clearImage() {
    setState(() {
      _selectedImage = null;
      _uploadState = _UploadState.idle;
    });
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final scale = (screenWidth / 375).clamp(0.85, 1.3);
    final hPad = max(14.0, 20.0 * scale);

    final textColor = isDark ? Colors.white : Colors.black;
    final subTextColor = isDark ? Colors.white60 : const Color(0xFF7B7B7B);

    final backgroundGradient = isDark
        ? const [Color(0xFF1A1625), Color(0xFF171320), Color(0xFF120F18)]
        : const [Color(0xFFF6F4FA), Color(0xFFF1EEFA), Color(0xFFEDE7F6)];

    final cardColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.white.withValues(alpha: 0.65);
    final cardBorder = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.white.withValues(alpha: 0.8);

    final hasImage = _selectedImage != null;

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
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              hPad,
              12 * scale,
              hPad,
              widget.hideBottomNav ? 120 : 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---- Header ----
                Row(
                  children: [
                    if (!widget.hideBottomNav)
                      IconButton(
                        onPressed: _handleBack,
                        icon: Icon(Icons.arrow_back, color: textColor, size: 28),
                      ),
                    Expanded(
                      child: Center(
                        child: Text(
                          'Food Scanner',
                          style: TextStyle(
                            fontSize: 26 * scale,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                          ),
                        ),
                      ),
                    ),
                    if (!widget.hideBottomNav) const SizedBox(width: 48),
                  ],
                ),
                SizedBox(height: 8 * scale),
                Center(
                  child: Text(
                    'Snap or pick a food photo to track your meals',
                    style: TextStyle(
                      fontSize: 13 * scale,
                      color: subTextColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                SizedBox(height: 20 * scale),

                // ---- Image preview ----
                AspectRatio(
                  aspectRatio: 4 / 3,
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      final borderAlpha = _isUploading
                          ? 0.3 + (_pulseController.value * 0.5)
                          : 0.0;
                      return Container(
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(24 * scale),
                          border: Border.all(
                            color: _isUploading
                                ? const Color(0xFF5E35B1)
                                    .withValues(alpha: borderAlpha)
                                : cardBorder,
                            width: _isUploading ? 2.5 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black
                                  .withValues(alpha: isDark ? 0.14 : 0.05),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: child,
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(23 * scale),
                      child: hasImage
                          ? Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.file(
                                  _selectedImage!,
                                  fit: BoxFit.cover,
                                ),
                                // Upload overlay
                                if (_isUploading)
                                  Container(
                                    color: Colors.black.withValues(alpha: 0.4),
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 3,
                                      ),
                                    ),
                                  ),
                                // Success overlay
                                if (_uploadState == _UploadState.success)
                                  Container(
                                    color: Colors.black.withValues(alpha: 0.35),
                                    child: Center(
                                      child: Container(
                                        width: 64 * scale,
                                        height: 64 * scale,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF4CAF50),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.check_rounded,
                                          color: Colors.white,
                                          size: 36 * scale,
                                        ),
                                      ),
                                    ),
                                  ),
                                // Clear button
                                if (!_isUploading)
                                  Positioned(
                                    top: 10 * scale,
                                    right: 10 * scale,
                                    child: GestureDetector(
                                      onTap: _clearImage,
                                      child: Container(
                                        width: 36 * scale,
                                        height: 36 * scale,
                                        decoration: BoxDecoration(
                                          color: Colors.black
                                              .withValues(alpha: 0.5),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.close_rounded,
                                          color: Colors.white,
                                          size: 20 * scale,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 72 * scale,
                                  height: 72 * scale,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF5E35B1)
                                        .withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.restaurant_menu_rounded,
                                    size: 36 * scale,
                                    color: const Color(0xFF5E35B1),
                                  ),
                                ),
                                SizedBox(height: 14 * scale),
                                Text(
                                  'No image selected',
                                  style: TextStyle(
                                    fontSize: 16 * scale,
                                    fontWeight: FontWeight.w700,
                                    color: textColor,
                                  ),
                                ),
                                SizedBox(height: 4 * scale),
                                Text(
                                  'Use the buttons below to get started',
                                  style: TextStyle(
                                    fontSize: 13 * scale,
                                    color: subTextColor,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
                SizedBox(height: 20 * scale),

                // ---- Action buttons ----
                Row(
                  children: [
                    Expanded(
                      child: _SourceButton(
                        icon: Icons.camera_alt_rounded,
                        label: 'Camera',
                        onTap: _isUploading ? null : _pickFromCamera,
                        cardColor: cardColor,
                        cardBorder: cardBorder,
                        isDark: isDark,
                        scale: scale,
                      ),
                    ),
                    SizedBox(width: 12 * scale),
                    Expanded(
                      child: _SourceButton(
                        icon: Icons.photo_library_rounded,
                        label: 'Gallery',
                        onTap: _isUploading ? null : _pickFromGallery,
                        cardColor: cardColor,
                        cardBorder: cardBorder,
                        isDark: isDark,
                        scale: scale,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 14 * scale),

                // ---- Upload button ----
                SizedBox(
                  width: double.infinity,
                  height: 54 * scale,
                  child: AnimatedOpacity(
                    opacity: hasImage && !_isUploading ? 1.0 : 0.5,
                    duration: const Duration(milliseconds: 200),
                    child: ElevatedButton.icon(
                      onPressed:
                          hasImage && !_isUploading ? _uploadImage : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5E35B1),
                        disabledBackgroundColor:
                            const Color(0xFF5E35B1).withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18 * scale),
                        ),
                        elevation: hasImage ? 4 : 0,
                        shadowColor:
                            const Color(0xFF5E35B1).withValues(alpha: 0.4),
                      ),
                      icon: Icon(
                        _isUploading
                            ? Icons.hourglass_top_rounded
                            : _uploadState == _UploadState.success
                                ? Icons.check_circle_rounded
                                : Icons.cloud_upload_rounded,
                        color: Colors.white,
                        size: 22 * scale,
                      ),
                      label: Text(
                        _isUploading
                            ? 'Uploading...'
                            : _uploadState == _UploadState.success
                                ? 'Uploaded!'
                                : 'Upload & scan',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16 * scale,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 22 * scale),

                // ---- Status card ----
                if (_uploadState != _UploadState.idle)
                  _StatusCard(
                    state: _uploadState,
                    isDark: isDark,
                    cardColor: cardColor,
                    cardBorder: cardBorder,
                    scale: scale,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---- Enums ----

enum _UploadState { idle, uploading, success, error }

// ---- Widgets ----

class _SourceButton extends StatelessWidget {
  const _SourceButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.cardColor,
    required this.cardBorder,
    required this.isDark,
    required this.scale,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color cardColor;
  final Color cardBorder;
  final bool isDark;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    final textColor = isDark ? Colors.white : Colors.black;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: disabled ? 0.45 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          height: 64 * scale,
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(18 * scale),
            border: Border.all(color: cardBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.10 : 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 38 * scale,
                height: 38 * scale,
                decoration: BoxDecoration(
                  color: const Color(0xFF5E35B1).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11 * scale),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF5E35B1),
                  size: 20 * scale,
                ),
              ),
              SizedBox(width: 10 * scale),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15 * scale,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.state,
    required this.isDark,
    required this.cardColor,
    required this.cardBorder,
    required this.scale,
  });

  final _UploadState state;
  final bool isDark;
  final Color cardColor;
  final Color cardBorder;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final Color accentColor;
    final IconData icon;
    final String title;
    final String subtitle;

    switch (state) {
      case _UploadState.uploading:
        accentColor = const Color(0xFF5E35B1);
        icon = Icons.cloud_sync_rounded;
        title = 'Uploading...';
        subtitle = 'Your food image is being uploaded and saved.';
      case _UploadState.success:
        accentColor = const Color(0xFF4CAF50);
        icon = Icons.check_circle_rounded;
        title = 'Upload complete';
        subtitle =
            'Your food image has been saved successfully.';
      case _UploadState.error:
        accentColor = const Color(0xFFE53935);
        icon = Icons.error_rounded;
        title = 'Upload failed';
        subtitle = 'Something went wrong. Please try again.';
      case _UploadState.idle:
        return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16 * scale),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20 * scale),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.10 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46 * scale,
            height: 46 * scale,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14 * scale),
            ),
            child: Icon(icon, color: accentColor, size: 24 * scale),
          ),
          SizedBox(width: 14 * scale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15 * scale,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                SizedBox(height: 2 * scale),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12 * scale,
                    color: isDark ? Colors.white54 : const Color(0xFF7B7B7B),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
