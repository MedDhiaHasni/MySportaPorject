// Views/Player/HomeSettings.dart

//e5er 7ajet zedthom
// Bookings + Announcements tabs now wired to BookingStore (live updates)
// NEW: Added player profile photo upload support
// NEW: Added logout button
// REDESIGNED: Matches Manager Profile Page style

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sporta/Core/Constants/app_colors.dart';
import 'package:sporta/Models/app_enums.dart';
import 'package:sporta/Services/announcement_service.dart';
import 'package:sporta/Services/player_manager_auth_service.dart';
import 'package:sporta/Services/booking_store.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sporta/Views/Auth/login_page.dart';

class HomeSettings extends StatefulWidget {
  final String username;
  final String email;
  final String? phone;
  final String? avatarPath;
  final String? playerToken;
  final String? currentPhotoUrl;

  const HomeSettings({super.key, required this.username, required this.email, this.phone, this.avatarPath, this.playerToken, this.currentPhotoUrl});

  @override
  State<HomeSettings> createState() => _HomeSettingsState();
}

class _HomeSettingsState extends State<HomeSettings> with TickerProviderStateMixin {
  late TabController _tabCtrl;
  late AnimationController _entryAnim;
  late Animation<double> _entryFade;
  late Animation<Offset> _entrySlide;
  final FocusNode _phoneFocus = FocusNode();
  late TextEditingController _usernameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  bool _isSaving = false;
  String? _photoUrl;
  bool _isUploadingPhoto = false;
  final ImagePicker _imagePicker = ImagePicker();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _usernameCtrl = TextEditingController(text: widget.username);
    _phoneCtrl    = TextEditingController(text: widget.phone ?? '');
    _emailCtrl    = TextEditingController(text: widget.email);
    _photoUrl = widget.currentPhotoUrl;

    _entryAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _entryFade = CurvedAnimation(parent: _entryAnim, curve: Curves.easeOut).drive(Tween(begin: 0.0, end: 1.0));
    _entrySlide = CurvedAnimation(parent: _entryAnim, curve: Curves.easeOutCubic).drive(Tween(begin: const Offset(0, 0.06), end: Offset.zero));
    _entryAnim.forward();

