// manager_profile_page.dart — Views/Manager/manager_profile_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sporta/Core/Constants/app_colors.dart';
import 'package:sporta/Services/player_manager_auth_service.dart';
import 'package:sporta/Views/Auth/login_page.dart';

class ManagerProfilePage extends StatefulWidget {
  final String? token;
  final Map<String, dynamic>? currentUser;
  final Function(Map<String, dynamic>)? onProfileUpdated;

  const ManagerProfilePage({
    super.key,
    this.token,
    this.currentUser,
    this.onProfileUpdated,
  });

  @override
  State<ManagerProfilePage> createState() => _ManagerProfilePageState();
}

class _ManagerProfilePageState extends State<ManagerProfilePage> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _oldPasswordController;
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmPasswordController;

  final _storage = const FlutterSecureStorage();
  final ImagePicker _imagePicker = ImagePicker();
  
  bool _isLoading = false;
  bool _isChangingPassword = false;
  bool _isUploadingPhoto = false;
  String? _photoUrl;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentUser?['username'] ?? '');
    _emailController = TextEditingController(text: widget.currentUser?['email'] ?? '');
    _phoneController = TextEditingController(text: widget.currentUser?['phone'] ?? '');
    _oldPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _photoUrl = widget.currentUser?['photoUrl'];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<String?> _getToken() async {
    if (widget.token != null && widget.token!.isNotEmpty) {
      return widget.token;
    }
    return _storage.read(key: 'jwt_token');
  }

  Future<void> _logout() async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
      content: const Text('Are you sure you want to logout?', style: TextStyle(fontSize: 14)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel', style: TextStyle(color: kTextMid)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: kRed,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Logout'),
        ),
      ],
    ),
  );

  if (confirm == true) {
    try {
      // Clear all stored data
      await _storage.delete(key: 'jwt_token');
      await _storage.delete(key: 'user_role');
      await _storage.delete(key: 'user_id');
      await _storage.delete(key: 'user_name');
      
      if (mounted) {
        // Navigate to admin login page
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      }
    } catch (e) {
      _showError('Failed to logout: $e');
    }
  }
}

  Future<void> _updateProfile() async {
    if (_nameController.text.trim().isEmpty) {
      _showError('Name cannot be empty');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final updateData = {
        'username': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
      };

      final response = await PlayerManagerAuthService.updateProfile(
        token: token,
        data: updateData,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: kGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );

        if (widget.onProfileUpdated != null) {
          final updatedUser = {
            ...widget.currentUser!,
            'username': _nameController.text.trim(),
            'email': _emailController.text.trim(),
            'phone': _phoneController.text.trim(),
            'photoUrl': _photoUrl,
          };
          widget.onProfileUpdated!(updatedUser);
        }

        await _storage.write(key: 'user_name', value: _nameController.text.trim());
        
        Navigator.pop(context);
      }
    } catch (e) {
      _showError(e.toString().replaceAll('Exception:', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _changePassword() async {
    if (_oldPasswordController.text.isEmpty) {
      _showError('Please enter your current password');
      return;
    }
    if (_newPasswordController.text.isEmpty) {
      _showError('Please enter a new password');
      return;
    }
    if (_newPasswordController.text.length < 6) {
      _showError('Password must be at least 6 characters');
      return;
    }
    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showError('New passwords do not match');
      return;
    }

    setState(() => _isChangingPassword = true);

    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      await PlayerManagerAuthService.changePassword(
        token: token,
        oldPassword: _oldPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password changed successfully!'),
            backgroundColor: kGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );

        _oldPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();

        Navigator.pop(context);
      }
    } catch (e) {
      _showError(e.toString().replaceAll('Exception:', ''));
    } finally {
      if (mounted) setState(() => _isChangingPassword = false);
    }
  }

  Future<void> _updatePhoto() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: kPrimary),
              title: const Text('Take a photo'),
              onTap: () async {
                Navigator.pop(context);
                await _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: kPrimary),
              title: const Text('Choose from gallery'),
              onTap: () async {
                Navigator.pop(context);
                await _pickImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 80,
      );
      
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _isUploadingPhoto = true;
        });
        
        await _uploadPhoto();
      }
    } catch (e) {
      _showError('Failed to pick image: $e');
    }
  }

  Future<void> _uploadPhoto() async {
    if (_selectedImage == null) return;

    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final photoUrl = await PlayerManagerAuthService.uploadProfilePhoto(
        token: token,
        imageFile: _selectedImage!,
      );

      if (mounted) {
        setState(() {
          _photoUrl = photoUrl;
          _isUploadingPhoto = false;
        });

        if (widget.onProfileUpdated != null) {
          final updatedUser = {
            ...widget.currentUser!,
            'photoUrl': _photoUrl,
          };
          widget.onProfileUpdated!(updatedUser);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo updated!'),
            backgroundColor: kGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() => _isUploadingPhoto = false);
      _showError(e.toString().replaceAll('Exception:', ''));
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: kRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showPasswordDialog() {
    _oldPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Change Password',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _oldPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Current Password',
                prefixIcon: const Icon(Icons.lock_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'New Password',
                prefixIcon: const Icon(Icons.lock_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirm New Password',
                prefixIcon: const Icon(Icons.lock_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _oldPasswordController.clear();
              _newPasswordController.clear();
              _confirmPasswordController.clear();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _isChangingPassword ? null : _changePassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isChangingPassword
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Update Password'),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'M';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final initials = _getInitials(_nameController.text);

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        title: const Text(
          'Profile Settings',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: kTextDark,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _updateProfile,
            child: Text(
              'Save',
              style: TextStyle(
                color: _isLoading ? kTextLight : kPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
          // Logout button in AppBar
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.red),
            onPressed: _logout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Photo Section
            Container(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _updatePhoto,
                      child: Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [kPrimary, Color(0xFF007B7D)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              border: Border.all(
                                color: Colors.white,
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: kPrimary.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: _isUploadingPhoto
                                  ? const Center(
                                      child: SizedBox(
                                        width: 30,
                                        height: 30,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      ),
                                    )
                                  : (_selectedImage != null
                                      ? Image.file(
                                          _selectedImage!,
                                          fit: BoxFit.cover,
                                          width: 100,
                                          height: 100,
                                        )
                                      : (_photoUrl != null && _photoUrl!.isNotEmpty
                                          ? Image.network(
                                              _photoUrl!,
                                              fit: BoxFit.cover,
                                              width: 100,
                                              height: 100,
                                              errorBuilder: (_, __, ___) => Center(
                                                child: Text(
                                                  initials,
                                                  style: const TextStyle(
                                                    fontSize: 36,
                                                    fontWeight: FontWeight.w800,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            )
                                          : Center(
                                              child: Text(
                                                initials,
                                                style: const TextStyle(
                                                  fontSize: 36,
                                                  fontWeight: FontWeight.w800,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ))),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: kPrimary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _updatePhoto,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: kPrimary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.camera_alt_rounded,
                              size: 16,
                              color: kPrimary,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Change Photo',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: kPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Personal Information Section
            Container(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Personal Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: kTextDark,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _nameController,
                      label: 'Full Name',
                      icon: Icons.person_outline,
                      hint: 'Enter your full name',
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _emailController,
                      label: 'Email Address',
                      icon: Icons.email_outlined,
                      hint: 'your@email.com',
                      keyboardType: TextInputType.emailAddress,
                      enabled: false,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      icon: Icons.phone_outlined,
                      hint: '+216 XX XXX XXX',
                      keyboardType: TextInputType.phone,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Security Section
            Container(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Security',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: kTextDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      onTap: _showPasswordDialog,
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: kPrimary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.lock_outline,
                          color: kPrimary,
                          size: 22,
                        ),
                      ),
                      title: const Text(
                        'Change Password',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: kTextDark,
                        ),
                      ),
                      subtitle: const Text(
                        'Update your account password',
                        style: TextStyle(fontSize: 12, color: kTextMid),
                      ),
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        color: kTextLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: kTextMid,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: kPrimary, size: 20),
            filled: true,
            fillColor: enabled ? kBg : const Color(0xFFF5F5F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: kPrimary, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }
}



















/*// manager_profile_page.dart — Views/Manager/manager_profile_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sporta/Core/Constants/app_colors.dart';
import 'package:sporta/Services/player_manager_auth_service.dart';

class ManagerProfilePage extends StatefulWidget {
  final String? token;
  final Map<String, dynamic>? currentUser;
  final Function(Map<String, dynamic>)? onProfileUpdated;

  const ManagerProfilePage({
    super.key,
    this.token,
    this.currentUser,
    this.onProfileUpdated,
  });

  @override
  State<ManagerProfilePage> createState() => _ManagerProfilePageState();
}

class _ManagerProfilePageState extends State<ManagerProfilePage> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _oldPasswordController;
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmPasswordController;

  final _storage = const FlutterSecureStorage();
  final ImagePicker _imagePicker = ImagePicker();
  
  bool _isLoading = false;
  bool _isChangingPassword = false;
  bool _isUploadingPhoto = false;
  String? _photoUrl;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentUser?['username'] ?? '');
    _emailController = TextEditingController(text: widget.currentUser?['email'] ?? '');
    _phoneController = TextEditingController(text: widget.currentUser?['phone'] ?? '');
    _oldPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _photoUrl = widget.currentUser?['photoUrl'];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<String?> _getToken() async {
    if (widget.token != null && widget.token!.isNotEmpty) {
      return widget.token;
    }
    return _storage.read(key: 'jwt_token');
  }

  Future<void> _updateProfile() async {
    if (_nameController.text.trim().isEmpty) {
      _showError('Name cannot be empty');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final updateData = {
        'username': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
      };

      final response = await PlayerManagerAuthService.updateProfile(
        token: token,
        data: updateData,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: kGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );

        if (widget.onProfileUpdated != null) {
          final updatedUser = {
            ...widget.currentUser!,
            'username': _nameController.text.trim(),
            'email': _emailController.text.trim(),
            'phone': _phoneController.text.trim(),
            'photoUrl': _photoUrl,
          };
          widget.onProfileUpdated!(updatedUser);
        }

        await _storage.write(key: 'user_name', value: _nameController.text.trim());
        
        Navigator.pop(context);
      }
    } catch (e) {
      _showError(e.toString().replaceAll('Exception:', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _changePassword() async {
    if (_oldPasswordController.text.isEmpty) {
      _showError('Please enter your current password');
      return;
    }
    if (_newPasswordController.text.isEmpty) {
      _showError('Please enter a new password');
      return;
    }
    if (_newPasswordController.text.length < 6) {
      _showError('Password must be at least 6 characters');
      return;
    }
    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showError('New passwords do not match');
      return;
    }

    setState(() => _isChangingPassword = true);

    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      await PlayerManagerAuthService.changePassword(
        token: token,
        oldPassword: _oldPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password changed successfully!'),
            backgroundColor: kGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );

        _oldPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();

        Navigator.pop(context);
      }
    } catch (e) {
      _showError(e.toString().replaceAll('Exception:', ''));
    } finally {
      if (mounted) setState(() => _isChangingPassword = false);
    }
  }

  Future<void> _updatePhoto() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: kPrimary),
              title: const Text('Take a photo'),
              onTap: () async {
                Navigator.pop(context);
                await _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: kPrimary),
              title: const Text('Choose from gallery'),
              onTap: () async {
                Navigator.pop(context);
                await _pickImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 80,
      );
      
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _isUploadingPhoto = true;
        });
        
        await _uploadPhoto();
      }
    } catch (e) {
      _showError('Failed to pick image: $e');
    }
  }

  Future<void> _uploadPhoto() async {
    if (_selectedImage == null) return;

    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final photoUrl = await PlayerManagerAuthService.uploadProfilePhoto(
        token: token,
        imageFile: _selectedImage!,
      );

      if (mounted) {
        setState(() {
          _photoUrl = photoUrl;
          _isUploadingPhoto = false;
        });

        if (widget.onProfileUpdated != null) {
          final updatedUser = {
            ...widget.currentUser!,
            'photoUrl': _photoUrl,
          };
          widget.onProfileUpdated!(updatedUser);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo updated!'),
            backgroundColor: kGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() => _isUploadingPhoto = false);
      _showError(e.toString().replaceAll('Exception:', ''));
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: kRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showPasswordDialog() {
    _oldPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Change Password',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _oldPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Current Password',
                prefixIcon: const Icon(Icons.lock_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'New Password',
                prefixIcon: const Icon(Icons.lock_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirm New Password',
                prefixIcon: const Icon(Icons.lock_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _oldPasswordController.clear();
              _newPasswordController.clear();
              _confirmPasswordController.clear();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _isChangingPassword ? null : _changePassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isChangingPassword
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Update Password'),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'M';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final initials = _getInitials(_nameController.text);

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        title: const Text(
          'Profile Settings',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: kTextDark,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _updateProfile,
            child: Text(
              'Save',
              style: TextStyle(
                color: _isLoading ? kTextLight : kPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Photo Section
            Container(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _updatePhoto,
                      child: Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [kPrimary, Color(0xFF007B7D)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              border: Border.all(
                                color: Colors.white,
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: kPrimary.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: _isUploadingPhoto
                                  ? const Center(
                                      child: SizedBox(
                                        width: 30,
                                        height: 30,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      ),
                                    )
                                  : (_selectedImage != null
                                      ? Image.file(
                                          _selectedImage!,
                                          fit: BoxFit.cover,
                                          width: 100,
                                          height: 100,
                                        )
                                      : (_photoUrl != null && _photoUrl!.isNotEmpty
                                          ? Image.network(
                                              _photoUrl!,
                                              fit: BoxFit.cover,
                                              width: 100,
                                              height: 100,
                                              errorBuilder: (_, __, ___) => Center(
                                                child: Text(
                                                  initials,
                                                  style: const TextStyle(
                                                    fontSize: 36,
                                                    fontWeight: FontWeight.w800,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            )
                                          : Center(
                                              child: Text(
                                                initials,
                                                style: const TextStyle(
                                                  fontSize: 36,
                                                  fontWeight: FontWeight.w800,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ))),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: kPrimary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _updatePhoto,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: kPrimary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.camera_alt_rounded,
                              size: 16,
                              color: kPrimary,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Change Photo',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: kPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Personal Information Section
            Container(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Personal Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: kTextDark,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _nameController,
                      label: 'Full Name',
                      icon: Icons.person_outline,
                      hint: 'Enter your full name',
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _emailController,
                      label: 'Email Address',
                      icon: Icons.email_outlined,
                      hint: 'your@email.com',
                      keyboardType: TextInputType.emailAddress,
                      enabled: false,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      icon: Icons.phone_outlined,
                      hint: '+216 XX XXX XXX',
                      keyboardType: TextInputType.phone,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Security Section
            Container(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Security',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: kTextDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      onTap: _showPasswordDialog,
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: kPrimary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.lock_outline,
                          color: kPrimary,
                          size: 22,
                        ),
                      ),
                      title: const Text(
                        'Change Password',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: kTextDark,
                        ),
                      ),
                      subtitle: const Text(
                        'Update your account password',
                        style: TextStyle(fontSize: 12, color: kTextMid),
                      ),
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        color: kTextLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: kTextMid,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: kPrimary, size: 20),
            filled: true,
            fillColor: enabled ? kBg : const Color(0xFFF5F5F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: kPrimary, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }
}






***********************************************


// manager_profile_page.dart — Views/Manager/manager_profile_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sporta/Core/Constants/app_colors.dart';
import 'package:sporta/Services/player_manager_auth_service.dart';

class ManagerProfilePage extends StatefulWidget {
  final String? token;
  final Map<String, dynamic>? currentUser;
  final Function(Map<String, dynamic>)? onProfileUpdated;

  const ManagerProfilePage({
    super.key,
    this.token,
    this.currentUser,
    this.onProfileUpdated,
  });

  @override
  State<ManagerProfilePage> createState() => _ManagerProfilePageState();
}

class _ManagerProfilePageState extends State<ManagerProfilePage> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _oldPasswordController;
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmPasswordController;

  final _storage = const FlutterSecureStorage();
  final ImagePicker _imagePicker = ImagePicker();
  
  bool _isLoading = false;
  bool _isChangingPassword = false;
  bool _isUploadingPhoto = false;
  String? _photoUrl;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentUser?['username'] ?? '');
    _emailController = TextEditingController(text: widget.currentUser?['email'] ?? '');
    _phoneController = TextEditingController(text: widget.currentUser?['phone'] ?? '');
    _oldPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _photoUrl = widget.currentUser?['photoUrl'];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<String?> _getToken() async {
    if (widget.token != null && widget.token!.isNotEmpty) {
      return widget.token;
    }
    return _storage.read(key: 'jwt_token');
  }

  Future<void> _updateProfile() async {
    if (_nameController.text.trim().isEmpty) {
      _showError('Name cannot be empty');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final updateData = {
        'username': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
      };

      final response = await PlayerManagerAuthService.updateProfile(
        token: token,
        data: updateData,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: kGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );

        if (widget.onProfileUpdated != null) {
          final updatedUser = {
            ...widget.currentUser!,
            'username': _nameController.text.trim(),
            'email': _emailController.text.trim(),
            'phone': _phoneController.text.trim(),
            'photoUrl': _photoUrl,
          };
          widget.onProfileUpdated!(updatedUser);
        }

        await _storage.write(key: 'user_name', value: _nameController.text.trim());
        
        Navigator.pop(context);
      }
    } catch (e) {
      _showError(e.toString().replaceAll('Exception:', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _changePassword() async {
    if (_oldPasswordController.text.isEmpty) {
      _showError('Please enter your current password');
      return;
    }
    if (_newPasswordController.text.isEmpty) {
      _showError('Please enter a new password');
      return;
    }
    if (_newPasswordController.text.length < 6) {
      _showError('Password must be at least 6 characters');
      return;
    }
    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showError('New passwords do not match');
      return;
    }

    setState(() => _isChangingPassword = true);

    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      await PlayerManagerAuthService.changePassword(
        token: token,
        oldPassword: _oldPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password changed successfully!'),
            backgroundColor: kGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );

        _oldPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();

        Navigator.pop(context);
      }
    } catch (e) {
      _showError(e.toString().replaceAll('Exception:', ''));
    } finally {
      if (mounted) setState(() => _isChangingPassword = false);
    }
  }

  Future<void> _updatePhoto() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: kPrimary),
              title: const Text('Take a photo'),
              onTap: () async {
                Navigator.pop(context);
                await _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: kPrimary),
              title: const Text('Choose from gallery'),
              onTap: () async {
                Navigator.pop(context);
                await _pickImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 80,
      );
      
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _isUploadingPhoto = true;
        });
        
        await _uploadPhoto();
      }
    } catch (e) {
      _showError('Failed to pick image: $e');
    }
  }

  Future<void> _uploadPhoto() async {
    if (_selectedImage == null) return;

    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await PlayerManagerAuthService.updateProfilePhoto(
        token: token,
        photoFile: _selectedImage!,
      );

      if (mounted) {
        setState(() {
          _photoUrl = response['photoUrl'];
          _isUploadingPhoto = false;
        });

        if (widget.onProfileUpdated != null) {
          final updatedUser = {
            ...widget.currentUser!,
            'photoUrl': _photoUrl,
          };
          widget.onProfileUpdated!(updatedUser);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo updated!'),
            backgroundColor: kGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() => _isUploadingPhoto = false);
      _showError(e.toString().replaceAll('Exception:', ''));
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: kRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showPasswordDialog() {
    _oldPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Change Password',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _oldPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Current Password',
                prefixIcon: const Icon(Icons.lock_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'New Password',
                prefixIcon: const Icon(Icons.lock_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirm New Password',
                prefixIcon: const Icon(Icons.lock_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _oldPasswordController.clear();
              _newPasswordController.clear();
              _confirmPasswordController.clear();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _isChangingPassword ? null : _changePassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isChangingPassword
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Update Password'),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'M';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final initials = _getInitials(_nameController.text);

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        title: const Text(
          'Profile Settings',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: kTextDark,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _updateProfile,
            child: Text(
              'Save',
              style: TextStyle(
                color: _isLoading ? kTextLight : kPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Photo Section
            Container(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _updatePhoto,
                      child: Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [kPrimary, Color(0xFF007B7D)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              border: Border.all(
                                color: Colors.white,
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: kPrimary.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: _isUploadingPhoto
                                  ? const Center(
                                      child: SizedBox(
                                        width: 30,
                                        height: 30,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      ),
                                    )
                                  : (_selectedImage != null
                                      ? Image.file(
                                          _selectedImage!,
                                          fit: BoxFit.cover,
                                          width: 100,
                                          height: 100,
                                        )
                                      : (_photoUrl != null && _photoUrl!.isNotEmpty
                                          ? Image.network(
                                              _photoUrl!,
                                              fit: BoxFit.cover,
                                              width: 100,
                                              height: 100,
                                              errorBuilder: (_, __, ___) => Center(
                                                child: Text(
                                                  initials,
                                                  style: const TextStyle(
                                                    fontSize: 36,
                                                    fontWeight: FontWeight.w800,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            )
                                          : Center(
                                              child: Text(
                                                initials,
                                                style: const TextStyle(
                                                  fontSize: 36,
                                                  fontWeight: FontWeight.w800,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ))),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: kPrimary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _updatePhoto,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: kPrimary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.camera_alt_rounded,
                              size: 16,
                              color: kPrimary,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Change Photo',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: kPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Personal Information Section
            Container(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Personal Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: kTextDark,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _nameController,
                      label: 'Full Name',
                      icon: Icons.person_outline,
                      hint: 'Enter your full name',
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _emailController,
                      label: 'Email Address',
                      icon: Icons.email_outlined,
                      hint: 'your@email.com',
                      keyboardType: TextInputType.emailAddress,
                      enabled: false,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      icon: Icons.phone_outlined,
                      hint: '+216 XX XXX XXX',
                      keyboardType: TextInputType.phone,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Security Section
            Container(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Security',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: kTextDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      onTap: _showPasswordDialog,
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: kPrimary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.lock_outline,
                          color: kPrimary,
                          size: 22,
                        ),
                      ),
                      title: const Text(
                        'Change Password',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: kTextDark,
                        ),
                      ),
                      subtitle: const Text(
                        'Update your account password',
                        style: TextStyle(fontSize: 12, color: kTextMid),
                      ),
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        color: kTextLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: kTextMid,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: kPrimary, size: 20),
            filled: true,
            fillColor: enabled ? kBg : const Color(0xFFF5F5F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: kPrimary, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }
}*/