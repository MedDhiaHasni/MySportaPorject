// Views/Player/HomeSettings.dart

//e5er 7ajet zedthom
// Bookings + Announcements tabs now wired to BookingStore (live updates)
// NEW: Added player profile photo upload support
// NEW: Added logout button
// REDESIGNED: Matches Manager Profile Page style

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sporta/Core/Theme/app_tokens.dart';
import 'package:sporta/Services/announcement_service.dart';
import 'package:sporta/Services/player_manager_auth_service.dart';
import 'package:sporta/Services/booking_store.dart';
import 'package:sporta/Services/firebase_identity_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sporta/Views/Auth/login_page.dart';

String _titleCaseDisplayName(String value) => value
    .trim()
    .split(RegExp(r'\s+'))
    .where((word) => word.isNotEmpty)
    .map(
      (word) => word.length == 1
          ? word.toUpperCase()
          : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
    )
    .join(' ');

class HomeSettings extends StatefulWidget {
  final String username;
  final String email;
  final String? phone;
  final String? avatarPath;
  final String? playerToken;
  final String? currentPhotoUrl;

  const HomeSettings({
    super.key,
    required this.username,
    required this.email,
    this.phone,
    this.avatarPath,
    this.playerToken,
    this.currentPhotoUrl,
  });

  @override
  State<HomeSettings> createState() => _HomeSettingsState();
}