    BookingStore.instance.addListener(_onStoreChange);
  }

  @override
  void dispose() {
    BookingStore.instance.removeListener(_onStoreChange);
    _tabCtrl.dispose();
    _phoneFocus.dispose();
    _entryAnim.dispose();
    _usernameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  void _onStoreChange() { if (mounted) setState(() {}); }

  Future<String?> _getToken() async {
    if (widget.playerToken?.isNotEmpty == true) return widget.playerToken;
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
        await _storage.delete(key: 'jwt_token');
        await _storage.delete(key: 'user_role');
        await _storage.delete(key: 'user_id');
        await _storage.delete(key: 'user_name');
        
        if (mounted) {
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

  Future<void> _updateProfilePhoto() async {
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
        final token = await _getToken();
        if (token == null) {
          _showError('Please login to update photo');
          return;
        }
        
        setState(() => _isUploadingPhoto = true);
        
        final photoUrl = await PlayerManagerAuthService.uploadProfilePhoto(
          token: token,
          imageFile: File(pickedFile.path),
        );
        
        setState(() {
          _photoUrl = photoUrl;
          _isUploadingPhoto = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo updated!'),
            backgroundColor: kGreen,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() => _isUploadingPhoto = false);
      _showError(e.toString().replaceAll('Exception:', ''));
    }
  }

  Future<void> _saveProfile() async {
    if (_usernameCtrl.text.trim().isEmpty) { _showError('Username cannot be empty'); return; }
    setState(() => _isSaving = true);
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');
      await PlayerManagerAuthService.updateProfile(token: token, data: {'username': _usernameCtrl.text.trim(), 'email': _emailCtrl.text.trim(), 'phone': _phoneCtrl.text.trim()});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated ✓', style: TextStyle(fontWeight: FontWeight.w600)),
            backgroundColor: kGreen,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
        await _storage.write(key: 'user_name', value: _usernameCtrl.text.trim());
      }
    } catch (e) {
      _showError(e.toString().replaceAll('Exception:', ''));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg),
      backgroundColor: kRed,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ),
  );

  String _getInitials() {
    final name = _usernameCtrl.text;
    if (name.isEmpty) return 'P';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
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
          onPressed: _isSaving ? null : _saveProfile,
          child: Text(
            'Save',
            style: TextStyle(
              color: _isSaving ? kTextLight : kPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.logout_rounded, color: Colors.red),
          onPressed: _logout,
        ),
      ],
    ),
    body: Column(
      children: [
        // Profile Header Section (like Manager Profile)
        Container(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _updateProfilePhoto,
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
                              : (_photoUrl != null && _photoUrl!.isNotEmpty
                                  ? Image.network(
                                      _photoUrl!,
                                      fit: BoxFit.cover,
                                      width: 100,
                                      height: 100,
                                      errorBuilder: (_, __, ___) => Center(
                                        child: Text(
                                          _getInitials(),
                                          style: const TextStyle(
                                            fontSize: 36,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    )
                                  : (widget.avatarPath != null
                                      ? Image.asset(
                                          widget.avatarPath!,
                                          fit: BoxFit.cover,
                                          width: 100,
                                          height: 100,
                                          errorBuilder: (_, __, ___) => Center(
                                            child: Text(
                                              _getInitials(),
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
                                            _getInitials(),
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
                  onTap: _updateProfilePhoto,
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
        
        // Tab Bar - with icon above text like Profile tab
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabCtrl,
            labelColor: kPrimary,
            unselectedLabelColor: kTextMid,
            labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            indicatorColor: kPrimary,
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.label,
            tabs: [
              const Tab(icon: Icon(Icons.person_outline_rounded, size: 22), text: 'Profile'),
              const Tab(icon: Icon(Icons.calendar_month_outlined, size: 22), text: 'Bookings'),
              const Tab(icon: Icon(Icons.campaign_outlined, size: 22), text: 'Announcements'),
            ],
          ),
        ),
        
        // Tab Bar View
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              _ProfileTab(
                usernameCtrl: _usernameCtrl,
                phoneCtrl: _phoneCtrl,
                emailCtrl: _emailCtrl,
                avatarPath: widget.avatarPath,
                photoUrl: _photoUrl,
                isUploadingPhoto: _isUploadingPhoto,
                onUpdatePhoto: _updateProfilePhoto,
                onSave: _saveProfile,
                isSaving: _isSaving,
              ),
              _BookingsTab(bookings: BookingStore.instance.bookings),
              _AnnouncementsTab(announcements: BookingStore.instance.myAnnouncements),
            ],
          ),
        ),
      ],
    ),
  );
}

// 
// PROFILE TAB - Redesigned like Manager Profile
// 
class _ProfileTab extends StatelessWidget {
  final TextEditingController usernameCtrl, phoneCtrl, emailCtrl;
  final String? avatarPath;
  final String? photoUrl;
  final bool isUploadingPhoto;
  final VoidCallback onUpdatePhoto;
  final VoidCallback onSave;
  final bool isSaving;

  const _ProfileTab({
    required this.usernameCtrl,
    required this.phoneCtrl,
    required this.emailCtrl,
    this.avatarPath,
    this.photoUrl,
    this.isUploadingPhoto = false,
    required this.onUpdatePhoto,
    required this.onSave,
    this.isSaving = false,
  });

  @override
  Widget build(BuildContext context) {
    final navH = kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom;
    
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 20, 20, navH + 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                    controller: usernameCtrl,
                    label: 'Username',
                    icon: Icons.person_outline,
                    hint: 'Enter your username',
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: phoneCtrl,
                    label: 'Phone Number',
                    icon: Icons.phone_outlined,
                    hint: '+216 XX XXX XXX',
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: emailCtrl,
                    label: 'Email Address',
                    icon: Icons.email_outlined,
                    hint: 'your@email.com',
                    keyboardType: TextInputType.emailAddress,
                    enabled: false,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Security Section
          Container(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Account',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: kTextDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    onTap: () {
                      _showPasswordDialog(context);
                    },
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
          
          const SizedBox(height: 24),
          
          // Save Button
          GestureDetector(
            onTap: isSaving ? null : onSave,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isSaving 
                      ? [kPrimary.withOpacity(0.4), kPrimary.withOpacity(0.4)]
                      : [const Color(0xFF004748), kPrimary, const Color(0xFF007677)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: isSaving 
                    ? [] 
                    : [BoxShadow(color: kPrimary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: Center(
                child: isSaving 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_rounded, color: Colors.white, size: 17),
                          SizedBox(width: 7),
                          Text('Save Changes', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
                        ],
                      ),
              ),
            ),
          ),
        ],
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

  void _showPasswordDialog(BuildContext context) {
    final oldPasswordCtrl = TextEditingController();
    final newPasswordCtrl = TextEditingController();
    final confirmPasswordCtrl = TextEditingController();
    bool isChanging = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text(
            'Change Password',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: oldPasswordCtrl,
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
                controller: newPasswordCtrl,
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
                controller: confirmPasswordCtrl,
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
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isChanging ? null : () async {
                if (oldPasswordCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Enter current password'), backgroundColor: kRed),
                  );
                  return;
                }
                if (newPasswordCtrl.text.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password must be at least 6 characters'), backgroundColor: kRed),
                  );
                  return;
                }
                if (newPasswordCtrl.text != confirmPasswordCtrl.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Passwords do not match'), backgroundColor: kRed),
                  );
                  return;
                }
                
                setModalState(() => isChanging = true);
                
                try {
                  final storage = FlutterSecureStorage();
                  final token = await storage.read(key: 'jwt_token');
                  if (token == null) throw Exception('Not authenticated');
                  
                  await PlayerManagerAuthService.changePassword(
                    token: token,
                    oldPassword: oldPasswordCtrl.text,
                    newPassword: newPasswordCtrl.text,
                  );
                  
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Password changed successfully!'),
                        backgroundColor: kGreen,
                      ),
                    );
                    Navigator.pop(context);
                  }
                } catch (e) {
                  setModalState(() => isChanging = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString().replaceAll('Exception:', '')),
                      backgroundColor: kRed,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isChanging
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
      ),
    );
  }
}

