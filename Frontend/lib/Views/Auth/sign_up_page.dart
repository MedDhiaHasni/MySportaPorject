import 'package:flutter/material.dart';
import 'package:sporta/Core/Utils/validators.dart';
import 'package:sporta/Core/Theme/app_tokens.dart';
import 'package:sporta/Views/Auth/login_page.dart';
import 'package:sporta/Services/player_manager_auth_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sporta/Core/Utils/app_logger.dart';
import 'package:sporta/Widgets/Buttons/app_buttons.dart';
import 'package:sporta/Widgets/Cards/app_card.dart';
import 'package:sporta/Widgets/Inputs/app_text_field.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});
  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _obscure = true;
  bool _obscureConfirm = true;
  bool _agreed = false;
  bool _isLoading = false;
  String? _errorMessage;

  final _storage = const FlutterSecureStorage();

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _register() async {
    if (!_agreed) {
      setState(
        () => _errorMessage =
            'Please agree to the Terms of Service and Privacy Policy',
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final response = await PlayerManagerAuthService.register(
          username: _name.text.trim(),
          email: _email.text.trim(),
          password: _password.text.trim(),
          phone: _phone.text.trim(),
        );

        if (response['id'] != null) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Account created successfully! Please login.',
              ),
              backgroundColor: MatchdayColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );

          // Navigate back to login page
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginPage()),
          );
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Registration failed. Please try again.';
          });
        }
      } catch (error) {
        AppLogger.error('Registration error: $error');
        final message = error.toString().replaceFirst('Exception: ', '');
        final normalizedMessage = message.toLowerCase();
        setState(() {
          _isLoading = false;
          _errorMessage =
              normalizedMessage.contains('429') ||
                  normalizedMessage.contains('too many') ||
                  normalizedMessage.contains('rate limit')
              ? 'Too many attempts, try again later'
              : message;
        });
      }
    }
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
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: IconButton(
                      tooltip: 'Back',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsetsDirectional.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: MatchdayColors.brand,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: Row(
                      children: [
                        Image.asset(
                          'assets/sportawhite.png',
                          width: AppSpacing.xxl,
                          height: AppSpacing.xxl,
                          semanticLabel: 'Sporta',
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Sporta',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: MatchdayColors.onBrand,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Join the community',
                    style: theme.textTheme.headlineLarge,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    'Create your account and get ready to play.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppCard(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_errorMessage != null) ...[
                            _SignUpErrorBanner(message: _errorMessage!),
                            const SizedBox(height: AppSpacing.md),
                          ],
                          AppTextField(
                            controller: _name,
                            label: 'Full name',
                            hint: 'Your name',
                            prefixIcon: Icons.person_outline_rounded,
                            textInputAction: TextInputAction.next,
                            validator: (value) =>
                                (value == null || value.trim().length < 3)
                                ? 'Name must be at least 3 characters'
                                : null,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                            controller: _email,
                            label: 'Email address',
                            hint: 'your@email.com',
                            prefixIcon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            validator: Validators.email,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                            controller: _phone,
                            label: 'Phone number',
                            hint: '+216',
                            prefixIcon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            validator: Validators.phone,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                            controller: _password,
                            label: 'Password',
                            hint: 'At least 6 characters',
                            prefixIcon: Icons.lock_outline_rounded,
                            obscureText: _obscure,
                            textInputAction: TextInputAction.next,
                            validator: Validators.password,
                            suffix: IconButton(
                              tooltip: _obscure
                                  ? 'Show password'
                                  : 'Hide password',
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                            controller: _confirm,
                            label: 'Confirm password',
                            hint: 'Re-enter your password',
                            prefixIcon: Icons.lock_outline_rounded,
                            obscureText: _obscureConfirm,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _register(),
                            validator: (value) => Validators.confirmPassword(
                              value,
                              _password.text,
                            ),
                            suffix: IconButton(
                              tooltip: _obscureConfirm
                                  ? 'Show password'
                                  : 'Hide password',
                              onPressed: () => setState(
                                () => _obscureConfirm = !_obscureConfirm,
                              ),
                              icon: Icon(
                                _obscureConfirm
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          CheckboxListTile(
                            value: _agreed,
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            onChanged: (value) => setState(() {
                              _agreed = value ?? false;
                              _errorMessage = null;
                            }),
                            title: Text(
                              'I agree to the Terms of Service and Privacy Policy.',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          AppPrimaryButton(
                            label: 'Create account',
                            icon: Icons.arrow_forward_rounded,
                            isLoading: _isLoading,
                            onPressed: _isLoading || !_agreed
                                ? null
                                : _register,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'Already have an account?',
                        style: theme.textTheme.bodyMedium,
                      ),
                      AppTextButton(
                        label: 'Log in',
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SignUpErrorBanner extends StatelessWidget {
  const _SignUpErrorBanner({required this.message});

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
          borderRadius: BorderRadius.circular(AppRadius.sm),
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