class _HomeSettingsState extends State<HomeSettings>
    with TickerProviderStateMixin {
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
    _phoneCtrl = TextEditingController(text: widget.phone ?? '');
    _emailCtrl = TextEditingController(text: widget.email);
    _photoUrl = widget.currentPhotoUrl;

    final disableAnimations = WidgetsBinding
        .instance
        .platformDispatcher
        .accessibilityFeatures
        .disableAnimations;
    _entryAnim = AnimationController(
      vsync: this,
      duration: disableAnimations
          ? Duration.zero
          : const Duration(milliseconds: 240),
    );
    _entryFade = CurvedAnimation(
      parent: _entryAnim,
      curve: Curves.easeOut,
    ).drive(Tween(begin: 0.0, end: 1.0));
    _entrySlide = CurvedAnimation(
      parent: _entryAnim,
      curve: Curves.easeOutCubic,
    ).drive(Tween(begin: const Offset(0, 0.06), end: Offset.zero));
    if (disableAnimations) {
      _entryAnim.value = 1;
    } else {
      _entryAnim.forward();
    }

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

  void _onStoreChange() {
    if (mounted) setState(() {});
  }

  Future<String?> _getToken() async {
    if (widget.playerToken?.isNotEmpty == true) return widget.playerToken;
    return _storage.read(key: 'jwt_token');
  }

  Future<void> _logout() async {
    HapticFeedback.selectionClick();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.logout_rounded, color: scheme.error),
        title: Text('Log out?', style: theme.textTheme.titleLarge),
        content: Text(
          'Are you sure you want to log out?',
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: scheme.error,
              foregroundColor: scheme.onError,
            ),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseIdentityService.instance.signOut();
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
        _showError('Failed to logout: $e', onRetry: _logout);
      }
    }
  }

  Future<void> _updateProfilePhoto() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Builder(
          builder: (sheetContext) {
            final theme = Theme.of(sheetContext);
            final scheme = theme.colorScheme;
            return Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.lg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Update profile photo',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ListTile(
                    minLeadingWidth: AppSpacing.xxl,
                    leading: Icon(
                      Icons.camera_alt_rounded,
                      color: scheme.onSurfaceVariant,
                    ),
                    title: Text(
                      'Take a photo',
                      style: theme.textTheme.bodyLarge,
                    ),
                    onTap: () async {
                      Navigator.pop(sheetContext);
                      await _pickImage(ImageSource.camera);
                    },
                  ),
                  ListTile(
                    minLeadingWidth: AppSpacing.xxl,
                    leading: Icon(
                      Icons.photo_library_rounded,
                      color: scheme.onSurfaceVariant,
                    ),
                    title: Text(
                      'Choose from gallery',
                      style: theme.textTheme.bodyLarge,
                    ),
                    onTap: () async {
                      Navigator.pop(sheetContext);
                      await _pickImage(ImageSource.gallery);
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      HapticFeedback.selectionClick();
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        final token = await _getToken();
        if (!mounted) return;
        if (token == null) {
          _showError('Please login to update photo');
          return;
        }

        setState(() => _isUploadingPhoto = true);

        final photoUrl = await PlayerManagerAuthService.uploadProfilePhoto(
          token: token,
          imageFile: File(pickedFile.path),
        );

        if (!mounted) return;
        setState(() {
          _photoUrl = photoUrl;
          _isUploadingPhoto = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo updated!'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
        _showError(
          e.toString().replaceAll('Exception:', ''),
          onRetry: () => _pickImage(source),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    HapticFeedback.selectionClick();
    if (_usernameCtrl.text.trim().isEmpty) {
      _showError('Username cannot be empty');
      return;
    }
    setState(() => _isSaving = true);
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');
      await PlayerManagerAuthService.updateProfile(
        token: token,
        data: {
          'username': _usernameCtrl.text.trim(),
          'email': _emailCtrl.text.trim(),
          'phone': _phoneCtrl.text.trim(),
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Profile updated ✓',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
        await _storage.write(
          key: 'user_name',
          value: _usernameCtrl.text.trim(),
        );
      }
    } catch (e) {
      _showError(
        e.toString().replaceAll('Exception:', ''),
        onRetry: _saveProfile,
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String msg, {VoidCallback? onRetry}) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            msg,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onError,
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          action: onRetry == null
              ? null
              : SnackBarAction(
                  label: 'Retry',
                  textColor: Theme.of(context).colorScheme.onError,
                  onPressed: onRetry,
                ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.input),
          ),
          margin: const EdgeInsetsDirectional.all(AppSpacing.md),
        ),
      );

  String _getInitials() {
    final name = _titleCaseDisplayName(_usernameCtrl.text);
    if (name.isEmpty) return 'P';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  Widget _avatarPlaceholder(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return ColoredBox(
      color: scheme.secondaryContainer,
      child: Center(
        child: Text(
          _getInitials(),
          style: theme.textTheme.headlineMedium?.copyWith(
            color: scheme.onSecondaryContainer,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Profile settings', style: theme.textTheme.titleLarge),
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton.filled(
            tooltip: 'Save profile',
            onPressed: _isSaving ? null : _saveProfile,
            icon: _isSaving
                ? const SizedBox.square(
                    dimension: AppSpacing.md,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_rounded),
          ),
          IconButton(
            tooltip: 'Log out',
            icon: Icon(Icons.logout_rounded, color: scheme.error),
            onPressed: _logout,
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _entryFade,
        child: SlideTransition(
          position: _entrySlide,
          child: Column(
            children: [
              Container(
                width: double.infinity,
                color: scheme.surface,
                padding: const EdgeInsetsDirectional.all(AppSpacing.md),
                child: Column(
                  children: [
                    Semantics(
                      button: true,
                      label: 'Change profile photo',
                      child: InkWell(
                        onTap: _updateProfilePhoto,
                        customBorder: const CircleBorder(),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: AppSpacing.xxl * 2,
                              height: AppSpacing.xxl * 2,
                              decoration: BoxDecoration(
                                color: scheme.secondaryContainer,
                                shape: BoxShape.circle,
                              ),
                              child: ClipOval(
                                child: _isUploadingPhoto
                                    ? Center(
                                        child: SizedBox.square(
                                          dimension: AppSpacing.lg,
                                          child: CircularProgressIndicator(
                                            color: scheme.onSecondaryContainer,
                                          ),
                                        ),
                                      )
                                    : _photoUrl?.isNotEmpty == true
                                    ? Image.network(
                                        _photoUrl!,
                                        fit: BoxFit.cover,
                                        semanticLabel: 'Profile photo',
                                        loadingBuilder: (_, child, progress) =>
                                            progress == null
                                            ? child
                                            : _avatarPlaceholder(context),
                                        errorBuilder: (_, _, _) =>
                                            _avatarPlaceholder(context),
                                      )
                                    : _avatarPlaceholder(context),
                              ),
                            ),
                            PositionedDirectional(
                              bottom: 0,
                              end: 0,
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: NightMatchColors.actionLime,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: scheme.surface,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  color: NightMatchColors.onAction,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      _titleCaseDisplayName(_usernameCtrl.text),
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      _emailCtrl.text,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    FilledButton.tonalIcon(
                      onPressed: _updateProfilePhoto,
                      icon: const Icon(Icons.photo_camera_outlined),
                      label: const Text('Change photo'),
                    ),
                  ],
                ),
              ),

              Container(
                color: scheme.surface,
                child: TabBar(
                  controller: _tabCtrl,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  labelColor: scheme.onSurface,
                  unselectedLabelColor: scheme.onSurfaceVariant,
                  labelStyle: theme.textTheme.labelLarge,
                  unselectedLabelStyle: theme.textTheme.labelLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                  indicatorColor: scheme.primary,
                  indicatorSize: TabBarIndicatorSize.label,
                  tabs: const [
                    Tab(
                      icon: Icon(Icons.person_outline_rounded),
                      text: 'Profile',
                    ),
                    Tab(
                      icon: Icon(Icons.calendar_month_outlined),
                      text: 'Bookings',
                    ),
                    Tab(
                      icon: Icon(Icons.campaign_outlined),
                      text: 'Announcements',
                    ),
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
                      onSave: _saveProfile,
                      isSaving: _isSaving,
                    ),
                    _BookingsTab(bookings: BookingStore.instance.bookings),
                    _AnnouncementsTab(
                      announcements: BookingStore.instance.myAnnouncements,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//
// PROFILE TAB - Redesigned like Manager Profile
//
class _ProfileTab extends StatelessWidget {
  final TextEditingController usernameCtrl, phoneCtrl, emailCtrl;
  final VoidCallback onSave;
  final bool isSaving;

  const _ProfileTab({
    required this.usernameCtrl,
    required this.phoneCtrl,
    required this.emailCtrl,
    required this.onSave,
    this.isSaving = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final navH =
        kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom;

    return SingleChildScrollView(
      padding: EdgeInsetsDirectional.fromSTEB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        navH + AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsetsDirectional.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Personal information',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildTextField(
                    context: context,
                    controller: usernameCtrl,
                    label: 'Username',
                    icon: Icons.person_outline,
                    hint: 'Enter your username',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildTextField(
                    context: context,
                    controller: phoneCtrl,
                    label: 'Phone Number',
                    icon: Icons.phone_outlined,
                    hint: '+216 XX XXX XXX',
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildTextField(
                    context: context,
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

          const SizedBox(height: AppSpacing.md),
          Card(
            child: Padding(
              padding: const EdgeInsetsDirectional.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Account', style: theme.textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.xs),
                  Semantics(
                    button: true,
                    label: 'Change password. Update your account password.',
                    child: ListTile(
                      minLeadingWidth: AppSpacing.xxl,
                      contentPadding: EdgeInsets.zero,
                      minVerticalPadding: AppSpacing.xs,
                      onTap: () {
                        _showPasswordDialog(context);
                      },
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: scheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(AppRadius.input),
                        ),
                        child: Icon(
                          Icons.lock_outline,
                          color: scheme.onSecondaryContainer,
                          size: 24,
                        ),
                      ),
                      title: Text(
                        'Change password',
                        style: theme.textTheme.titleMedium,
                      ),
                      subtitle: Text(
                        'Update your account password',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: isSaving ? null : onSave,
              icon: isSaving
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_rounded),
              label: Text(isSaving ? 'Saving profile' : 'Save changes'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          minLines: 1,
          maxLines: 1,
          style: theme.textTheme.bodyLarge,
          textCapitalization: controller == usernameCtrl
              ? TextCapitalization.words
              : TextCapitalization.none,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            prefixIcon: Icon(
              icon,
              color: scheme.onSurfaceVariant,
              semanticLabel: label,
            ),
            filled: true,
            fillColor: scheme.surfaceContainerHighest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.input),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.input),
              borderSide: BorderSide(color: scheme.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.input),
              borderSide: BorderSide(color: scheme.onSurfaceVariant, width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.input),
              borderSide: BorderSide(color: scheme.outlineVariant),
            ),
            contentPadding: const EdgeInsetsDirectional.all(AppSpacing.md),
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

    showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final theme = Theme.of(context);
          final scheme = theme.colorScheme;
          return AlertDialog(
            icon: const Icon(Icons.lock_reset_rounded),
            title: Text('Change password', style: theme.textTheme.titleLarge),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _passwordField(oldPasswordCtrl, 'Current password', theme),
                  const SizedBox(height: AppSpacing.sm),
                  _passwordField(newPasswordCtrl, 'New password', theme),
                  const SizedBox(height: AppSpacing.sm),
                  _passwordField(
                    confirmPasswordCtrl,
                    'Confirm new password',
                    theme,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: isChanging
                    ? null
                    : () async {
                        if (oldPasswordCtrl.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Enter current password',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: scheme.onError,
                                ),
                              ),
                              backgroundColor: scheme.error,
                            ),
                          );
                          return;
                        }
                        if (newPasswordCtrl.text.length < 6) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Password must be at least 6 characters',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: scheme.onError,
                                ),
                              ),
                              backgroundColor: scheme.error,
                            ),
                          );
                          return;
                        }
                        if (newPasswordCtrl.text != confirmPasswordCtrl.text) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Passwords do not match',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: scheme.onError,
                                ),
                              ),
                              backgroundColor: scheme.error,
                            ),
                          );
                          return;
                        }

                        setModalState(() => isChanging = true);

                        try {
                          final storage = FlutterSecureStorage();
                          final token = await storage.read(key: 'jwt_token');
                          if (token == null) {
                            throw Exception('Not authenticated');
                          }

                          await PlayerManagerAuthService.changePassword(
                            token: token,
                            oldPassword: oldPasswordCtrl.text,
                            newPassword: newPasswordCtrl.text,
                          );

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Password changed successfully!'),
                                backgroundColor: scheme.tertiary,
                              ),
                            );
                            Navigator.pop(context);
                          }
                        } catch (e) {
                          if (context.mounted) {
                            setModalState(() => isChanging = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  e.toString().replaceAll('Exception:', ''),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: scheme.onError,
                                  ),
                                ),
                                backgroundColor: scheme.error,
                              ),
                            );
                          }
                        }
                      },
                child: isChanging
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Update password'),
              ),
            ],
          );
        },
      ),
    ).then((_) {
      oldPasswordCtrl.dispose();
      newPasswordCtrl.dispose();
      confirmPasswordCtrl.dispose();
    });
  }

  Widget _passwordField(
    TextEditingController controller,
    String label,
    ThemeData theme,
  ) => TextField(
    controller: controller,
    obscureText: true,
    style: theme.textTheme.bodyLarge,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: const Icon(Icons.lock_outline_rounded),
    ),
  );
}