// 
// BOOKINGS TAB — wired to BookingStore
// 
class _BookingsTab extends StatelessWidget {
  final List<LocalBooking> bookings;
  const _BookingsTab({required this.bookings});

  @override
  Widget build(BuildContext context) {
    final navH = kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom;
    if (bookings.isEmpty) return const _EmptyState(Icons.calendar_month_outlined, 'No bookings yet', 'Your reservation history will appear here');
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(20, 20, 20, navH + 20),
      itemCount: bookings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final b = bookings[i];
        final isPaid = b.status == 'confirmed';
        final sc = isPaid ? const Color(0xFF16A34A) : const Color(0xFFF59E0B);
        return Container(
          decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16), boxShadow: kElevation),
          child: Row(children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
              child: SizedBox(width: 72, height: 84, child: Stack(fit: StackFit.expand, children: [
                b.courtImageUrl.isNotEmpty ? Image.network(b.courtImageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: kPrimary.withOpacity(0.08), child: const Icon(Icons.stadium_rounded, color: kPrimary, size: 24))) : Container(color: kPrimary.withOpacity(0.08), child: const Icon(Icons.stadium_rounded, color: kPrimary, size: 24)),
                Container(color: Colors.black.withOpacity(0.15)),
              ])),
            ),
            const SizedBox(width: 12),
            Expanded(child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(b.courtName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kTextDark), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(b.venueName, style: const TextStyle(fontSize: 11, color: kTextMid)),
                const SizedBox(height: 2),
                Text('${b.date}  ·  ${b.time}', style: const TextStyle(fontSize: 11, color: kTextMid)),
                const SizedBox(height: 4),
                Row(children: [
                  Text('${b.price} DT', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: kPrimary)),
                  const SizedBox(width: 6),
                  Container(width: 4, height: 4, decoration: const BoxDecoration(color: kTextLight, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text(b.reference, style: const TextStyle(fontSize: 10, color: kTextMid, fontWeight: FontWeight.w500)),
                ]),
              ]),
            )),
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: sc.withOpacity(0.08), borderRadius: BorderRadius.circular(20), border: Border.all(color: sc.withOpacity(0.25))),
                child: Text(isPaid ? 'Confirmed' : 'Pending', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: sc)),
              ),
            ),
          ]),
        );
      },
    );
  }
}

