import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gp_pro/screens/settings_screen.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'about_app_screen.dart';
import 'sign_in_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    this.hideBottomNav = false,
    this.onBackToHome,
  });

  final bool hideBottomNav;
  final VoidCallback? onBackToHome;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<ProfileData> _profileFuture;

  final SupabaseClient _supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadProfile();
  }

  void _handleBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else if (widget.onBackToHome != null) {
      widget.onBackToHome!();
    }
  }

  Future<ProfileData> _loadProfile() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      return ProfileData.empty();
    }

    final metadata = user.userMetadata ?? {};
    final fullName = metadata['full_name'];
    final avatarUrl = metadata['avatar_url'];
    final email = user.email;

    debugPrint('Load profile - avatarUrl from metadata: $avatarUrl');

    String? fixedAvatarUrl;
    if (avatarUrl is String && avatarUrl.trim().isNotEmpty) {
      fixedAvatarUrl = avatarUrl.trim().replaceFirst(
        '.storage.supabase.co',
        '.supabase.co/storage',
      );
    }

    return ProfileData(
      fullName: fullName is String && fullName.trim().isNotEmpty
          ? fullName.trim()
          : _nameFromEmail(email),
      email: email ?? 'No email',
      avatarUrl: fixedAvatarUrl,
    );
  }

  String _nameFromEmail(String? email) {
    if (email == null || email.isEmpty) return 'User';
    return email.split('@').first;
  }

  Future<void> _refresh() async {
    setState(() {
      _profileFuture = _loadProfile();
    });
    await _profileFuture;
  }

  void _showSimpleDialog({
    required String title,
    required String message,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E22) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        content: Text(
          message,
          style: TextStyle(
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _getFileExtension(String path) {
    final parts = path.split('.');
    if (parts.length < 2) return 'jpg';
    return parts.last.toLowerCase();
  }

  Future<String?> _pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile == null) return null;
      return pickedFile.path;
    } catch (e) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to open gallery: $e')),
      );
      return null;
    }
  }

  Future<String?> _uploadProfileImage(File file) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final session = _supabase.auth.currentSession;
      if (session == null) return null;

      final extension = _getFileExtension(file.path);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$extension';
      final storagePath = '${user.id}/$fileName';

      final bytes = await file.readAsBytes();

      final mimeType = switch (extension) {
        'png' => 'image/png',
        'gif' => 'image/gif',
        'webp' => 'image/webp',
        _ => 'image/jpeg',
      };

      // Direct HTTP upload — bypasses SDK multipart handling which
      // can fail on iOS due to NSURLSession differences.
      final supabaseUrl = 'https://gmdosbaezuykmyuiidhk.supabase.co';
      final uploadUrl = Uri.parse(
        '$supabaseUrl/storage/v1/object/profile-images/$storagePath',
      );

      final response = await http.post(
        uploadUrl,
        headers: {
          'Authorization': 'Bearer ${session.accessToken}',
          'Content-Type': mimeType,
          'x-upsert': 'true',
        },
        body: bytes,
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint('Upload failed: ${response.statusCode} ${response.body}');
        throw Exception('Upload failed (${response.statusCode})');
      }

      return '$supabaseUrl/storage/v1/object/public/profile-images/$storagePath';
    } catch (e) {
      debugPrint('Upload error: $e');
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image upload failed: $e')),
      );
      return null;
    }
  }

  Future<void> _editProfile(ProfileData data) async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final nameController = TextEditingController(text: data.fullName);
    String? selectedImagePath;
    String? previewAvatarUrl = data.avatarUrl;
    bool isSaving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E1E22) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        final bottomTheme = Theme.of(context);
        final bottomIsDark = bottomTheme.brightness == Brightness.dark;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 46,
                    height: 5,
                    decoration: BoxDecoration(
                      color: bottomIsDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Edit profile',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: bottomIsDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 18),
                  GestureDetector(
                    onTap: () async {
                      final path = await _pickImageFromGallery();
                      if (path == null) return;

                      setModalState(() {
                        selectedImagePath = path;
                      });
                    },
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: bottomIsDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : const Color(0xFFF7F7FA),
                        border: Border.all(
                          color: const Color(0xFF5E35B1).withValues(alpha: 0.25),
                        ),
                      ),
                      child: ClipOval(
                        child: selectedImagePath != null
                            ? Image.file(
                          File(selectedImagePath!),
                          width: 110,
                          height: 110,
                          fit: BoxFit.cover,
                        )
                            : (previewAvatarUrl != null &&
                            previewAvatarUrl!.trim().isNotEmpty)
                            ? Image.network(
                          previewAvatarUrl!,
                          width: 110,
                          height: 110,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.person,
                            size: 44,
                            color: Colors.grey,
                          ),
                        )
                            : const Icon(
                          Icons.add_a_photo_outlined,
                          size: 36,
                          color: Color(0xFF5E35B1),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Tap to choose profile photo',
                    style: TextStyle(
                      fontSize: 13,
                      color: bottomIsDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    style: TextStyle(
                      color: bottomIsDark ? Colors.white : Colors.black,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Full name',
                      labelStyle: TextStyle(
                        color: bottomIsDark ? Colors.white70 : Colors.black54,
                      ),
                      filled: true,
                      fillColor: bottomIsDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : const Color(0xFFF7F7FA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5E35B1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      onPressed: isSaving
                          ? null
                          : () async {
                        try {
                          setModalState(() {
                            isSaving = true;
                          });

                          String? finalAvatarUrl = previewAvatarUrl;

                          if (selectedImagePath != null) {
                            final uploadedUrl =
                            await _uploadProfileImage(File(selectedImagePath!));
                            if (uploadedUrl != null) {
                              finalAvatarUrl = uploadedUrl;
                            }
                          }

                          debugPrint('Saving avatar_url: $finalAvatarUrl');

                          await _supabase.auth.updateUser(
                            UserAttributes(
                              data: {
                                'full_name': nameController.text.trim(),
                                'avatar_url': finalAvatarUrl ?? '',
                              },
                            ),
                          );

                          // Refresh session to get updated metadata
                          await _supabase.auth.refreshSession();

                          if (!mounted) return;
                          Navigator.pop(context);

                          setState(() {
                            _profileFuture = _loadProfile();
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Profile updated successfully'),
                            ),
                          );
                        } on AuthException catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.message)),
                          );
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
                        } finally {
                          if (mounted) {
                            setModalState(() {
                              isSaving = false;
                            });
                          }
                        }
                      },
                      child: Text(
                        isSaving ? 'Saving...' : 'Save changes',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showWatchSetupDialog(BuildContext context) {
    final uuid = _supabase.auth.currentUser?.id ?? 'Not signed in';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    bool copied = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Text('⌚', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Text(
                'Connect Watch',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'To pair your health watch:',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '1. Power on the watch\n'
                '2. Connect your phone to WiFi "Watch-Setup"\n'
                '3. Open http://192.168.4.1 in your browser\n'
                '4. Enter your WiFi name, password, and the UUID below',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.6,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Your User UUID',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.08),
                  ),
                ),
                child: Text(
                  uuid,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: isDark ? const Color(0xFF818CF8) : const Color(0xFF4F46E5),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: uuid));
                    setState(() => copied = true);
                  },
                  icon: Icon(
                    copied ? Icons.check : Icons.copy_outlined,
                    size: 18,
                    color: copied ? Colors.green : const Color(0xFF6366F1),
                  ),
                  label: Text(
                    copied ? 'Copied!' : 'Copy UUID',
                    style: TextStyle(
                      color: copied ? Colors.green : const Color(0xFF6366F1),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _resetPassword() async {
    try {
      final user = _supabase.auth.currentUser;
      final email = user?.email;

      if (email == null || email.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No email found for this account')),
        );
        return;
      }

      await _supabase.auth.resetPasswordForEmail(email);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password reset email sent to $email'),
        ),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reset password error: $e')),
      );
    }
  }

  Future<void> _logout() async {
    try {
      await _supabase.auth.signOut();

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const SignInScreen()),
            (route) => false,
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout error: $e')),
      );
    }
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
      Color(0xFFF4F1FB),
      Color(0xFFEDE7F6),
    ];

    final cardColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.white.withValues(alpha: 0.55);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.white.withValues(alpha: 0.7);
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final subTextColor =
        theme.textTheme.bodySmall?.color ?? const Color(0xFF9A98A3);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: backgroundGradient,
            begin: Alignment.topLeft,
            end: Alignment.topRight,
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: FutureBuilder<ProfileData>(
              future: _profileFuture,
              builder: (context, snapshot) {
                final profile = snapshot.data ?? ProfileData.empty();

                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    22,
                    12,
                    22,
                    widget.hideBottomNav ? 120 : 24,
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          if (!widget.hideBottomNav)
                            IconButton(
                              onPressed: _handleBack,
                              icon: Icon(
                                Icons.arrow_back,
                                size: 30,
                                color: textColor,
                              ),
                            ),
                          Expanded(
                            child: Center(
                              child: Text(
                                'Profile',
                                style: TextStyle(
                                  fontSize: 30,
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
                      if (snapshot.connectionState == ConnectionState.waiting &&
                          !snapshot.hasData)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 80),
                          child: CircularProgressIndicator(),
                        )
                      else if (snapshot.hasError)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E1E22) : Colors.white,
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: Text(
                            'Error loading profile:\n${snapshot.error}',
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 16,
                            ),
                          ),
                        )
                      else
                        Column(
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.fromLTRB(22, 28, 22, 28),
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: borderColor,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(
                                      alpha: isDark ? 0.14 : 0.04,
                                    ),
                                    blurRadius: 18,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    width: 138,
                                    height: 138,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isDark
                                          ? const Color(0xFF1E1E22)
                                          : Colors.white,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: isDark ? 0.16 : 0.07,
                                          ),
                                          blurRadius: 18,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(4),
                                      child: ClipOval(
                                        child: profile.avatarUrl != null
                                            ? Image.network(
                                          profile.avatarUrl!,
                                          width: 130,
                                          height: 130,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Icon(
                                            Icons.person,
                                            size: 60,
                                            color: isDark
                                                ? Colors.white70
                                                : Colors.grey,
                                          ),
                                        )
                                            : Icon(
                                          Icons.person,
                                          size: 60,
                                          color: isDark
                                              ? Colors.white70
                                              : Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 22),
                                  Text(
                                    profile.fullName,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      color: textColor,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    profile.email,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: subTextColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 22),
                                  GestureDetector(
                                    onTap: () => _editProfile(profile),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 26,
                                        vertical: 18,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(24),
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF353535),
                                            Color(0xFF2B2B2B),
                                          ],
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          Icon(
                                            Icons.edit_outlined,
                                            color: Colors.white,
                                            size: 26,
                                          ),
                                          SizedBox(width: 12),
                                          Text(
                                            'Edit profile',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 17,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            _ProfileMenuTile(
                              icon: Icons.watch_outlined,
                              title: 'Connect Watch',
                              onTap: () => _showWatchSetupDialog(context),
                            ),
                            const SizedBox(height: 16),
                            _ProfileMenuTile(
                              icon: Icons.settings_outlined,
                              title: 'Setting',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const SettingsScreen(),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            _ProfileMenuTile(
                              icon: Icons.lock_reset_outlined,
                              title: 'Reset password',
                              onTap: _resetPassword,
                            ),
                            const SizedBox(height: 16),
                            _ProfileMenuTile(
                              icon: Icons.info_outline,
                              title: 'About app',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const AboutAppScreen(),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            _ProfileMenuTile(
                              icon: Icons.logout_outlined,
                              title: 'Log out',
                              onTap: _logout,
                            ),
                          ],
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileMenuTile extends StatelessWidget {
  const _ProfileMenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final subColor =
        theme.textTheme.bodySmall?.color ?? const Color(0xFF9A9A9A);

    return Material(
      color: isDark
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.white.withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.white.withValues(alpha: 0.7),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.03),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 34,
                color: textColor,
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 38,
                color: subColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileData {
  final String fullName;
  final String email;
  final String? avatarUrl;

  ProfileData({
    required this.fullName,
    required this.email,
    required this.avatarUrl,
  });

  factory ProfileData.empty() {
    return ProfileData(
      fullName: 'User',
      email: 'No email',
      avatarUrl: null,
    );
  }
}