//
// BOOKINGS TAB — wired to BookingStore
//
// TODO(night-match): expose the store's loading/error state so both lists can
// show skeletons and retryable errors without changing their fetch flow.
class _BookingsTab extends StatelessWidget {
  final List<LocalBooking> bookings;
  const _BookingsTab({required this.bookings});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final navH =
        kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom;
    if (bookings.isEmpty) {
      return _refreshableEmptyState(
        context,
        onRefresh: BookingStore.instance.refresh,
        child: const _EmptyState(
          Icons.calendar_month_outlined,
          'No bookings yet',
          'Your reservation history will appear here',
        ),
      );
    }
    return RefreshIndicator(
      color: scheme.onSurfaceVariant,
      onRefresh: BookingStore.instance.refresh,
      child: ListView.separated(
        padding: EdgeInsetsDirectional.fromSTEB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          navH + AppSpacing.md,
        ),
        itemCount: bookings.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (_, i) {
          final b = bookings[i];
          final isPaid = b.status == 'confirmed';
          final statusBackground = isPaid
              ? scheme.tertiaryContainer
              : scheme.secondaryContainer;
          final statusForeground = isPaid
              ? scheme.onTertiaryContainer
              : scheme.onSecondaryContainer;
          return Card(
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadiusDirectional.horizontal(
                    start: Radius.circular(AppRadius.card),
                  ),
                  child: SizedBox(
                    width: 80,
                    height: 112,
                    child: b.courtImageUrl.isNotEmpty
                        ? Image.network(
                            b.courtImageUrl,
                            fit: BoxFit.cover,
                            semanticLabel:
                                'Court image: ${_titleCaseDisplayName(b.courtName)}',
                            errorBuilder: (_, _, _) =>
                                _bookingImageFallback(context),
                          )
                        : _bookingImageFallback(context),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.all(AppSpacing.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _titleCaseDisplayName(b.courtName),
                          style: theme.textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          _titleCaseDisplayName(b.venueName),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          '${b.date}  ·  ${b.time}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                '${b.price} DT',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: scheme.onSurface,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: Text(
                                b.reference,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            Container(
                              constraints: const BoxConstraints(minHeight: 40),
                              padding: const EdgeInsetsDirectional.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: AppSpacing.xxs,
                              ),
                              decoration: BoxDecoration(
                                color: statusBackground,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.pill,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  isPaid ? 'Confirmed' : 'Pending',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: statusForeground,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _bookingImageFallback(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.stadium_rounded,
          color: scheme.onSurfaceVariant,
          size: AppSpacing.lg,
        ),
      ),
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final navH =
        kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom;
    if (announcements.isEmpty) {
      return _refreshableEmptyState(
        context,
        onRefresh: BookingStore.instance.refresh,
        child: const _EmptyState(
          Icons.campaign_outlined,
          'No announcements yet',
          'Announcements you post will appear here',
        ),
      );
    }
    return RefreshIndicator(
      color: scheme.onSurfaceVariant,
      onRefresh: BookingStore.instance.refresh,
      child: ListView.separated(
        padding: EdgeInsetsDirectional.fromSTEB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          navH + AppSpacing.md,
        ),
        itemCount: announcements.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (_, i) {
          final a = announcements[i];
          final spotsLeft = a.spotsLeft;
          return Container(
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: scheme.outlineVariant),
              boxShadow: theme.brightness == Brightness.dark
                  ? AppElevation.nightGlow
                  : const [],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header - shows court name
                Container(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                    AppSpacing.sm,
                    AppSpacing.sm,
                    AppSpacing.sm,
                    AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: const BorderRadiusDirectional.vertical(
                      top: Radius.circular(AppRadius.card),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: AppSpacing.xxl,
                            height: AppSpacing.xxl,
                            decoration: BoxDecoration(
                              color: scheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(
                                AppRadius.input,
                              ),
                            ),
                            child: Icon(
                              Icons.sports_soccer_rounded,
                              color: scheme.onSecondaryContainer,
                              size: AppSpacing.lg,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _titleCaseDisplayName(a.courtName),
                                  style: theme.textTheme.titleMedium,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: AppSpacing.xxs),
                                Text(
                                  '${a.date}  ·  ${a.startTime} – ${a.endTime}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 40),
                          padding: const EdgeInsetsDirectional.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xxs,
                          ),
                          decoration: BoxDecoration(
                            color: spotsLeft > 0
                                ? scheme.tertiaryContainer
                                : scheme.errorContainer,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(
                            spotsLeft > 0 ? '$spotsLeft spots left' : 'Full',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: spotsLeft > 0
                                  ? scheme.onTertiaryContainer
                                  : scheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Body
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                    AppSpacing.sm,
                    AppSpacing.xs,
                    AppSpacing.sm,
                    AppSpacing.sm,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a.description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _Stat(
                            Icons.people_rounded,
                            '${a.playersNeeded}',
                            'Needed',
                          ),
                          _Stat(
                            Icons.check_circle_outline_rounded,
                            '${a.acceptedCount}',
                            'Joined',
                          ),
                          _Stat(
                            Icons.hourglass_top_rounded,
                            '$spotsLeft',
                            'Left',
                          ),
                          IconButton(
                            tooltip: 'Delete announcement',
                            constraints: const BoxConstraints(
                              minWidth: 48,
                              minHeight: 48,
                            ),
                            onPressed: () => _deleteAnnouncement(context, a.id),
                            icon: Icon(
                              Icons.delete_outline_rounded,
                              color: scheme.error,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _deleteAnnouncement(
    BuildContext context,
    String announcementId,
  ) async {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.delete_outline_rounded, color: scheme.error),
        title: Text('Delete announcement?', style: theme.textTheme.titleLarge),
        content: Text(
          'This action cannot be undone.',
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: scheme.error,
              foregroundColor: scheme.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await BookingStore.instance.deleteAnnouncement(announcementId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Announcement deleted'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to delete: $e',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onError,
              ),
            ),
            backgroundColor: scheme.error,
            action: SnackBarAction(
              label: 'Retry',
              textColor: scheme.onError,
              onPressed: () => _deleteAnnouncement(context, announcementId),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String value, label;
  const _Stat(this.icon, this.value, this.label);
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.input),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: scheme.onSecondaryContainer),
          const SizedBox(width: AppSpacing.xxs),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(value, style: theme.textTheme.labelLarge),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Widget _refreshableEmptyState(
  BuildContext context, {
  required Future<void> Function() onRefresh,
  required Widget child,
}) => LayoutBuilder(
  builder: (context, constraints) => RefreshIndicator(
    color: Theme.of(context).colorScheme.onSurfaceVariant,
    onRefresh: onRefresh,
    child: ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: child,
        ),
      ],
    ),
  ),
);

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title, sub;
  const _EmptyState(this.icon, this.title, this.sub);
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: AppSpacing.xxl,
              color: scheme.onSurfaceVariant,
              semanticLabel: title,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(title, style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(
              sub,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