// 
// ANNOUNCEMENTS TAB — Fixed to show court name like before
// 
class _AnnouncementsTab extends StatelessWidget {
  final List<AnnouncementData> announcements;
  const _AnnouncementsTab({required this.announcements});

  @override
  Widget build(BuildContext context) {
    final navH = kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom;
    if (announcements.isEmpty) return const _EmptyState(Icons.campaign_outlined, 'No announcements yet', 'Announcements you post will appear here');
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(20, 20, 20, navH + 20),
      itemCount: announcements.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (_, i) {
        final a = announcements[i];
        final spotsLeft = a.spotsLeft;
        return Container(
          decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(18), boxShadow: kElevation),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Header - shows court name
            Container(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              decoration: BoxDecoration(color: kPrimary.withOpacity(0.04), borderRadius: const BorderRadius.vertical(top: Radius.circular(18))),
              child: Row(children: [
                Container(width: 38, height: 38, decoration: BoxDecoration(color: kPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.sports_soccer_rounded, color: kPrimary, size: 18)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(a.courtName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: kTextDark), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text('${a.date}  ·  ${a.startTime} – ${a.endTime}', style: const TextStyle(fontSize: 11, color: kTextMid)),
                ])),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: spotsLeft > 0 ? kGreen.withOpacity(0.09) : kRed.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: (spotsLeft > 0 ? kGreen : kRed).withOpacity(0.25)),
                  ),
                  child: Text(spotsLeft > 0 ? '$spotsLeft spots left' : 'Full', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: spotsLeft > 0 ? kGreen : kRed)),
                ),
              ]),
            ),
            // Body
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(a.description, style: const TextStyle(fontSize: 12, color: kTextMid, height: 1.5)),
                const SizedBox(height: 12),
                Row(children: [
                  _Stat(Icons.people_rounded, '${a.playersNeeded}', 'Needed', kPrimary),
                  const SizedBox(width: 8),
                  _Stat(Icons.check_circle_outline_rounded, '${a.acceptedCount}', 'Joined', kGreen),
                  const SizedBox(width: 8),
                  _Stat(Icons.hourglass_top_rounded, '$spotsLeft', 'Left', kAmber),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _deleteAnnouncement(context, a.id),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(color: kRed.withOpacity(0.07), borderRadius: BorderRadius.circular(10), border: Border.all(color: kRed.withOpacity(0.2))),
                      child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.delete_outline_rounded, size: 13, color: kRed), SizedBox(width: 5), Text('Remove', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kRed))]),
                    ),
                  ),
                ]),
              ]),
            ),
          ]),
        );
      },
    );
  }

  Future<void> _deleteAnnouncement(BuildContext context, String announcementId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete announcement?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: kRed))),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await BookingStore.instance.deleteAnnouncement(announcementId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Announcement deleted'),
            backgroundColor: kGreen,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: $e'),
            backgroundColor: kRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

class _Stat extends StatelessWidget {
  final IconData icon; final String value, label; final Color color;
  const _Stat(this.icon, this.value, this.label, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(color: color.withOpacity(0.07), borderRadius: BorderRadius.circular(10)),
    child: Column(children: [Icon(icon, size: 13, color: color), const SizedBox(height: 2), Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color)), Text(label, style: const TextStyle(fontSize: 9, color: kTextMid))]),
  );
}

class _EmptyState extends StatelessWidget {
  final IconData icon; final String title, sub;
  const _EmptyState(this.icon, this.title, this.sub);
  @override
  Widget build(BuildContext context) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Icon(icon, size: 56, color: kTextLight.withOpacity(0.5)),
    const SizedBox(height: 14),
    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kTextDark)),
    const SizedBox(height: 6),
    Text(sub, style: const TextStyle(fontSize: 13, color: kTextMid), textAlign: TextAlign.center),
  ]));
}

