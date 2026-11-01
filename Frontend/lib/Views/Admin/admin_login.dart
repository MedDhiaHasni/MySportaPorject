import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sporta/Core/Theme/app_tokens.dart';
import 'package:sporta/Services/admin_auth_service.dart';
import 'package:sporta/Services/firebase_identity_service.dart';
import 'package:sporta/Views/Admin/admindashboard.dart';
import 'package:sporta/Widgets/Buttons/app_buttons.dart';
import 'package:sporta/Widgets/Cards/app_card.dart';
import 'package:sporta/Widgets/Inputs/app_text_field.dart';
import 'package:sporta/Widgets/feedback_components.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _storage = const FlutterSecureStorage();

  bool _obscure = true;
  bool _remember = false;
  bool _isLoading = false;
  String? _errorMsg;

  late AnimationController _anim;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _fade = CurvedAnimation(
      parent: _anim,
      curve: Curves.easeOut,
    ).drive(Tween(begin: 0.0, end: 1.0));
    _slide = CurvedAnimation(
      parent: _anim,
      curve: Curves.easeOutCubic,
    ).drive(Tween(begin: const Offset(0, 0.06), end: Offset.zero));
    _anim.forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _anim.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context) && _anim.value != 1) {
      _anim.value = 1;
    }
  }

  Future<void> _handleLogin() async {
    setState(() => _errorMsg = null);
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.lightImpact();
    setState(() => _isLoading = true);

    try {
      final response = await AdminAuthService.login(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
      );

      if (response['token'] == null) {
        setState(() {
          _isLoading = false;
          _errorMsg = 'No token received';
        });
        return;
      }

      if (response['user']['user_role'] != 'admin') {
        setState(() {
          _isLoading = false;
          _errorMsg = 'Access denied. Admin privileges required.';
        });
        return;
      }

      final token = response['token'] as String;
      await _storage.write(key: 'jwt_token', value: token);
      await FirebaseIdentityService.instance.signInWithStrapiToken(
        token,
        force: true,
      );
      await _storage.write(
        key: 'user_role',
        value: response['user']['user_role'],
      );
      await _storage.write(
        key: 'user_id',
        value: response['user']['id'].toString(),
      );

      if (_remember) {
        await _storage.write(
          key: 'remember_email',
          value: _emailCtrl.text.trim(),
        );
      } else {
        await _storage.delete(key: 'remember_email');
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => AdminDashboard(adminToken: token, onLogout: () {}),
          ),
        );
      }
    } catch (error) {
      final message = error.toString().replaceAll('Exception:', '').trim();
      final normalizedMessage = message.toLowerCase();
      setState(() {
        _isLoading = false;
        _errorMsg =
            normalizedMessage.contains('429') ||
                normalizedMessage.contains('too many') ||
                normalizedMessage.contains('rate limit')
            ? 'Too many attempts, try again later'
            : message;
      });
    }
  }

  void _showForgotPassword() {
    final controller = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(
        context,
      ).colorScheme.surface.withValues(alpha: 0),
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: _ForgotPasswordSheet(
          controller: controller,
          onSend: () async {
            if (controller.text.trim().isEmpty) return;
            Navigator.pop(context);
            try {
              await AdminAuthService.forgotPassword(
                email: controller.text.trim(),
              );
              if (mounted) _showSnack('Reset link sent', isError: false);
            } catch (error) {
              if (!mounted) return;
              final message = error.toString();
              final normalizedMessage = message.toLowerCase();
              _showSnack(
                normalizedMessage.contains('429') ||
                        normalizedMessage.contains('too many') ||
                        normalizedMessage.contains('rate limit')
                    ? 'Too many attempts, try again later'
                    : message,
                isError: true,
              );
            }
          },
          onCancel: () => Navigator.pop(context),
        ),
      ),
    );
  }

  void _showSnack(String message, {required bool isError}) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: theme.textTheme.labelLarge?.copyWith(
            color: NightMatchColors.text,
          ),
        ),
        backgroundColor: isError
            ? theme.colorScheme.error
            : NightMatchColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsetsDirectional.all(AppSpacing.md),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: FadeTransition(
                opacity: _fade,
                child: SlideTransition(
                  position: _slide,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: NightMatchColors.brandTeal,
                          borderRadius: BorderRadius.circular(AppRadius.card),
                        ),
                        child: Column(
                          children: [
                            Image.asset(
                              'assets/sportawhite.png',
                              width: AppSpacing.xxl,
                              height: AppSpacing.xxl,
                              semanticLabel: 'Sporta',
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Sporta',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: NightMatchColors.text,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Admin sign in',
                        style: theme.textTheme.headlineLarge,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        'Sign in to manage your sports platform.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AppCard(child: _buildFormContent(context)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormContent(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_errorMsg != null) ...[
            _AdminErrorBanner(message: _errorMsg!),
            const SizedBox(height: AppSpacing.md),
          ],
          AppTextField(
            controller: _emailCtrl,
            label: 'Email address',
            hint: 'admin@sporta.tn',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Email is required';
              if (!value.contains('@')) return 'Enter a valid email address';
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _passwordCtrl,
            label: 'Password',
            hint: 'Enter your password',
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: _obscure,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleLogin(),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Password is required';
              if (value.length < 6) return 'Must be at least 6 characters';
              return null;
            },
            suffix: IconButton(
              tooltip: _obscure ? 'Show password' : 'Hide password',
              onPressed: () => setState(() => _obscure = !_obscure),
              icon: Icon(
                _obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: _remember,
                    onChanged: (value) =>
                        setState(() => _remember = value ?? false),
                  ),
                  Text('Remember me', style: theme.textTheme.bodyMedium),
                ],
              ),
              AppTextButton(
                label: 'Forgot password?',
                onPressed: _showForgotPassword,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          AppPrimaryButton(
            label: 'Sign in',
            icon: Icons.arrow_forward_rounded,
            isLoading: _isLoading,
            onPressed: _isLoading ? null : _handleLogin,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline_rounded, color: scheme.onSurfaceVariant),
              const SizedBox(width: AppSpacing.xs),
              Text('Admin access only', style: theme.textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdminErrorBanner extends StatelessWidget {
  const _AdminErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsetsDirectional.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(AppRadius.xs),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: theme.colorScheme.onErrorContainer,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ForgotPasswordSheet extends StatelessWidget {
  const _ForgotPasswordSheet({
    required this.controller,
    required this.onSend,
    required this.onCancel,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AppBottomSheet(
      title: 'Reset your password',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Enter your admin email and we’ll send a reset link.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: controller,
            label: 'Email address',
            hint: 'admin@sporta.tn',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => onSend(),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: AppSecondaryButton(label: 'Cancel', onPressed: onCancel),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppPrimaryButton(label: 'Send link', onPressed: onSend),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
